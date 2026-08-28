package users

import (
	"errors"

	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// Models should only be concerned with database schema, more strict checking should be put in validator.
//
// More detail you can find here: http://jinzhu.me/gorm/models.html#model-definition
//
// HINT: If you want to split null and "", you should use *string instead of string.
type UserModel struct {
	ID           uint    `gorm:"primaryKey"`
	Username     string  `gorm:"column:username;uniqueIndex"`
	Email        string  `gorm:"column:email;uniqueIndex"`
	Bio          string  `gorm:"column:bio;size:1024"`
	Image        *string `gorm:"column:image"`
	PasswordHash string  `gorm:"column:password;not null"`
}

// A hack way to save ManyToMany relationship,
// gorm will build the alias as FollowingBy <-> FollowingByID <-> "following_by_id".
//
// DB schema looks like: id, created_at, updated_at, deleted_at, following_id, followed_by_id.
//
// Retrieve them by:
//
//	db.Where(FollowModel{ FollowingID:  v.ID, FollowedByID: u.ID, }).First(&follow)
//	db.Where(FollowModel{ FollowedByID: u.ID, }).Find(&follows)
//
// More details about gorm.Model: http://jinzhu.me/gorm/models.html#conventions
type FollowModel struct {
	gorm.Model
	Following    UserModel
	FollowingID  uint `gorm:"uniqueIndex:idx_follow_edge"`
	FollowedBy   UserModel
	FollowedByID uint `gorm:"uniqueIndex:idx_follow_edge"`
}

// Migrate the schema of database if needed
func AutoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(&UserModel{}, &FollowModel{})
}

// What's bcrypt? https://en.wikipedia.org/wiki/Bcrypt
// Golang bcrypt doc: https://godoc.org/golang.org/x/crypto/bcrypt
// You can change the value in bcrypt.DefaultCost to adjust the security index.
//
//	err := userModel.setPassword("password0")
func (u *UserModel) setPassword(password string) error {
	if len(password) == 0 {
		return errors.New("password should not be empty!")
	}
	bytePassword := []byte(password)
	// Make sure the second param `bcrypt generator cost` between [4, 32)
	passwordHash, err := bcrypt.GenerateFromPassword(bytePassword, bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.PasswordHash = string(passwordHash)
	return nil
}

// Database will only save the hashed string, you should check it by util function.
//
//	if err := serModel.checkPassword("password0"); err != nil { password error }
func (u *UserModel) checkPassword(password string) error {
	bytePassword := []byte(password)
	byteHashedPassword := []byte(u.PasswordHash)
	return bcrypt.CompareHashAndPassword(byteHashedPassword, bytePassword)
}

// You could input the conditions and it will return an UserModel in database with error info.
//
//	userModel, err := FindOneUser(&UserModel{Username: "username0"})
func FindOneUser(condition interface{}) (UserModel, error) {
	db := common.GetDB()
	var model UserModel
	err := db.Where(condition).First(&model).Error
	return model, err
}

// You could input an UserModel which will be saved in database returning with error info
//
//	if err := SaveOne(&userModel); err != nil { ... }
func SaveOne(data interface{}) error {
	db := common.GetDB()
	err := db.Save(data).Error
	return err
}

// You could update properties of an UserModel to database returning with error info.
//
//	err := db.Model(userModel).Updates(UserModel{Username: "wangzitian0"}).Error
func (model *UserModel) Update(data interface{}) error {
	db := common.GetDB()
	err := db.Model(model).Updates(data).Error
	return err
}

// You could add a following relationship as userModel1 following userModel2
//
//	err = userModel1.following(userModel2)
func (u UserModel) following(v UserModel) error {
	db := common.GetDB()
	follow := FollowModel{
		FollowingID:  v.ID,
		FollowedByID: u.ID,
	}
	return db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "following_id"}, {Name: "followed_by_id"}},
		DoNothing: true,
	}).Create(&follow).Error
}

// You could check whether  userModel1 following userModel2
//
//	followingBool, err = myUserModel.isFollowing(self.UserModel)
func (u UserModel) isFollowing(v UserModel) (bool, error) {
	return u.isFollowingWithDB(common.GetDB(), v)
}

func (u UserModel) isFollowingWithDB(db *gorm.DB, v UserModel) (bool, error) {
	if u.ID == 0 {
		return false, nil
	}
	var follow FollowModel
	err := db.Where(FollowModel{
		FollowingID:  v.ID,
		FollowedByID: u.ID,
	}).First(&follow).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// You could delete a following relationship as userModel1 following userModel2
//
//	err = userModel1.unFollowing(userModel2)
func (u UserModel) unFollowing(v UserModel) error {
	db := common.GetDB()
	err := db.Unscoped().Where("following_id = ? AND followed_by_id = ?", v.ID, u.ID).Delete(&FollowModel{}).Error
	return err
}

// GetFollowingsWithDB keeps feed reads on the caller's transaction and exposes
// database failures instead of converting them into an empty following list.
func (u UserModel) GetFollowingsWithDB(db *gorm.DB) ([]UserModel, error) {
	var follows []FollowModel
	var followings []UserModel
	if err := db.Preload("Following").Where(FollowModel{
		FollowedByID: u.ID,
	}).Find(&follows).Error; err != nil {
		return nil, err
	}
	for _, follow := range follows {
		followings = append(followings, follow.Following)
	}
	return followings, nil
}
