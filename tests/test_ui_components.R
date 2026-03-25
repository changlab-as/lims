#!/usr/bin/env Rscript
# Minimal UI test to isolate the Invalid object type error

cat("Testing minimal UI components...\n")

library(shiny)
library(bs4Dash)

# Test 1: Basic Navbar
cat("Test 1: Basic navbar...\n")
tryCatch({
  navbar <- bs4DashNavbar(
    title = "Test",
    skin = "light",
    status = "info"
  )
  cat("✓ Navbar OK\n")
}, error = function(e) {
  cat("✗ Navbar error:", e$message, "\n")
})

# Test 2: Basic Sidebar
cat("Test 2: Sidebar with menu items...\n")
tryCatch({
  sidebar <- bs4DashSidebar(
    skin = "light",
    brand_color = "info",
    bs4SidebarMenu(
      id = "sidebar_menu",
      bs4SidebarMenuItem(text = "Tab1", tabName = "tab1"),
      bs4SidebarMenuItem(text = "Tab2", tabName = "tab2")
    )
  )
  cat("✓ Sidebar OK\n")
}, error = function(e) {
  cat("✗ Sidebar error:", e$message, "\n")
})

# Test 3: Basic body with fluidRow/column
cat("Test 3: Body with fluidRow and column...\n")
tryCatch({
  body <- bs4DashBody(
    fluidRow(
      column(width = 12, h2("Test"))
    )
  )
  cat("✓ Body OK\n")
}, error = function(e) {
  cat("✗ Body error:", e$message, "\n")
})

# Test 4: bs4TabItems
cat("Test 4: bs4TabItems with bs4TabItem...\n")
tryCatch({
  tabs <- bs4TabItems(
    bs4TabItem(
      tabName = "tab1",
      fluidRow(
        column(width = 12, h2("Tab 1"))
      )
    ),
    bs4TabItem(
      tabName = "tab2",
      fluidRow(
        column(width = 12, h2("Tab 2"))
      )
    )
  )
  cat("✓ TabItems OK\n")
}, error = function(e) {
  cat("✗ TabItems error:", e$message, "\n")
})

# Test 5: Full page
cat("Test 5: Full bs4DashPage...\n")
tryCatch({
  full_ui <- bs4DashPage(
    header = bs4DashNavbar(
      title = "Test",
      skin = "light",
      status = "info"
    ),
    sidebar = bs4DashSidebar(
      skin = "light",
      brand_color = "info",
      bs4SidebarMenu(
        id = "sidebar_menu",
        bs4SidebarMenuItem(text = "Tab1", tabName = "tab1")
      )
    ),
    body = bs4DashBody(
      bs4TabItems(
        bs4TabItem(
          tabName = "tab1",
          fluidRow(
            column(width = 12, h2("Tab 1"))
          )
        )
      )
    )
  )
  cat("✓ Full page OK\n")
}, error = function(e) {
  cat("✗ Full page error:", e$message, "\n")
  cat("  Details:", conditionMessage(e), "\n")
})

cat("\nAll component tests done.\n")
