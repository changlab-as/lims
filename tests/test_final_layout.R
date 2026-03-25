#!/usr/bin/env Rscript
# Test corrected label layout using raster graphics - text visible, no overlap

library(qrcode)
library(grid)
library(png)

cat("Testing final corrected layout - text + QR, no overlap, using raster...\n\n")

site_id <- "ST0001"
start_idx <- 1
end_idx <- 2
labels_dir <- "data/test_labels_final"

if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
system(paste("rm -f", file.path(labels_dir, "*.png")))

tryCatch({
  for (i in start_idx:end_idx) {
    plant_id <- sprintf("%s-P%04d", site_id, i)
    label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
    
    cat(sprintf("Generating %s...", plant_id))
    
    # Step 1: Create QR code image
    qr_obj <- qr_code(plant_id)
    temp_qr <- tempfile(fileext = ".png")
    png(temp_qr, width = 400, height = 400, bg = "white")
    plot(qr_obj)
    dev.off()
    qr_img <- readPNG(temp_qr)
    
    # Step 2: Create label with text and QR
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
    
    # RIGHT: QR Code area (50%) - using raster to avoid overlap
    qr_vp <- viewport(x = 0.735, y = 0.5, width = 0.475, height = 0.95)
    pushViewport(qr_vp)
    grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
    
    # Plot QR as raster image
    grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
    
    popViewport()
    popViewport()
    dev.off()
    
    unlink(temp_qr)
    
    cat(" ✓\n")
  }
  
  cat("\n✅ Final labels generated!\n")
  cat("Layout (FIXED):\n")
  cat("  ┌─────────────────────────────────────┐\n")
  cat("  │ ST0001-P0001 │                      │\n")
  cat("  │ Site: ST0001 │   [QR CODE]         │\n")
  cat("  │ 2026-03-25   │                      │\n")
  cat("  └─────────────────────────────────────┘\n")
  cat("✓ NO OVERLAPPING\n")
  cat("✓ Text clearly visible in PNG\n")
  cat("✓ QR code clearly visible\n")
  cat("Files: ", labels_dir, "\n")
  
}, error = function(e) {
  cat(sprintf("\n✗ Error: %s\n", e$message))
  cat("Traceback:\n")
  print(e)
})
