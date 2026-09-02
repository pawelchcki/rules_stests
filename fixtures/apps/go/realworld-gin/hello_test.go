package main

import (
	"testing"

	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestMigratePropagatesSchemaFailure(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:migrate-failure?mode=memory&cache=shared"), &gorm.Config{TranslateError: true})
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
	if err := Migrate(db); err == nil {
		t.Fatal("migration on a closed database unexpectedly succeeded")
	}
}
