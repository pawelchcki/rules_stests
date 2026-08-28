package articles

import (
	"errors"
	"strconv"

	"github.com/gosimple/slug"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type ArticleModel struct {
	gorm.Model
	Slug        string `gorm:"uniqueIndex"`
	Title       string
	Description string `gorm:"size:2048"`
	Body        string `gorm:"size:2048"`
	Author      ArticleUserModel
	AuthorID    uint
	Tags        []TagModel     `gorm:"many2many:article_tags;"`
	Comments    []CommentModel `gorm:"ForeignKey:ArticleID"`
}

type ArticleUserModel struct {
	gorm.Model
	UserModel      users.UserModel
	UserModelID    uint            `gorm:"uniqueIndex"`
	ArticleModels  []ArticleModel  `gorm:"ForeignKey:AuthorID"`
	FavoriteModels []FavoriteModel `gorm:"ForeignKey:FavoriteByID"`
}

type FavoriteModel struct {
	gorm.Model
	Favorite     ArticleModel
	FavoriteID   uint `gorm:"uniqueIndex:idx_favorite_user"`
	FavoriteBy   ArticleUserModel
	FavoriteByID uint `gorm:"uniqueIndex:idx_favorite_user"`
}

type TagModel struct {
	gorm.Model
	Tag           string         `gorm:"uniqueIndex"`
	ArticleModels []ArticleModel `gorm:"many2many:article_tags;"`
}

type CommentModel struct {
	gorm.Model
	Article   ArticleModel
	ArticleID uint
	Author    ArticleUserModel
	AuthorID  uint
	Body      string `gorm:"size:2048"`
}

func GetArticleUserModel(userModel users.UserModel) ArticleUserModel {
	return getArticleUserModel(common.GetDB(), userModel)
}

func getArticleUserModel(db *gorm.DB, userModel users.UserModel) ArticleUserModel {
	var articleUserModel ArticleUserModel
	if userModel.ID == 0 {
		return articleUserModel
	}
	db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_model_id"}},
		DoNothing: true,
	}).Create(&ArticleUserModel{UserModelID: userModel.ID})
	db.Where(&ArticleUserModel{UserModelID: userModel.ID}).First(&articleUserModel)
	articleUserModel.UserModel = userModel
	return articleUserModel
}

func (article ArticleModel) favoritesCount() uint {
	db := common.GetDB()
	var count int64
	db.Model(&FavoriteModel{}).Where(FavoriteModel{
		FavoriteID: article.ID,
	}).Count(&count)
	return uint(count)
}

func (article ArticleModel) isFavoriteBy(user ArticleUserModel) bool {
	db := common.GetDB()
	var favorite FavoriteModel
	db.Where(FavoriteModel{
		FavoriteID:   article.ID,
		FavoriteByID: user.ID,
	}).First(&favorite)
	return favorite.ID != 0
}

// BatchGetFavoriteCounts returns a map of article ID to favorite count
func BatchGetFavoriteCounts(articleIDs []uint) map[uint]uint {
	if len(articleIDs) == 0 {
		return make(map[uint]uint)
	}
	db := common.GetDB()

	type result struct {
		FavoriteID uint
		Count      uint
	}
	var results []result
	db.Model(&FavoriteModel{}).
		Select("favorite_id, COUNT(*) as count").
		Where("favorite_id IN ?", articleIDs).
		Group("favorite_id").
		Find(&results)

	countMap := make(map[uint]uint)
	for _, r := range results {
		countMap[r.FavoriteID] = r.Count
	}
	return countMap
}

// BatchGetFavoriteStatus returns a map of article ID to whether the user favorited it
func BatchGetFavoriteStatus(articleIDs []uint, userID uint) map[uint]bool {
	if len(articleIDs) == 0 || userID == 0 {
		return make(map[uint]bool)
	}
	db := common.GetDB()

	var favorites []FavoriteModel
	db.Where("favorite_id IN ? AND favorite_by_id = ?", articleIDs, userID).Find(&favorites)

	statusMap := make(map[uint]bool)
	for _, f := range favorites {
		statusMap[f.FavoriteID] = true
	}
	return statusMap
}

func (article ArticleModel) favoriteBy(user ArticleUserModel) error {
	db := common.GetDB()
	favorite := FavoriteModel{
		FavoriteID:   article.ID,
		FavoriteByID: user.ID,
	}
	return db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "favorite_id"}, {Name: "favorite_by_id"}},
		DoNothing: true,
	}).Create(&favorite).Error
}

