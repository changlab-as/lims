setup_test_db <- function() {
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
  
  con
}

test_that("insert_site adds site record", {
  con <- setup_test_db()
  on.exit(DBI::dbDisconnect(con))
  
  insert_site(con, "ST0001", "Test Site")
  
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 1)
  expect_equal(result$site_id[1], "ST0001")
})

test_that("check_site_exists returns correct value", {
  con <- setup_test_db()
  on.exit(DBI::dbDisconnect(con))
  
  insert_site(con, "ST0001", "Test Site")
  
  expect_true(check_site_exists(con, "ST0001"))
  expect_false(check_site_exists(con, "ST0002"))
})

test_that("fetch_all_sites retrieves all records", {
  con <- setup_test_db()
  on.exit(DBI::dbDisconnect(con))
  
  insert_site(con, "ST0001", "Site 1")
  insert_site(con, "ST0002", "Site 2")
  
  result <- fetch_all_sites(con)
  expect_equal(nrow(result), 2)
})

test_that("insert_label creates label record", {
  con <- setup_test_db()
  on.exit(DBI::dbDisconnect(con))
  
  insert_site(con, "ST0001", "Test Site")
  insert_label(con, "LBL001", "ST0001", "SAMPLE001", "/path/to/qr.png")
  
  result <- fetch_all_labels(con)
  expect_equal(nrow(result), 1)
})

test_that("insert_batch_scan records scan", {
  con <- setup_test_db()
  on.exit(DBI::dbDisconnect(con))
  
  insert_site(con, "ST0001", "Test Site")
  insert_batch_scan(con, "ST0001", "SCANNED_DATA")
  
  result <- fetch_all_batch_scans(con)
  expect_equal(nrow(result), 1)
  expect_equal(result$scanner_input[1], "SCANNED_DATA")
})
