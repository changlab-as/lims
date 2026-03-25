#!/usr/bin/env Rscript
# Test horizontal label generation for label maker tape

library(qrcode)
library(grid)

cat("Testing horizontal label generation for label maker tape...\n\n")

# Test parameters
site_id <- "ST0001"
start_idx <- 1
end_idx <- 3
labels_dir <- "data/test_labels_horizontal"

if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)

# Clear old test labels
system(paste("rm -f", file.path(labels_dir, "*.png")))

tryCatch({
  cat("Generating 3 horizontal labels...\n")
  
  for (i in start_idx:end_idx) {
    plant_id <- sprintf("%s-P%04d", site_id, i)
    label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
    
    cat(sprintf("  Generating %s...", plant_id))
    
    # Create horizontal label for label maker tape (6x4 inches = 1800x800 at 300 DPI)
    png(label_file, width = 1800, height = 800, res = 300, bg = "white")
    
    # Create viewport for entire label
    grid.newpage()
    pushViewport(viewport(width = 0.98, height = 0.98, x = 0.5, y = 0.5))
    
    # Draw border
    grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 2, fill = NA))
    
    # Left side: Text (40% width)
    pushViewport(viewport(x = 0.2, y = 0.5, width = 0.38, height = 1))
    grid.text(plant_id, 
              x = 0.5, y = 0.7, gp = gpar(fontsize = 28, fontface = "bold", family = "mono"))
    grid.text(site_id, 
              x = 0.5, y = 0.4, gp = gpar(fontsize = 18, fontface = "bold", family = "mono"))
    grid.text(as.character(Sys.Date()), 
              x = 0.5, y = 0.1, gp = gpar(fontsize = 14, family = "mono"))
    popViewport()
    
    # Center separator line
    grid.lines(x = c(0.4, 0.4), y = c(0.05, 0.95), default.units = "npc",
               gp = gpar(col = "black", lwd = 1))
    
    # Right side: QR Code (55% width)
    qr_obj <- qr_code(plant_id)
    pushViewport(viewport(x = 0.73, y = 0.5, width = 0.52, height = 1))
    plot(qr_obj, asp = 1, new = TRUE)
    popViewport()
    
    popViewport()
    dev.off()
    
    cat(" ✓\n")
  }
  
  cat("\n✅ Horizontal labels generated successfully!\n")
  cat(sprintf("Format: 6x4 inches (landscape for label maker tape)\n"))
  cat(sprintf("Resolution: 300 DPI (print quality)\n"))
  cat(sprintf("Location: %s\n", labels_dir))
  
}, error = function(e) {
  cat(sprintf("\n✗ Error: %s\n", e$message))
})