func (article ArticleModel) unFavoriteBy(user ArticleUserModel) error {
	db := common.GetDB()
	// Favorites are relationships, not retained records. A hard delete permits
	// the same unique pair to be created again after an unfavorite.
	err := db.Unscoped().Where("favorite_id = ? AND favorite_by_id = ?", article.ID, user.ID).Delete(&FavoriteModel{}).Error
	return err
}

func SaveOne(data interface{}) error {
	db := common.GetDB()
	err := db.Save(data).Error
	return err
}

func FindOneArticle(condition interface{}) (ArticleModel, error) {
	db := common.GetDB()
	var model ArticleModel
	err := db.Preload("Author.UserModel").Preload("Tags").Where(condition).First(&model).Error
	return model, err
}

func FindOneComment(condition *CommentModel) (CommentModel, error) {
	db := common.GetDB()
	var model CommentModel
	err := db.Preload("Author.UserModel").Preload("Article").Where(condition).First(&model).Error
	return model, err
}

func (self *ArticleModel) getComments() error {
	db := common.GetDB()
	err := db.Preload("Author.UserModel").Model(self).Association("Comments").Find(&self.Comments)
	return err
}

func getAllTags() ([]TagModel, error) {
	db := common.GetDB()
	var models []TagModel
	err := db.Find(&models).Error
	return models, err
}

func FindManyArticle(tag, author, limit, offset, favorited string) ([]ArticleModel, int, error) {
	db := common.GetDB()
	models := make([]ArticleModel, 0)

	offset_int, errOffset := strconv.Atoi(offset)
	if errOffset != nil {
		offset_int = 0
	}

	limit_int, errLimit := strconv.Atoi(limit)
	if errLimit != nil {
		limit_int = 20
	}

	query := db.Model(&ArticleModel{})
	if tag != "" {
		query = query.
			Joins("JOIN article_tags ON article_tags.article_model_id = article_models.id").
			Joins("JOIN tag_models ON tag_models.id = article_tags.tag_model_id AND tag_models.deleted_at IS NULL").
			Where("tag_models.tag = ?", tag)
	}
	if author != "" {
		query = query.
			Joins("JOIN article_user_models AS authors ON authors.id = article_models.author_id AND authors.deleted_at IS NULL").
			Joins("JOIN user_models AS author_users ON author_users.id = authors.user_model_id").
			Where("author_users.username = ?", author)
	}
	if favorited != "" {
		query = query.
			Joins("JOIN favorite_models AS favorites ON favorites.favorite_id = article_models.id AND favorites.deleted_at IS NULL").
			Joins("JOIN article_user_models AS favoriters ON favoriters.id = favorites.favorite_by_id AND favoriters.deleted_at IS NULL").
			Joins("JOIN user_models AS favoriter_users ON favoriter_users.id = favoriters.user_model_id").
			Where("favoriter_users.username = ?", favorited)
	}

	var count64 int64
	if err := query.Distinct("article_models.id").Count(&count64).Error; err != nil {
		return models, 0, err
	}
	if err := query.Distinct("article_models.*").
		Preload("Author.UserModel").Preload("Tags").
		Order("article_models.updated_at DESC").
		Offset(offset_int).Limit(limit_int).Find(&models).Error; err != nil {
		return models, 0, err
	}
	return models, int(count64), nil
}

func (self *ArticleUserModel) GetArticleFeed(limit, offset string) ([]ArticleModel, int, error) {
	db := common.GetDB()
	models := make([]ArticleModel, 0)
	var count int

	offset_int, errOffset := strconv.Atoi(offset)
	if errOffset != nil {
		offset_int = 0
	}
	limit_int, errLimit := strconv.Atoi(limit)
	if errLimit != nil {
		limit_int = 20
	}

	tx := db.Begin()
	if tx.Error != nil {
		return models, 0, tx.Error
	}
	rollback := func(err error) ([]ArticleModel, int, error) {
		_ = tx.Rollback().Error
		return models, 0, err
	}
	followings, err := self.UserModel.GetFollowingsWithDB(tx)
	if err != nil {
		return rollback(err)
	}

	// Batch get ArticleUserModel IDs to avoid N+1 query
	if len(followings) > 0 {
		var followingUserIDs []uint
		for _, following := range followings {
			followingUserIDs = append(followingUserIDs, following.ID)
		}

		var articleUserModels []ArticleUserModel
		if err := tx.Where("user_model_id IN ?", followingUserIDs).Find(&articleUserModels).Error; err != nil {
			return rollback(err)
		}

		var authorIDs []uint
		for _, aum := range articleUserModels {
			authorIDs = append(authorIDs, aum.ID)
		}

		if len(authorIDs) > 0 {
			var count64 int64
			if err := tx.Model(&ArticleModel{}).Where("author_id IN ?", authorIDs).Count(&count64).Error; err != nil {
				return rollback(err)
			}
			count = int(count64)
			if err := tx.Preload("Author.UserModel").Preload("Tags").Where("author_id IN ?", authorIDs).Order("updated_at desc").Offset(offset_int).Limit(limit_int).Find(&models).Error; err != nil {
				return rollback(err)
			}
		}
	}

	if err := tx.Commit().Error; err != nil {
		return models, 0, err
	}
	return models, count, nil
}

