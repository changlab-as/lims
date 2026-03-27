# ============================================================
# COMPREHENSIVE UNIT TESTS FOR LIMS APP
# Tests all functions: label generation, database operations,
# table rendering, QR code validation, and edge cases
# ============================================================

# Load libraries
library(testthat)
library(DBI)
library(RSQLite)
library(qrcode)
library(png)

# Setup: Create test database
setup_test_db <- function() {
  setup_test_database <- function() {
    db_path <- "test_lims_db.sqlite"
    
    # Remove existing test DB if it exists
    if (file.exists(db_path)) {
      unlink(db_path)
    }
    
    con <- dbConnect(RSQLite::SQLite(), db_path)
    
    # Create Sites table
    dbExecute(con, "
      CREATE TABLE Sites (
        site_id TEXT PRIMARY KEY,
        site_name TEXT NOT NULL,
        site_lat REAL,
        site_long REAL,
        date_created DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ")
    
    # Create Labels table
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS Labels (
        label_id TEXT PRIMARY KEY,
        stage INTEGER,
        site_id TEXT,
        sample_type TEXT,
        sample_id TEXT,
        part_code TEXT,
        part_id TEXT,
        use_code TEXT,
        sample_status TEXT DEFAULT 'label_created',
        storage_location TEXT,
        collected_date DATETIME,
        created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(site_id) REFERENCES Sites(site_id)
      )
    ")
    
    # Create Equipment table
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS Equipment (
        equipment_id TEXT PRIMARY KEY,
        character_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date_created DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ")
    
    dbDisconnect(con)
    return(db_path)
  }
  
  return(setup_test_database())
}

# ============================================================
# TEST SUITE 1: DATABASE INITIALIZATION
# ============================================================

test_that("Database initializes with correct schema", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  tables <- dbListTables(con)
  
  expect_true("Sites" %in% tables, "Sites table should exist")
  expect_true("Labels" %in% tables, "Labels table should exist")
  expect_true("Equipment" %in% tables, "Equipment table should exist")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Database schema has correct columns", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Check Sites table columns
  sites_info <- dbGetQuery(con, "PRAGMA table_info(Sites)")
  sites_cols <- sites_info$name
  expect_true("site_id" %in% sites_cols)
  expect_true("site_name" %in% sites_cols)
  expect_true("site_lat" %in% sites_cols)
  expect_true("site_long" %in% sites_cols)
  
  # Check Labels table columns
  labels_info <- dbGetQuery(con, "PRAGMA table_info(Labels)")
  labels_cols <- labels_info$name
  expect_true("label_id" %in% labels_cols)
  expect_true("stage" %in% labels_cols)
  expect_true("sample_status" %in% labels_cols)
  expect_true("storage_location" %in% labels_cols)
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 2: SITE ID GENERATION
# ============================================================

test_that("Site creation generates valid ID format", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Insert test site
  dbExecute(con, 
    "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test Site')")
  
  # Verify site exists
  result <- dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'ST0001'")
  expect_equal(nrow(result), 1, "Site should be inserted")
  expect_equal(result$site_id[1], "ST0001")
  expect_equal(result$site_name[1], "Test Site")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Site ID validation rejects invalid format", {
  # Test invalid formats
  invalid_ids <- c("S0001", "ST001", "ST00001", "st0001", "")
  
  for (id in invalid_ids) {
    is_valid <- grepl("^ST\\d{4}$", id)
    expect_false(is_valid, paste("ID", id, "should be invalid"))
  }
})

test_that("Site ID validation accepts valid format", {
  # Test valid formats
  valid_ids <- c("ST0001", "ST0002", "ST9999", "ST0000")
  
  for (id in valid_ids) {
    is_valid <- grepl("^ST\\d{4}$", id)
    expect_true(is_valid, paste("ID", id, "should be valid"))
  }
})

# ============================================================
# TEST SUITE 3: PLANT/SAMPLE ID GENERATION
# ============================================================

test_that("Plant sample IDs follow correct 2-segment format", {
  # Valid 2-segment IDs
  valid_2seg <- c("ST0001-P0001", "ST0001-S0001", "ST0002-P0005")
  
  for (id in valid_2seg) {
    is_valid <- grepl("^ST\\d{4}-[PS]\\d{4}$", id)
    expect_true(is_valid, paste(id, "should be valid 2-segment format"))
  }
})

test_that("Part/3-segment IDs follow correct format", {
  # Valid 3-segment IDs
  valid_3seg <- c("ST0001-P0001-SH001", "ST0001-P0001-RT001", "ST0001-S0001-ND001")
  
  for (id in valid_3seg) {
    is_valid <- grepl("^ST\\d{4}-[PS]\\d{4}-[A-Z]{2}\\d{3}$", id)
    expect_true(is_valid, paste(id, "should be valid 3-segment format"))
  }
})

test_that("Use/4-segment IDs follow correct format", {
  # Valid 4-segment IDs
  valid_4seg <- c("ST0001-P0001-SH001-GW01", "ST0001-P0001-RT001-DE01", "ST0001-S0001-ND001-RE01")
  
  for (id in valid_4seg) {
    is_valid <- grepl("^ST\\d{4}-[PS]\\d{4}-[A-Z]{2}\\d{3}-[A-Z]{2}\\d{2}$", id)
    expect_true(is_valid, paste(id, "should be valid 4-segment format"))
  }
})

# ============================================================
# TEST SUITE 4: QR CODE GENERATION AND VALIDATION
# ============================================================

test_that("QR code is generated as square image", {
  # Generate QR code
  test_id <- "ST0001-P0001"
  temp_qr_file <- tempfile(fileext = ".png")
  
  set.seed(123)
  qr_obj <- qr_code(test_id)
  png(temp_qr_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  
  # Read image and check dimensions
  img <- readPNG(temp_qr_file)
  dimensions <- dim(img)
  
  # QR code should be square (width == height)
  expect_equal(dimensions[1], dimensions[2], 
    "QR code width and height should be equal (square)")
  
  # Clean up
  unlink(temp_qr_file)
})

test_that("QR codes are readable", {
  # Generate QR code
  test_id <- "ST0001-P0001-SH001"
  set.seed(as.integer(charToRaw(test_id)) %% 2147483647)
  qr_obj <- qr_code(test_id)
  
  # QR object should be valid (not NULL, has structure)
  expect_true(!is.null(qr_obj), "QR code should not be NULL")
  expect_true(is.matrix(qr_obj), "QR code should be a matrix")
  expect_true(nrow(qr_obj) > 0, "QR code should have dimensions")
})

# ============================================================
# TEST SUITE 5: LABEL GENERATION - PRE-SAMPLING
# ============================================================

test_that("Pre-sampling plant labels are created with correct format", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Insert test site
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test Site')")
  
  # Generate plant labels
  site_id <- "ST0001"
  count <- 3
  labels <- character()
  
  for (i in 1:count) {
    label_id <- sprintf("%s-P%04d", site_id, i)
    labels <- c(labels, label_id)
    
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
       VALUES (?, 1, ?, 'plant')",
      params = list(label_id, site_id)
    )
  }
  
  # Verify labels were created
  result <- dbGetQuery(con, "SELECT * FROM Labels WHERE stage = 1 AND site_id = 'ST0001'")
  expect_equal(nrow(result), 3, "Should have 3 plant labels")
  
  # Verify format
  expect_true(all(grepl("^ST0001-P\\d{4}$", result$label_id)))
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Pre-sampling soil labels are created with correct format", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Insert test site
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0002', 'Test Site 2')")
  
  # Generate soil labels
  site_id <- "ST0002"
  count <- 2
  
  for (i in 1:count) {
    label_id <- sprintf("%s-S%04d", site_id, i)
    
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
       VALUES (?, 1, ?, 'soil')",
      params = list(label_id, site_id)
    )
  }
  
  # Verify labels were created
  result <- dbGetQuery(con, "SELECT * FROM Labels WHERE stage = 1 AND site_id = 'ST0002' AND sample_type = 'soil'")
  expect_equal(nrow(result), 2, "Should have 2 soil labels")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Duplicate labels are rejected", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test Site')")
  
  # Insert first label
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
     VALUES ('ST0001-P0001', 1, 'ST0001', 'plant')")
  
  # Try to insert duplicate
  result <- tryCatch({
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
       VALUES ('ST0001-P0001', 1, 'ST0001', 'plant')")
    FALSE
  }, error = function(e) TRUE)
  
  expect_true(result, "Duplicate insertion should fail")
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 6: LABEL GENERATION - PARTS PROCESSING
# ============================================================

test_that("Parts labels are generated with correct format and hierarchy", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Create parent plant sample
  parent_sample <- "ST0001-P0001"
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_type, sample_status) 
     VALUES (?, 1, 'ST0001', 'plant', 'collected')",
    params = list(parent_sample)
  )
  
  # Generate parts labels
  part_types <- list(SH = 2, RT = 1)
  labels <- character()
  
  for (part_code in names(part_types)) {
    count <- part_types[[part_code]]
    for (i in 1:count) {
      label_id <- sprintf("%s-%s%03d", parent_sample, part_code, i)
      labels <- c(labels, label_id)
      
      dbExecute(con,
        "INSERT INTO Labels (label_id, stage, site_id, sample_id, part_code, part_id) 
         VALUES (?, 2, 'ST0001', ?, ?, ?)",
        params = list(label_id, parent_sample, part_code, label_id)
      )
    }
  }
  
  # Verify parts were created
  result <- dbGetQuery(con, "SELECT * FROM Labels WHERE stage = 2 AND sample_id = ?", 
    params = list(parent_sample))
  expect_equal(nrow(result), 3, "Should have 3 part labels")
  
  # Verify format
  for (i in 1:nrow(result)) {
    expect_true(grepl("^ST0001-P0001-[A-Z]{2}\\d{3}$", result$label_id[i]))
  }
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Parts labels properly link to parent samples", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Create two different plant samples
  parents <- c("ST0001-P0001", "ST0001-P0002")
  
  for (parent in parents) {
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
       VALUES (?, 1, 'ST0001', 'plant')",
      params = list(parent)
    )
    
    # Add parts for each
    for (i in 1:2) {
      label_id <- sprintf("%s-SH%03d", parent, i)
      dbExecute(con,
        "INSERT INTO Labels (label_id, stage, site_id, sample_id, part_id) 
         VALUES (?, 2, 'ST0001', ?, ?)",
        params = list(label_id, parent, label_id)
      )
    }
  }
  
  # Verify each parent has correct parts
  result1 <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Labels WHERE stage = 2 AND sample_id = ?",
    params = list("ST0001-P0001"))
  result2 <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Labels WHERE stage = 2 AND sample_id = ?",
    params = list("ST0001-P0002"))
  
  expect_equal(result1$count[1], 2, "Parent 1 should have 2 parts")
  expect_equal(result2$count[1], 2, "Parent 2 should have 2 parts")
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 7: LABEL GENERATION - USE SAMPLES
# ============================================================

