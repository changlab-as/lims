#!/usr/bin/env Rscript

# Equipment Label Generation Test
# Validates QR code and label generation for equipment identifiers

library(qrcode)
library(grid)
library(png)

test_equipment_labels <- function() {
  test_name <- "Equipment Label Generation"
  
  test_dir <- "data/test_equipment_labels"
  if (!dir.exists(test_dir)) dir.create(test_dir, recursive = TRUE, showWarnings = FALSE)
  
  equipment_list <- data.frame(
    equipment_id = c("U01", "Z01", "F01"),
    character_name = c("Totoro, in B16-1", "Jiji, -30°C in R100", "Teto, 4C in R100")
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
  
  return(TRUE)
}

if (sys.nframe() == 0) {
  result <- test_equipment_labels()
  if (result) {
    cat("✓ Equipment Label Generation Test PASSED\n")
  }
}