func (model *ArticleModel) setTagsWithDB(db *gorm.DB, tags []string) error {
	if len(tags) == 0 {
		model.Tags = []TagModel{}
		return nil
	}

	uniqueTags := make([]string, 0, len(tags))
	seen := make(map[string]struct{}, len(tags))
	for _, tag := range tags {
		if _, exists := seen[tag]; exists {
			continue
		}
		seen[tag] = struct{}{}
		uniqueTags = append(uniqueTags, tag)
	}

	// Batch fetch existing tags
	var existingTags []TagModel
	if err := db.Where("tag IN ?", uniqueTags).Find(&existingTags).Error; err != nil {
		return err
	}

	// Create a map for quick lookup
	existingTagMap := make(map[string]TagModel)
	for _, t := range existingTags {
		existingTagMap[t.Tag] = t
	}

	// Create missing tags and build final list
	var tagList []TagModel
	for _, tag := range uniqueTags {
		if existing, ok := existingTagMap[tag]; ok {
			tagList = append(tagList, existing)
		} else {
			// Create new tag with race condition handling
			newTag := TagModel{Tag: tag}
			if err := db.Create(&newTag).Error; err != nil {
				// If creation failed (e.g., concurrent insert), try to fetch existing
				var existing TagModel
				if err2 := db.Where("tag = ?", tag).First(&existing).Error; err2 == nil {
					tagList = append(tagList, existing)
					continue
				}
				return err
			}
			tagList = append(tagList, newTag)
		}
	}
	model.Tags = tagList
	return nil
}

// UniqueSlug derives a slug from a title, appending a counter when an article
// already owns the derived value. The contract requires two articles that share
// a title to receive distinct slugs.
func UniqueSlug(title string) (string, error) {
	return uniqueSlugWithDB(common.GetDB(), title)
}

func uniqueSlugWithDB(db *gorm.DB, title string) (string, error) {
	base := slug.Make(title)
	if base == "" {
		return "", errors.New("title must produce a non-empty slug")
	}
	candidate := base
	for attempt := 2; ; attempt++ {
		var existing ArticleModel
		// A soft-deleted article still occupies the unique slug index. Include
		// retired rows so a replacement advances to a free suffix.
		if err := db.Unscoped().Where(&ArticleModel{Slug: candidate}).First(&existing).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return candidate, nil
			}
			return "", err
		}
		candidate = base + "-" + strconv.Itoa(attempt)
	}
}

// SaveArticleWithUniqueSlug allocates the slug and inserts the article as one
// retryable operation. The unique index decides races between equal titles;
// a losing request observes the winner and advances to the next suffix.
func SaveArticleWithUniqueSlug(model *ArticleModel) error {
	return saveArticleWithUniqueSlugWithDB(common.GetDB(), model)
}

func saveArticleWithUniqueSlugWithDB(db *gorm.DB, model *ArticleModel) error {
	for {
		candidate, err := uniqueSlugWithDB(db, model.Title)
		if err != nil {
			return err
		}
		model.Slug = candidate
		if err := db.Save(model).Error; err != nil {
			if !errors.Is(err, gorm.ErrDuplicatedKey) {
				return err
			}
			var existing ArticleModel
			if lookupErr := db.Unscoped().Where("slug = ?", model.Slug).First(&existing).Error; lookupErr != nil {
				return err
			}
			model.ID = 0
			continue
		}
		return nil
	}
}

func DeleteArticleModel(condition interface{}) error {
	db := common.GetDB()
	err := db.Where(condition).Delete(&ArticleModel{}).Error
	return err
}

func DeleteCommentModel(condition interface{}) error {
	db := common.GetDB()
	err := db.Where(condition).Delete(&CommentModel{}).Error
	return err
}
