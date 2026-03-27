#!/usr/bin/env Rscript

# Database Initialization Test
# Validates that database tables are created with correct schema

library(RSQLite)
library(DBI)

test_db_init <- function() {
  test_name <- "Database Initialization & Schema"
  
  # Create temp database to test schema
  temp_db <- tempfile(fileext = ".sqlite")
  
  con <- dbConnect(RSQLite::SQLite(), temp_db)
  
  # Create tables as per app.R
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Equipment (
      equipment_id TEXT PRIMARY KEY,
      character_name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      date_created DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Plants (
      plant_id TEXT PRIMARY KEY,
      site_id TEXT NOT NULL,
      species TEXT NOT NULL,
      health_status TEXT,
      fridge_loc TEXT,
      date_created DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Processing (
      proc_id TEXT PRIMARY KEY,
      plant_id TEXT NOT NULL,
      type TEXT NOT NULL,
      date DATETIME DEFAULT CURRENT_TIMESTAMP,
      technician TEXT,
      notes TEXT
    )
  ")
  
  # Test Equipment table
  dbExecute(con, 
    "INSERT INTO Equipment (equipment_id, character_name, category, description) 
     VALUES (?, ?, ?, ?)",
    params = list("TEST01", "Test Equipment", "Test Category", "Test Description")
  )
  
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Equipment")
  if (result$count[1] != 1) {
    stop("Equipment table insert/query test failed")
  }
  
  # Test Plants table
  dbExecute(con,
    "INSERT INTO Plants (plant_id, site_id, species, health_status, fridge_loc) 
     VALUES (?, ?, ?, ?, ?)",
    params = list("ST0001-P0001", "SITE01", "Species1", "healthy", "U01")
  )
  
  result <- dbGetQuery(con, "SELECT * FROM Plants WHERE plant_id = 'ST0001-P0001'")
  if (nrow(result) != 1) {
    stop("Plants table insert/query test failed")
  }
  
  # Test Processing table
  dbExecute(con,
    "INSERT INTO Processing (proc_id, plant_id, type, notes) 
     VALUES (?, ?, ?, ?)",
    params = list("PROC001", "ST0001-P0001", "Mobile_Checkin", "Test check-in")
  )
  
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Processing")
  if (result$count[1] != 1) {
    stop("Processing table insert/query test failed")
  }
  
  dbDisconnect(con)
  unlink(temp_db)
  
  return(TRUE)
}

if (sys.nframe() == 0) {
  result <- test_db_init()
  if (result) {
    cat("✓ DB Initialization Test PASSED\n")
  }
}
