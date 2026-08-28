package users

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestClaimUserIDRejectsMalformedValues(t *testing.T) {
	tests := []struct {
		name  string
		value interface{}
		want  bool
	}{
		{name: "missing", want: false},
		{name: "null", value: nil, want: false},
		{name: "string", value: "1", want: false},
		{name: "float", value: float64(1), want: false},
		{name: "zero", value: json.Number("0"), want: false},
		{name: "fractional", value: json.Number("1.5"), want: false},
		{name: "exponent", value: json.Number("1e3"), want: false},
		{name: "valid", value: json.Number("1"), want: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			claims := jwt.MapClaims{}
			if test.name != "missing" {
				claims["id"] = test.value
			}
			_, ok := claimUserID(claims)
			if ok != test.want {
				t.Fatalf("valid=%v, want %v", ok, test.want)
			}
		})
	}
}

func TestAuthMiddlewarePreservesUserIDAboveJSONFloatPrecision(t *testing.T) {
	if strconv.IntSize != 64 {
		t.Skip("requires 64-bit uint")
	}
	const roundedID uint = 9007199254740992
	const exactID uint = 9007199254740993
	db, err := gorm.Open(sqlite.Open("file:large-token-user-id?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}); err != nil {
		t.Fatal(err)
	}
	for _, user := range []UserModel{
		{ID: roundedID, Username: "rounded-user", Email: "rounded@example.test", PasswordHash: "unused"},
		{ID: exactID, Username: "exact-user", Email: "exact@example.test", PasswordHash: "unused"},
	} {
		if err := db.Create(&user).Error; err != nil {
			t.Fatal(err)
		}
	}

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(AuthMiddleware(true))
	router.GET("/", func(c *gin.Context) {
		user := c.MustGet("my_user_model").(UserModel)
		if user.ID != exactID {
			c.Status(http.StatusConflict)
			return
		}
		c.Status(http.StatusNoContent)
	})
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Token "+common.GenToken(exactID))
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNoContent {
		t.Fatalf("status=%d body=%s, want exact user authentication", recorder.Code, recorder.Body.String())
	}
}

func TestOptionalAuthPropagatesUserLookupDatabaseError(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:optional-auth-database-error?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
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

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(AuthMiddleware(false))
	handlerCalled := false
	router.GET("/", func(c *gin.Context) {
		handlerCalled = true
		c.Status(http.StatusNoContent)
	})
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Token "+common.GenToken(1))
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if handlerCalled {
		t.Fatal("optional-auth handler ran after an operational user lookup failure")
	}
}

func TestAuthMiddlewareRejectsSignedTokenWithMalformedID(t *testing.T) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":  "not-a-number",
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	signed, err := token.SignedString([]byte(common.JWTSecret))
	if err != nil {
		t.Fatal(err)
	}

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(AuthMiddleware(true))
	router.GET("/", func(c *gin.Context) { c.Status(http.StatusNoContent) })
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Token "+signed)
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d, want 401", recorder.Code)
	}
}

func TestAuthMiddlewareRejectsSignedTokenForMissingUser(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:missing-token-user?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}); err != nil {
		t.Fatal(err)
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":  float64(999),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	signed, err := token.SignedString([]byte(common.JWTSecret))
	if err != nil {
		t.Fatal(err)
	}

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(AuthMiddleware(true))
	router.GET("/", func(c *gin.Context) { c.Status(http.StatusNoContent) })
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Token "+signed)
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d, want 401", recorder.Code)
	}
}

func TestUserValidatorHashesSentinelLiteralWhenSupplied(t *testing.T) {
	payload, err := json.Marshal(map[string]interface{}{
		"user": map[string]string{
			"username": "sentinel-user",
			"email":    "sentinel@example.test",
			"password": common.RandomPassword,
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	context, _ := gin.CreateTestContext(httptest.NewRecorder())
	context.Request = httptest.NewRequest(http.MethodPost, "/", strings.NewReader(string(payload)))
	context.Request.Header.Set("Content-Type", "application/json")
	validator := NewUserModelValidator()
	if err := validator.Bind(context); err != nil {
		t.Fatal(err)
	}
	if validator.userModel.PasswordHash == "" || validator.userModel.checkPassword(common.RandomPassword) != nil {
		t.Fatal("supplied sentinel literal was not hashed")
	}
}

func TestUserValidatorRejectsUsernameContainingPathSeparator(t *testing.T) {
	payload := `{"user":{"username":"bad/name","email":"bad@example.test","password":"password0"}}`
	context, _ := gin.CreateTestContext(httptest.NewRecorder())
	context.Request = httptest.NewRequest(http.MethodPost, "/", strings.NewReader(payload))
	context.Request.Header.Set("Content-Type", "application/json")
	validator := NewUserModelValidator()
	if err := validator.Bind(context); err == nil {
		t.Fatal("username containing slash unexpectedly validated")
	}
}

func TestSetPasswordPropagatesBcryptLengthError(t *testing.T) {
	var user UserModel
	if err := user.setPassword(strings.Repeat("a", 73)); err == nil {
		t.Fatal("73-byte password unexpectedly succeeded")
	}
	if user.PasswordHash != "" {
		t.Fatal("failed password hashing stored a hash")
	}
}

func TestDuplicateUsernameConstraintKeepsConflictResponse(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:duplicate-user?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(&UserModel{}); err != nil {
		t.Fatal(err)
	}
	first := UserModel{Username: "same", Email: "first@example.test", PasswordHash: "unused"}
	if err := db.Create(&first).Error; err != nil {
		t.Fatal(err)
	}
	duplicate := UserModel{Username: "same", Email: "second@example.test", PasswordHash: "unused"}
	writeErr := db.Create(&duplicate).Error
	if !errors.Is(writeErr, gorm.ErrDuplicatedKey) {
		t.Fatalf("error=%v, want duplicated key", writeErr)
	}

	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)
	if !writeIdentityConflict(context, duplicate, 0, writeErr) {
		t.Fatal("duplicate was not handled as an identity conflict")
	}
	if recorder.Code != http.StatusConflict || !strings.Contains(recorder.Body.String(), `"username"`) {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
}
