#!/usr/bin/env Rscript
# Test label generation

library(shiny)
library(bs4Dash)
library(qrcode)
library(grid)
library(gridExtra)

cat("Testing label generation code...\n\n")

# Test parameters (matching what's in the app)
site_id <- "ST0001"
start_idx <- 1
end_idx <- 4
labels_dir <- "data/test_labels"

if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)

tryCatch({
  cat("Generating 4 test labels...\n")
  
  for (i in start_idx:end_idx) {
    plant_id <- sprintf("%s-P%04d", site_id, i)
    label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
    
    cat(sprintf("  Generating %s...", plant_id))
    
    # Create label with QR code using grid graphics
    png(label_file, width = 800, height = 800, res = 150, bg = "white")
    
    # Create viewport for entire label
    grid.newpage()
    pushViewport(viewport(width = 0.95, height = 0.95, x = 0.5, y = 0.5))
    
    # Draw border
    grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 2, fill = NA))
    
    # QR code area (top 60%)
    qr_obj <- qr_code(plant_id)
    pushViewport(viewport(y = 0.7, height = 0.55, width = 0.8, x = 0.5))
    plot(qr_obj, asp = 1, new = TRUE)
    popViewport()
    
    # Text area (bottom 40%)
    pushViewport(viewport(y = 0.25, height = 0.35, width = 0.9, x = 0.5))
    
    # Separator line
    grid.lines(x = c(0, 1), y = c(0.95, 0.95), default.units = "npc",
               gp = gpar(col = "black", lwd = 1))
    
    # Text labels
    grid.text(paste("Site:", site_id), 
              x = 0.5, y = 0.75, gp = gpar(fontsize = 14, fontface = "bold", family = "mono"))
    grid.text(sprintf("Plant P%04d", i), 
              x = 0.5, y = 0.5, gp = gpar(fontsize = 14, fontface = "bold", family = "mono"))
    grid.text(plant_id, 
              x = 0.5, y = 0.25, gp = gpar(fontsize = 12, fontface = "bold", family = "mono"))
    grid.text(as.character(Sys.Date()), 
              x = 0.5, y = 0.05, gp = gpar(fontsize = 10, family = "mono"))
    
    popViewport()
    popViewport()
    
    dev.off()
    cat(" ✓\n")
  }
  
  cat("\n✅ Label generation successful!\n")
  cat(sprintf("Generated %d labels in: %s\n", end_idx - start_idx + 1, labels_dir))
  
}, error = function(e) {
  cat(sprintf("\n✗ Error: %s\n", e$message))
})
