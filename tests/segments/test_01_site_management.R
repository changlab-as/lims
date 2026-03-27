# Unit Tests for Site Management Segment
# Test business logic functions for the 01_site_management segment

library(testthat)
library(RSQLite)
library(DBI)

# Setup test database
setup_test_db <- function() {
  db_path <- tempfile(fileext = ".sqlite")
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Create Sites table
  dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  list(con = con, db_path = db_path)
}

teardown_test_db <- function(test_db) {
  dbDisconnect(test_db$con)
  unlink(test_db$db_path)
}

# ------ VALIDATION TESTS ------

test_that("validate_site_id accepts valid format ST0001-ST9999", {
  result <- validate_site_id("ST0001")
  expect_true(result$valid)
  expect_equal(result$value, "ST0001")
  
  result <- validate_site_id("ST9999")
  expect_true(result$valid)
  expect_equal(result$value, "ST9999")
})

test_that("validate_site_id rejects invalid formats", {
  # No leading zeros
  result <- validate_site_id("ST1")
  expect_false(result$valid)
  expect_match(result$error, "ST followed by 4 digits")
  
  # Wrong prefix
  result <- validate_site_id("SX0001")
  expect_false(result$valid)
  
  # Non-numeric
  result <- validate_site_id("STAAAA")
  expect_false(result$valid)
  
  # Empty
  result <- validate_site_id("")
  expect_false(result$valid)
  expect_match(result$error, "cannot be empty")
  
  # Whitespace only
  result <- validate_site_id("   ")
  expect_false(result$valid)
})

test_that("validate_site_id trims whitespace", {
  result <- validate_site_id("  ST0001  ")
  expect_true(result$valid)
  expect_equal(result$value, "ST0001")
})

test_that("validate_site_name accepts valid names", {
  result <- validate_site_name("North meadow plot")
  expect_true(result$valid)
  expect_equal(result$value, "North meadow plot")
  
  result <- validate_site_name("Test Site A")
  expect_true(result$valid)
})

test_that("validate_site_name rejects invalid names", {
  # Empty
  result <- validate_site_name("")
  expect_false(result$valid)
  expect_match(result$error, "cannot be empty")
  
  # Too long (>100 chars)
  long_name <- paste0(rep("A", 101), collapse = "")
  result <- validate_site_name(long_name)
  expect_false(result$valid)
  expect_match(result$error, "100 characters")
})

test_that("validate_site_name trims whitespace", {
  result <- validate_site_name("  My Site  ")
  expect_true(result$valid)
  expect_equal(result$value, "My Site")
})

# ------ DATABASE OPERATION TESTS ------

test_that("check_site_exists returns FALSE for non-existent site", {
  test_db <- setup_test_db()
  
  result <- check_site_exists("ST0001", test_db$con)
  expect_false(result)
  
  teardown_test_db(test_db)
})

test_that("check_site_exists returns TRUE for existing site", {
  test_db <- setup_test_db()
  
  # Insert a site
  dbExecute(test_db$con,
    "INSERT INTO Sites (site_id, site_name) VALUES (?, ?)",
    params = list("ST0001", "Test Site"))
  
  result <- check_site_exists("ST0001", test_db$con)
  expect_true(result)
  
  teardown_test_db(test_db)
})

test_that("create_site successfully creates a new site", {
  test_db <- setup_test_db()
  
  result <- create_site("ST0001", "Test Site", test_db$con)
  expect_true(result$success)
  expect_equal(result$site_id, "ST0001")
  expect_equal(result$site_name, "Test Site")
  
  # Verify in database
  sites <- dbGetQuery(test_db$con,
    "SELECT * FROM Sites WHERE site_id = ?",
    params = list("ST0001"))
  expect_equal(nrow(sites), 1)
  expect_equal(sites$site_name[1], "Test Site")
  
  teardown_test_db(test_db)
})

test_that("create_site rejects invalid site ID", {
  test_db <- setup_test_db()
  
  result <- create_site("INVALID", "Test Site", test_db$con)
  expect_false(result$success)
  expect_match(result$error, "ST followed by 4 digits")
  
  teardown_test_db(test_db)
})

test_that("create_site rejects empty site name", {
  test_db <- setup_test_db()
  
  result <- create_site("ST0001", "", test_db$con)
  expect_false(result$success)
  expect_match(result$error, "cannot be empty")
  
  teardown_test_db(test_db)
})

test_that("create_site rejects duplicate site ID", {
  test_db <- setup_test_db()
  
  # Create first site
  result1 <- create_site("ST0001", "Site One", test_db$con)
  expect_true(result1$success)
  
  # Attempt to create duplicate
  result2 <- create_site("ST0001", "Site Two", test_db$con)
  expect_false(result2$success)
  expect_match(result2$error, "already exists")
  
  teardown_test_db(test_db)
})

test_that("get_all_sites returns empty data frame for no sites", {
  test_db <- setup_test_db()
  
  result <- get_all_sites(test_db$con)
  expect_true(result$success)
  expect_equal(nrow(result$data), 0)
  
  teardown_test_db(test_db)
})

test_that("get_all_sites returns all sites with correct columns", {
  test_db <- setup_test_db()
  
  # Insert test sites
  dbExecute(test_db$con,
    "INSERT INTO Sites (site_id, site_name, site_lat, site_long) 
     VALUES (?, ?, ?, ?)",
    params = list("ST0001", "Site One", "40.7128", "-74.0060"))
  
  dbExecute(test_db$con,
    "INSERT INTO Sites (site_id, site_name, site_lat, site_long) 
     VALUES (?, ?, ?, ?)",
    params = list("ST0002", "Site Two", NULL, NULL))
  
  result <- get_all_sites(test_db$con)
  expect_true(result$success)
  expect_equal(nrow(result$data), 2)
  expect_contains(colnames(result$data), "Site ID")
  expect_contains(colnames(result$data), "Coordinates")
  
  # Verify coordinate status icons
  coords <- result$data$Coordinates
  expect_equal(coords[1], "✓ Added")      # Has coordinates
  expect_equal(coords[2], "⚠️ Missing")  # Missing coordinates
  
  teardown_test_db(test_db)
})

# ------ INTEGRATION TESTS ------

test_that("Full workflow: create multiple sites and retrieve", {
  test_db <- setup_test_db()
  
  # Create sites
  result1 <- create_site("ST0001", "Field A", test_db$con)
  result2 <- create_site("ST0002", "Field B", test_db$con)
  result3 <- create_site("ST0003", "Lab Site", test_db$con)
  
  expect_true(all(c(result1$success, result2$success, result3$success)))
  
  # Retrieve all sites
  result <- get_all_sites(test_db$con)
  expect_true(result$success)
  expect_equal(nrow(result$data), 3)
  
  teardown_test_db(test_db)
})

test_that("Site IDs are ordered correctly", {
  test_db <- setup_test_db()
  
  # Create in random order
  create_site("ST0003", "Third", test_db$con)
  create_site("ST0001", "First", test_db$con)
  create_site("ST0002", "Second", test_db$con)
  
  result <- get_all_sites(test_db$con)
  ids <- result$data$`Site ID`
  
  expect_equal(ids, c("ST0001", "ST0002", "ST0003"))
  
  teardown_test_db(test_db)
})
