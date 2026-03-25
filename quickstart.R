#!/usr/bin/env Rscript
# Riverside Rhizobia LIMS - Quick Start Guide
# This script walks you through the initial setup and provides menu options

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║     Riverside Rhizobia LIMS - Quick Start                     ║\n")
cat("║     Laboratory Information Management System                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Check dependencies
check_deps <- function() {
  required_pkgs <- c("shiny", "bs4Dash", "shinyjs", "DT", "RSQLite", "qrcode", 
                     "pool", "dplyr", "DBI", "gridExtra")
  
  cat("Checking dependencies...\n")
  missing <- c()
  
  for (pkg in required_pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing <- c(missing, pkg)
    }
  }
  
  if (length(missing) > 0) {
    cat("\n⚠️  Missing packages:", paste(missing, collapse = ", "), "\n")
    cat("Run the following to install:\n\n")
    cat('source("packages.R")\n\n')
    return(FALSE)
  } else {
    cat("✓ All dependencies installed!\n\n")
    return(TRUE)
  }
}

# Show menu
show_menu <- function() {
  cat("What would you like to do?\n\n")
  cat("1. Run the LIMS Shiny App\n")
  cat("2. Generate batch barcode labels\n")
  cat("3. View database statistics\n")
  cat("4. Reset database (clear all data)\n")
  cat("5. View setup guide\n")
  cat("6. View mobile scanning guide\n")
  cat("7. Exit\n\n")
  cat("Choose option (1-7): ")
}

# Run Shiny app
run_app <- function() {
  cat("\n🚀 Starting LIMS Shiny App...\n")
  cat("The app will open in your default browser at: http://localhost:3838\n")
  cat("Press Ctrl+C to stop the server.\n\n")
  
  if (!dir.exists("data")) dir.create("data")
  if (!dir.exists("www")) dir.create("www")
  
  library(shiny)
  shiny::runApp()
}

# View database stats
view_stats <- function() {
  if (!file.exists("data/lims_db.sqlite")) {
    cat("\n❌ Database not found. Create a site in the app first.\n\n")
    return()
  }
  
  library(RSQLite)
  library(DBI)
  
  con <- dbConnect(RSQLite::SQLite(), "data/lims_db.sqlite")
  
  sites <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Sites")
  plants <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Plants")
  processing <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Processing")
  
  cat("\n📊 Database Statistics\n")
  cat("═════════════════════════\n")
  cat("Sites:          ", sites$count[1], "\n")
  cat("Plants:         ", plants$count[1], "\n")
  cat("Processing:     ", processing$count[1], "\n")
  
  sites_detail <- dbGetQuery(con, "SELECT site_id, location_name FROM Sites")
  if (nrow(sites_detail) > 0) {
    cat("\nSites in database:\n")
    for (i in 1:nrow(sites_detail)) {
      cat(sprintf("  • %s - %s\n", sites_detail$site_id[i], sites_detail$location_name[i]))
    }
  }
  
  dbDisconnect(con)
  cat("\n")
}

# Reset database
reset_db <- function() {
  cat("\n⚠️  WARNING: This will delete all data!\n\n")
  cat("Type 'YES' to confirm database reset: ")
  confirm <- readline()
  
  if (confirm != "YES") {
    cat("Cancelled.\n\n")
    return()
  }
  
  if (file.exists("data/lims_db.sqlite")) {
    file.remove("data/lims_db.sqlite")
    cat("✓ Database deleted. A fresh database will be created when you run the app.\n\n")
  } else {
    cat("Database not found.\n\n")
  }
}

# View guides
view_setup_guide <- function() {
  if (file.exists("SETUP.md")) {
    content <- readLines("SETUP.md")
    cat(paste(content, collapse = "\n"))
    cat("\n")
  } else {
    cat("SETUP.md not found.\n\n")
  }
}

view_mobile_guide <- function() {
  if (file.exists("MOBILE_SCANNING_GUIDE.md")) {
    content <- readLines("MOBILE_SCANNING_GUIDE.md")
    cat(paste(content, collapse = "\n"))
    cat("\n")
  } else {
    cat("MOBILE_SCANNING_GUIDE.md not found.\n\n")
  }
}

# Generate labels
generate_labels <- function() {
  source("generate_barcode_labels.R", local = TRUE)
}

# Main loop
if (!check_deps()) {
  cat("\nExiting due to missing dependencies.\n")
  quit(status = 1)
}

repeat {
  show_menu()
  choice <- readline()
  
  switch(choice,
    "1" = run_app(),
    "2" = generate_labels(),
    "3" = view_stats(),
    "4" = reset_db(),
    "5" = view_setup_guide(),
    "6" = view_mobile_guide(),
    "7" = {
      cat("\nGoodbye! 👋\n\n")
      quit(status = 0)
    },
    {
      cat("\n❌ Invalid option. Try again.\n\n")
    }
  )
}
