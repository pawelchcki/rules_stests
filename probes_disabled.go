//go:build !datadog

package main

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func installFixtureProbes(*gin.Engine, *gorm.DB) {}
