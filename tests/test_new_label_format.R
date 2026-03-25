#!/usr/bin/env Rscript
# Test new label format

library(qrcode)
library(grid)

cat("Testing updated label format with ID and QR code visible...\n\n")

site_id <- "ST0001"
start_idx <- 1
end_idx <- 2
labels_dir <- "data/test_labels_updated"

if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
system(paste("rm -f", file.path(labels_dir, "*.png")))

tryCatch({
  for (i in start_idx:end_idx) {
    plant_id <- sprintf("%s-P%04d", site_id, i)
    label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
    
    cat(sprintf("Generating %s...", plant_id))
    
    # Create horizontal label (1800x600 at 150 DPI for screen preview)
    png(label_file, width = 1800, height = 600, res = 150, bg = "white")
    
    grid.newpage()
    pushViewport(viewport(width = 0.96, height = 0.94, x = 0.5, y = 0.5))
    
    # Border
    grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 2, fill = NA))
    
    # Left: Plant ID (35% width)
    pushViewport(viewport(x = 0.175, y = 0.5, width = 0.33, height = 0.9))
    grid.text(plant_id, 
              x = 0.5, y = 0.65, gp = gpar(fontsize = 32, fontface = "bold", family = "mono"))
    grid.text(site_id, 
              x = 0.5, y = 0.35, gp = gpar(fontsize = 14, family = "mono"))
    grid.text(as.character(Sys.Date()), 
              x = 0.5, y = 0.05, gp = gpar(fontsize = 10, family = "mono"))
    popViewport()
    
    # Separator line
    grid.lines(x = c(0.35, 0.35), y = c(0.05, 0.95), default.units = "npc",
               gp = gpar(col = "black", lwd = 1.5))
    
    # Right: QR code (60% width)
    qr_obj <- qr_code(plant_id)
    pushViewport(viewport(x = 0.68, y = 0.5, width = 0.6, height = 0.9))
    plot(qr_obj, asp = 1, new = TRUE)
    popViewport()
    
    popViewport()
    dev.off()
    
    cat(" ✓\n")
  }
  
  cat("\n✅ New label format generated!\n")
  cat("Layout: ST0001-P0001 on left | QR CODE on right\n")
  cat("Files: ", labels_dir, "\n")
  
}, error = function(e) {
  cat(sprintf("\n✗ Error: %s\n", e$message))
})
