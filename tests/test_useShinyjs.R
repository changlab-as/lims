#!/usr/bin/env Rscript
# Test bs4DashPage with useShinyjs

library(shiny)
library(bs4Dash)
library(shinyjs)

cat("Testing bs4DashPage with shinyjs::useShinyjs()...\n\n")

# Test 1: Without useShinyjs
cat("Test 1: Without useShinyjs...\n")
tryCatch({
  page1 <- bs4DashPage(
    header = bs4DashNavbar(title = "Test"),
    sidebar = bs4DashSidebar(
      bs4SidebarMenu(bs4SidebarMenuItem(text = "T", tabName = "t"))
    ),
    body = bs4DashBody(bs4TabItems(bs4TabItem(tabName = "t")))
  )
  cat("✓ OK without useShinyjs\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

# Test 2: With useShinyjs as first argument (current app.R approach)
cat("\nTest 2: With useShinyjs as first argument (like in app.R)...\n")
tryCatch({
  page2 <- bs4DashPage(
    shinyjs::useShinyjs(),
    header = bs4DashNavbar(title = "Test"),
    sidebar = bs4DashSidebar(
      bs4SidebarMenu(bs4SidebarMenuItem(text = "T", tabName = "t"))
    ),
    body = bs4DashBody(bs4TabItems(bs4TabItem(tabName = "t")))
  )
  cat("✓ OK with useShinyjs as first arg\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

# Test 3: With useShinyjs inside body
cat("\nTest 3: With useShinyjs inside body...\n")
tryCatch({
  page3 <- bs4DashPage(
    header = bs4DashNavbar(title = "Test"),
    sidebar = bs4DashSidebar(
      bs4SidebarMenu(bs4SidebarMenuItem(text = "T", tabName = "t"))
    ),
    body = bs4DashBody(
      shinyjs::useShinyjs(),
      bs4TabItems(bs4TabItem(tabName = "t"))
    )
  )
  cat("✓ OK with useShinyjs in body\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

