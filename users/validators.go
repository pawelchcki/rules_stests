package users

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
)

// *ModelValidator containing two parts:
// - Validator: write the form/json checking rule according to the doc https://github.com/go-playground/validator
// - DataModel: fill with data from Validator after invoking common.Bind(c, self)
// Then, you can just call model.save() after the data is ready in DataModel.
type UserModelValidator struct {
	User struct {
		Username string `form:"username" json:"username" binding:"required,min=4,max=255,excludes=/"`
		Email    string `form:"email" json:"email" binding:"required,email"`
		Password string `form:"password" json:"password" binding:"required,min=8,max=255"`
		Bio      string `form:"bio" json:"bio" binding:"max=1024"`
		Image    string `form:"image" json:"image" binding:"omitempty,url"`
	} `json:"user"`
	userModel UserModel `json:"-"`
	supplied  map[string]json.RawMessage
}

// There are some difference when you create or update a model, you need to fill the DataModel before
// update so that you can use your origin data to cheat the validator.
// BTW, you can put your general binding logic here such as setting password.
func (self *UserModelValidator) Bind(c *gin.Context) error {
	supplied, err := common.SuppliedFields(c, "user")
	if err != nil {
		return err
	}
	if err := common.Bind(c, self); err != nil {
		return err
	}
	self.supplied = supplied
	if _, ok := supplied["username"]; ok {
		self.userModel.Username = self.User.Username
	}
	if _, ok := supplied["email"]; ok {
		self.userModel.Email = self.User.Email
	}
	if _, ok := supplied["bio"]; ok {
		self.userModel.Bio = self.User.Bio
	}

	if _, passwordSupplied := supplied["password"]; passwordSupplied {
		if err := self.userModel.setPassword(self.User.Password); err != nil {
			return err
		}
	}
	if _, imageSupplied := supplied["image"]; imageSupplied && self.User.Image != "" {
		self.userModel.Image = &self.User.Image
	}
	return nil
}

// You can put the default value of a Validator here
func NewUserModelValidator() UserModelValidator {
	userModelValidator := UserModelValidator{}
	return userModelValidator
}

func NewUserModelValidatorFillWith(userModel UserModel) UserModelValidator {
	userModelValidator := NewUserModelValidator()
	userModelValidator.userModel = userModel
	userModelValidator.User.Username = userModel.Username
	userModelValidator.User.Email = userModel.Email
	userModelValidator.User.Bio = userModel.Bio
	userModelValidator.User.Password = common.RandomPassword

	if userModel.Image != nil {
		userModelValidator.User.Image = *userModel.Image
	}
	return userModelValidator
}

type LoginValidator struct {
	User struct {
		Email    string `form:"email" json:"email" binding:"required,email"`
		Password string `form:"password" json:"password" binding:"required,min=8,max=255"`
	} `json:"user"`
	userModel UserModel `json:"-"`
}

func (self *LoginValidator) Bind(c *gin.Context) error {
	err := common.Bind(c, self)
	if err != nil {
		return err
	}

	self.userModel.Email = self.User.Email
	return nil
}

// You can put the default value of a Validator here
func NewLoginValidator() LoginValidator {
	loginValidator := LoginValidator{}
	return loginValidator
}
