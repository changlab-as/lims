create_test_pool <- function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  
  # Create schema
  DBI::dbExecute(con, "
    CREATE TABLE sites (
      site_id TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  DBI::dbExecute(con, "
    CREATE TABLE labels (
      label_id TEXT PRIMARY KEY,
      site_id TEXT NOT NULL,
      sample_id TEXT NOT NULL,
      qr_code_path TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES sites(site_id)
    )
  ")
  
  DBI::dbExecute(con, "
    CREATE TABLE batch_scans (
      scan_id INTEGER PRIMARY KEY AUTOINCREMENT,
      site_id TEXT NOT NULL,
      scanner_input TEXT,
      scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES sites(site_id)
    )
  ")
  
  # Create a pool-like object that returns the connection
  pool <- list(
    checkout = function() con,
    return = function(c) {}
  )
  
  con
}

test_that("mod_inventory_server creates site", {
  con <- create_test_pool()
  
  # Mock pool object
  mock_pool <- list()
  mock_pool$checkout <- function() con
  mock_pool$return <- function(c) {}
  
  # Test module logic
  insert_site(con, "ST0001", "Test Site")
  expect_true(check_site_exists(con, "ST0001"))
})

test_that("mod_labels_server generates label", {
  con <- create_test_pool()
  
  insert_site(con, "ST0001", "Test Site")
  insert_label(con, "LBL001", "ST0001", "SAMPLE001", "data:image/png;base64,...")
  
  labels <- fetch_all_labels(con)
  expect_equal(nrow(labels), 1)
})

test_that("mod_batch_scan_server records scan", {
  con <- create_test_pool()
  
  insert_site(con, "ST0001", "Test Site")
  insert_batch_scan(con, "ST0001", "SCAN_DATA")
  
  scans <- fetch_all_batch_scans(con)
  expect_equal(nrow(scans), 1)
})

test_that("All modules handle empty database gracefully", {
  con <- create_test_pool()
  
  # Fetch from empty tables should not error
  sites <- fetch_all_sites(con)
  labels <- fetch_all_labels(con)
  scans <- fetch_all_batch_scans(con)
  
  expect_equal(nrow(sites), 0)
  expect_equal(nrow(labels), 0)
  expect_equal(nrow(scans), 0)
})
