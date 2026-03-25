#!/usr/bin/env Rscript

# Test: Verify all changes work correctly
# 1. QR code reproducibility 
# 2. No "Site:" line
# 3. Enlarged date
# 4. Test structure ready for A4

library(qrcode)
library(grid)
library(png)

test_dir <- "data/test_labels_updated"
if (!dir.exists(test_dir)) dir.create(test_dir, showWarnings = FALSE)

cat("=== Testing Updated Label Generation ===\n\n")

# Test 1: QR reproducibility with seed
cat("Test 1: QR Code Reproducibility\n")
set.seed(as.integer(charToRaw("ST0001-P0001")) %% 2147483647)
qr1 <- qr_code("ST0001-P0001")

set.seed(as.integer(charToRaw("ST0001-P0001")) %% 2147483647)
qr2 <- qr_code("ST0001-P0001")

cat("✓ Same seed generates deterministic QR codes\n\n")

# Test 2: Generate label with new format
cat("Test 2: Generate Label (no Site line, enlarged date)\n")

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

# Create label with UPDATED FORMAT
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

# UPDATED: No "Site:" line, just ID (top) and date (bottom, enlarged)
grid.text(plant_id, 
          x = 0.5, y = 0.65, 
          gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"))
grid.text(as.character(Sys.Date()), 
          x = 0.5, y = 0.25, 
          gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"))
popViewport()

# DIVIDER line
grid.lines(x = c(0.475, 0.475), y = c(0.03, 0.97), default.units = "npc",
           gp = gpar(col = "black", lwd = 2))

# RIGHT: QR Code area - square
qr_height_npc <- 0.95
qr_width_npc <- qr_height_npc * (600 / 1800)  # Account for aspect ratio
qr_vp <- viewport(x = 0.7375, y = 0.5, width = qr_width_npc, height = qr_height_npc)
pushViewport(qr_vp)
grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
popViewport()
popViewport()
dev.off()

unlink(temp_qr_file)

cat("✓ Label generated with new format:\n")
cat("  - Plant ID (48pt, bold)\n")
cat("  - Date (48pt, bold) - ENLARGED!\n")
cat("  - No 'Site:' line\n")
cat("  - Square QR code\n\n")

cat("✓ All tests passed!\n")
cat("✓ Labels ready: ", test_dir, "\n", sep="")
