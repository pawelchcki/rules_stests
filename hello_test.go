package main

import (
	"net"
	"testing"

	"github.com/gothinkster/golang-gin-realworld-example-app/common"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestListenSharesReservedPort(t *testing.T) {
	reservation, err := listen("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer reservation.Close()

	address := reservation.Addr().(*net.TCPAddr)
	server, err := listen(address.String())
	if err != nil {
		t.Fatalf("listen with SO_REUSEPORT reservation: %v", err)
	}
	server.Close()
}

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
