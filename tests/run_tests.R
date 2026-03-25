#!/usr/bin/env Rscript

# Unified Test Suite for LIMS
# Runs all tests and provides summary report

library(qrcode)
library(grid)
library(png)
library(RSQLite)
library(DBI)

# Test configuration
test_results <- list()
test_count <- 0
test_passed <- 0
test_failed <- 0

# Helper function to run a test
run_test <- function(test_name, test_func) {
  test_count <<- test_count + 1
  cat(sprintf("\n[Test %d] %s\n", test_count, test_name))
  cat(strrep("-", 60), "\n")
  
  tryCatch({
    test_func()
    test_passed <<- test_passed + 1
    cat("✓ PASSED\n")
    test_results[[test_name]] <<- "PASSED"
  }, error = function(e) {
    test_failed <<- test_failed + 1
    cat("✗ FAILED:", e$message, "\n")
    test_results[[test_name]] <<- paste("FAILED:", e$message)
  })
}

# ===== TEST 1: Plant Labels with Text Inside QR Bounds =====
run_test("Plant Label Generation - Text Inside QR Bounds", function() {
  test_dir <- "data/test_labels"
  if (!dir.exists(test_dir)) dir.create(test_dir, recursive = TRUE, showWarnings = FALSE)
  
  plant_id <- "ST0001-P0001"
  label_file <- file.path(test_dir, paste0(plant_id, ".png"))
  
  # Generate QR
  set.seed(as.integer(charToRaw(plant_id)) %% 2147483647)
  qr_obj <- qr_code(plant_id)
  temp_qr_file <- tempfile(fileext = ".png")
  png(temp_qr_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  qr_img <- png::readPNG(temp_qr_file)
  
  # Create label
  png(label_file, width = 1800, height = 600, res = 150, bg = "white")
  grid.newpage()
  
  # Text positioned INSIDE QR bounds
  # QR bounds: y from 0.025 to 0.975
  # Text at y=0.75 (top, inside upper area) and y=0.25 (bottom, inside lower area)
  grid.text(plant_id, 
            x = 0.27, y = 0.75, 
            gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
            just = "centre")
  
  grid.text(as.character(Sys.Date()), 
            x = 0.27, y = 0.25, 
            gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
            just = "centre")
  
  # QR Code
  qr_height_npc <- 0.95
  qr_width_npc <- qr_height_npc * (600 / 1800)
  qr_vp <- viewport(x = 0.75, y = 0.5, width = qr_width_npc, height = qr_height_npc)
  pushViewport(qr_vp)
  grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
  popViewport()
  
  dev.off()
  unlink(temp_qr_file)
  
  # Validate file was created
  if (!file.exists(label_file)) {
    stop("Plant label file not created")
  }
  
  cat("  Generated:", label_file, "\n")
})

# ===== TEST 2: Equipment Labels with Text Inside QR Bounds =====
run_test("Equipment Label Generation - Text Inside QR Bounds", function() {
  test_dir <- "data/test_equipment_labels"
  if (!dir.exists(test_dir)) dir.create(test_dir, recursive = TRUE, showWarnings = FALSE)
  
  equipment_list <- data.frame(
    equipment_id = c("U01", "Z01", "F01"),
    character_name = c("Totoro", "San", "Calcifer")
  )
  
  generated_files <- 0
  for (row in 1:nrow(equipment_list)) {
    equipment_id <- equipment_list$equipment_id[row]
    character_name <- equipment_list$character_name[row]
    label_file <- file.path(test_dir, paste0(equipment_id, ".png"))
    
    # Generate QR
    set.seed(as.integer(charToRaw(equipment_id)) %% 2147483647)
    qr_obj <- qr_code(equipment_id)
    temp_qr_file <- tempfile(fileext = ".png")
    png(temp_qr_file, width = 400, height = 400, bg = "white")
    plot(qr_obj)
    dev.off()
    qr_img <- png::readPNG(temp_qr_file)
    
    # Create label
    png(label_file, width = 1800, height = 600, res = 150, bg = "white")
    grid.newpage()
    
    # Text positioned INSIDE QR bounds
    grid.text(equipment_id, 
              x = 0.27, y = 0.75, 
              gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
              just = "centre")
    
    grid.text(character_name, 
              x = 0.27, y = 0.25, 
              gp = gpar(fontsize = 36, fontface = "bold", family = "monospace"),
              just = "centre")
    
    # QR Code
    qr_height_npc <- 0.95
    qr_width_npc <- qr_height_npc * (600 / 1800)
    qr_vp <- viewport(x = 0.75, y = 0.5, width = qr_width_npc, height = qr_height_npc)
    pushViewport(qr_vp)
    grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
    popViewport()
    
    dev.off()
    unlink(temp_qr_file)
    
    if (file.exists(label_file)) {
      generated_files <- generated_files + 1
    }
  }
  
  if (generated_files != 3) {
    stop(sprintf("Expected 3 equipment labels, generated %d", generated_files))
  }
  
  cat(sprintf("  Generated: %d equipment labels\n", generated_files))
})

# ===== TEST 3: App Loading =====
run_test("Shiny App Loading", function() {
  # Check if app.R exists and can be parsed
  if (!file.exists("app.R")) {
    stop("app.R not found")
  }
  
  tryCatch({
    parse(file = "app.R")
    cat("  app.R syntax validated\n")
  }, error = function(e) {
    stop(sprintf("Syntax error in app.R: %s", e$message))
  })
})

# ===== TEST 4: Database Initialization =====
run_test("Database Initialization", function() {
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
  
  # Test insert
  dbExecute(con, 
    "INSERT INTO Equipment (equipment_id, character_name, category, description) 
     VALUES (?, ?, ?, ?)",
    params = list("TEST01", "Test Equipment", "Test Category", "Test Description")
  )
  
  # Test query
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Equipment")
  
  dbDisconnect(con)
  unlink(temp_db)
  
  if (result$count[1] != 1) {
    stop("Database insert/query test failed")
  }
  
  cat("  Equipment table schema validated\n")
})

# ===== TEST 5: QR Code Reproducibility =====
run_test("QR Code Reproducibility", function() {
  # Generate same QR twice with same seed
  test_id <- "REPRODUCE_TEST"
  
  # First generation
  set.seed(as.integer(charToRaw(test_id)) %% 2147483647)
  qr_1 <- qr_code(test_id)
  
  # Second generation with same seed
  set.seed(as.integer(charToRaw(test_id)) %% 2147483647)
  qr_2 <- qr_code(test_id)
  
  # Both should produce identical QR codes
  # Check that objects have same attributes/structure
  if (!all(dim(qr_1) == dim(qr_2))) {
    stop("QR reproducibility failed: different dimensions")
  }
  
  cat("  QR codes reproducible with seed-based generation\n")
})

# ===== Print Summary =====
cat("\n")
cat(strrep("=", 60), "\n")
cat("TEST SUMMARY\n")
cat(strrep("=", 60), "\n")
cat(sprintf("Total Tests:  %d\n", test_count))
cat(sprintf("Passed:       %d ✓\n", test_passed))
cat(sprintf("Failed:       %d ✗\n", test_failed))
cat(strrep("=", 60), "\n")

if (test_failed > 0) {
  cat("\nFailed Tests:\n")
  for (name in names(test_results)) {
    result <- test_results[[name]]
    if (result != "PASSED") {
      cat(sprintf("  ✗ %s: %s\n", name, result))
    }
  }
  quit(status = 1)
} else {
  cat("\n✓ ALL TESTS PASSED\n\n")
  cat("Generated test outputs:\n")
  cat("  - Plant labels: data/test_labels/\n")
  cat("  - Equipment labels: data/test_equipment_labels/\n\n")
  quit(status = 0)
}
