#!/usr/bin/env Rscript
# Test the specific a() tag that might be causing the issue

library(shiny)
library(bs4Dash)

cat("Testing the a() tag with download and href attributes...\n\n")

tryCatch({
  # Test 1: Simple a() tag
  cat("Test 1: Simple a tag...\n")
  tag1 <- a(href = "#", "Click me")
  cat("✓ Simple a tag OK\n")
  
  # Test 2: a() tag with download
  cat("Test 2: a tag with download...\n")
  tag2 <- a(download = "labels.zip", href = "#", "Download")
  cat("✓ a tag with download OK\n")
  
  # Test 3: a() tag with all attributes like in app.R  
  cat("Test 3: a tag with all attributes...\n")
  tag3 <- a(download = "labels.zip", href = "#", id = "download_labels_link",
            class = "btn btn-success btn-lg", style = "display:none;",
            "Download Generated Labels")
  cat("✓ Full a tag OK\n")
  
  # Test 4: Full card with the a() tag
  cat("Test 4: Card with a tag...\n")
  card <- bs4Card(
    title = "Test Card",
    img(src = "test.png", width = "200px"),
    br(), br(),
    a(download = "labels.zip", href = "#", id = "download_labels_link",
      class = "btn btn-success btn-lg", style = "display:none;",
      "Download Generated Labels")
  )
  cat("✓ Card with a tag OK\n")
  
  # Test 5: Full page with this card
  cat("Test 5: Full page with card...\n")
  full_page <- bs4DashPage(
    header = bs4DashNavbar(title = "Test"),
    sidebar = bs4DashSidebar(
      bs4SidebarMenu(
        bs4SidebarMenuItem(text = "Test", tabName = "test")
      )
    ),
    body = bs4DashBody(
      bs4TabItems(
        bs4TabItem(
          tabName = "test",
          fluidRow(
            column(
              width = 6,
              bs4Card(
                title = "Test Card",
                img(src = "test.png", width = "200px", onerror = "this.alt='No preview generated yet'"),
                br(), br(),
                a(download = "labels.zip", href = "#", id = "download_labels_link",
                  class = "btn btn-success btn-lg", style = "display:none;",
                  "Download Generated Labels")
              )
            )
          )
        )
      )
    )
  )
  cat("✓ Full page OK\n")
  
  cat("\n✅ All a() tag tests passed!\n")
  
}, error = function(e) {
  cat("✗ Error:\n")
  cat(sprintf("  %s\n", e$message))
})
