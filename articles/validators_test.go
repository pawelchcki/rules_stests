package articles

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func TestArticleValidatorPropagatesTagCreationFailure(t *testing.T) {
	db := articleTestDB(t, "tag-create-failure")
	user, _ := articleTestUser(t, db, "tag-author")
	wantErr := errors.New("forced tag creation failure")
	if err := db.Callback().Create().Before("gorm:create").Register("test:fail-tag-create", func(tx *gorm.DB) {
		if _, ok := tx.Statement.Model.(*TagModel); ok {
			tx.AddError(wantErr)
		}
	}); err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(
		http.MethodPost,
		"/api/articles",
		strings.NewReader(`{"article":{"title":"Tagged article","description":"description","body":"body","tagList":["go"]}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	validator := NewArticleModelValidator()
	if err := validator.Bind(context); !errors.Is(err, wantErr) {
		t.Fatalf("Bind error=%v, want %v", err, wantErr)
	}
}
