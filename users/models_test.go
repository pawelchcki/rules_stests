package users

import (
	"encoding/json"
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

func TestProfileRetrievePropagatesLookupDatabaseErrors(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:profile-retrieve-database-error?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	if err := sqlDB.Close(); err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(http.MethodGet, "/api/profiles/example", nil)
	context.Params = gin.Params{{Key: "username", Value: "example"}}
	context.Set("my_user_model", UserModel{})

	ProfileRetrieve(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"database"`) {
		t.Fatalf("body=%s, want database error", recorder.Body.String())
	}
}

func TestFollowChangesRollBackWhenResponseReadFails(t *testing.T) {
	for _, test := range []struct {
		name      string
		method    string
		handler   func(*gin.Context)
		seedCount int64
	}{
		{name: "follow", method: http.MethodPost, handler: ProfileFollow, seedCount: 0},
		{name: "unfollow", method: http.MethodDelete, handler: ProfileUnfollow, seedCount: 1},
	} {
		t.Run(test.name, func(t *testing.T) {
			db, err := gorm.Open(sqlite.Open("file:follow-response-transaction-"+test.name+"?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
			if err != nil {
				t.Fatal(err)
			}
			common.DB = db
			if err := db.AutoMigrate(&UserModel{}, &FollowModel{}); err != nil {
				t.Fatal(err)
			}
			follower := UserModel{Username: "follower-" + test.name, Email: "follower-" + test.name + "@example.test", PasswordHash: "unused"}
			followed := UserModel{Username: "followed-" + test.name, Email: "followed-" + test.name + "@example.test", PasswordHash: "unused"}
			if err := db.Create(&follower).Error; err != nil {
				t.Fatal(err)
			}
			if err := db.Create(&followed).Error; err != nil {
				t.Fatal(err)
			}
			if test.seedCount == 1 {
				if err := follower.following(followed); err != nil {
					t.Fatal(err)
				}
			}

			wantErr := errors.New("forced follow response read failure")
			callbackName := "test:fail-follow-response-read-" + test.name
			if err := db.Callback().Query().Before("gorm:query").Register(callbackName, func(tx *gorm.DB) {
				if tx.Statement.Table == "follow_models" {
					tx.AddError(wantErr)
				}
			}); err != nil {
				t.Fatal(err)
			}

			recorder := httptest.NewRecorder()
			gin.SetMode(gin.TestMode)
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(test.method, "/api/profiles/"+followed.Username+"/follow", nil)
			context.Params = gin.Params{{Key: "username", Value: followed.Username}}
			context.Set("my_user_model", follower)

			test.handler(context)
			if recorder.Code != http.StatusUnprocessableEntity {
				t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
			}
			if err := db.Callback().Query().Remove(callbackName); err != nil {
				t.Fatal(err)
			}
			var count int64
			if err := db.Model(&FollowModel{}).Count(&count).Error; err != nil {
				t.Fatal(err)
			}
			if count != test.seedCount {
				t.Fatalf("follow count=%d, want rollback to %d", count, test.seedCount)
			}
		})
	}
}

func TestUserUpdateValuesContainOnlySuppliedFields(t *testing.T) {
	image := "https://example.test/new.png"
	validator := NewUserModelValidatorFillWith(UserModel{
		ID:       1,
		Username: "original",
		Email:    "original@example.test",
		Bio:      "original bio",
	})
	validator.userModel.Image = &image
	updates := userUpdateValues(validator, map[string]json.RawMessage{"image": json.RawMessage(`"https://example.test/new.png"`)})
	if len(updates) != 1 || updates["image"] != validator.userModel.Image {
		t.Fatalf("updates=%v, want only the supplied image", updates)
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
	if err := db.Callback().Update().Before("gorm:update").Register("test:fail-nullable-clear", func(tx *gorm.DB) {
		if tx.Statement.Table == "user_models" {
			tx.AddError(wantErr)
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
