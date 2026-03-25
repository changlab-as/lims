#!/usr/bin/env Rscript
# Minimal UI test for LIMS app

cat("\n=== Testing Minimal LIMS UI ===\n\n")

library(shiny)
library(bs4Dash)
library(shinyjs)

# Try to build just the sidebar
cat("Building sidebar menu...\n")

tryCatch({
  sidebar_test <- bs4DashSidebar(
    skin = "light",
    brand_color = "info",
    bs4SidebarMenu(
      id = "sidebar_menu",
      bs4SidebarMenuItem(
        text = "Field Entry",
        tabName = "field_entry"
      )
    )
  )
  cat("✓ Sidebar built successfully\n")
}, error = function(e) {
  cat("✗ Sidebar error:", e$message, "\n")
})

# Try to build the full UI
cat("\nBuilding full UI...\n")

tryCatch({
  ui_test <- bs4DashPage(
    shinyjs::useShinyjs(),
    header = bs4DashNavbar(
      title = "Riverside Rhizobia LIMS",
      skin = "light",
      status = "info"
    ),
    sidebar = bs4DashSidebar(
      skin = "light",
      brand_color = "info",
      bs4SidebarMenu(
        id = "sidebar_menu",
        bs4SidebarMenuItem(
          text = "Field Entry",
          tabName = "field_entry"
        )
      )
    ),
    body = bs4DashBody(
      h2("Test")
    )
  )
  cat("✓ UI built successfully\n")
}, error = function(e) {
  cat("✗ UI error:", e$message, "\n")
})

cat("\n✓ Tests complete\n\n")
