//go:build tools

package tools

import (
	_ "github.com/DataDog/dd-trace-go/contrib/database/sql/v2"    // integration
	_ "github.com/DataDog/dd-trace-go/contrib/gin-gonic/gin/v2"   // integration
	_ "github.com/DataDog/dd-trace-go/contrib/gorm.io/gorm.v1/v2" // integration
	_ "github.com/DataDog/dd-trace-go/v2/ddtrace/tracer"          // integration
	_ "github.com/DataDog/orchestrion"                            // integration
)
