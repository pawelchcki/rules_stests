package articles

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync"
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
		&users.FollowModel{},
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
		Model:       gorm.Model{CreatedAt: updatedAt, UpdatedAt: updatedAt},
		Slug:        title,
		Title:       title,
		Description: "description",
		Body:        "body",
		AuthorID:    author.ID,
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
	// Editing the oldest article must not move it to the first list page.
	if err := db.Model(&match).UpdateColumn("updated_at", base.Add(10*time.Minute)).Error; err != nil {
		t.Fatal(err)
	}

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

func TestFindManyArticleReadsCountAndPageInOneTransaction(t *testing.T) {
	db := articleTestDB(t, "article-list-transaction")
	_, author := articleTestUser(t, db, "transactional-list-author")
	articleTestArticle(t, db, author, "transactional-list-article", time.Now())

	articleQueries := 0
	outsideTransaction := false
	if err := db.Callback().Query().Before("gorm:query").Register("test:verify-list-transaction", func(tx *gorm.DB) {
		if tx.Statement.Table != "article_models" {
			return
		}
		articleQueries++
		if _, ok := tx.Statement.ConnPool.(*sql.Tx); !ok {
			outsideTransaction = true
		}
	}); err != nil {
		t.Fatal(err)
	}

	models, count, err := FindManyArticle("", "", "20", "0", "")
	if err != nil {
		t.Fatal(err)
	}
	if count != 1 || len(models) != 1 {
		t.Fatalf("count=%d models=%v, want one article", count, articleIDs(models))
	}
	if articleQueries != 2 {
		t.Fatalf("article query count=%d, want count and page queries", articleQueries)
	}
	if outsideTransaction {
		t.Fatal("article count or page query ran outside the shared transaction")
	}
}

