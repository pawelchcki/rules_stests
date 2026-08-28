package users

import (
	"github.com/gin-gonic/gin"

	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/gorm"
)

type ProfileSerializer struct {
	C *gin.Context
	UserModel
}

// The RealWorld contract represents an unset bio or image as JSON null rather
// than as an empty string, so both are optional in the response schema.
type ProfileResponse struct {
	ID        uint    `json:"-"`
	Username  string  `json:"username"`
	Bio       *string `json:"bio"`
	Image     *string `json:"image"`
	Following bool    `json:"following"`
}

// nullableText renders an empty value as JSON null.
func nullableText(value string) *string {
	if value == "" {
		return nil
	}
	return &value
}

// Put your response logic including wrap the userModel here.
func (self *ProfileSerializer) Response() (ProfileResponse, error) {
	return self.ResponseWithDB(common.GetDB())
}

func (self *ProfileSerializer) ResponseWithDB(db *gorm.DB) (ProfileResponse, error) {
	myUserModel := self.C.MustGet("my_user_model").(UserModel)
	following, err := myUserModel.isFollowingWithDB(db, self.UserModel)
	if err != nil {
		return ProfileResponse{}, err
	}
	image := ""
	if self.Image != nil {
		image = *self.Image
	}
	profile := ProfileResponse{
		ID:        self.ID,
		Username:  self.Username,
		Bio:       nullableText(self.Bio),
		Image:     nullableText(image),
		Following: following,
	}
	return profile, nil
}

type UserSerializer struct {
	c *gin.Context
}

type UserResponse struct {
	Username string  `json:"username"`
	Email    string  `json:"email"`
	Bio      *string `json:"bio"`
	Image    *string `json:"image"`
	Token    string  `json:"token"`
}

func (self *UserSerializer) Response() UserResponse {
	myUserModel := self.c.MustGet("my_user_model").(UserModel)
	image := ""
	if myUserModel.Image != nil {
		image = *myUserModel.Image
	}
	user := UserResponse{
		Username: myUserModel.Username,
		Email:    myUserModel.Email,
		Bio:      nullableText(myUserModel.Bio),
		Image:    nullableText(image),
		Token:    common.GenToken(myUserModel.ID),
	}
	return user
}
