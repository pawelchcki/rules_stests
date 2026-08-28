package users

import (
	"testing"

	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestUnfollowHardDeletesRelationship(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:hard-delete-follow?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}, &FollowModel{}); err != nil {
		t.Fatal(err)
	}
	follower := UserModel{Username: "follower", Email: "follower@example.test", PasswordHash: "unused"}
	followed := UserModel{Username: "followed", Email: "followed@example.test", PasswordHash: "unused"}
	if err := db.Create(&follower).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&followed).Error; err != nil {
		t.Fatal(err)
	}
	if err := follower.following(followed); err != nil {
		t.Fatal(err)
	}
	if err := follower.unFollowing(followed); err != nil {
		t.Fatal(err)
	}
	if err := follower.following(followed); err != nil {
		t.Fatal(err)
	}

	var count int64
	if err := db.Unscoped().Model(&FollowModel{}).
		Where("following_id = ? AND followed_by_id = ?", followed.ID, follower.ID).
		Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("follow row count=%d, want 1", count)
	}
}
