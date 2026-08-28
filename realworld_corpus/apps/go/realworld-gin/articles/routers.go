package articles

import (
	"errors"
	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/gorm"
	"net/http"
	"strconv"
)

func ArticlesRegister(router *gin.RouterGroup) {
	router.GET("/feed", ArticleFeed)
	router.POST("", ArticleCreate)
	router.POST("/", ArticleCreate)
	router.PUT("/:slug", ArticleUpdate)
	router.PUT("/:slug/", ArticleUpdate)
	router.DELETE("/:slug", ArticleDelete)
	router.POST("/:slug/favorite", ArticleFavorite)
	router.DELETE("/:slug/favorite", ArticleUnfavorite)
	router.POST("/:slug/comments", ArticleCommentCreate)
	router.DELETE("/:slug/comments/:id", ArticleCommentDelete)
}

func ArticlesAnonymousRegister(router *gin.RouterGroup) {
	router.GET("", ArticleList)
	router.GET("/", ArticleList)
	router.GET("/:slug", ArticleRetrieve)
	router.GET("/:slug/comments", ArticleCommentList)
}

func TagsAnonymousRegister(router *gin.RouterGroup) {
	router.GET("", TagList)
	router.GET("/", TagList)
}

func ArticleCreate(c *gin.Context) {
	articleModelValidator := NewArticleModelValidator()
	var bindErr error
	err := common.GetDB().Transaction(func(tx *gorm.DB) error {
		bindErr = articleModelValidator.bindWithDB(c, tx)
		if bindErr != nil {
			return bindErr
		}
		return saveArticleWithUniqueSlugWithDB(tx, &articleModelValidator.articleModel)
	})
	if err != nil {
		if bindErr != nil {
			c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(bindErr))
		} else {
			c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		}
		return
	}
	serializer := ArticleSerializer{c, articleModelValidator.articleModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusCreated, gin.H{"article": response})
}

func ArticleList(c *gin.Context) {
	//condition := ArticleModel{}
	tag := c.Query("tag")
	author := c.Query("author")
	favorited := c.Query("favorited")
	limit := c.Query("limit")
	offset := c.Query("offset")
	articleModels, modelCount, err := FindManyArticle(tag, author, limit, offset, favorited)
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := ArticlesSerializer{c, articleModels}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"articles": response, "articlesCount": modelCount})
}

func ArticleFeed(c *gin.Context) {
	limit := c.Query("limit")
	offset := c.Query("offset")
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	if myUserModel.ID == 0 {
		c.AbortWithError(http.StatusUnauthorized, errors.New("{error : \"Require auth!\"}"))
		return
	}
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	articleModels, modelCount, err := articleUserModel.GetArticleFeed(limit, offset)
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := ArticlesSerializer{c, articleModels}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"articles": response, "articlesCount": modelCount})
}

func ArticleRetrieve(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := ArticleSerializer{c, articleModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"article": response})
}

func ArticleUpdate(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	// Check if current user is the author
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	if articleModel.AuthorID != articleUserModel.ID {
		c.JSON(http.StatusForbidden, common.NewError("article", errors.New("forbidden")))
		return
	}

	supplied, err := common.SuppliedFields(c, "article")
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("body", errors.New("is invalid")))
		return
	}
	nullFields := make([]string, 0, 4)
	for _, field := range []string{"title", "description", "body", "tagList"} {
		if common.IsExplicitNull(supplied, field) {
			nullFields = append(nullFields, field)
		}
	}
	if len(nullFields) != 0 {
		c.JSON(http.StatusUnprocessableEntity, common.BlankFieldError(nullFields...))
		return
	}

	articleModelValidator := NewArticleModelValidatorFillWith(articleModel)
	var bindErr error
	err = common.GetDB().Transaction(func(tx *gorm.DB) error {
		bindErr = articleModelValidator.bindWithDB(c, tx)
		if bindErr != nil {
			return bindErr
		}

		articleModelValidator.articleModel.ID = articleModel.ID
		// The slug identifies the article for the rest of the contract, so an
		// update keeps the one the article was created with.
		articleModelValidator.articleModel.Slug = articleModel.Slug
		updatedTags := articleModelValidator.articleModel.Tags
		if err := tx.Model(&articleModel).Updates(articleModelValidator.articleModel).Error; err != nil {
			return err
		}
		return tx.Model(&articleModel).Association("Tags").Replace(updatedTags)
	})
	if err != nil {
		if bindErr != nil {
			c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(bindErr))
		} else {
			c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		}
		return
	}
	articleModel, err = FindOneArticle(&ArticleModel{Slug: articleModel.Slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := ArticleSerializer{c, articleModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"article": response})
}

func ArticleDelete(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	if articleModel.AuthorID != articleUserModel.ID {
		c.JSON(http.StatusForbidden, common.NewError("article", errors.New("forbidden")))
		return
	}
	if err := DeleteArticleModel(&ArticleModel{Slug: slug}); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	// The pinned RealWorld contract suite expects an empty 204 for deletes.
	c.Status(http.StatusNoContent)
}

func ArticleFavorite(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	if err = articleModel.favoriteBy(articleUserModel); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	serializer := ArticleSerializer{c, articleModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"article": response})
}

func ArticleUnfavorite(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	if err = articleModel.unFavoriteBy(articleUserModel); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	serializer := ArticleSerializer{c, articleModel}
	response, err := serializer.Response()
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	c.JSON(http.StatusOK, gin.H{"article": response})
}

func ArticleCommentCreate(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	commentModelValidator := NewCommentModelValidator()
	if err := commentModelValidator.Bind(c); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewValidatorError(err))
		return
	}
	commentModelValidator.commentModel.Article = articleModel

	if err := SaveOne(&commentModelValidator.commentModel); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	serializer := CommentSerializer{c, commentModelValidator.commentModel}
	c.JSON(http.StatusCreated, gin.H{"comment": serializer.Response()})
}

func ArticleCommentDelete(c *gin.Context) {
	articleModel, err := FindOneArticle(&ArticleModel{Slug: c.Param("slug")})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	id64, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("comment", errors.New("not found")))
		return
	}
	id := uint(id64)
	commentModel, err := FindOneComment(&CommentModel{
		Model:     gorm.Model{ID: id},
		ArticleID: articleModel.ID,
	})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("comment", errors.New("not found")))
		return
	}
	myUserModel := c.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	if commentModel.AuthorID != articleUserModel.ID {
		c.JSON(http.StatusForbidden, common.NewError("comment", errors.New("forbidden")))
		return
	}
	if err := DeleteCommentModel([]uint{id}); err != nil {
		c.JSON(http.StatusUnprocessableEntity, common.NewError("database", err))
		return
	}
	// The pinned RealWorld contract suite expects an empty 204 for deletes.
	c.Status(http.StatusNoContent)
}

func ArticleCommentList(c *gin.Context) {
	slug := c.Param("slug")
	articleModel, err := FindOneArticle(&ArticleModel{Slug: slug})
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	err = articleModel.getComments()
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := CommentsSerializer{c, articleModel.Comments}
	c.JSON(http.StatusOK, gin.H{"comments": serializer.Response()})
}
func TagList(c *gin.Context) {
	tagModels, err := getAllTags()
	if err != nil {
		c.JSON(http.StatusNotFound, common.NewError("article", errors.New("not found")))
		return
	}
	serializer := TagsSerializer{c, tagModels}
	c.JSON(http.StatusOK, gin.H{"tags": serializer.Response()})
}
