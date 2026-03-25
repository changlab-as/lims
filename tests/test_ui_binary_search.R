#!/usr/bin/env Rscript
# Binary search to find the problematic line in the UI

library(shiny)
library(bs4Dash)
library(shinyjs)
library(DT)
library(qrcode)

cat("Binary search for problematic UI line...\n\n")

# Read app.R
content <- readLines("app.R")

# Find UI and server boundaries
ui_start <- which(grepl("^ui <- ", content))[1]
server_start <- which(grepl("^server <- ", content))[1]
ui_lines <- content[ui_start:server_start - 1]

cat(sprintf("UI definition: lines %d to %d (total %d lines)\n\n", 
            ui_start, server_start - 1, length(ui_lines)))

# Test progressively adding more lines
for (n_lines in seq(1, length(ui_lines), by = 50)) {
  cat(sprintf("Testing with %d lines...", n_lines))
  
  test_code <- paste(ui_lines[1:n_lines], collapse = "\n")
  
  result <- tryCatch({
    eval(parse(text = test_code))
    cat(" ✓\n")
    TRUE
  }, error = function(e) {
    cat(sprintf(" ✗ Error\n"))
    FALSE
  })
  
  if (!result) {
    cat(sprintf("\n  Error occurred around line %d (absolute line %d in file)\n", 
                n_lines, ui_start + n_lines - 1))
    
    # Do detailed check
    cat("\nTrying binary search in this range...\n")
    low <- max(1, n_lines - 50)
    high <- n_lines
    
    while (high - low > 1) {
      mid <- (low + high) %/% 2
      test_code <- paste(ui_lines[1:mid], collapse = "\n")
      
      result <- tryCatch({
        eval(parse(text = test_code))
        TRUE
      }, error = function(e) {
        FALSE
      })
      
      if (result) {
        low <- mid
        cat(sprintf("  Lines 1-%d: ✓\n", mid))
      } else {
        high <- mid
        cat(sprintf("  Lines 1-%d: ✗\n", mid))
      }
    }
    
    cat(sprintf("\nProblem is between lines %d-%d (absolute lines %d-%d)\n",
                low+1, high, ui_start + low, ui_start + high - 1))
    
    # Show the problematic lines
    cat("\nProblematic lines:\n")
    for (i in (low+1):high) {
      cat(sprintf("%4d: %s\n", ui_start + i - 1, ui_lines[i]))
    }
    
    break
  }
}

cat("\nSearch complete.\n")
