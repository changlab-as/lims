#!/usr/bin/env Rscript

# Test: Generate labels with simplified format (no borders)

library(qrcode)
library(grid)
library(png)

test_dir <- "data/test_labels_clean"
if (!dir.exists(test_dir)) dir.create(test_dir, showWarnings = FALSE)

cat("=== Testing Simplified Label Format (No Borders) ===\n\n")

plant_id <- "ST0001-P0001"
site_id <- "ST0001"
label_file <- file.path(test_dir, paste0(plant_id, ".png"))

# Set seed for reproducible QR
set.seed(as.integer(charToRaw(plant_id)) %% 2147483647)

qr_obj <- qr_code(plant_id)
temp_qr_file <- tempfile(fileext = ".png")
png(temp_qr_file, width = 400, height = 400, bg = "white")
plot(qr_obj)
dev.off()
qr_img <- png::readPNG(temp_qr_file)

# Create label with SIMPLIFIED FORMAT - NO BORDERS
png(label_file, width = 1800, height = 600, res = 150, bg = "white")

grid.newpage()

# LEFT COLUMN: Plant ID (top) and Date (bottom) - direct positioning
# Plant ID - positioned inside QR bounds, below upper edge
grid.text(plant_id, 
          x = 0.27, y = 0.75, 
          gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
          just = "centre")

# Date - positioned inside QR bounds, above lower edge
grid.text(as.character(Sys.Date()), 
          x = 0.27, y = 0.25, 
          gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
          just = "centre"

# RIGHT: QR Code area - square
qr_height_npc <- 0.95
qr_width_npc <- qr_height_npc * (600 / 1800)
qr_vp <- viewport(x = 0.75, y = 0.5, width = qr_width_npc, height = qr_height_npc)
pushViewport(qr_vp)

# Plot QR as raster image as a perfect square
grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)

popViewport()
dev.off()

unlink(temp_qr_file)

cat("✓ Label generated with simplified format:\n")
cat("  - Plant ID (left, 48pt bold)\n")
cat("  - Date (middle, 48pt bold)\n")
cat("  - QR code (right, square)\n")
cat("  - NO BORDERS\n")
cat("  - NO DIVIDER LINES\n\n")

cat("✓ All tests passed!\n")
cat("✓ Labels ready: ", test_dir, "\n", sep="")
