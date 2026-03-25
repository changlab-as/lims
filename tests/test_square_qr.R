#!/usr/bin/env Rscript

# Test: Verify QR codes are now square

library(qrcode)
library(grid)
library(png)

# Create a temp directory
test_dir <- "data/test_labels_square"
if (!dir.exists(test_dir)) dir.create(test_dir, showWarnings = FALSE)

generate_label <- function(plant_id, site_id, plant_index, output_dir) {
  label_file <- file.path(output_dir, paste0(plant_id, ".png"))
  
  # Generate QR code
  qr_obj <- qr_code(plant_id)
  
  # STAGE 1: Generate QR as separate image
  temp_qr_file <- tempfile(fileext = ".png")
  png(temp_qr_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  qr_img <- png::readPNG(temp_qr_file)
  
  # STAGE 2: Create label with text and QR
  png(label_file, width = 1800, height = 600, res = 150, bg = "white")
  
  grid.newpage()
  main_vp <- viewport(width = 0.96, height = 0.94, x = 0.5, y = 0.5)
  pushViewport(main_vp)
  
  # Border
  grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 2, fill = NA))
  
  # LEFT: Text area (45%)
  text_vp <- viewport(x = 0.225, y = 0.5, width = 0.45, height = 0.95)
  pushViewport(text_vp)
  grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
  
  grid.text(plant_id, 
            x = 0.5, y = 0.70, 
            gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"))
  grid.text(paste("Site:", site_id), 
            x = 0.5, y = 0.40, 
            gp = gpar(fontsize = 16, family = "monospace"))
  grid.text(as.character(Sys.Date()), 
            x = 0.5, y = 0.12, 
            gp = gpar(fontsize = 12, family = "monospace"))
  popViewport()
  
  # DIVIDER line
  grid.lines(x = c(0.475, 0.475), y = c(0.03, 0.97), default.units = "npc",
             gp = gpar(col = "black", lwd = 2))
  
  # RIGHT: QR Code area - square viewport (accounting for 1800x600 page aspect ratio)
  # Page is 3:1 aspect ratio, so for a square: width_npc = height_npc * (600/1800)
  qr_height_npc <- 0.95
  qr_width_npc <- qr_height_npc * (600 / 1800)  # 0.3167
  qr_vp <- viewport(x = 0.7375, y = 0.5, width = qr_width_npc, height = qr_height_npc)
  pushViewport(qr_vp)
  grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
  
  # Plot QR as raster image as a perfect square
  grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
  
  popViewport()
  popViewport()
  dev.off()
  
  unlink(temp_qr_file)
  cat("✓ Generated:", plant_id, "->", basename(label_file), "\n")
}

# Generate two test labels
generate_label("ST0001-P0001", "ST0001", 1, test_dir)
generate_label("ST0001-P0002", "ST0001", 2, test_dir)

cat("\n✅ Test labels created in", test_dir, "\n")
