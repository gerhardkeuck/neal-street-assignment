package main

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthEndpoint(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	response := httptest.NewRecorder()

	router("abc123", "eu-west-1").ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, response.Code)
	}

	want := `{"commit":"abc123","region":"eu-west-1","service":"rewards","status":"ok"}`
	if strings.TrimSpace(response.Body.String()) != want {
		t.Fatalf("unexpected response body: %s", response.Body.String())
	}
}

func TestHealthEndpointLogsRequest(t *testing.T) {
	var logBuffer bytes.Buffer
	originalLogger := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&logBuffer, nil)))
	defer slog.SetDefault(originalLogger)

	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	response := httptest.NewRecorder()

	router("abc123", "eu-west-1").ServeHTTP(response, request)

	var logEntry map[string]any
	if err := json.Unmarshal(logBuffer.Bytes(), &logEntry); err != nil {
		t.Fatalf("expected JSON log entry, got %q: %v", logBuffer.String(), err)
	}

	if logEntry["msg"] != "request completed" {
		t.Fatalf("expected request log message, got %v", logEntry["msg"])
	}
	if logEntry["method"] != http.MethodGet {
		t.Fatalf("expected method %s, got %v", http.MethodGet, logEntry["method"])
	}
	if logEntry["path"] != "/health" {
		t.Fatalf("expected path /health, got %v", logEntry["path"])
	}
	if logEntry["route"] != "/health" {
		t.Fatalf("expected route /health, got %v", logEntry["route"])
	}
	if logEntry["status"] != float64(http.StatusOK) {
		t.Fatalf("expected status %d, got %v", http.StatusOK, logEntry["status"])
	}
}