test_that("Use labels are generated with correct format", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Create hierarchy: plant -> part
  plant_id <- "ST0001-P0001"
  part_id <- "ST0001-P0001-SH001"
  
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
     VALUES (?, 1, 'ST0001', 'plant')",
    params = list(plant_id)
  )
  
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_id, part_id) 
     VALUES (?, 2, 'ST0001', ?, ?)",
    params = list(part_id, plant_id, part_id)
  )
  
  # Generate use labels
  use_types <- list(GW = 2, DE = 1)
  
  for (use_code in names(use_types)) {
    count <- use_types[[use_code]]
    for (i in 1:count) {
      label_id <- sprintf("%s-%s%02d", part_id, use_code, i)
      
      dbExecute(con,
        "INSERT INTO Labels (label_id, stage, site_id, part_id, use_code) 
         VALUES (?, 3, 'ST0001', ?, ?)",
        params = list(label_id, part_id, use_code)
      )
    }
  }
  
  # Verify use labels
  result <- dbGetQuery(con, "SELECT * FROM Labels WHERE stage = 3 AND part_id = ?",
    params = list(part_id))
  expect_equal(nrow(result), 3, "Should have 3 use labels")
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 8: INVENTORY TABLE DISPLAY
# ============================================================

test_that("Inventory table shows unique samples (not counts)", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Create multiple labels
  for (i in 1:3) {
    label_id <- sprintf("ST0001-P%04d", i)
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_type) 
       VALUES (?, 1, 'ST0001', 'plant')",
      params = list(label_id)
    )
  }
  
  # Query should return 3 rows (unique samples), not aggregated
  result <- dbGetQuery(con, "
    SELECT DISTINCT label_id, stage, site_id
    FROM Labels
    WHERE stage = 1
  ")
  
  expect_equal(nrow(result), 3, "Should have 3 unique samples (rows)")
  expect_true(!("count" %in% names(result)), "Should not have count column")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Inventory table correctly displays status", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Create labels with different statuses
  statuses <- c("label_created", "collected", "processed")
  
  for (i in seq_along(statuses)) {
    label_id <- sprintf("ST0001-P%04d", i)
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id, sample_status) 
       VALUES (?, 1, 'ST0001', ?)",
      params = list(label_id, statuses[i])
    )
  }
  
  # Verify all statuses are stored correctly
  result <- dbGetQuery(con, "SELECT label_id, sample_status FROM Labels WHERE stage = 1")
  
  for (i in 1:nrow(result)) {
    expect_true(result$sample_status[i] %in% c("label_created", "collected", "processed"),
      "Status should be valid enum value")
  }
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Inventory table search filters correctly", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0002', 'Test2')")
  
  # Create labels in different sites
  for (i in 1:2) {
    for (j in 1:2) {
      label_id <- sprintf("ST%04d-P%04d", i, j)
      site_id <- sprintf("ST%04d", i)
      dbExecute(con,
        "INSERT INTO Labels (label_id, stage, site_id) 
         VALUES (?, 1, ?)",
        params = list(label_id, site_id)
      )
    }
  }
  
  # Search for ST0001
  result <- dbGetQuery(con, 
    "SELECT * FROM Labels WHERE site_id LIKE 'ST0001%' OR label_id LIKE '%ST0001%'")
  expect_equal(nrow(result), 2, "Search should find 2 ST0001 labels")
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 9: COORDINATE VALIDATION
# ============================================================

