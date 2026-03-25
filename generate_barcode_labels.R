# Riverside Rhizobia LIMS - Batch Barcode Label Generator
# Run this script to generate printable labels with QR codes for your samples
# Usage: Rscript generate_barcode_labels.R
# Or: source("generate_barcode_labels.R") in R console

library(qrcode)
library(RSQLite)
library(DBI)
library(gridExtra)
library(grid)
library(png)

# Configuration
DB_PATH <- "data/lims_db.sqlite"
LABELS_DIR <- "data/labels"
OUTPUT_FORMAT <- "png"  # "png" or "pdf"
DPI <- 300  # Print quality resolution
LABEL_SIZE_INCHES <- 2

# Create output directories
if (!dir.exists(LABELS_DIR)) dir.create(LABELS_DIR, recursive = TRUE)

# Function to generate individual label (horizontal format for label maker tape)
generate_label <- function(plant_id, site_id, plant_index, output_dir, dpi = 300) {
  tryCatch({
    label_file <- file.path(output_dir, paste0(plant_id, ".png"))
    
    # First, generate QR code to temporary file
    qr_obj <- qr_code(plant_id)
    
    # Set seed based on plant_id for reproducible QR codes
    set.seed(as.integer(charToRaw(plant_id)) %% 2147483647)
    
    temp_qr_file <- tempfile(fileext = ".png")
    png(temp_qr_file, width = 400, height = 400, bg = "white")
    plot(qr_obj)
    dev.off()
    qr_img <- png::readPNG(temp_qr_file)
    
    # Create horizontal label (1800x600 at dpi for print quality)
    png(label_file, width = 1800, height = 600, res = dpi, bg = "white")
    
    grid.newpage()
    
    # LEFT COLUMN: Plant ID (top) and Date (bottom) - direct positioning
    # Plant ID - top portion (~70% height)
    grid.text(plant_id, 
              x = 0.15, y = 0.85, 
              gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
              just = "centre")
    
    # Date - bottom portion (~25% height)
    grid.text(as.character(Sys.Date()), 
              x = 0.15, y = 0.25, 
              gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
              just = "centre")
    
    # RIGHT: QR Code area - square viewport (accounting for 1800x600 page aspect ratio)
    # Page is 3:1 aspect ratio, so for a square: width_npc = height_npc * (600/1800)
    qr_height_npc <- 0.95
    qr_width_npc <- qr_height_npc * (600 / 1800)  # 0.3167
    qr_vp <- viewport(x = 0.75, y = 0.5, width = qr_width_npc, height = qr_height_npc)
    pushViewport(qr_vp)
    
    # Plot QR as raster image as a perfect square
    grid.raster(qr_img, width = 0.85, height = 0.85, x = 0.5, y = 0.5)
    
    popViewport()
    dev.off()
    
    unlink(temp_qr_file)
    
    cat("✓ Generated:", plant_id, "\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("✗ Error for", plant_id, ":", e$message, "\n")
    return(FALSE)
  })
}

# Function to generate PDF sheet of labels (4 per page)
generate_pdf_sheet <- function(plant_ids, site_id, output_dir) {
  tryCatch({
    pdf_file <- file.path(output_dir, paste0(site_id, "_labels_sheet.pdf"))
    
    pdf(pdf_file, width = 8.5, height = 11, onefile = TRUE)
    
    labels_per_page <- 4
    total_pages <- ceiling(length(plant_ids) / labels_per_page)
    
    for (page in 1:total_pages) {
      grid.newpage()
      
      # Create grid: 2 columns x 2 rows
      pushViewport(viewport(width = 0.95, height = 0.95, x = 0.5, y = 0.5))
      
      start_idx <- (page - 1) * labels_per_page + 1
      end_idx <- min(page * labels_per_page, length(plant_ids))
      
      label_positions <- list(
        list(x = 0.25, y = 0.75, w = 0.4, h = 0.4),  # Top left
        list(x = 0.75, y = 0.75, w = 0.4, h = 0.4),  # Top right
        list(x = 0.25, y = 0.25, w = 0.4, h = 0.4),  # Bottom left
        list(x = 0.75, y = 0.25, w = 0.4, h = 0.4)   # Bottom right
      )
      
      for (i in start_idx:end_idx) {
        pos_idx <- (i - start_idx) + 1
        pos <- label_positions[[pos_idx]]
        
        plant_id <- plant_ids[i]
        
        pushViewport(viewport(x = pos$x, y = pos$y, width = pos$w, height = pos$h))
        
        # Draw border
        grid.rect(width = 1, height = 1, gp = gpar(col = "black", lwd = 1, fill = NA))
        
        # Draw text
        grid.text(plant_id, 
                  x = 0.5, y = 0.5, gp = gpar(fontsize = 10, fontface = "bold", family = "mono"))
        
        popViewport()
      }
      
      popViewport()
    }
    
    dev.off()
    cat("✓ PDF sheet created:", pdf_file, "\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("✗ Error creating PDF:", e$message, "\n")
    return(FALSE)
  })
}

# Main execution
interactive_mode <- function() {
  cat("\n=== Riverside Rhizobia LIMS - Barcode Label Generator ===\n\n")
  
  # Connect to database
  if (!file.exists(DB_PATH)) {
    cat("Error: Database not found at", DB_PATH, "\n")
    cat("Please run the Shiny app first to initialize the database.\n")
    return()
  }
  
  con <- dbConnect(RSQLite::SQLite(), DB_PATH)
  
  # Get available sites
  sites <- dbGetQuery(con, "SELECT DISTINCT site_id, location_name FROM Sites ORDER BY site_id")
  
  if (nrow(sites) == 0) {
    cat("No sites found in database. Please create a site in the Shiny app first.\n")
    dbDisconnect(con)
    return()
  }
  
  cat("Available Sites:\n")
  for (i in 1:nrow(sites)) {
    cat(sprintf("%d. %s - %s\n", i, sites$site_id[i], sites$location_name[i]))
  }
  
  # User input
  cat("\nEnter site number to generate labels for (or 'q' to quit): ")
  site_choice <- readline()
  
  if (tolower(site_choice) == "q") {
    dbDisconnect(con)
    return()
  }
  
  site_num <- as.numeric(site_choice)
  
  if (is.na(site_num) || site_num < 1 || site_num > nrow(sites)) {
    cat("Invalid choice.\n")
    dbDisconnect(con)
    return()
  }
  
  selected_site <- sites$site_id[site_num]
  
  # Get number of existing plants
  existing_plants <- dbGetQuery(con,
    paste0("SELECT MAX(CAST(SUBSTR(plant_id, -4) AS INTEGER)) as max_num 
            FROM Plants WHERE site_id = '", selected_site, "'")
  )
  
  max_existing <- if_else(is.na(existing_plants$max_num[1]), 0, existing_plants$max_num[1])
  
  cat(sprintf("\nExisting plants for %s: %d\n", selected_site, max_existing))
  cat(sprintf("Start label number (current: %d, press Enter for %d): ", max_existing + 1, max_existing + 1))
  start_input <- readline()
  start_num <- if_else(start_input == "", max_existing + 1, as.numeric(start_input))
  
  cat("Number of labels to generate (default 20): ")
  num_labels_input <- readline()
  num_labels <- if_else(num_labels_input == "", 20, as.numeric(num_labels_input))
  
  cat("\nGenerate format:\n1. PNG files (for direct printing)\n2. PDF sheet (4 per page)\nChoice (1-2): ")
  format_choice <- readline()
  
  end_num <- start_num + num_labels - 1
  
  cat(sprintf("\nGenerating %d labels for %s (P%04d - P%04d)...\n\n", 
              num_labels, selected_site, start_num, end_num))
  
  # Generate labels
  generated_count <- 0
  for (i in start_num:end_num) {
    plant_id <- sprintf("%s-P%04d", selected_site, i)
    
    # Check for duplicates
    dup_check <- dbGetQuery(con, 
      paste0("SELECT COUNT(*) as count FROM Plants WHERE plant_id = '", plant_id, "'"))
    
    if (dup_check$count[1] > 0) {
      cat("✗ Skip (duplicate):", plant_id, "\n")
      next
    }
    
    if (generate_label(plant_id, selected_site, i, LABELS_DIR, dpi = DPI)) {
      generated_count <- generated_count + 1
    }
  }
  
  # Generate PDF if requested
  if (format_choice == "2") {
    all_labels <- sprintf("%s-P%04d", selected_site, start_num:end_num)
    generate_pdf_sheet(all_labels, selected_site, LABELS_DIR)
  }
  
  dbDisconnect(con)
  
  cat(sprintf("\n✓ Successfully generated %d labels!\n", generated_count))
  cat(sprintf("Labels saved in: %s\n", LABELS_DIR))
  cat("Ready to print and stick on sample bags! 🏷️\n\n")
}

# Run interactive mode
interactive_mode()
