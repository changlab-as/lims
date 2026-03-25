#!/usr/bin/env Rscript
# Load just the UI from app.R to find the exact error

cat("Loading app.R UI...\n\n")

library(shiny)
library(bs4Dash)
library(shinyjs)
library(DT)
library(qrcode)

tryCatch({
  # Read the app.R file
  content <- readLines("app.R")
  
  # Find where "ui <-" starts and "server <-" starts
  ui_start <- which(grepl("^ui <- ", content))[1]
  server_start <- which(grepl("^server <- ", content))[1]
  
  cat(sprintf("UI definition starts at line %d\n", ui_start))
  cat(sprintf("Server starts at line %d\n", server_start))
  
  # Extract and eval just the UI part
  ui_code <- content[ui_start:(server_start - 1)]
  ui_code <- paste(ui_code, collapse = "\n")
  
  cat("\nEvaluating UI definition...\n")
  eval(parse(text = ui_code))
  
  cat("✓ UI loaded successfully!\n")
  cat(sprintf("UI class: %s\n", class(ui)[1]))
  
}, error = function(e) {
  cat("✗ Error loading UI:\n")
  cat(sprintf("  %s\n", e$message))
  cat(sprintf("\nFull error:\n%s\n", conditionMessage(e)))
  
  # Try to get more context
  traceback_info <- traceback()
  cat("\nTraceback:\n")
  print(traceback())
})