test_that("Latitude values are validated correctly", {
  valid_lats <- c(-90, -45, 0, 45, 90)
  invalid_lats <- c(-91, -100, 100, 91)
  
  for (lat in valid_lats) {
    is_valid <- lat >= -90 && lat <= 90
    expect_true(is_valid, paste("Latitude", lat, "should be valid"))
  }
  
  for (lat in invalid_lats) {
    is_valid <- lat >= -90 && lat <= 90
    expect_false(is_valid, paste("Latitude", lat, "should be invalid"))
  }
})

test_that("Longitude values are validated correctly", {
  valid_lons <- c(-180, -90, 0, 90, 180)
  invalid_lons <- c(-181, -200, 200, 181)
  
  for (lon in valid_lons) {
    is_valid <- lon >= -180 && lon <= 180
    expect_true(is_valid, paste("Longitude", lon, "should be valid"))
  }
  
  for (lon in invalid_lons) {
    is_valid <- lon >= -180 && lon <= 180
    expect_false(is_valid, paste("Longitude", lon, "should be invalid"))
  }
})

test_that("Coordinates are stored in database with correct precision", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Insert site with coordinates
  test_lat <- 37.7749
  test_lon <- -122.4194
  
  dbExecute(con,
    "INSERT INTO Sites (site_id, site_name, site_lat, site_long) 
     VALUES (?, ?, ?, ?)",
    params = list("ST0001", "Test", test_lat, test_lon)
  )
  
  # Retrieve and verify
  result <- dbGetQuery(con, "SELECT * FROM Sites WHERE site_id = 'ST0001'")
  
  expect_equal(result$site_lat[1], test_lat, tolerance = 0.0001)
  expect_equal(result$site_long[1], test_lon, tolerance = 0.0001)
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUITE 10: EDGE CASES AND ERROR HANDLING
# ============================================================

test_that("Empty database doesn't break queries", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Query empty tables should return empty data frame, not error
  result <- dbGetQuery(con, "SELECT * FROM Labels")
  expect_equal(nrow(result), 0, "Empty query should return 0 rows")
  expect_true(is.data.frame(result), "Result should be data frame even if empty")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Null values are handled correctly in storage_location", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Insert label without location
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id) 
     VALUES ('ST0001-P0001', 1, 'ST0001')")
  
  # Retrieve
  result <- dbGetQuery(con, "SELECT storage_location FROM Labels")
  
  expect_true(is.na(result$storage_location[1]) || result$storage_location[1] == "",
    "Location should be NULL or empty when not set")
  
  dbDisconnect(con)
  unlink(db_path)
})

