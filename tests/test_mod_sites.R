library(testthat)
library(shiny)
library(DBI)
library(RSQLite)

# Source the modules and utilities
source("R/mod_sites.R")
source("R/utils_db.R")

# ── Validation Tests ─────────────────────────────────────────────────────────

test_that("sitesUI returns a Shiny UI element", {
  ui <- sitesUI("test_id")
  expect_s3_class(ui, "shiny.tag")
})

test_that("sitesUI contains all required input elements", {
  ui <- sitesUI("test_id")
  ui_str <- toString(ui)
  
  # Check for required elements
  expect_true(grepl("site_id", ui_str))
  expect_true(grepl("site_name", ui_str))
  expect_true(grepl("create_btn", ui_str))
})

test_that("sitesUI uses correct namespacing with NS()", {
  ui <- sitesUI("myid")
  ui_str <- toString(ui)
  
  # Should contain namespaced IDs
  expect_true(grepl("myid-site_id", ui_str) || grepl("myid_site_id", ui_str))
})

# ── Site ID Validation Tests ──────────────────────────────────────────────

test_that("Valid site IDs match format ST followed by 4 digits", {
  valid_ids <- c("ST0001", "ST9999", "ST5555", "ST0000")
  pattern <- "^ST\\d{4}$"
  
  for (id in valid_ids) {
    expect_true(grepl(pattern, id), 
                label = paste("Site ID", id, "should be valid"))
  }
})

test_that("Invalid site IDs are rejected", {
  invalid_ids <- c(
    "ST001",      # Too few digits
    "ST00001",    # Too many digits
    "ST000A",     # Contains letter
    "ST-0001",    # Contains dash
    "st0001",     # Lowercase
    "0001",       # No prefix
    "",           # Empty
    "ST"          # Incomplete
  )
  pattern <- "^ST\\d{4}$"
  
  for (id in invalid_ids) {
    expect_false(grepl(pattern, id), 
                 label = paste("Site ID", id, "should be invalid"))
  }
})

test_that("Input trimming removes whitespace", {
  expect_equal(trimws("  ST0001  "), "ST0001")
  expect_equal(trimws("  Site Name  "), "Site Name")
  expect_equal(trimws(""), "")
})

# ── Database Function Tests ────────────────────────────────────────────────

test_that("initialize_database creates database file", {
  # Use temporary directory for testing
  test_db <- "data/test_lims_db.sqlite"
  
  # Create new database
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Test Sites table creation
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Verify table exists
  tables <- dbListTables(con)
  expect_true("Sites" %in% tables)
  
  dbDisconnect(con)
  
  # Cleanup
  if (file.exists(test_db)) unlink(test_db)
})

test_that("insert_site adds site to database", {
  test_db <- "data/test_sites_insert.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Insert a site
  insert_site("ST0001", "Test Site", con = con)
  
  # Verify it was inserted
  result <- dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'ST0001'")
  expect_equal(nrow(result), 1)
  expect_equal(result$site_name, "Test Site")
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

test_that("check_site_exists returns TRUE for existing site", {
  test_db <- "data/test_site_exists_true.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Insert a site
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Check if it exists
  exists <- check_site_exists("ST0001", con)
  expect_true(exists)
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

test_that("check_site_exists returns FALSE for non-existing site", {
  test_db <- "data/test_site_exists_false.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Check non-existing site
  exists <- check_site_exists("ST9999", con)
  expect_false(exists)
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

test_that("fetch_all_sites returns all sites from database", {
  test_db <- "data/test_fetch_all_sites.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Insert multiple sites
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Site A')")
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0002', 'Site B')")
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0003', 'Site C')")
  
  # Fetch all
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 3)
  expect_true("ST0001" %in% result$site_id)
  expect_true("ST0002" %in% result$site_id)
  expect_true("ST0003" %in% result$site_id)
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

test_that("fetch_all_sites returns empty dataframe when no sites exist", {
  test_db <- "data/test_fetch_empty.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Fetch from empty table
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 0)
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

# ── Helper Function Tests ────────────────────────────────────────────────

test_that("generate_site_id creates properly formatted ID", {
  site_id <- generate_site_id()
  expect_match(site_id, "^ST\\d{4}$")
  expect_length(site_id, 1)
})

test_that("generate_plant_id creates properly formatted ID", {
  plant_id <- generate_plant_id("ST0001")
  expect_match(plant_id, "^P\\d{4}$")
  expect_length(plant_id, 1)
})

test_that("generate_proc_id creates properly formatted ID", {
  proc_id <- generate_proc_id()
  expect_match(proc_id, "^PR\\d{4}$")
  expect_length(proc_id, 1)
})

# ── Integration Tests ────────────────────────────────────────────────────

test_that("End-to-end: Create site and verify retrieval", {
  test_db <- "data/test_integration.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Create a site
  insert_site("ST0001", "Integration Test Site", con = con)
  
  # Verify it exists
  expect_true(check_site_exists("ST0001", con))
  
  # Fetch it
  sites <- fetch_all_sites(con)
  expect_equal(nrow(sites), 1)
  expect_equal(sites$site_id[1], "ST0001")
  expect_equal(sites$site_name[1], "Integration Test Site")
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})

test_that("Multiple sites can be created and retrieved", {
  test_db <- "data/test_multiple_sites.sqlite"
  
  con <- dbConnect(RSQLite::SQLite(), test_db)
  
  # Create schema
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Create multiple sites
  for (i in 1:5) {
    site_id <- sprintf("ST%04d", i)
    insert_site(site_id, paste("Site", i), con = con)
  }
  
  # Verify all exist
  sites <- fetch_all_sites(con)
  expect_equal(nrow(sites), 5)
  
  for (i in 1:5) {
    site_id <- sprintf("ST%04d", i)
    expect_true(check_site_exists(site_id, con))
  }
  
  dbDisconnect(con)
  if (file.exists(test_db)) unlink(test_db)
})
