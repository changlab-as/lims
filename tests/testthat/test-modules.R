library(testthat)
library(shiny)
library(pool)
library(DBI)
library(RSQLite)

# Module integration tests using testServer()

create_test_pool <- function() {
  pool::dbPool(
    drv = RSQLite::SQLite(),
    dbname = ":memory:",
    minSize = 1,
    maxSize = 5
  )
}

setup_test_pool <- function(pool) {
  con <- pool::poolCheckout(pool)
  on.exit(pool::poolReturn(con))
  
  # Create schema
  DBI::dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  DBI::dbExecute(con, "
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
  
  DBI::dbExecute(con, "
    CREATE TABLE BatchScans (
      scan_id       TEXT PRIMARY KEY,
      site_id       TEXT,
      sample_id     TEXT,
      scan_time     DATETIME DEFAULT CURRENT_TIMESTAMP,
      scanner_id    TEXT,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
}

test_that("mod_inventory_server creates a site", {
  skip_if_not_installed("shiny")
  
  test_pool <- create_test_pool()
  setup_test_pool(test_pool)
  
  shiny::testServer(mod_inventory_server, args = list(pool = test_pool), {
    
    # Set inputs
    session$setInputs(site_id = "ST0001", site_name = "Test Site")
    session$setInputs(create_btn = 1)
    
    # Verify site was created
    con <- pool::poolCheckout(test_pool)
    on.exit(pool::poolReturn(con))
    
    result <- DBI::dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'ST0001'")
    expect_equal(nrow(result), 1)
  })
  
  pool::poolClose(test_pool)
})

test_that("mod_inventory_server validates Site ID format", {
  skip_if_not_installed("shiny")
  
  test_pool <- create_test_pool()
  setup_test_pool(test_pool)
  
  shiny::testServer(mod_inventory_server, args = list(pool = test_pool), {
    
    # Try invalid Site ID
    session$setInputs(site_id = "INVALID", site_name = "Test Site")
    session$setInputs(create_btn = 1)
    
    # Verify site was NOT created
    con <- pool::poolCheckout(test_pool)
    on.exit(pool::poolReturn(con))
    
    result <- DBI::dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'INVALID'")
    expect_equal(nrow(result), 0)
  })
  
  pool::poolClose(test_pool)
})

test_that("mod_labels_server generates a label", {
  skip_if_not_installed("shiny")
  
  test_pool <- create_test_pool()
  setup_test_pool(test_pool)
  
  # Create a site first
  con <- pool::poolCheckout(test_pool)
  insert_site("ST0001", "Test Site", con = con)
  pool::poolReturn(con)
  
  shiny::testServer(mod_labels_server, args = list(pool = test_pool), {
    
    # Wait for site choices to update
    shiny::waitFor(!is.null(input$site_id))
    
    # Set inputs
    session$setInputs(site_id = "ST0001")
    session$setInputs(sample_id = "SAMPLE001")
    session$setInputs(sample_type = "plant_tissue")
    session$setInputs(generate_btn = 1)
    
    # Verify label was created
    con <- pool::poolCheckout(test_pool)
    on.exit(pool::poolReturn(con))
    
    labels <- DBI::dbGetQuery(con, "SELECT * FROM Labels")
    expect_equal(nrow(labels), 1)
    expect_equal(labels$sample_id[1], "SAMPLE001")
  })
  
  pool::poolClose(test_pool)
})

test_that("mod_batch_scan_server records a scan", {
  skip_if_not_installed("shiny")
  
  test_pool <- create_test_pool()
  setup_test_pool(test_pool)
  
  # Create a site first
  con <- pool::poolCheckout(test_pool)
  insert_site("ST0001", "Test Site", con = con)
  pool::poolReturn(con)
  
  shiny::testServer(mod_batch_scan_server, args = list(pool = test_pool), {
    
    # Wait for site choices to update
    shiny::waitFor(!is.null(input$site_id))
    
    # Set inputs
    session$setInputs(site_id = "ST0001")
    session$setInputs(scanner_input = "SAMPLE001")
    session$setInputs(quick_scan_btn = 1)
    
    # Verify scan was recorded
    con <- pool::poolCheckout(test_pool)
    on.exit(pool::poolReturn(con))
    
    scans <- DBI::dbGetQuery(con, "SELECT * FROM BatchScans")
    expect_equal(nrow(scans), 1)
  })
  
  pool::poolClose(test_pool)
})

test_that("Modules handle empty database gracefully", {
  skip_if_not_installed("shiny")
  
  test_pool <- create_test_pool()
  setup_test_pool(test_pool)
  
  # Test labels module with no sites
  shiny::testServer(mod_labels_server, args = list(pool = test_pool), {
    # Should not crash when opening with no sites
    expect_equal(length(input$site_id), 1)
  })
  
  # Test batch scan module with no sites
  shiny::testServer(mod_batch_scan_server, args = list(pool = test_pool), {
    # Should not crash when opening with no sites
    expect_equal(length(input$site_id), 1)
  })
  
  pool::poolClose(test_pool)
})
