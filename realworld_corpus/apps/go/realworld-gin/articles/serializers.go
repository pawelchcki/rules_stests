package articles

import (
	"sort"

	"github.com/gin-gonic/gin"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/gorm"
)

type TagSerializer struct {
	C *gin.Context
	TagModel
}

type TagsSerializer struct {
	C    *gin.Context
	Tags []TagModel
}

func (s *TagSerializer) Response() string {
	return s.TagModel.Tag
}

func (s *TagsSerializer) Response() []string {
	response := []string{}
	for _, tag := range s.Tags {
		serializer := TagSerializer{C: s.C, TagModel: tag}
		response = append(response, serializer.Response())
	}
	return response
}

type ArticleUserSerializer struct {
	C *gin.Context
	ArticleUserModel
}

func (s *ArticleUserSerializer) Response() (users.ProfileResponse, error) {
	return s.ResponseWithDB(common.GetDB())
}

func (s *ArticleUserSerializer) ResponseWithDB(db *gorm.DB) (users.ProfileResponse, error) {
	response := users.ProfileSerializer{C: s.C, UserModel: s.ArticleUserModel.UserModel}
	return response.ResponseWithDB(db)
}

type ArticleSerializer struct {
	C *gin.Context
	ArticleModel
}

type ArticleResponse struct {
	ID          uint   `json:"-"`
	Title       string `json:"title"`
	Slug        string `json:"slug"`
	Description string `json:"description"`
	// The multiple-articles contract omits the body, so it is optional here and
	// only the single-article responses populate it.
	Body           *string               `json:"body,omitempty"`
	CreatedAt      string                `json:"createdAt"`
	UpdatedAt      string                `json:"updatedAt"`
	Author         users.ProfileResponse `json:"author"`
	Tags           []string              `json:"tagList"`
	Favorite       bool                  `json:"favorited"`
	FavoritesCount uint                  `json:"favoritesCount"`
}

type ArticlesSerializer struct {
	C        *gin.Context
	Articles []ArticleModel
}

func (s *ArticleSerializer) Response() (ArticleResponse, error) {
	return s.ResponseWithDB(common.GetDB())
}

func (s *ArticleSerializer) ResponseWithDB(db *gorm.DB) (ArticleResponse, error) {
	body := s.Body
	myUserModel := s.C.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := getArticleUserModel(db, myUserModel)
	if err != nil {
		return ArticleResponse{}, err
	}
	favorited, err := s.isFavoriteByWithDB(db, articleUserModel)
	if err != nil {
		return ArticleResponse{}, err
	}
	favoritesCount, err := s.favoritesCountWithDB(db)
	if err != nil {
		return ArticleResponse{}, err
	}
	authorSerializer := ArticleUserSerializer{C: s.C, ArticleUserModel: s.Author}
	author, err := authorSerializer.ResponseWithDB(db)
	if err != nil {
		return ArticleResponse{}, err
	}
	response := ArticleResponse{
		ID:          s.ID,
		Slug:        s.Slug,
		Title:       s.Title,
		Description: s.Description,
		Body:        &body,
		CreatedAt:   s.CreatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		//UpdatedAt:      s.UpdatedAt.UTC().Format(time.RFC3339Nano),
		UpdatedAt:      s.UpdatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		Author:         author,
		Favorite:       favorited,
		FavoritesCount: favoritesCount,
	}
	response.Tags = make([]string, 0)
	for _, tag := range s.Tags {
		serializer := TagSerializer{C: s.C, TagModel: tag}
		response.Tags = append(response.Tags, serializer.Response())
	}
	sort.Strings(response.Tags)
	return response, nil
}

// ResponseWithPreloaded creates response using preloaded favorite data to avoid N+1 queries
func (s *ArticleSerializer) ResponseWithPreloaded(favorited bool, favoritesCount uint) (ArticleResponse, error) {
	authorSerializer := ArticleUserSerializer{C: s.C, ArticleUserModel: s.Author}
	author, err := authorSerializer.Response()
	if err != nil {
		return ArticleResponse{}, err
	}
	response := ArticleResponse{
		ID:             s.ID,
		Slug:           s.Slug,
		Title:          s.Title,
		Description:    s.Description,
		CreatedAt:      s.CreatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		UpdatedAt:      s.UpdatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		Author:         author,
		Favorite:       favorited,
		FavoritesCount: favoritesCount,
	}
	response.Tags = make([]string, 0)
	for _, tag := range s.Tags {
		serializer := TagSerializer{C: s.C, TagModel: tag}
		response.Tags = append(response.Tags, serializer.Response())
	}
	sort.Strings(response.Tags)
	return response, nil
}

func (s *ArticlesSerializer) Response() ([]ArticleResponse, error) {
	response := []ArticleResponse{}
	if len(s.Articles) == 0 {
		return response, nil
	}

	// Batch fetch favorite counts and status
	var articleIDs []uint
	for _, article := range s.Articles {
		articleIDs = append(articleIDs, article.ID)
	}

	favoriteCounts, err := BatchGetFavoriteCounts(articleIDs)
	if err != nil {
		return nil, err
	}

	myUserModel := s.C.MustGet("my_user_model").(users.UserModel)
	articleUserModel, err := GetArticleUserModel(myUserModel)
	if err != nil {
		return nil, err
	}
	favoriteStatus, err := BatchGetFavoriteStatus(articleIDs, articleUserModel.ID)
	if err != nil {
		return nil, err
	}

	for _, article := range s.Articles {
		serializer := ArticleSerializer{C: s.C, ArticleModel: article}
		favorited := favoriteStatus[article.ID]
		count := favoriteCounts[article.ID]
		articleResponse, err := serializer.ResponseWithPreloaded(favorited, count)
		if err != nil {
			return nil, err
		}
		response = append(response, articleResponse)
	}
	return response, nil
}

type CommentSerializer struct {
	C *gin.Context
	CommentModel
}

type CommentsSerializer struct {
	C        *gin.Context
	Comments []CommentModel
}

type CommentResponse struct {
	ID        uint                  `json:"id"`
	Body      string                `json:"body"`
	CreatedAt string                `json:"createdAt"`
	UpdatedAt string                `json:"updatedAt"`
	Author    users.ProfileResponse `json:"author"`
}

func (s *CommentSerializer) Response() (CommentResponse, error) {
	authorSerializer := ArticleUserSerializer{C: s.C, ArticleUserModel: s.Author}
	author, err := authorSerializer.Response()
	if err != nil {
		return CommentResponse{}, err
	}
	response := CommentResponse{
		ID:        s.ID,
		Body:      s.Body,
		CreatedAt: s.CreatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		UpdatedAt: s.UpdatedAt.UTC().Format("2006-01-02T15:04:05.999Z"),
		Author:    author,
	}
	return response, nil
}

func (s *CommentsSerializer) Response() ([]CommentResponse, error) {
	response := []CommentResponse{}
	for _, comment := range s.Comments {
		serializer := CommentSerializer{C: s.C, CommentModel: comment}
		commentResponse, err := serializer.Response()
		if err != nil {
			return nil, err
		}
		response = append(response, commentResponse)
	}
	return response, nil
}
