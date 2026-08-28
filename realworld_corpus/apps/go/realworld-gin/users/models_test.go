package users

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
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

func TestFollowingStatusPropagatesDatabaseErrors(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:follow-read-error?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}, &FollowModel{}); err != nil {
		t.Fatal(err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	if err := sqlDB.Close(); err != nil {
		t.Fatal(err)
	}
	if _, err := (UserModel{ID: 1}).isFollowing(UserModel{ID: 2}); err == nil {
		t.Fatal("follow-status query on closed database unexpectedly succeeded")
	}
}

func TestUserUpdateRollsBackScalarChangeWhenNullableClearFails(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:user-update-transaction?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}); err != nil {
		t.Fatal(err)
	}
	user := UserModel{Username: "original", Email: "original@example.test", Bio: "old bio", PasswordHash: "unused"}
	if err := db.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	wantErr := errors.New("forced nullable clear failure")
	updateCalls := 0
	if err := db.Callback().Update().Before("gorm:update").Register("test:fail-nullable-clear", func(tx *gorm.DB) {
		if tx.Statement.Table == "user_models" {
			updateCalls++
			if updateCalls == 2 {
				tx.AddError(wantErr)
			}
		}
	}); err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(
		http.MethodPut,
		"/api/user",
		strings.NewReader(`{"user":{"username":"changed","bio":""}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	UserUpdate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var stored UserModel
	if err := db.First(&stored, user.ID).Error; err != nil {
		t.Fatal(err)
	}
	if stored.Username != user.Username || stored.Bio != user.Bio {
		t.Fatalf("stored username=%q bio=%q, want rollback to %q and %q", stored.Username, stored.Bio, user.Username, user.Bio)
	}
}

func TestUserUpdateRequiresEnvelopeButAllowsEmptyUpdate(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:user-update-envelope?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}); err != nil {
		t.Fatal(err)
	}
	user := UserModel{Username: "envelope-user", Email: "envelope@example.test", PasswordHash: "unused"}
	if err := db.Create(&user).Error; err != nil {
		t.Fatal(err)
	}

	for _, test := range []struct {
		name string
		body string
		want int
	}{
		{name: "missing", body: `{}`, want: http.StatusUnprocessableEntity},
		{name: "empty", body: `{"user":{}}`, want: http.StatusOK},
	} {
		t.Run(test.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			gin.SetMode(gin.TestMode)
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(http.MethodPut, "/api/user", strings.NewReader(test.body))
			context.Request.Header.Set("Content-Type", "application/json")
			context.Set("my_user_model", user)

			UserUpdate(context)
			if recorder.Code != test.want {
				t.Fatalf("status=%d body=%s, want %d", recorder.Code, recorder.Body.String(), test.want)
			}
		})
	}
}
