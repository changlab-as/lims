#!/usr/bin/env Rscript

# Test: Generate equipment labels with QR codes

library(qrcode)
library(grid)
library(png)

test_dir <- "data/test_equipment_labels"
if (!dir.exists(test_dir)) dir.create(test_dir, showWarnings = FALSE)

cat("=== Testing Equipment Label Generation ===\n\n")

# Equipment data
equipment_list <- data.frame(
  equipment_id = c("U01", "Z01", "F01", "F02", "F03", "G01"),
  character_name = c("Totoro", "San", "Calcifer", "No-Face", "Ponyo", "Laputa")
)

# Generate label for each equipment
for (row in 1:nrow(equipment_list)) {
  equipment_id <- equipment_list$equipment_id[row]
  character_name <- equipment_list$character_name[row]
  label_file <- file.path(test_dir, paste0(equipment_id, ".png"))
  
  cat("Generating label for:", equipment_id, "-", character_name, "\n")
  
  # Set seed based on equipment_id for reproducible QR codes
  set.seed(as.integer(charToRaw(equipment_id)) %% 2147483647)
  
  # Generate QR code to temporary file
  qr_obj <- qr_code(equipment_id)
  temp_qr_file <- tempfile(fileext = ".png")
  png(temp_qr_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  qr_img <- png::readPNG(temp_qr_file)
  
  # Create label with text and QR (1800x600 horizontal format)
  png(label_file, width = 1800, height = 600, res = 150, bg = "white")
  
  grid.newpage()
  
  # LEFT: Equipment ID and Character Name (stacked in left column)
  # Equipment ID - positioned inside QR bounds, below upper edge
  grid.text(equipment_id, 
            x = 0.27, y = 0.75, 
            gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
            just = "centre")
  
  # Character Name - positioned inside QR bounds, above lower edge
  grid.text(character_name, 
            x = 0.27, y = 0.25, 
            gp = gpar(fontsize = 36, fontface = "bold", family = "monospace"),
            just = "centre")
  
  # RIGHT: QR Code (square format)
  qr_height_npc <- 0.95
  qr_width_npc <- qr_height_npc * (600 / 1800)
  qr_vp <- viewport(x = 0.75, y = 0.5, width = qr_width_npc, height = qr_height_npc)
  pushViewport(qr_vp)
  grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
  popViewport()
  
  dev.off()
  
  unlink(temp_qr_file)
}

cat("\n✓ Equipment labels generated successfully!\n")
cat("✓ Labels ready in:", test_dir, "\n\n")

# List generated files
files <- list.files(test_dir, pattern = "*.png")
cat("Generated files:\n")
for (f in files) {
  cat("  -", f, "\n")
}
