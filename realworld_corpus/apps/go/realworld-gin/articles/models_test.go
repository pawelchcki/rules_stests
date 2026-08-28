package articles

import (
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func articleTestDB(t *testing.T, name string) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+name+"?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	common.DB = db
	if err := db.AutoMigrate(
		&users.UserModel{},
		&ArticleUserModel{},
		&ArticleModel{},
		&TagModel{},
		&FavoriteModel{},
		&CommentModel{},
	); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		sqlDB, err := db.DB()
		if err == nil {
			_ = sqlDB.Close()
		}
	})
	return db
}

func articleTestUser(t *testing.T, db *gorm.DB, username string) (users.UserModel, ArticleUserModel) {
	t.Helper()
	user := users.UserModel{Username: username, Email: username + "@example.test", PasswordHash: "unused"}
	if err := db.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	author := ArticleUserModel{UserModelID: user.ID}
	if err := db.Create(&author).Error; err != nil {
		t.Fatal(err)
	}
	return user, author
}

func articleTestArticle(t *testing.T, db *gorm.DB, author ArticleUserModel, title string, updatedAt time.Time, tags ...TagModel) ArticleModel {
	t.Helper()
	article := ArticleModel{
		Model:    gorm.Model{UpdatedAt: updatedAt},
		Slug:     title,
		Title:    title,
		AuthorID: author.ID,
	}
	if err := db.Create(&article).Error; err != nil {
		t.Fatal(err)
	}
	if len(tags) > 0 {
		if err := db.Model(&article).Association("Tags").Append(tags); err != nil {
			t.Fatal(err)
		}
	}
	if err := db.Model(&article).UpdateColumn("updated_at", updatedAt).Error; err != nil {
		t.Fatal(err)
	}
	article.UpdatedAt = updatedAt
	return article
}

func TestFindManyArticleCombinesFiltersAndOrdersBeforePaging(t *testing.T) {
	db := articleTestDB(t, "article-list")
	_, alice := articleTestUser(t, db, "alice")
	_, bob := articleTestUser(t, db, "bob")
	carolUser, carol := articleTestUser(t, db, "carol")

	goTag := TagModel{Tag: "go"}
	rustTag := TagModel{Tag: "rust"}
	if err := db.Create(&goTag).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&rustTag).Error; err != nil {
		t.Fatal(err)
	}

	base := time.Unix(1_700_000_000, 0)
	match := articleTestArticle(t, db, alice, "match", base.Add(time.Minute), goTag)
	newerTag := articleTestArticle(t, db, bob, "newer-tag", base.Add(4*time.Minute), goTag)
	newerAuthor := articleTestArticle(t, db, alice, "newer-author", base.Add(3*time.Minute), rustTag)
	newest := articleTestArticle(t, db, alice, "newest", base.Add(5*time.Minute), goTag)

	for _, article := range []ArticleModel{match, newerTag, newerAuthor} {
		if err := article.favoriteBy(carol); err != nil {
			t.Fatal(err)
		}
	}

	models, count, err := FindManyArticle("go", "alice", "20", "0", carolUser.Username)
	if err != nil {
		t.Fatal(err)
	}
	if count != 1 || len(models) != 1 || models[0].ID != match.ID {
		t.Fatalf("combined filters returned count=%d models=%v", count, articleIDs(models))
	}

	tests := []struct {
		name      string
		tag       string
		author    string
		favorited string
		want      uint
	}{
		{name: "unfiltered", want: newest.ID},
		{name: "tag", tag: "go", want: newest.ID},
		{name: "author", author: "alice", want: newest.ID},
		{name: "favorited", favorited: "carol", want: newerTag.ID},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			page, _, err := FindManyArticle(test.tag, test.author, "1", "0", test.favorited)
			if err != nil {
				t.Fatal(err)
			}
			if len(page) != 1 || page[0].ID != test.want {
				t.Fatalf("got %v, want [%d]", articleIDs(page), test.want)
			}
		})
	}
}

func TestFavoriteIsIdempotentAndCanBeRecreated(t *testing.T) {
	db := articleTestDB(t, "favorite")
	_, author := articleTestUser(t, db, "author")
	_, favoriter := articleTestUser(t, db, "favoriter")
	article := articleTestArticle(t, db, author, "article", time.Now())

	if err := article.favoriteBy(favoriter); err != nil {
		t.Fatal(err)
	}
	if err := article.favoriteBy(favoriter); err != nil {
		t.Fatal(err)
	}
	assertFavoriteCount(t, db, 1)
	if err := article.unFavoriteBy(favoriter); err != nil {
		t.Fatal(err)
	}
	assertFavoriteCount(t, db, 0)
	if err := article.favoriteBy(favoriter); err != nil {
		t.Fatal(err)
	}
	assertFavoriteCount(t, db, 1)
}

func TestArticleUserMappingIsUniqueAndStable(t *testing.T) {
	db := articleTestDB(t, "article-user")
	user := users.UserModel{Username: "mapped", Email: "mapped@example.test", PasswordHash: "unused"}
	if err := db.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	first := GetArticleUserModel(user)
	second := GetArticleUserModel(user)
	if first.ID == 0 || second.ID != first.ID {
		t.Fatalf("mapping IDs = %d and %d", first.ID, second.ID)
	}
	var count int64
	if err := db.Model(&ArticleUserModel{}).Where("user_model_id = ?", user.ID).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("mapping count=%d, want 1", count)
	}
}

func TestSaveArticleWithUniqueSlugAdvancesSuffix(t *testing.T) {
	db := articleTestDB(t, "unique-slug")
	_, author := articleTestUser(t, db, "slug-author")
	first := ArticleModel{Title: "Same title", AuthorID: author.ID}
	second := ArticleModel{Title: "Same title", AuthorID: author.ID}
	if err := SaveArticleWithUniqueSlug(&first); err != nil {
		t.Fatal(err)
	}
	if err := SaveArticleWithUniqueSlug(&second); err != nil {
		t.Fatal(err)
	}
	if first.Slug != "same-title" || second.Slug != "same-title-2" {
		t.Fatalf("slugs = %q and %q", first.Slug, second.Slug)
	}
}

func TestCommentDeleteRequiresCommentToBelongToArticle(t *testing.T) {
	db := articleTestDB(t, "comment-delete")
	user, author := articleTestUser(t, db, "commenter")
	articleA := articleTestArticle(t, db, author, "article-a", time.Now())
	articleB := articleTestArticle(t, db, author, "article-b", time.Now())
	comment := CommentModel{ArticleID: articleA.ID, AuthorID: author.ID, Body: "body"}
	if err := db.Create(&comment).Error; err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Params = gin.Params{
		{Key: "slug", Value: articleB.Slug},
		{Key: "id", Value: strconv.FormatUint(uint64(comment.ID), 10)},
	}
	context.Set("my_user_model", user)
	ArticleCommentDelete(context)
	if recorder.Code != 404 {
		t.Fatalf("status=%d, want 404", recorder.Code)
	}
	var count int64
	if err := db.Model(&CommentModel{}).Where("id = ?", comment.ID).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("comment count=%d, want 1", count)
	}
}

func articleIDs(models []ArticleModel) []uint {
	ids := make([]uint, len(models))
	for index, model := range models {
		ids[index] = model.ID
	}
	return ids
}

func assertFavoriteCount(t *testing.T, db *gorm.DB, want int64) {
	t.Helper()
	var count int64
	if err := db.Model(&FavoriteModel{}).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != want {
		t.Fatalf("favorite count=%d, want %d", count, want)
	}
}
