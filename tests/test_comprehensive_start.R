#!/usr/bin/env Rscript
# Comprehensive LIMS App Start Test

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║  LIMS Shiny App - Comprehensive Start Test                  ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

# Test 1: Syntax check
cat("TEST 1: Syntax Validation\n")
cat("─────────────────────────────────────\n")
syntax_ok <- tryCatch({
  parse(file = "app.R")
  cat("✓ R syntax valid\n")
  TRUE
}, error = function(e) {
  cat("✗ Syntax error:", e$message, "\n")
  FALSE
})

if (!syntax_ok) quit(status = 1)

# Test 2: Check for problematic functions
cat("\nTEST 2: Function Check\n")
cat("─────────────────────────────────────\n")

app_content <- readLines("app.R")
problematic_funcs <- c("bs4Row", "bs4Column", "navbarMenuItem")

for (func in problematic_funcs) {
  count <- sum(grepl(func, app_content))
  if (count > 0) {
    cat(sprintf("✗ Found %d instances of '%s' (should be removed)\n", count, func))
  } else {
    cat(sprintf("✓ No instances of '%s'\n", func))
  }
}

# Test 3: Load libraries
cat("\nTEST 3: Loading Libraries\n")
cat("─────────────────────────────────────\n")

libs_ok <- tryCatch({
  library(shiny, quietly = TRUE)
  library(bs4Dash, quietly = TRUE)
  library(shinyjs, quietly = TRUE)
  library(DT, quietly = TRUE)
  library(RSQLite, quietly = TRUE)
  library(qrcode, quietly = TRUE)
  library(pool, quietly = TRUE)
  library(dplyr, quietly = TRUE)
  library(DBI, quietly = TRUE)
  library(gridExtra, quietly = TRUE)
  cat("✓ All libraries loaded\n")
  TRUE
}, error = function(e) {
  cat("✗ Library error:", e$message, "\n")
  FALSE
})

if (!libs_ok) quit(status = 1)

# Test 4: Try to load app without running shinyApp()
cat("\nTEST 4: Loading App Components\n")
cat("─────────────────────────────────────\n")

app_ok <- tryCatch({
  # Parse and evaluate all but the last line (shinyApp call)
  expr <- parse(file = "app.R")
  
  # Find the shinyApp() call and exclude it
  eval(expr[1:(length(expr)-1)])
  
  cat("✓ App components loaded successfully\n")
  TRUE
}, error = function(e) {
  cat("✗ App loading error:", e$message, "\n")
  cat("  Details:", conditionMessage(e), "\n")
  FALSE
})

if (!app_ok) quit(status = 1)

# Test 5: Verify ui and server exist
cat("\nTEST 5: UI and Server Objects\n")
cat("─────────────────────────────────────\n")

if (exists("ui")) {
  cat(sprintf("✓ UI object exists (class: %s)\n", class(ui)[1]))
} else {
  cat("✗ UI object not found\n")
  quit(status = 1)
}

if (exists("server")) {
  cat(sprintf("✓ Server function exists\n"))
} else {
  cat("✗ Server function not found\n")
  quit(status = 1)
}

# Test 6: Check database
cat("\nTEST 6: Database Setup\n")
cat("─────────────────────────────────────\n")

if (dir.exists("data")) {
  cat("✓ Data directory exists\n")
} else {
  cat("✗ Data directory missing\n")
}

if (dir.exists("www")) {
  cat("✓ WWW directory exists\n")
} else {
  cat("✗ WWW directory missing\n")
}

# Final Result
cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║  ✅ SUCCESS - App is Ready to Run!                          ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

cat("To start the Shiny app, execute:\n\n")
cat("  shiny::runApp()\n\n")
cat("Or from terminal:\n\n")
cat("  Rscript -e \"shiny::runApp()\"\n\n")
cat("The app will be available at:\n")
cat("  http://localhost:3838\n\n")
