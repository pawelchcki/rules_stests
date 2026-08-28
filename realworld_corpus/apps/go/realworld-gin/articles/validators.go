package articles

import (
	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/gorm"
)

type ArticleModelValidator struct {
	Article struct {
		Title       string `form:"title" json:"title" binding:"required,min=4"`
		Description string `form:"description" json:"description" binding:"required,max=2048"`
		Body        string `form:"body" json:"body" binding:"required,max=2048"`
		// A pointer distinguishes "tagList omitted" (leave tags alone) from
		// "tagList: []" (remove every tag), which the contract separates.
		Tags *[]string `form:"tagList" json:"tagList" binding:"omitempty,dive,required"`
	} `json:"article"`
	articleModel ArticleModel `json:"-"`
}

func NewArticleModelValidator() ArticleModelValidator {
	return ArticleModelValidator{}
}

func NewArticleModelValidatorFillWith(articleModel ArticleModel) ArticleModelValidator {
	articleModelValidator := NewArticleModelValidator()
	articleModelValidator.Article.Title = articleModel.Title
	articleModelValidator.Article.Description = articleModel.Description
	articleModelValidator.Article.Body = articleModel.Body
	tags := []string{}
	for _, tagModel := range articleModel.Tags {
		tags = append(tags, tagModel.Tag)
	}
	articleModelValidator.Article.Tags = &tags
	return articleModelValidator
}

func (s *ArticleModelValidator) Bind(c *gin.Context) error {
	return s.bindWithDB(c, common.GetDB())
}

func (s *ArticleModelValidator) bindWithDB(c *gin.Context, db *gorm.DB) error {
	myUserModel := c.MustGet("my_user_model").(users.UserModel)

	err := common.Bind(c, s)
	if err != nil {
		return err
	}
	s.articleModel.Title = s.Article.Title
	s.articleModel.Description = s.Article.Description
	s.articleModel.Body = s.Article.Body
	articleUserModel, err := getArticleUserModel(db, myUserModel)
	if err != nil {
		return err
	}
	s.articleModel.Author = articleUserModel
	if s.Article.Tags != nil {
		if err := s.articleModel.setTagsWithDB(db, *s.Article.Tags); err != nil {
			return err
		}
	}
	return nil
}

type CommentModelValidator struct {
	Comment struct {
		Body string `form:"body" json:"body" binding:"required,max=2048"`
	} `json:"comment"`
	commentModel CommentModel `json:"-"`
}

func NewCommentModelValidator() CommentModelValidator {
	return CommentModelValidator{}
}

func (s *CommentModelValidator) Bind(c *gin.Context) error {
	myUserModel := c.MustGet("my_user_model").(users.UserModel)

	err := common.Bind(c, s)
	if err != nil {
		return err
	}
	s.commentModel.Body = s.Comment.Body
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		return err
	}
	s.commentModel.Author = articleUserModel
	return nil
}
