package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"os"

	"github.com/gin-gonic/gin"

	"github.com/gothinkster/golang-gin-realworld-example-app/articles"
	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"github.com/gothinkster/golang-gin-realworld-example-app/users"
	"gorm.io/gorm"
)

func Migrate(db *gorm.DB) error {
	if err := users.AutoMigrate(db); err != nil {
		return fmt.Errorf("migrate users: %w", err)
	}
	if err := db.AutoMigrate(
		&articles.ArticleModel{},
		&articles.TagModel{},
		&articles.FavoriteModel{},
		&articles.ArticleUserModel{},
		&articles.CommentModel{},
	); err != nil {
		return fmt.Errorf("migrate articles: %w", err)
	}
	return nil
}

// parseServeAddress reads the corpus launcher convention
// `serve --host <host> --port <port>` and falls back to the upstream PORT
// environment variable when no subcommand is given.
func parseServeAddress(argv []string) (string, error) {
	host := "0.0.0.0"
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	if len(argv) > 0 {
		if argv[0] != "serve" {
			return "", fmt.Errorf("unsupported subcommand %q", argv[0])
		}
		flags := flag.NewFlagSet("serve", flag.ContinueOnError)
		flags.StringVar(&host, "host", host, "address to bind")
		flags.StringVar(&port, "port", port, "port to bind")
		if err := flags.Parse(argv[1:]); err != nil {
			return "", err
		}
		if flags.NArg() != 0 {
			return "", fmt.Errorf("unexpected arguments: %v", flags.Args())
		}
	}
	return net.JoinHostPort(host, port), nil
}

func main() {
	address, err := parseServeAddress(os.Args[1:])
	if err != nil {
		log.Fatal("usage: realworld-gin serve --host <host> --port <port>: ", err)
	}

	db, err := common.Init()
	if err != nil {
		log.Fatal("initialize database: ", err)
	}
	if err := Migrate(db); err != nil {
		log.Fatal("initialize schema: ", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		log.Println("failed to get sql.DB:", err)
	} else {
		defer sqlDB.Close()
	}

	r := gin.Default()

	// Disable automatic redirect for trailing slashes
	// This prevents POST body from being lost during redirects
	r.RedirectTrailingSlash = false

	v1 := r.Group("/api")
	users.UsersRegister(v1.Group("/users"))
	v1.Use(users.AuthMiddleware(false))
	articles.ArticlesAnonymousRegister(v1.Group("/articles"))
	articles.TagsAnonymousRegister(v1.Group("/tags"))
	users.ProfileRetrieveRegister(v1.Group("/profiles"))

	v1.Use(users.AuthMiddleware(true))
	users.UserRegister(v1.Group("/user"))
	users.ProfileRegister(v1.Group("/profiles"))

	articles.ArticlesRegister(v1.Group("/articles"))

	testAuth := r.Group("/api/ping")

	testAuth.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	if err := r.Run(address); err != nil {
		log.Fatal("failed to start server:", err)
	}
}
