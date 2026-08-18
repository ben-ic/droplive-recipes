package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	healthURL := "http://127.0.0.1:8080/health"
	if len(os.Args) == 2 {
		healthURL = os.Args[1]
	}
	client := http.Client{Timeout: 3 * time.Second}
	response, err := client.Get(healthURL)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer response.Body.Close()

	var health struct {
		Status string `json:"status"`
	}
	if response.StatusCode != http.StatusOK || json.NewDecoder(response.Body).Decode(&health) != nil || !strings.EqualFold(health.Status, "UP") {
		fmt.Fprintf(os.Stderr, "unhealthy: http_status=%d application_status=%q\n", response.StatusCode, health.Status)
		os.Exit(1)
	}
}
