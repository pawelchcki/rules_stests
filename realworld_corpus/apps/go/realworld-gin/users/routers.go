package users

import (
	"encoding/json"
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/gorm"
	"net/http"
)

func UsersRegister(router *gin.RouterGroup) {
	router.POST("", UsersRegistration)
	router.POST("/", UsersRegistration)
	router.POST("/login", UsersLogin)
}

func UserRegister(router *gin.RouterGroup) {
	router.GET("", UserRetrieve)
	router.GET("/", UserRetrieve)
	router.PUT("", UserUpdate)
	router.PUT("/", UserUpdate)
}

func ProfileRetrieveRegister(router *gin.RouterGroup) {
	router.GET("/:username", ProfileRetrieve)
}

func ProfileRegister(router *gin.RouterGroup) {
	router.POST("/:username/follow", ProfileFollow)
	router.DELETE("/:username/follow", ProfileUnfollow)
}

func ProfileRetrieve(c *gin.Context) {
	username := c.Param("username")
	userModel, err := FindOneUser(&UserModel{Username: username})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("profile", errors.New("not found")))
		return
	}
	profileSerializer := ProfileSerializer{c, userModel}
	response, err := profileSerializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"profile": response})
}

func ProfileFollow(c *gin.Context) {
	username := c.Param("username")
	userModel, err := FindOneUser(&UserModel{Username: username})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("profile", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(UserModel)
	err = myUserModel.following(userModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	serializer := ProfileSerializer{c, userModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"profile": response})
}

func ProfileUnfollow(c *gin.Context) {
	username := c.Param("username")
	userModel, err := FindOneUser(&UserModel{Username: username})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("profile", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(UserModel)

	err = myUserModel.unFollowing(userModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	serializer := ProfileSerializer{c, userModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"profile": response})
}

func UsersRegistration(c *gin.Context) {
	userModelValidator := NewUserModelValidator()
	if err := userModelValidator.Bind(c); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(err))
		return
	}

	// A duplicate of either identity is a conflict rather than a validation
	// failure under the RealWorld contract.
	if taken, field := identityTaken(userModelValidator.userModel, 0); taken {
		c.JSON(http.StatusConflict, common.NewError(field, errors.New("has already been taken")))
		return
	}
	if err := SaveOne(&userModelValidator.userModel); err != nil {
		if writeIdentityConflict(c, userModelValidator.userModel, 0, err) {
			return
		}
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.Set("my_user_model", userModelValidator.userModel)
	serializer := UserSerializer{c}
	c.JSON(http.StatusCreated, gin.H{"user": serializer.Response()})
}

func UsersLogin(c *gin.Context) {
	loginValidator := NewLoginValidator()
	if err := loginValidator.Bind(c); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(err))
		return
	}
	userModel, err := FindOneUser(&UserModel{Email: loginValidator.userModel.Email})

	if err != nil {
		c.JSON(http.StatusUnauthorized, common.NewError("credentials", errors.New("invalid")))
		return
	}

	if userModel.checkPassword(loginValidator.User.Password) != nil {
		c.JSON(http.StatusUnauthorized, common.NewError("credentials", errors.New("invalid")))
		return
	}
	UpdateContextUserModel(c, userModel.ID)
	serializer := UserSerializer{c}
	c.JSON(http.StatusOK, gin.H{"user": serializer.Response()})
}

func UserRetrieve(c *gin.Context) {
	serializer := UserSerializer{c}
	c.JSON(http.StatusOK, gin.H{"user": serializer.Response()})
}

func UserUpdate(c *gin.Context) {
	myUserModel := c.MustGet("my_user_model").(UserModel)
	// A field set to null is a request to clear an identity the contract
	// requires, and is rejected. Because the validator is pre-filled from the
	// stored user, an explicit null is otherwise indistinguishable from an
	// omitted field.
	supplied, err := common.SuppliedFields(c, "user")
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("body", errors.New("is invalid")))
		return
	}
	var blanked []string
	for _, field := range []string{"username", "email", "password"} {
		if common.IsExplicitNull(supplied, field) {
			blanked = append(blanked, field)
		}
	}
	if len(blanked) > 0 {
		c.JSON(http.StatusUnprocessableEntity, common.BlankFieldError(blanked...))
		return
	}

	userModelValidator := NewUserModelValidatorFillWith(myUserModel)
	if err := userModelValidator.Bind(c); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(err))
		return
	}

	userModelValidator.userModel.ID = myUserModel.ID
	if taken, field := identityTaken(userModelValidator.userModel, myUserModel.ID); taken {
		c.JSON(http.StatusConflict, common.NewError(field, errors.New("has already been taken")))
		return
	}
	err = common.GetDB().Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&myUserModel).Updates(userModelValidator.userModel).Error; err != nil {
			return err
		}
		// A struct update skips empty values. Nullable bio and image clears need
		// explicit column writes in the same transaction as the scalar update.
		if cleared(supplied, "bio") {
			if err := tx.Model(&myUserModel).Update("bio", "").Error; err != nil {
				return err
			}
		}
		if cleared(supplied, "image") {
			if err := tx.Model(&myUserModel).Update("image", nil).Error; err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		if writeIdentityConflict(c, userModelValidator.userModel, myUserModel.ID, err) {
			return
		}
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	UpdateContextUserModel(c, myUserModel.ID)
	serializer := UserSerializer{c}
	c.JSON(http.StatusOK, gin.H{"user": serializer.Response()})
}

// cleared reports whether the request asked to empty a nullable field, which
// the contract expresses as either an empty string or null.
func cleared(supplied map[string]json.RawMessage, key string) bool {
	raw, ok := supplied[key]
	return ok && (string(raw) == `""` || string(raw) == "null")
}

// identityTaken reports whether another user already owns the candidate's
// username or email, naming the field that collided.
func identityTaken(candidate UserModel, selfID uint) (bool, string) {
	if existing, err := FindOneUser(&UserModel{Username: candidate.Username}); err == nil && existing.ID != selfID {
		return true, "username"
	}
	if existing, err := FindOneUser(&UserModel{Email: candidate.Email}); err == nil && existing.ID != selfID {
		return true, "email"
	}
	return false, ""
}

// writeIdentityConflict handles the race where another request claims an
// identity after the precheck but before this request writes it.
func writeIdentityConflict(c *gin.Context, candidate UserModel, selfID uint, err error) bool {
	if !errors.Is(err, gorm.ErrDuplicatedKey) {
		return false
	}
	if taken, field := identityTaken(candidate, selfID); taken {
		c.JSON(http.StatusConflict, common.NewError(field, errors.New("has already been taken")))
		return true
	}
	return false
}