func TestGetArticleFeedPropagatesQueryFailure(t *testing.T) {
	db := articleTestDB(t, "article-feed-error")
	reader, readerProfile := articleTestUser(t, db, "feed-reader")
	author, authorProfile := articleTestUser(t, db, "feed-author")
	if err := db.Create(&users.FollowModel{FollowingID: author.ID, FollowedByID: reader.ID}).Error; err != nil {
		t.Fatal(err)
	}
	articleTestArticle(t, db, authorProfile, "feed-article", time.Now())

	wantErr := errors.New("forced feed query failure")
	if err := db.Callback().Query().Before("gorm:query").Register("test:fail-feed-query", func(tx *gorm.DB) {
		if tx.Statement.Table == "article_models" {
			tx.AddError(wantErr)
		}
	}); err != nil {
		t.Fatal(err)
	}

	if _, _, err := readerProfile.GetArticleFeed("20", "0"); !errors.Is(err, wantErr) {
		t.Fatalf("GetArticleFeed error=%v, want %v", err, wantErr)
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
	first, err := GetArticleUserModel(user)
	if err != nil {
		t.Fatal(err)
	}
	second, err := GetArticleUserModel(user)
	if err != nil {
		t.Fatal(err)
	}
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

func TestParsePaginationRejectsNegativeValues(t *testing.T) {
	limit, offset := parsePagination("-1", "-9")
	if limit != 20 || offset != 0 {
		t.Fatalf("pagination=(%d, %d), want (20, 0)", limit, offset)
	}
}

func TestArticleUpdateValuesContainOnlySuppliedFields(t *testing.T) {
	validator := NewArticleModelValidatorFillWith(ArticleModel{
		Title:       "old title",
		Description: "old description",
		Body:        "old body",
		Tags:        []TagModel{{Tag: "old"}},
	})
	validator.Article.Title = "new title"
	updates := articleUpdateValues(validator, map[string]json.RawMessage{"title": json.RawMessage(`"new title"`)})
	if len(updates) != 1 || updates["title"] != "new title" {
		t.Fatalf("updates=%v, want only the supplied title", updates)
	}
}

func TestArticleUserMappingPropagatesDatabaseErrors(t *testing.T) {
	db := articleTestDB(t, "article-user-errors")
	user := users.UserModel{ID: 42}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	if err := sqlDB.Close(); err != nil {
		t.Fatal(err)
	}
	if _, err := GetArticleUserModel(user); err == nil {
		t.Fatal("closed database mapping unexpectedly succeeded")
	}
}

func TestFavoriteBatchReadsPropagateDatabaseErrors(t *testing.T) {
	db := articleTestDB(t, "favorite-read-errors")
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	if err := sqlDB.Close(); err != nil {
		t.Fatal(err)
	}
	if _, err := BatchGetFavoriteCounts([]uint{1}); err == nil {
		t.Fatal("favorite count query on closed database unexpectedly succeeded")
	}
	if _, err := BatchGetFavoriteStatus([]uint{1}, 1); err == nil {
		t.Fatal("favorite status query on closed database unexpectedly succeeded")
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

func TestConcurrentArticleCreatesAllocateDistinctSlugs(t *testing.T) {
	db := articleTestDB(t, "concurrent-article-create")
	user, _ := articleTestUser(t, db, "concurrent-create-author")
	gin.SetMode(gin.TestMode)
	const requestCount = 8
	recorders := make([]*httptest.ResponseRecorder, requestCount)
	start := make(chan struct{})
	var wait sync.WaitGroup
	for index := range recorders {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			recorder := httptest.NewRecorder()
			recorders[index] = recorder
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(
				http.MethodPost,
				"/api/articles",
				strings.NewReader(`{"article":{"title":"Concurrent title","description":"description","body":"body"}}`),
			)
			context.Request.Header.Set("Content-Type", "application/json")
			context.Set("my_user_model", user)
			<-start
			ArticleCreate(context)
		}(index)
	}
	close(start)
	wait.Wait()

	for index, recorder := range recorders {
		if recorder.Code != http.StatusCreated {
			t.Fatalf("request %d status=%d body=%s, want 201", index, recorder.Code, recorder.Body.String())
		}
	}
	var slugs []string
	if err := db.Model(&ArticleModel{}).Order("slug").Pluck("slug", &slugs).Error; err != nil {
		t.Fatal(err)
	}
	if len(slugs) != requestCount {
		t.Fatalf("slugs=%v, want %d distinct articles", slugs, requestCount)
	}
	seen := make(map[string]struct{}, requestCount)
	for _, value := range slugs {
		if _, duplicate := seen[value]; duplicate {
			t.Fatalf("duplicate slug %q in %v", value, slugs)
		}
		seen[value] = struct{}{}
	}
}

func TestSaveArticleWithUniqueSlugAccountsForDeletedArticles(t *testing.T) {
	db := articleTestDB(t, "deleted-unique-slug")
	_, author := articleTestUser(t, db, "deleted-slug-author")
	deleted := ArticleModel{Title: "Reusable title", AuthorID: author.ID}
	if err := SaveArticleWithUniqueSlug(&deleted); err != nil {
		t.Fatal(err)
	}
	if err := DeleteArticleModel(&ArticleModel{Slug: deleted.Slug}); err != nil {
		t.Fatal(err)
	}

	replacement := ArticleModel{Title: "Reusable title", AuthorID: author.ID}
	if err := SaveArticleWithUniqueSlug(&replacement); err != nil {
		t.Fatal(err)
	}
	if replacement.Slug != "reusable-title-2" {
		t.Fatalf("replacement slug=%q, want %q", replacement.Slug, "reusable-title-2")
	}
}

func TestSaveArticleRejectsEmptyGeneratedSlug(t *testing.T) {
	db := articleTestDB(t, "empty-slug")
	_, author := articleTestUser(t, db, "empty-slug-author")
	article := ArticleModel{Title: "!!!!", AuthorID: author.ID}
	if err := SaveArticleWithUniqueSlug(&article); err == nil {
		t.Fatal("article with an empty generated slug unexpectedly succeeded")
	}
	var count int64
	if err := db.Model(&ArticleModel{}).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Fatalf("article count=%d, want 0", count)
	}
}

func TestArticleCreateRollsBackTagsWhenSlugIsRejected(t *testing.T) {
	db := articleTestDB(t, "article-create-transaction")
	user, _ := articleTestUser(t, db, "create-transaction-author")
	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(
		http.MethodPost,
		"/api/articles",
		strings.NewReader(`{"article":{"title":"!!!!","description":"description","body":"body","tagList":["orphan"]}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	ArticleCreate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var tagCount int64
	if err := db.Unscoped().Model(&TagModel{}).Where("tag = ?", "orphan").Count(&tagCount).Error; err != nil {
		t.Fatal(err)
	}
	if tagCount != 0 {
		t.Fatalf("orphan tag count=%d, want 0", tagCount)
	}
}

func TestArticleCreateRollsBackWhenResponseReadFails(t *testing.T) {
	db := articleTestDB(t, "article-create-response-transaction")
	user, _ := articleTestUser(t, db, "response-transaction-author")
	wantErr := errors.New("forced favorite read failure")
	if err := db.Callback().Query().Before("gorm:query").Register("test:fail-favorite-read", func(tx *gorm.DB) {
		if tx.Statement.Table == "favorite_models" {
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
		strings.NewReader(`{"article":{"title":"Transactional response","description":"description","body":"body","tagList":["rollback"]}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	ArticleCreate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var articleCount, tagCount int64
	if err := db.Model(&ArticleModel{}).Count(&articleCount).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&TagModel{}).Count(&tagCount).Error; err != nil {
		t.Fatal(err)
	}
	if articleCount != 0 || tagCount != 0 {
		t.Fatalf("article count=%d tag count=%d, want rollback", articleCount, tagCount)
	}
}

func TestArticleCreateRejectsEmptyTagName(t *testing.T) {
	db := articleTestDB(t, "article-create-empty-tag")
	user, _ := articleTestUser(t, db, "empty-tag-author")
	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(
		http.MethodPost,
		"/api/articles",
		strings.NewReader(`{"article":{"title":"Valid title","description":"description","body":"body","tagList":[""]}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	ArticleCreate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"tagList"`) || strings.Contains(recorder.Body.String(), `"tags[`) {
		t.Fatalf("body=%s, want normalized tagList validation error", recorder.Body.String())
	}
	var tagCount int64
	if err := db.Unscoped().Model(&TagModel{}).Count(&tagCount).Error; err != nil {
		t.Fatal(err)
	}
	if tagCount != 0 {
		t.Fatalf("tag count=%d, want 0", tagCount)
	}
}

func TestArticleCreateRejectsNullTagList(t *testing.T) {
	db := articleTestDB(t, "article-create-null-tag-list")
	user, _ := articleTestUser(t, db, "null-tag-list-author")
	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(
		http.MethodPost,
		"/api/articles",
		strings.NewReader(`{"article":{"title":"Valid title","description":"description","body":"body","tagList":null}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Set("my_user_model", user)

	ArticleCreate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"tagList"`) {
		t.Fatalf("body=%s, want tagList validation error", recorder.Body.String())
	}
	var articleCount int64
	if err := db.Model(&ArticleModel{}).Count(&articleCount).Error; err != nil {
		t.Fatal(err)
	}
	if articleCount != 0 {
		t.Fatalf("article count=%d, want 0", articleCount)
	}
}

func TestArticleListPropagatesDatabaseErrors(t *testing.T) {
	db := articleTestDB(t, "article-list-database-error")
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
	context.Request = httptest.NewRequest(http.MethodGet, "/api/articles", nil)
	context.Set("my_user_model", users.UserModel{})

	ArticleList(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"database"`) {
		t.Fatalf("body=%s, want database error", recorder.Body.String())
	}
}

func TestSetTagsDeduplicatesInput(t *testing.T) {
	db := articleTestDB(t, "deduplicate-tags")
	existing := TagModel{Tag: "go"}
	if err := db.Create(&existing).Error; err != nil {
		t.Fatal(err)
	}
	var article ArticleModel
	if err := article.setTagsWithDB(db, []string{"go", "go", "gin", "gin"}); err != nil {
		t.Fatal(err)
	}
	if len(article.Tags) != 2 || article.Tags[0].Tag != "go" || article.Tags[1].Tag != "gin" {
		t.Fatalf("tags=%v, want [go gin]", article.Tags)
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

func TestCommentCreateRollsBackWhenResponseReadFails(t *testing.T) {
	db := articleTestDB(t, "comment-create-response-transaction")
	user, author := articleTestUser(t, db, "comment-response-author")
	article := articleTestArticle(t, db, author, "comment-response-article", time.Now())
	wantErr := errors.New("forced follow read failure")
	if err := db.Callback().Query().Before("gorm:query").Register("test:fail-comment-follow-read", func(tx *gorm.DB) {
		if tx.Statement.Table == "follow_models" {
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
		"/api/articles/"+article.Slug+"/comments",
		strings.NewReader(`{"comment":{"body":"transactional comment"}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
	context.Set("my_user_model", user)

	ArticleCommentCreate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var commentCount int64
	if err := db.Model(&CommentModel{}).Count(&commentCount).Error; err != nil {
		t.Fatal(err)
	}
	if commentCount != 0 {
		t.Fatalf("comment count=%d, want rollback", commentCount)
	}
}

func TestCommentListPropagatesDatabaseErrors(t *testing.T) {
	db := articleTestDB(t, "comment-list-database-error")
	user, author := articleTestUser(t, db, "comment-list-error-author")
	article := articleTestArticle(t, db, author, "comment-list-error-article", time.Now())
	wantErr := errors.New("forced comment list failure")
	if err := db.Callback().Query().Before("gorm:query").Register("test:fail-comment-list", func(tx *gorm.DB) {
		if tx.Statement.Table == "comment_models" {
			tx.AddError(wantErr)
		}
	}); err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	gin.SetMode(gin.TestMode)
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(http.MethodGet, "/api/articles/"+article.Slug+"/comments", nil)
	context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
	context.Set("my_user_model", user)

	ArticleCommentList(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"database"`) {
		t.Fatalf("body=%s, want database error", recorder.Body.String())
	}
}

func TestArticleUpdateRejectsExplicitNullRequiredFields(t *testing.T) {
	db := articleTestDB(t, "article-update-null")
	user, author := articleTestUser(t, db, "null-author")
	article := articleTestArticle(t, db, author, "null-article", time.Now())

	for _, field := range []string{"title", "description", "body"} {
		t.Run(field, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			gin.SetMode(gin.TestMode)
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(
				http.MethodPut,
				"/api/articles/"+article.Slug,
				strings.NewReader(`{"article":{"`+field+`":null}}`),
			)
			context.Request.Header.Set("Content-Type", "application/json")
			context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
			context.Set("my_user_model", user)

			ArticleUpdate(context)
			if recorder.Code != http.StatusUnprocessableEntity {
				t.Fatalf("status=%d, want %d", recorder.Code, http.StatusUnprocessableEntity)
			}
			if !strings.Contains(recorder.Body.String(), `"`+field+`"`) {
				t.Fatalf("response %s does not name %q", recorder.Body.String(), field)
			}
		})
	}
}

func TestArticleUpdateRequiresEnvelopeButAllowsEmptyUpdate(t *testing.T) {
	db := articleTestDB(t, "article-update-envelope")
	user, author := articleTestUser(t, db, "envelope-author")
	article := articleTestArticle(t, db, author, "envelope-article", time.Now())

	for _, test := range []struct {
		name string
		body string
		want int
	}{
		{name: "missing", body: `{}`, want: http.StatusUnprocessableEntity},
		{name: "empty", body: `{"article":{}}`, want: http.StatusOK},
	} {
		t.Run(test.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			gin.SetMode(gin.TestMode)
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(http.MethodPut, "/api/articles/"+article.Slug, strings.NewReader(test.body))
			context.Request.Header.Set("Content-Type", "application/json")
			context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
			context.Set("my_user_model", user)

			ArticleUpdate(context)
			if recorder.Code != test.want {
				t.Fatalf("status=%d body=%s, want %d", recorder.Code, recorder.Body.String(), test.want)
			}
		})
	}
}

func TestArticleUpdateRollsBackScalarChangesWhenTagReplacementFails(t *testing.T) {
	db := articleTestDB(t, "article-update-transaction")
	user, author := articleTestUser(t, db, "transaction-author")
	oldTag := TagModel{Tag: "old"}
	newTag := TagModel{Tag: "new"}
	if err := db.Create(&oldTag).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&newTag).Error; err != nil {
		t.Fatal(err)
	}
	article := articleTestArticle(t, db, author, "transaction-article", time.Now(), oldTag)
	wantErr := errors.New("forced association replacement failure")
	if err := db.Callback().Create().Before("gorm:create").Register("test:fail-article-tags", func(tx *gorm.DB) {
		if tx.Statement.Table == "article_tags" {
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
		"/api/articles/"+article.Slug,
		strings.NewReader(`{"article":{"title":"Changed title","tagList":["new"]}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
	context.Set("my_user_model", user)

	ArticleUpdate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var stored ArticleModel
	if err := db.Preload("Tags").First(&stored, article.ID).Error; err != nil {
		t.Fatal(err)
	}
	if stored.Title != article.Title {
		t.Fatalf("stored title=%q, want rollback to %q", stored.Title, article.Title)
	}
	if len(stored.Tags) != 1 || stored.Tags[0].Tag != "old" {
		t.Fatalf("stored tags=%v, want [old]", stored.Tags)
	}
}

func TestArticleUpdateRollsBackWhenResponseReadFails(t *testing.T) {
	db := articleTestDB(t, "article-update-response-transaction")
	user, author := articleTestUser(t, db, "update-response-author")
	article := articleTestArticle(t, db, author, "update-response-article", time.Now())
	wantErr := errors.New("forced update response read failure")
	if err := db.Callback().Query().Before("gorm:query").Register("test:fail-update-response-read", func(tx *gorm.DB) {
		if tx.Statement.Table == "favorite_models" {
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
		"/api/articles/"+article.Slug,
		strings.NewReader(`{"article":{"title":"Changed title"}}`),
	)
	context.Request.Header.Set("Content-Type", "application/json")
	context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
	context.Set("my_user_model", user)

	ArticleUpdate(context)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
	}
	var stored ArticleModel
	if err := db.First(&stored, article.ID).Error; err != nil {
		t.Fatal(err)
	}
	if stored.Title != article.Title {
		t.Fatalf("stored title=%q, want rollback to %q", stored.Title, article.Title)
	}
}

func TestFavoriteChangesRollBackWhenResponseReadFails(t *testing.T) {
	for _, test := range []struct {
		name      string
		handler   func(*gin.Context)
		seedCount int64
	}{
		{name: "favorite", handler: ArticleFavorite, seedCount: 0},
		{name: "unfavorite", handler: ArticleUnfavorite, seedCount: 1},
	} {
		t.Run(test.name, func(t *testing.T) {
			db := articleTestDB(t, "favorite-response-transaction-"+test.name)
			user, favoriter := articleTestUser(t, db, "favorite-response-user-"+test.name)
			_, author := articleTestUser(t, db, "favorite-response-author-"+test.name)
			article := articleTestArticle(t, db, author, "favorite-response-article-"+test.name, time.Now())
			if test.seedCount == 1 {
				if err := article.favoriteBy(favoriter); err != nil {
					t.Fatal(err)
				}
			}

			wantErr := errors.New("forced favorite response read failure")
			callbackName := "test:fail-favorite-response-read-" + test.name
			if err := db.Callback().Query().Before("gorm:query").Register(callbackName, func(tx *gorm.DB) {
				if tx.Statement.Table == "favorite_models" {
					tx.AddError(wantErr)
				}
			}); err != nil {
				t.Fatal(err)
			}

			recorder := httptest.NewRecorder()
			gin.SetMode(gin.TestMode)
			context, _ := gin.CreateTestContext(recorder)
			context.Request = httptest.NewRequest(http.MethodPost, "/api/articles/"+article.Slug+"/favorite", nil)
			context.Params = gin.Params{{Key: "slug", Value: article.Slug}}
			context.Set("my_user_model", user)

			test.handler(context)
			if recorder.Code != http.StatusUnprocessableEntity {
				t.Fatalf("status=%d body=%s, want 422", recorder.Code, recorder.Body.String())
			}
			if err := db.Callback().Query().Remove(callbackName); err != nil {
				t.Fatal(err)
			}
			assertFavoriteCount(t, db, test.seedCount)
		})
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
