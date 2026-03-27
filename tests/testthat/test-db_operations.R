library(testthat)
library(DBI)
library(RSQLite)

# Database operation tests using in-memory SQLite database

setup_test_db <- function() {
  con <- dbConnect(RSQLite::SQLite(), ":memory:")
  
  # Create Sites table
  dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Create Labels table
  dbExecute(con, "
    CREATE TABLE Labels (
      label_id      TEXT PRIMARY KEY,
      stage         INTEGER,
      site_id       TEXT,
      sample_type   TEXT,
      sample_id     TEXT,
      sample_status TEXT DEFAULT 'label_created',
      created_date  DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  # Create BatchScans table
  dbExecute(con, "
    CREATE TABLE BatchScans (
      scan_id       TEXT PRIMARY KEY,
      site_id       TEXT,
      sample_id     TEXT,
      scan_time     DATETIME DEFAULT CURRENT_TIMESTAMP,
      scanner_id    TEXT,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  return(con)
}

test_that("insert_site adds new site to database", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  
  result <- dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'ST0001'")
  expect_equal(nrow(result), 1)
  expect_equal(result$site_name, "Test Site")
  
  dbDisconnect(con)
})

test_that("check_site_exists returns TRUE for existing site", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  
  exists <- check_site_exists("ST0001", con)
  expect_true(exists)
  
  dbDisconnect(con)
})

test_that("check_site_exists returns FALSE for non-existing site", {
  con <- setup_test_db()
  
  exists <- check_site_exists("ST9999", con)
  expect_false(exists)
  
  dbDisconnect(con)
})

test_that("fetch_all_sites retrieves all sites from database", {
  con <- setup_test_db()
  
  # Insert multiple sites
  insert_site("ST0001", "Site A", con = con)
  insert_site("ST0002", "Site B", con = con)
  insert_site("ST0003", "Site C", con = con)
  
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 3)
  expect_true("ST0001" %in% result$site_id)
  expect_true("ST0002" %in% result$site_id)
  expect_true("ST0003" %in% result$site_id)
  
  dbDisconnect(con)
})

test_that("fetch_all_sites returns empty dataframe when no sites exist", {
  con <- setup_test_db()
  
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 0)
  
  dbDisconnect(con)
})

test_that("fetch_site_by_id retrieves specific site", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  
  result <- fetch_site_by_id("ST0001", con)
  expect_equal(nrow(result), 1)
  expect_equal(result$site_name, "Test Site")
  
  dbDisconnect(con)
})

test_that("insert_label adds new label to database", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  insert_label("LBL001", 1, "ST0001", "plant_tissue", "SAMPLE001", con = con)
  
  result <- dbGetQuery(con, "SELECT * FROM Labels WHERE label_id = 'LBL001'")
  expect_equal(nrow(result), 1)
  expect_equal(result$site_id, "ST0001")
  expect_equal(result$sample_id, "SAMPLE001")
  
  dbDisconnect(con)
})

test_that("fetch_all_labels retrieves all labels from database", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  insert_label("LBL001", 1, "ST0001", "plant_tissue", "SAMPLE001", con = con)
  insert_label("LBL002", 1, "ST0001", "seed", "SAMPLE002", con = con)
  
  result <- fetch_all_labels(con)
  expect_equal(nrow(result), 2)
  expect_true("LBL001" %in% result$label_id)
  expect_true("LBL002" %in% result$label_id)
  
  dbDisconnect(con)
})

test_that("insert_batch_scan adds new scan to database", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  insert_batch_scan("SCAN001", "ST0001", "SAMPLE001", "scanner_1", con = con)
  
  result <- dbGetQuery(con, "SELECT * FROM BatchScans WHERE scan_id = 'SCAN001'")
  expect_equal(nrow(result), 1)
  expect_equal(result$site_id, "ST0001")
  
  dbDisconnect(con)
})

test_that("fetch_all_batch_scans retrieves scans with site names", {
  con <- setup_test_db()
  
  insert_site("ST0001", "Test Site", con = con)
  insert_batch_scan("SCAN001", "ST0001", "SAMPLE001", "scanner_1", con = con)
  insert_batch_scan("SCAN002", "ST0001", "SAMPLE002", "scanner_1", con = con)
  
  result <- fetch_all_batch_scans(con)
  expect_equal(nrow(result), 2)
  expect_true("Test Site" %in% result$site_name)
  
  dbDisconnect(con)
})

test_that("Multiple database operations maintain data integrity", {
  con <- setup_test_db()
  
  # Create 3 sites
  for (i in 1:3) {
    site_id <- sprintf("ST%04d", i)
    insert_site(site_id, paste("Site", i), con = con)
  }
  
  # Create 2 labels per site
  for (i in 1:3) {
    site_id <- sprintf("ST%04d", i)
    for (j in 1:2) {
      label_id <- paste0(site_id, "_LBL", j)
      insert_label(label_id, 1, site_id, "plant_tissue", paste0("SAMPLE", j), con = con)
    }
  }
  
  # Verify counts
  sites <- fetch_all_sites(con)
  labels <- fetch_all_labels(con)
  
  expect_equal(nrow(sites), 3)
  expect_equal(nrow(labels), 6)
  
  dbDisconnect(con)
})
