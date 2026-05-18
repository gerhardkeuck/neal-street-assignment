package main

import (
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	_ = godotenv.Load()

	commit := mustEnv("COMMIT_HASH")
	region := mustEnv("REGION")
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}

	logger.Info("starting rewards service", "addr", addr, "commit", commit, "region", region)
	if err := router(commit, region).Run(addr); err != nil {
		logger.Error("rewards service stopped", "error", err)
		os.Exit(1)
	}
}

func mustEnv(key string) string {
	value := os.Getenv(key)
	if value == "" {
		slog.Error("required environment variable missing", "key", key)
		os.Exit(1)
	}
	return value
}

func router(commit, region string) *gin.Engine {
	gin.SetMode(gin.ReleaseMode)

	r := gin.New()
	r.Use(requestLogger())
	r.Use(gin.Recovery())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": "rewards",
			"status":  "ok",
			"commit":  commit,
			"region":  region,
		})
	})

	return r
}

func requestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		attrs := []any{
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"route", c.FullPath(),
			"status", c.Writer.Status(),
			"duration_ms", time.Since(start).Milliseconds(),
			"client_ip", c.ClientIP(),
			"user_agent", c.Request.UserAgent(),
		}

		if len(c.Errors) > 0 {
			attrs = append(attrs, "errors", c.Errors.String())
		}

		if c.Writer.Status() >= http.StatusInternalServerError {
			slog.Error("request completed", attrs...)
			return
		}
		slog.Info("request completed", attrs...)
	}
}
