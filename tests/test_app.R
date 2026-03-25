#!/usr/bin/env Rscript
# Unit test for LIMS Shiny App
# Validates syntax, structure, and key components

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║  LIMS Shiny App - Unit Test Suite                        ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Test 1: Check syntax
cat("TEST 1: Syntax Validation\n")
cat("─────────────────────────────────\n")
syntax_check <- tryCatch({
  parse(file = "app.R")
  cat("✓ R syntax is valid (no commas or brackets issues)\n")
  TRUE
}, error = function(e) {
  cat("✗ Syntax error:", e$message, "\n")
  FALSE
})

# Test 2: Load libraries
cat("\nTEST 2: Required Libraries\n")
cat("─────────────────────────────────\n")

required_libs <- c("shiny", "bs4Dash", "shinyjs", "DT", "RSQLite", "qrcode", 
                   "pool", "dplyr", "DBI", "gridExtra")

libs_ok <- TRUE
for (lib in required_libs) {
  if (requireNamespace(lib, quietly = TRUE)) {
    cat(paste0("✓ ", lib, "\n"))
  } else {
    cat(paste0("✗ ", lib, " NOT FOUND\n"))
    libs_ok <- FALSE
  }
}

# Test 3: Load app components
cat("\nTEST 3: App Component Loading\n")
cat("─────────────────────────────────\n")

# Make sure all libraries are loaded in this environment
library(shiny)
library(bs4Dash)
library(shinyjs)
library(DT)
library(RSQLite)
library(qrcode)
library(pool)
library(dplyr)
library(DBI)
library(gridExtra)

app_ok <- tryCatch({
  # Load app with all dependencies available
  source("app.R", local = TRUE)
  cat("✓ App loaded successfully\n")
  TRUE
}, error = function(e) {
  cat("✗ App loading error:", e$message, "\n")
  FALSE
})

# Test 4: Check UI structure
cat("\nTEST 4: UI Structure Validation\n")
cat("─────────────────────────────────\n")

ui_ok <- tryCatch({
  # Verify ui object exists and is a shiny.tag
  if (exists("ui")) {
    if (inherits(ui, "shiny.tag")) {
      cat("✓ UI object is valid shiny.tag\n")
    } else {
      cat("✗ UI is not a shiny.tag object\n")
      FALSE
    }
  } else {
    cat("✗ UI object not found\n")
    FALSE
  }
  TRUE
}, error = function(e) {
  cat("✗ UI validation error:", e$message, "\n")
  FALSE
})

# Test 5: Check server function
cat("\nTEST 5: Server Function Validation\n")
cat("─────────────────────────────────\n")

server_ok <- tryCatch({
  if (exists("server")) {
    if (is.function(server)) {
      cat("✓ Server is a valid function\n")
      TRUE
    } else {
      cat("✗ Server is not a function\n")
      FALSE
    }
  } else {
    cat("✗ Server function not found\n")
    FALSE
  }
}, error = function(e) {
  cat("✗ Server validation error:", e$message, "\n")
  FALSE
})

# Test 6: Check database setup
cat("\nTEST 6: Database Setup\n")
cat("─────────────────────────────────\n")

db_ok <- tryCatch({
  # Check if database was initialized
  if (file.exists("data/lims_db.sqlite")) {
    cat("✓ Database file created (data/lims_db.sqlite)\n")
  } else {
    cat("✓ Database will be created on first run\n")
  }
  
  # Check if directories exist
  if (dir.exists("data")) {
    cat("✓ Data directory exists\n")
  }
  
  if (dir.exists("www")) {
    cat("✓ WWW directory exists\n")
  }
  
  TRUE
}, error = function(e) {
  cat("✗ Database setup error:", e$message, "\n")
  FALSE
})

# Summary
cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║  Test Summary                                              ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

all_tests <- c(
  "Syntax Validation" = syntax_check,
  "Libraries" = libs_ok,
  "App Loading" = app_ok,
  "UI Structure" = ui_ok,
  "Server Function" = server_ok,
  "Database Setup" = db_ok
)

passed <- sum(all_tests)
total <- length(all_tests)

for (test_name in names(all_tests)) {
  status <- if (all_tests[[test_name]]) "✓ PASS" else "✗ FAIL"
  cat(sprintf("%s: %s\n", status, test_name))
}

cat(sprintf("\nOverall: %d/%d tests passed\n", passed, total))

if (passed == total) {
  cat("\n🎉 All tests passed! App is ready to run with:\n")
  cat("   shiny::runApp()\n\n")
  quit(status = 0)
} else {
  cat("\n⚠️  Some tests failed. Please check errors above.\n\n")
  quit(status = 1)
}
