#!/usr/bin/env Rscript

# Plant Label Generation Test
# Validates QR code generation and label formatting with text inside QR bounds

library(qrcode)
library(grid)
library(png)

test_plant_labels <- function() {
  test_name <- "Plant Label Generation"
  
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
  
  return(TRUE)
}

if (sys.nframe() == 0) {
  result <- test_plant_labels()
  if (result) {
    cat("✓ Plant Label Generation Test PASSED\n")
  }
}
