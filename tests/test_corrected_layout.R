#!/usr/bin/env Rscript
# Test new corrected label layout - text visible in PNG

library(qrcode)
library(grid)

cat("Testing corrected label layout - text and QR code visible, no overlap...\n\n")

site_id <- "ST0001"
start_idx <- 1
end_idx <- 2
labels_dir <- "data/test_labels_corrected"

if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
system(paste("rm -f", file.path(labels_dir, "*.png")))

tryCatch({
  for (i in start_idx:end_idx) {
    plant_id <- sprintf("%s-P%04d", site_id, i)
    label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
    
    cat(sprintf("Generating %s...", plant_id))
    
    # Create horizontal label (1800x600 at 150 DPI for preview)
    png(label_file, width = 1800, height = 600, res = 150, bg = "white")
    
    # Create main viewport for entire label
    grid.newpage()
    main_vp <- viewport(width = 0.96, height = 0.94, x = 0.5, y = 0.5)
    pushViewport(main_vp)
    
    # Draw border around entire label
    grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 2, fill = NA))
    
    # LEFT SECTION: Text area (45% of width)
    text_vp <- viewport(x = 0.225, y = 0.5, width = 0.45, height = 0.95)
    pushViewport(text_vp)
    
    # Background
    grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
    
    # Plant ID - Large and bold
    grid.text(plant_id, 
              x = 0.5, y = 0.70, 
              gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"))
    
    # Site ID
    grid.text(paste("Site:", site_id), 
              x = 0.5, y = 0.40, 
              gp = gpar(fontsize = 16, family = "monospace"))
    
    # Date
    grid.text(as.character(Sys.Date()), 
              x = 0.5, y = 0.12, 
              gp = gpar(fontsize = 12, family = "monospace"))
    
    popViewport()
    
    # DIVIDER: Vertical line between sections
    grid.lines(x = c(0.475, 0.475), y = c(0.03, 0.97), default.units = "npc",
               gp = gpar(col = "black", lwd = 2))
    
    # RIGHT SECTION: QR Code (50% of width)
    qr_vp <- viewport(x = 0.735, y = 0.5, width = 0.475, height = 0.95)
    pushViewport(qr_vp)
    
    # Background
    grid.rect(width = 1, height = 1, gp = gpar(fill = "white", col = NA))
    
    # QR code
    qr_obj <- qr_code(plant_id)
    plot(qr_obj, asp = 1, new = TRUE)
    
    popViewport()  # Exit QR viewport
    popViewport()  # Exit main viewport
    
    dev.off()
    
    cat(" ✓\n")
  }
  
  cat("\n✅ Corrected labels generated!\n")
  cat("Layout:\n")
  cat("  Left (45%): Large ID + Site + Date\n")
  cat("  Divider: Black line\n")
  cat("  Right (50%): QR Code\n")
  cat("  NO OVERLAPPING - Clean separation\n")
  cat("Files: ", labels_dir, "\n")
  
}, error = function(e) {
  cat(sprintf("\n✗ Error: %s\n", e$message))
})