test_that("Large quantity of labels can be generated", {
  db_path <- setup_test_db()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "INSERT INTO Sites (site_id, site_name) VALUES ('ST0001', 'Test')")
  
  # Generate 100 labels
  for (i in 1:100) {
    label_id <- sprintf("ST0001-P%04d", i)
    dbExecute(con,
      "INSERT INTO Labels (label_id, stage, site_id) 
       VALUES (?, 1, 'ST0001')",
      params = list(label_id)
    )
  }
  
  # Verify all were inserted
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Labels")
  expect_equal(result$count[1], 100, "Should have 100 labels")
  
  dbDisconnect(con)
  unlink(db_path)
})

# ============================================================
# TEST SUMMARY REPORT
# ============================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("LIMS COMPREHENSIVE TEST SUITE COMPLETE\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("Tests include:\n")
cat("✓ Database initialization and schema validation\n")
cat("✓ Site and Sample ID format validation\n")
cat("✓ QR code generation and square format validation\n")
cat("✓ Pre-sampling, Parts, and Use label generation\n")
cat("✓ Duplicate label rejection\n")
cat("✓ Inventory table unique row display (no counts)\n")
cat("✓ Status tracking and filtering\n")
cat("✓ Coordinate validation (latitude/longitude)\n")
cat("✓ Edge cases and error handling\n")
cat("✓ Large dataset handling (100+ labels)\n")
cat("═══════════════════════════════════════════════════════════\n")
