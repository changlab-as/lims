# Riverside Rhizobia LIMS Application
# Session-Based Batch Scanning Workflow for Hardware Barcode Scanners
# 
# State Machine:
# State 0 (Idle): Waiting for Equipment ID scan
# State 1 (Active): Locked to equipment, collecting plant ID scans
# Exit: Same equipment ID, FINISH barcode, or error

# Load required libraries
library(shiny)
library(bslib)
library(shinyjs)
library(DT)
library(RSQLite)
library(qrcode)
library(pool)
library(dplyr)
library(DBI)
library(gridExtra)
library(grid)
library(base64enc)
# Camera and audio libraries for mobile scanning
# Note: shinyScanner requires external dependencies
# Alternative: Using WebRTC via HTML5 camera API with JavaScript

# Create app directory for QR codes
if (!dir.exists("www")) {
  dir.create("www")
}

# Initialize Database
initialize_database <- function() {
  db_path <- "data/lims_db.sqlite"
  
  # Create data directory if it doesn't exist
  if (!dir.exists("data")) {
    dir.create("data")
  }
  
  # Connect to database
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Create Sites table (with migration for existing tables)
  # Drop and recreate Sites table to apply new schema
  dbExecute(con, "DROP TABLE IF EXISTS Sites")
  
  dbExecute(con, "
    CREATE TABLE Sites (
      site_id TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat TEXT,
      site_long TEXT
    )
  ")
  
  # Create Plants table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Plants (
      plant_id TEXT PRIMARY KEY,
      site_id TEXT NOT NULL,
      species TEXT NOT NULL,
      health_status TEXT,
      fridge_loc TEXT,
      date_created DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  # Create Processing table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Processing (
      proc_id TEXT PRIMARY KEY,
      plant_id TEXT NOT NULL,
      equipment_id TEXT,
      type TEXT NOT NULL,
      date DATETIME DEFAULT CURRENT_TIMESTAMP,
      technician TEXT,
      notes TEXT,
      FOREIGN KEY(plant_id) REFERENCES Plants(plant_id)
    )
  ")
  
  # Create Equipment table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Equipment (
      equipment_id TEXT PRIMARY KEY,
      character_name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      date_created DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  # Create Labels table for tracking generated QR code labels
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Labels (
      label_id TEXT PRIMARY KEY,
      stage INTEGER,
      site_id TEXT,
      sample_type TEXT,
      sample_id TEXT,
      part_code TEXT,
      part_id TEXT,
      use_code TEXT,
      sample_status TEXT DEFAULT 'label_created',
      storage_location TEXT,
      collected_date DATETIME,
      created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  # Seed equipment data if table is empty
  existing_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Equipment")
  if (existing_count$count[1] == 0) {
    equipment_data <- data.frame(
      equipment_id = c("U01", "Z01", "F01", "F02", "F03", "F04", "G01"),
      character_name = c("Totoro, in B16-1", "Jiji, -30°C in R100", "Teto, 4C in R100", 
                        "Warawara, the large 2-door in the kitchen", "Ponyo, the small 2-door in my office",
                        "Kodama, the fridge in the B05", "Laputa (Castle in the Sky)"),
      category = c("Ultra-Low Temperature (-80°C)", "Standard Freezers (-20°C to -30°C)", 
                   "Fridges (4C)", "Fridges (4C)", "Fridges (4C)", "Fridges (4C)", "Plant growth chamber"),
      description = c("Ultra-Low Freezer at -80C", "Freezer at -30C in R100", "Fridge at 4C in R100",
                      "Large 2-door refrigerator in the kitchen", "Small 2-door refrigerator in my office",
                      "Fridge in B05", "Plant growth chamber - Castle in the Sky")
    )
    dbAppendTable(con, "Equipment", equipment_data)
  }
  
  dbDisconnect(con)
  return(db_path)
}

# Initialize database on app start
db_path <- initialize_database()

# Create connection pool for efficient database handling
pool <- dbPool(
  drv = RSQLite::SQLite(),
  dbname = db_path,
  minSize = 1,
  maxSize = 5
)

# Helper function to generate sequenced IDs
generate_site_id <- function() {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Sites")
  poolReturn(con)
  count <- result$count[1] + 1
  sprintf("ST%04d", count)
}

generate_plant_id <- function(site_id) {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, 
    paste0("SELECT COUNT(*) as count FROM Plants WHERE site_id = '", site_id, "'"))
  poolReturn(con)
  count <- result$count[1] + 1
  sprintf("%s-P%04d", site_id, count)
}

# Check if plant_id already exists
check_duplicate_plant_id <- function(plant_id) {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, 
    paste0("SELECT COUNT(*) as count FROM Plants WHERE plant_id = '", plant_id, "'"))
  poolReturn(con)
  result$count[1] > 0
}


# ============================================================
# UI DEFINITION - Two-Tab Interface
# ============================================================

ui <- page(
  theme = bslib::bs_theme(),
  shinyjs::useShinyjs(),
  
  tags$head(
    # Audio functions
    tags$script(HTML("
      function playStartBeep() {
        var audio = new Audio('https://actions.google.com/sounds/v1/alarms/digital_alarm_clock.ogg');
        audio.volume = 0.8;
        audio.play().catch(e => console.log('Audio play failed:', e));
      }
      
      function playSuccessBeep() {
        var audio = new Audio('https://actions.google.com/sounds/v1/alarms/beep_short.ogg');
        audio.volume = 0.7;
        audio.play().catch(e => console.log('Audio play failed:', e));
      }
      
      function playErrorBeep() {
        var audio = new Audio('https://actions.google.com/sounds/v1/alarms/beep_error.ogg');
        audio.volume = 0.7;
        audio.play().catch(e => console.log('Audio play failed:', e));
      }
      
      // Force focus on scanner input every 2 seconds when on batch scanning tab
      setInterval(function() {
        var elem = document.getElementById('master_scanner_input');
        if (elem && document.activeElement !== elem && elem.offsetParent !== null) {
          elem.focus();
        }
      }, 2000);
    ")),
    
    tags$style(HTML("
      html, body {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        background: #f5f5f5;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      }
      
      /* Master scanner input - hidden but always active */
      #master_scanner_input {
        position: fixed;
        top: -9999px;
        left: -9999px;
        width: 1px;
        height: 1px;
        opacity: 0;
        pointer-events: none;
      }
      
      /* Batch Scanning Container */
      .batch-scanning-container {
        display: flex;
        flex-direction: column;
        height: 100vh;
        background: #FFFFFF;
      }
      
      /* Batch header */
      .batch-header {
        background: linear-gradient(135deg, #26A69A 0%, #00A19A 100%);
        color: white;
        padding: 30px 20px;
        text-align: center;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      }
      
      .batch-header h1 {
        font-size: 56px;
        margin: 0;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
      }
      
      /* Last scanned - massive display */
      .last-scanned-box {
        background: #f5f5f5;
        padding: 25px;
        text-align: center;
        border-bottom: 2px solid #ddd;
      }
      
      .last-scanned-box .label {
        font-size: 16px;
        color: #999;
        margin: 0;
      }
      
      .last-scanned-box .value {
        font-size: 72px;
        font-weight: 700;
        color: #00A19A;
        margin: 10px 0 0 0;
        font-family: 'Courier New', monospace;
        letter-spacing: 4px;
      }
      
      /* Batch list - scrollable */
      .batch-list-container {
        flex: 1;
        overflow-y: auto;
        padding: 20px;
      }
      
      .batch-item {
        background: white;
        border: 2px solid #ddd;
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 12px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        animation: slideIn 0.4s ease-out;
      }
      
      .batch-item.success {
        border-color: #26A69A;
        background: rgba(38, 166, 154, 0.05);
      }
      
      @keyframes slideIn {
        from {
          transform: translateY(20px);
          opacity: 0;
        }
        to {
          transform: translateY(0);
          opacity: 1;
        }
      }
      
      .batch-item-id {
        font-size: 24px;
        font-weight: 700;
        font-family: 'Courier New', monospace;
        color: #00A19A;
      }
      
      .batch-item-time {
        font-size: 14px;
        color: #999;
      }
      
      .batch-item-checkmark {
        font-size: 32px;
        color: #26A69A;
      }
      
      /* Batch counter */
      .batch-counter {
        background: white;
        border-top: 2px solid #ddd;
        padding: 20px;
        text-align: center;
      }
      
      .batch-counter .count {
        font-size: 48px;
        font-weight: 700;
        color: #00A19A;
        margin: 0;
      }
      
      .batch-counter .label {
        font-size: 16px;
        color: #999;
        margin: 5px 0 0 0;
      }
      
      /* Invalid/error warnings */
      .invalid-warning {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: #EF5350;
        color: white;
        padding: 40px;
        border-radius: 12px;
        text-align: center;
        z-index: 2000;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        animation: slideDown 0.3s ease-out;
        min-width: 80vw;
        max-width: 400px;
      }
      
      .invalid-warning h2 {
        font-size: 48px;
        margin: 0 0 15px 0;
      }
      
      .invalid-warning p {
        font-size: 24px;
        margin: 10px 0;
      }
      
      @keyframes slideDown {
        from {
          transform: translate(-50%, -150%);
          opacity: 0;
        }
        to {
          transform: translate(-50%, -50%);
          opacity: 1;
        }
      }
      
      /* Success flash */
      .success-flash {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(135deg, #26A69A 0%, #00A19A 100%);
        color: white;
        padding: 40px;
        border-radius: 12px;
        text-align: center;
        z-index: 2000;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        animation: successFlash 0.6s ease-in-out;
        min-width: 80vw;
        max-width: 400px;
      }
      
      .success-flash h2 {
        font-size: 48px;
        margin: 0 0 15px 0;
      }
      
      .success-flash p {
        font-size: 32px;
        margin: 10px 0;
        font-family: 'Courier New', monospace;
      }
      
      @keyframes successFlash {
        0% { transform: translate(-50%, -50%) scale(0.8); opacity: 0; }
        50% { transform: translate(-50%, -50%) scale(1.05); opacity: 1; }
        100% { transform: translate(-50%, -50%) scale(1); opacity: 0; }
      }
      
      /* Label generation tab styles */
      .label-gen-tab {
        padding: 20px 40px;
      }
      
      .label-gen-container {
        display: grid;
        grid-template-columns: 1fr 400px;
        gap: 30px;
      }
      
      .label-gen-inputs {
        flex: 1;
      }
      
      .label-gen-section {
        background: white;
        border: 2px solid #e0e0e0;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
      }
      
      .label-gen-section h4 {
        margin: 0 0 15px 0;
        color: #00A19A;
        font-weight: 700;
        font-size: 16px;
        display: flex;
        align-items: center;
      }
      
      .label-gen-section .section-num {
        background: #00A19A;
        color: white;
        border-radius: 50%;
        width: 28px;
        height: 28px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        margin-right: 12px;
        font-size: 14px;
      }
      
      .label-gen-example {
        background: #f5f5f5;
        padding: 12px;
        border-radius: 4px;
        font-family: 'Courier New', monospace;
        font-size: 14px;
        color: #00A19A;
        margin-top: 10px;
        font-weight: 700;
      }
      
      .reference-panel {
        background: white;
        border: 2px solid #ddd;
        border-radius: 8px;
        padding: 15px;
        position: sticky;
        top: 20px;
        max-height: 90vh;
        overflow-y: auto;
      }
      
      .reference-panel h4 {
        margin: 0 0 15px 0;
        font-size: 14px;
        font-weight: 700;
        color: #333;
        text-transform: uppercase;
        border-bottom: 2px solid #00A19A;
        padding-bottom: 10px;
      }
      
      .reference-section {
        margin-bottom: 18px;
      }
      
      .reference-section:last-child {
        margin-bottom: 0;
      }
      
      .reference-title {
        font-size: 12px;
        font-weight: 700;
        color: #00A19A;
        margin-bottom: 8px;
        text-transform: uppercase;
      }
      
      .reference-item {
        font-size: 12px;
        padding: 6px 0;
        border-bottom: 1px solid #f0f0f0;
        display: flex;
        justify-content: space-between;
      }
      
      .reference-item:last-child {
        border-bottom: none;
      }
      
      .reference-abbrev {
        font-weight: 700;
        color: #00A19A;
        font-family: 'Courier New', monospace;
        min-width: 35px;
      }
      
      .reference-desc {
        flex: 1;
        color: #666;
        margin-left: 8px;
        font-size: 11px;
      }
      
      .full-id-example {
        background: #e3f2fd;
        border-left: 4px solid #2196F3;
        padding: 12px;
        margin-top: 15px;
        border-radius: 4px;
        font-size: 12px;
      }
      
      .full-id-example .label {
        font-weight: 700;
        color: #1976D2;
      }
      
      .full-id-example .value {
        font-family: 'Courier New', monospace;
        font-weight: 700;
        color: #00A19A;
        margin-top: 6px;
      }
    "))
  ),
  
  # Hidden scanner input - only on batch scanning tab
  textInput(
    inputId = "master_scanner_input",
    label = NULL,
    placeholder = "Scanner input (hidden)",
    value = ""
  ),
  
  # Two-tab navigation
  navset_tab(
    nav_panel(
      "Batch Scanning",
      div(
        class = "batch-scanning-container",
        
        # Batch header
        div(
          class = "batch-header",
          h1(textOutput("batch_header_display"))
        ),
        
        # Last scanned display
        div(
          class = "last-scanned-box",
          p(class = "label", "Last Scanned:"),
          p(class = "value", textOutput("last_scanned_display"))
        ),
        
        # Batch list - growing in real-time
        div(
          class = "batch-list-container",
          uiOutput("batch_list_ui")
        ),
        
        # Batch counter at bottom
        div(
          class = "batch-counter",
          p(class = "count", textOutput("batch_count")),
          p(class = "label", "samples scanned")
        )
      ),
      
      # Invalid code warning (overlay)
      uiOutput("invalid_warning_ui"),
      
      # Success flash (overlay)
      uiOutput("success_flash_ui")
    ),
    
    nav_panel(
      "Create Site",
      div(
        class = "label-gen-tab",
        h2("Register New Sampling Site"),
        h4(style = "color: #666; margin: 0 0 30px 0;", "Two-step process: Create before field trip, add coordinates after"),
        
        # ============ STEP 1: Create Site (ID + Description) ============
        div(
          class = "label-gen-section",
          style = "background: #e8f5e9; border-left: 6px solid #4caf50; margin-bottom: 30px;",
          h3(style = "margin: 0 0 15px 0; color: #2e7d32;", "① Before Field Trip: Create Site"),
          p(style = "color: #666; font-size: 13px; margin: 0 0 15px 0;",
            "Create sampling site with ID and description. Coordinates added later after GPS data collection."
          ),
          
          div(
            style = "display: grid; grid-template-columns: 1fr 3fr; gap: 30px;",
            
            # Left: Create site form
            div(
              div(
                style = "background: white; border: 2px solid #c8e6c9; border-radius: 8px; padding: 20px;",
                h5(style = "color: #2e7d32; margin: 0 0 15px 0;", "️New Site"),
                
                textInput(
                  inputId = "create_site_id",
                  label = "Site ID",
                  placeholder = "e.g., ST0001",
                  width = "100%"
                ),
                
                p(style = "color: #999; font-size: 12px; margin: 5px 0 15px 0;",
                  "Format: ST + 4 digits"
                ),
                
                textAreaInput(
                  inputId = "create_site_description",
                  label = "Site Description",
                  placeholder = "Field location, region, habitat, etc.",
                  rows = 4,
                  width = "100%"
                ),
                
                p(style = "color: #999; font-size: 12px; margin: 5px 0 20px 0;",
                  "Describe the location and any relevant details"
                ),
                
                actionButton(
                  "btn_create_site",
                  "✓ Create Site",
                  class = "btn btn-success btn-lg",
                  style = "width: 100%; padding: 12px; font-size: 16px;"
                ),
                
                br(), br(),
                
                uiOutput("create_site_status")
              )
            ),
            
            # Right: Existing sites table
            div(
              h4(style = "margin: 0 0 15px 0; color: #2e7d32; font-weight: 700;", "📍 Your Sites"),
              div(
                style = "background: white; border: 2px solid #e0e0e0; border-radius: 8px; padding: 15px; max-height: 55vh; overflow-y: auto;",
                DT::dataTableOutput("existing_sites_table", height = "100%")
              )
            )
          )
        ),
        
        # ============ STEP 2: Add Coordinates (After GPS Collection) ============
        div(
          class = "label-gen-section",
          style = "background: #fff3e0; border-left: 6px solid #ff9800;",
          h3(style = "margin: 0 0 15px 0; color: #e65100;", "② After Field Trip: Add Coordinates"),
          p(style = "color: #666; font-size: 13px; margin: 0 0 15px 0;",
            "Add GPS coordinates from your Garmin device for sites created above."
          ),
          
          div(
            style = "display: grid; grid-template-columns: 1fr 1fr; gap: 30px;",
            
            # Left: Add coordinates form
            div(
              div(
                style = "background: white; border: 2px solid #ffe0b2; border-radius: 8px; padding: 20px;",
                h5(style = "color: #e65100; margin: 0 0 15px 0;", "🗺️ Add GPS Data"),
                
                selectInput(
                  inputId = "add_coord_site_id",
                  label = "Select Site to Update",
                  choices = c("Select..." = ""),
                  width = "100%"
                ),
                
                p(style = "color: #999; font-size: 12px; margin: 5px 0 15px 0;",
                  "Only shows sites without coordinates"
                ),
                
                textInput(
                  inputId = "add_coord_latitude",
                  label = "Latitude",
                  placeholder = "e.g., 37.7749",
                  width = "100%"
                ),
                
                textInput(
                  inputId = "add_coord_longitude",
                  label = "Longitude",
                  placeholder = "e.g., -122.4194",
                  width = "100%"
                ),
                
                p(style = "color: #999; font-size: 12px; margin: 10px 0 15px 0;",
                  "From Garmin GPS data. Lat: -90 to 90, Lon: -180 to 180"
                ),
                
                actionButton(
                  "btn_add_coord",
                  "✓ Add Coordinates",
                  class = "btn btn-warning btn-lg",
                  style = "width: 100%; padding: 12px; font-size: 16px; color: white;"
                ),
                
                br(), br(),
                
                uiOutput("add_coord_status")
              )
            ),
            
            # Right: Sites needing coordinates
            div(
              h5(style = "color: #e65100; margin: 0 0 15px 0;", "⚠️ Sites Needing Coordinates"),
              p(style = "color: #999; font-size: 12px; margin: 0 0 15px 0;",
                "These sites were created but don't have GPS coordinates yet"
              ),
              div(
                style = "background: white; border: 2px solid #ffe0b2; border-radius: 8px; padding: 15px; max-height: 40vh; overflow-y: auto; min-height: 250px;",
                uiOutput("sites_needing_coords_list")
              )
            )
          )
        )
      )
    ),
    
    nav_panel(
      "Generate Labels",
      div(
        class = "label-gen-tab",
        h2("🏷️ Label Generation Workflow"),
        p(style = "color: #666; font-size: 14px; margin: 0 0 30px 0;",
          "Three-stage workflow: Pre-Sampling → Parts Processing → Sample Use"
        ),
        
        # ============ STAGE 1: PRE-SAMPLING LABELS ============
        div(
          class = "label-gen-section",
          style = "background: #e8f5e9; border-left: 6px solid #4caf50;",
          h3(style = "margin: 0 0 15px 0; color: #2e7d32;", "① PRE-FIELD SAMPLING"),
          p(style = "color: #666; font-size: 13px; margin: 0 0 15px 0;",
            "Generate labels BEFORE field sampling (2-segment IDs: Site + Sample Number)"
          ),
          
          div(
            style = "display: grid; grid-template-columns: 1fr 1fr; gap: 15px;",
            
            # Plant samples
            div(
              style = "border: 2px solid #26A69A; border-radius: 8px; padding: 15px; background: white;",
              h5(style = "margin: 0 0 12px 0; color: #00A19A; font-weight: 700;", "🌱 Plant Samples"),
              selectInput(
                inputId = "presamp_site_plant",
                label = "Site",
                choices = c("Select..." = ""),
                width = "100%"
              ),
              sliderInput(
                inputId = "presamp_plant_count",
                label = "Number of samples",
                min = 1,
                max = 20,
                value = 5,
                step = 1,
                width = "100%"
              ),
              dateInput(
                inputId = "presamp_plant_date",
                label = "Label Date",
                value = Sys.Date(),
                width = "100%"
              ),
              actionButton(
                "btn_presamp_plant",
                "Generate Plant Sample Labels",
                class = "btn btn-success btn-block",
                style = "width: 100%; margin-top: 12px;"
              ),
              div(class = "label-gen-example", "Example: ST0001-P0001")
            ),
            
            # Soil samples
            div(
              style = "border: 2px solid #FF9800; border-radius: 8px; padding: 15px; background: white;",
              h5(style = "margin: 0 0 12px 0; color: #FF9800; font-weight: 700;", "🌍 Soil Samples"),
              selectInput(
                inputId = "presamp_site_soil",
                label = "Site",
                choices = c("Select..." = ""),
                width = "100%"
              ),
              sliderInput(
                inputId = "presamp_soil_count",
                label = "Number of samples",
                min = 0,
                max = 20,
                value = 0,
                step = 1,
                width = "100%"
              ),
              dateInput(
                inputId = "presamp_soil_date",
                label = "Label Date",
                value = Sys.Date(),
                width = "100%"
              ),
              actionButton(
                "btn_presamp_soil",
                "Generate Soil Sample Labels",
                class = "btn btn-warning btn-block",
                style = "width: 100%; margin-top: 12px; color: white;"
              ),
              div(class = "label-gen-example", "Example: ST0001-S0001")
            )
          ),
          
          uiOutput("presamp_status")
        ),
        
        br(),
        
        # ============ STAGE 2: PARTS PROCESSING LABELS ============
        div(
          class = "label-gen-section",
          style = "background: #fff3e0; border-left: 6px solid #ff9800;",
          h3(style = "margin: 0 0 15px 0; color: #e65100;", "② PROCESS INTO PARTS"),
          p(style = "color: #666; font-size: 13px; margin: 0 0 15px 0;",
            "Generate labels before processing samples into individual parts (3-segment IDs: Site + Sample + Part)"
          ),
          
          # Sample ID input with autocomplete
          fluidRow(
            column(6,
              selectInput(
                inputId = "parts_sample_id",
                label = "Sample ID to process",
                choices = c("Select collected sample..." = ""),
                width = "100%"
              ),
              p(style = "color: #999; font-size: 12px; margin: 5px 0 0 0;",
                "Only shows collected/processed 2-segment samples"
              )
            ),
            column(6,
              p(style = "color: #999; font-size: 12px; margin: 0 0 8px 0; font-weight: 700;", "Part Quantities:"),
              fluidRow(
                column(3,
                  div(
                    style = "border: 1px solid #ddd; border-radius: 6px; padding: 10px; text-align: center;",
                    h6(style = "margin: 0 0 6px 0; color: #00A19A; font-size: 12px;", "SH"),
                    numericInput(inputId = "parts_sh_count", label = NULL, value = 0, min = 0, width = "100%")
                  )
                ),
                column(3,
                  div(
                    style = "border: 1px solid #ddd; border-radius: 6px; padding: 10px; text-align: center;",
                    h6(style = "margin: 0 0 6px 0; color: #00A19A; font-size: 12px;", "RT"),
                    numericInput(inputId = "parts_rt_count", label = NULL, value = 0, min = 0, width = "100%")
                  )
                ),
                column(3,
                  div(
                    style = "border: 1px solid #ddd; border-radius: 6px; padding: 10px; text-align: center;",
                    h6(style = "margin: 0 0 6px 0; color: #00A19A; font-size: 12px;", "ND"),
                    numericInput(inputId = "parts_nd_count", label = NULL, value = 0, min = 0, width = "100%")
                  )
                ),
                column(3,
                  div(
                    style = "border: 1px solid #ddd; border-radius: 6px; padding: 10px; text-align: center;",
                    h6(style = "margin: 0 0 6px 0; color: #00A19A; font-size: 12px;", "LF"),
                    numericInput(inputId = "parts_lf_count", label = NULL, value = 0, min = 0, width = "100%")
                  )
                )
              )
            )
          ),
          
          # Date input below
          dateInput(
            inputId = "parts_date",
            label = "Label Date",
            value = Sys.Date(),
            width = "100%"
          ),
          
          br(),
          
          actionButton(
            "btn_parts_generate",
            "Generate Part Labels",
            class = "btn btn-primary btn-lg",
            style = "width: 100%; padding: 12px; font-size: 16px;"
          ),
          
          div(class = "label-gen-example", 
            "Example: ST0001-P0001-SH001, ST0001-P0001-SH002, ST0001-P0001-RT001, etc."
          ),
          
          uiOutput("parts_status")
        ),
        
        br(),
        
        # ============ STAGE 3: SAMPLE USE LABELS ============
        div(
          class = "label-gen-section",
          style = "background: #e3f2fd; border-left: 6px solid #2196f3;",
          h3(style = "margin: 0 0 15px 0; color: #0d47a1;", "③ SAMPLE USE/PURPOSE"),
          p(style = "color: #666; font-size: 13px; margin: 0 0 15px 0;",
            "Generate full labels for use processing (4-segment IDs: Site + Sample + Part + Use)"
          ),
          
          fluidRow(
            column(6,
              textInput(
                inputId = "use_part_id",
                label = "Part ID to process",
                placeholder = "e.g., ST0001-P0001-SH001",
                width = "100%"
              ),
              
              p(style = "color: #999; font-size: 12px; margin: 5px 0 15px 0;",
                "Enter the 3-segment part ID from previous stage"
              )
            ),
            column(6,
              dateInput(
                inputId = "use_date",
                label = "Label Date",
                value = Sys.Date(),
                width = "100%"
              )
            )
          ),
          
          p(style = "color: #999; font-size: 12px; margin: 10px 0 15px 0;",
            "Specify quantities for each use type:"
          ),
          
          fluidRow(
            column(3,
              div(
                style = "border: 1px solid #ddd; border-radius: 6px; padding: 12px; text-align: center;",
                h6(style = "margin: 0 0 8px 0; color: #1976D2;", "GW (Growth)"),
                numericInput(inputId = "use_gw_count", label = NULL, value = 0, min = 0, width = "100%")
              )
            ),
            column(3,
              div(
                style = "border: 1px solid #ddd; border-radius: 6px; padding: 12px; text-align: center;",
                h6(style = "margin: 0 0 8px 0; color: #1976D2;", "DE (DNA)"),
                numericInput(inputId = "use_de_count", label = NULL, value = 0, min = 0, width = "100%")
              )
            ),
            column(3,
              div(
                style = "border: 1px solid #ddd; border-radius: 6px; padding: 12px; text-align: center;",
                h6(style = "margin: 0 0 8px 0; color: #1976D2;", "RE (RNA)"),
                numericInput(inputId = "use_re_count", label = NULL, value = 0, min = 0, width = "100%")
              )
            ),
            column(3,
              div(
                style = "border: 1px solid #ddd; border-radius: 6px; padding: 12px; text-align: center;",
                h6(style = "margin: 0 0 8px 0; color: #1976D2;", "IS/GS"),
                numericInput(inputId = "use_other_count", label = NULL, value = 0, min = 0, width = "100%")
              )
            )
          ),
          
          br(),
          
          actionButton(
            "btn_use_generate",
            "Generate Use Labels",
            class = "btn btn-primary btn-lg",
            style = "width: 100%; padding: 12px; font-size: 16px;"
          ),
          
          div(class = "label-gen-example", 
            "Example: ST0001-P0001-SH001-GW01, ST0001-P0001-SH001-DE01, etc."
          ),
          
          uiOutput("use_status")
        ),
        
        br()
      )
    ),
    
    # ============ INVENTORY TAB ============
    nav_panel(
      "Inventory",
      div(
        class = "label-gen-tab",
        h2("📦 Sample Inventory & Status"),
        p(style = "color: #666; font-size: 14px; margin: 0 0 20px 0;",
          "Track sample processing status from field collection through sample use"
        ),
        
        div(
          style = "display: flex; gap: 15px; margin-bottom: 20px;",
          div(style = "background: #e8f5e9; padding: 12px 15px; border-radius: 6px; flex: 1;",
            div(style = "font-size: 12px; color: #666;", "Samples with labels"),
            div(style = "font-size: 24px; font-weight: 700; color: #2e7d32;", textOutput("inventory_total_count"))
          ),
          div(style = "background: #fff3e0; padding: 12px 15px; border-radius: 6px; flex: 1;",
            div(style = "font-size: 12px; color: #666;", "Processing stage"),
            div(style = "font-size: 18px; font-weight: 700; color: #e65100;", "Multi-level")
          ),
          div(style = "background: #e3f2fd; padding: 12px 15px; border-radius: 6px; flex: 1;",
            div(style = "font-size: 12px; color: #666;", "Overall Status"),
            div(style = "font-size: 18px; font-weight: 700; color: #0d47a1;", "Active")
          )
        ),
        
        # Inventory table with hierarchical view
        div(
          style = "background: white; border: 2px solid #e0e0e0; border-radius: 8px; padding: 20px;",
          
          # Search and filter controls
          fluidRow(
            column(6,
              textInput(
                inputId = "inventory_search",
                label = "Search by Site or Sample ID",
                placeholder = "e.g., ST0001 or ST0001-P0001",
                width = "100%"
              )
            ),
            column(6,
              selectInput(
                inputId = "inventory_status_filter",
                label = "Filter by Status",
                choices = c("All" = "", "Created" = "created", "Stored" = "stored", 
                           "Processing" = "processing", "Complete" = "complete"),
                width = "100%"
              )
            )
          ),
          
          br(),
          
          # Inventory table
          DT::dataTableOutput("inventory_table", height = "auto")
        )
      )
    )
  )
)

# ============================================================
# SERVER LOGIC
# ============================================================

server <- function(input, output, session) {
  
  # Initialize batch scanning state
  batch_state <- reactiveValues(
    batch_samples = character(),
    last_scanned = "",
    show_invalid = FALSE,
    invalid_code = "",
    show_success = FALSE,
    show_success_code = ""
  )
  
  # Plant ID regex pattern - foolproof validation
  plant_id_pattern <- "^ST\\d{4}-P\\d{4}$"
  
  # ============================================================
  # BATCH SCANNING TAB
  # ============================================================
  
  # Update site choices on load and when sites change
  observe({
    # Trigger on site creation or coordinate addition
    input$btn_create_site
    input$btn_add_coord
    
    con <- poolCheckout(pool)
    sites <- dbGetQuery(con, "SELECT site_id FROM Sites ORDER BY site_id")
    poolReturn(con)
    
    if (nrow(sites) > 0) {
      site_choices <- c("Select a site" = "", setNames(sites$site_id, sites$site_id))
      updateSelectInput(session, "label_site_select", choices = site_choices)
      updateSelectInput(session, "presamp_site_plant", choices = site_choices)
      updateSelectInput(session, "presamp_site_soil", choices = site_choices)
    }
  })
  
  # Update sites needing coordinates dropdown
  observe({
    input$btn_create_site
    input$btn_add_coord
    
    con <- poolCheckout(pool)
    # Sites without coordinates (site_lat is NULL)
    sites_needing <- dbGetQuery(con, 
      "SELECT site_id FROM Sites WHERE site_lat IS NULL OR site_lat = '' ORDER BY site_id"
    )
    poolReturn(con)
    
    if (nrow(sites_needing) > 0) {
      site_choices <- c("Select..." = "", setNames(sites_needing$site_id, sites_needing$site_id))
      updateSelectInput(session, "add_coord_site_id", choices = site_choices)
    } else {
      updateSelectInput(session, "add_coord_site_id", choices = c("Select..." = ""))
    }
  })
  
  # Generate sites needing coordinates list
  output$sites_needing_coords_list <- renderUI({
    input$btn_create_site
    input$btn_add_coord
    
    con <- poolCheckout(pool)
    sites_needing <- dbGetQuery(con, 
      "SELECT site_id, site_name FROM Sites WHERE site_lat IS NULL OR site_lat = '' ORDER BY site_id"
    )
    poolReturn(con)
    
    if (nrow(sites_needing) > 0) {
      div(
        lapply(1:nrow(sites_needing), function(i) {
          div(
            style = "padding: 12px; border-bottom: 1px solid #f0f0f0; font-size: 13px;",
            div(style = "font-weight: 700; color: #e65100;", sites_needing$site_id[i]),
            div(style = "color: #999; font-size: 12px; margin-top: 4px;", sites_needing$site_name[i])
          )
        })
      )
    } else {
      div(
        style = "padding: 20px; text-align: center; color: #4caf50;",
        p(style = "font-size: 14px; font-weight: 700;", "✓ All sites have coordinates!"),
        p(style = "font-size: 12px; color: #999;", "Ready to generate labels.")
      )
    }
  })
  
  # Master scanner input handler - foolproof plant ID validation
  observeEvent(input$master_scanner_input, {
    scan_input <- trimws(input$master_scanner_input)
    
    if (nchar(scan_input) == 0) return()
    
    # Handle multi-line input
    scans <- strsplit(scan_input, "\n")[[1]]
    
    for (scan in scans) {
      scan <- trimws(scan)
      if (nchar(scan) == 0) next
      
      # Check for exit code
      if (scan == "FINISH" || scan == "EXIT") {
        # Reset batch
        batch_state$batch_samples <- character()
        batch_state$last_scanned <- ""
        shinyjs::runjs("playStartBeep();")
        batch_state$show_success <- TRUE
        batch_state$show_success_code <- "SESSION ENDED"
        shinyjs::delay(600, {
          batch_state$show_success <- FALSE
        })
        next
      }
      
      # Validate plant ID format (FOOLPROOF)
      if (grepl(plant_id_pattern, scan)) {
        # Check if plant exists in database (FOOLPROOF)
        con <- poolCheckout(pool)
        plant_check <- dbGetQuery(con, 
          paste0("SELECT * FROM Plants WHERE plant_id = '", scan, "'"))
        poolReturn(con)
        
        if (nrow(plant_check) > 0) {
          # Valid plant - save to Processing table
          save_batch_scan(scan)
          
          # Add to batch list
          batch_state$batch_samples <- c(scan, batch_state$batch_samples)
          batch_state$last_scanned <- scan
          
          # Show success
          batch_state$show_success <- TRUE
          batch_state$show_success_code <- scan
          shinyjs::runjs("playSuccessBeep();")
          
          shinyjs::delay(600, {
            batch_state$show_success <- FALSE
          })
        } else {
          # Plant format valid but not in database
          batch_state$show_invalid <- TRUE
          batch_state$invalid_code <- paste(scan, "\n(not found)")
          shinyjs::runjs("playErrorBeep();")
          
          shinyjs::delay(1500, {
            batch_state$show_invalid <- FALSE
          })
        }
      } else {
        # Invalid plant ID format
        batch_state$show_invalid <- TRUE
        batch_state$invalid_code <- scan
        shinyjs::runjs("playErrorBeep();")
        
        shinyjs::delay(1500, {
          batch_state$show_invalid <- FALSE
        })
      }
    }
    
    # Clear input for next scan
    shinyjs::runjs("document.getElementById('master_scanner_input').value = '';")
  }, priority = 10)
  
  # Database operation to save batch scan
  save_batch_scan <- function(plant_id) {
    con <- poolCheckout(pool)
    
    proc_id <- generate_proc_id()
    dbExecute(con,
      "INSERT INTO Processing (proc_id, plant_id, type, date, notes) 
       VALUES (?, ?, ?, datetime('now'), ?)",
      params = list(
        proc_id,
        plant_id,
        "Batch_Scan",
        "Batch scanned"
      )
    )
    
    poolReturn(con)
  }
  
  # Batch scanning outputs
  output$batch_header_display <- renderText({
    "🔖 BATCH SCANNER"
  })
  
  output$last_scanned_display <- renderText({
    if (nchar(batch_state$last_scanned) > 0) {
      batch_state$last_scanned
    } else {
      "waiting..."
    }
  })
  
  output$batch_list_ui <- renderUI({
    if (length(batch_state$batch_samples) > 0) {
      lapply(seq_along(batch_state$batch_samples), function(i) {
        sample_id <- batch_state$batch_samples[i]
        time_str <- format(Sys.time(), "%H:%M:%S")
        
        div(
          class = "batch-item success",
          div(
            div(class = "batch-item-id", sample_id),
            div(class = "batch-item-time", time_str)
          ),
          div(class = "batch-item-checkmark", "✓")
        )
      })
    } else {
      div(
        style = "text-align: center; color: #999; margin-top: 40px; font-size: 18px;",
        "Ready to scan samples..."
      )
    }
  })
  
  output$batch_count <- renderText({
    length(batch_state$batch_samples)
  })
  
  output$invalid_warning_ui <- renderUI({
    if (batch_state$show_invalid) {
      div(
        class = "invalid-warning",
        h2("❌ INVALID"),
        p(batch_state$invalid_code),
        p(style = "font-size: 16px; margin-top: 20px;", "Code not recognized")
      )
    }
  })
  
  output$success_flash_ui <- renderUI({
    if (batch_state$show_success) {
      div(
        class = "success-flash",
        h2("✓ SUCCESS"),
        p(batch_state$show_success_code)
      )
    }
  })
  
  # Keep scanner input focused when on batch scanning tab
  observe({
    shinyjs::runjs("
      var elem = document.getElementById('master_scanner_input');
      if (elem && elem.offsetParent !== null) {
        elem.focus();
      }
    ")
  })
  
  # ============================================================
  # CREATE SITE TAB
  # ============================================================
  
  observeEvent(input$btn_create_site, {
    tryCatch({
      # Validate site ID format
      if (is.null(input$create_site_id) || input$create_site_id == "") {
        showNotification("❌ Please enter a Site ID", type = "error", duration = 5)
        return()
      }
      
      # Validate site ID format (ST + 4 digits)
      if (!grepl("^ST\\d{4}$", input$create_site_id)) {
        showNotification("❌ Site ID must be in format: ST0001, ST0002, etc.", type = "error", duration = 5)
        return()
      }
      
      site_id <- input$create_site_id
      description <- input$create_site_description
      
      if (is.null(description)) description <- ""
      
      # Check for duplicates
      con <- poolCheckout(pool)
      existing <- dbGetQuery(con, 
        paste0("SELECT * FROM Sites WHERE site_id = '", site_id, "'"))
      
      if (nrow(existing) > 0) {
        poolReturn(con)
        showNotification(
          paste("❌ Site", site_id, "already exists"),
          type = "error",
          duration = 5
        )
        return()
      }
      
      # Insert new site without coordinates (Step 1 - before field trip)
      dbExecute(con,
        "INSERT INTO Sites (site_id, site_name, site_lat, site_long) 
         VALUES (?, ?, NULL, NULL)",
        params = list(site_id, description)
      )
      
      poolReturn(con)
      
      # Show success
      output$create_site_status <- renderUI({
        div(
          style = "padding: 20px; background: #e8f5e9; border-radius: 8px; border-left: 4px solid #4caf50;",
          h4("✓ Site Created Successfully"),
          p(strong("Site ID:"), site_id),
          p(strong("Description:"), description),
          p(style = "margin-top: 15px; color: #666; font-size: 13px;",
            "Next step: After collecting GPS data, go to Step 2 to add coordinates."
          )
        )
      })
      
      # Clear inputs - use reset() method
      shinyjs::runjs("document.getElementById('create_site_id').value = '';")
      shinyjs::runjs("document.getElementById('create_site_description').value = '';")
      
      showNotification(paste("✓ Site", site_id, "created successfully!"), type = "message", duration = 5)
      
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # ADD COORDINATES TAB
  # ============================================================
  
  observeEvent(input$btn_add_coord, {
    tryCatch({
      # Validate site selection
      if (is.null(input$add_coord_site_id) || input$add_coord_site_id == "") {
        showNotification("❌ Please select a site", type = "error", duration = 5)
        return()
      }
      
      # Validate latitude
      if (is.null(input$add_coord_latitude) || input$add_coord_latitude == "") {
        showNotification("❌ Please enter latitude", type = "error", duration = 5)
        return()
      }
      
      # Validate longitude
      if (is.null(input$add_coord_longitude) || input$add_coord_longitude == "") {
        showNotification("❌ Please enter longitude", type = "error", duration = 5)
        return()
      }
      
      # Parse and validate coordinates
      lat <- tryCatch(as.numeric(input$add_coord_latitude), error = function(e) NA)
      lon <- tryCatch(as.numeric(input$add_coord_longitude), error = function(e) NA)
      
      if (is.na(lat) || is.na(lon)) {
        showNotification("❌ Latitude and Longitude must be valid numbers", type = "error", duration = 5)
        return()
      }
      
      if (lat < -90 || lat > 90) {
        showNotification("❌ Latitude must be between -90 and 90", type = "error", duration = 5)
        return()
      }
      
      if (lon < -180 || lon > 180) {
        showNotification("❌ Longitude must be between -180 and 180", type = "error", duration = 5)
        return()
      }
      
      site_id <- input$add_coord_site_id
      
      # Update site with coordinates
      con <- poolCheckout(pool)
      dbExecute(con,
        "UPDATE Sites SET site_lat = ?, site_long = ? WHERE site_id = ?",
        params = list(lat, lon, site_id)
      )
      poolReturn(con)
      
      # Show success
      output$add_coord_status <- renderUI({
        div(
          style = "padding: 20px; background: #fff3cd; border-radius: 8px; border-left: 4px solid #ffc107;",
          h4("✓ Coordinates Added"),
          p(strong("Site ID:"), site_id),
          p(strong("Latitude:"), lat),
          p(strong("Longitude:"), lon),
          p(style = "margin-top: 15px; color: #666; font-size: 13px;",
            "Site is now ready for label generation."
          )
        )
      })
      
      # Clear inputs
      shinyjs::runjs("document.getElementById('add_coord_latitude').value = '';")
      shinyjs::runjs("document.getElementById('add_coord_longitude').value = '';")
      
      showNotification(paste("✓ Coordinates added for", site_id), type = "message", duration = 5)
      
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Render existing sites table with proper formatting
  output$existing_sites_table <- DT::renderDataTable({
    # Reactive trigger
    input$btn_create_site
    input$btn_add_coord
    
    con <- poolCheckout(pool)
    sites_data <- dbGetQuery(con, "SELECT site_id as 'Site ID', site_name as 'Site Name', site_lat as 'Latitude', site_long as 'Longitude' FROM Sites ORDER BY site_id")
    poolReturn(con)
    
    # Add icon for coordinate status
    if (nrow(sites_data) > 0) {
      sites_data$'Coordinates' <- sapply(1:nrow(sites_data), function(i) {
        if (is.na(sites_data[i, 'Latitude']) || sites_data[i, 'Latitude'] == '') {
          "⚠️ Missing"
        } else {
          "✓ Added"
        }
      })
    }
    
    datatable(sites_data,
      options = list(
        pageLength = 10,
        searching = TRUE,
        ordering = TRUE,
        paging = TRUE,
        scrollY = "400px",
        dom = 'lfrtip'
      ),
      rownames = FALSE,
      selection = 'none'
    )
  }, server = TRUE)
  
  # ============================================================
  # LABEL GENERATION TAB
  # ============================================================
  
  # Generate plant labels button
  # ============ STAGE 1: PRE-SAMPLING LABELS ============
  
  observeEvent(input$btn_presamp_plant, {
    generate_presamp_labels("P", "plant")
  })
  
  observeEvent(input$btn_presamp_soil, {
    generate_presamp_labels("S", "soil")
  })
  
  generate_presamp_labels <- function(sample_type, sample_type_name) {
    # Validation
    site_id <- if (sample_type == "P") input$presamp_site_plant else input$presamp_site_soil
    quantity <- if (sample_type == "P") input$presamp_plant_count else input$presamp_soil_count
    label_date <- if (sample_type == "P") input$presamp_plant_date else input$presamp_soil_date
    
    if (site_id == "") {
      showNotification("❌ Please select a site", type = "error")
      return()
    }
    
    if (quantity < 1) {
      showNotification(paste("❌ Please enter at least 1 sample"), type = "error")
      return()
    }
    
    # Show progress
    output$presamp_status <- renderUI({
      div(
        style = "padding: 15px; background: #e3f2fd; border-radius: 6px; margin-top: 15px;",
        p("🔄 Generating labels...")
      )
    })
    
    tryCatch({
      labels_dir <- "data/labels"
      if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
      
      con <- poolCheckout(pool)
      
      generated_labels <- character()
      
      for (i in 1:quantity) {
        sample_num <- sprintf("%04d", i)
        full_id <- sprintf("%s-%s%s", site_id, sample_type, sample_num)
        
        # Check duplicate
        dup_check <- dbGetQuery(con, 
          paste0("SELECT label_id FROM Labels WHERE label_id = '", full_id, "'"))
        
        if (nrow(dup_check) > 0) {
          showNotification(paste("⚠️", full_id, "already exists - skipping"), type = "warning")
          next
        }
        
        # Generate QR code
        label_file <- file.path(labels_dir, paste0(full_id, ".png"))
        set.seed(as.integer(charToRaw(full_id)) %% 2147483647)
        qr_obj <- qr_code(full_id)
        temp_qr_file <- tempfile(fileext = ".png")
        png(temp_qr_file, width = 400, height = 400, bg = "white")
        plot(qr_obj)
        dev.off()
        qr_img <- png::readPNG(temp_qr_file)
        
        # Create label with selected date
        png(label_file, width = 1800, height = 600, res = 150, bg = "white")
        grid.newpage()
        grid.text(full_id, x = 0.27, y = 0.75, 
          gp = gpar(fontsize = 44, fontface = "bold", family = "monospace"), just = "centre")
        grid.text(as.character(label_date), x = 0.27, y = 0.25,
          gp = gpar(fontsize = 40, fontface = "bold", family = "monospace"), just = "centre")
        
        # QR code viewport: fixed square aspect ratio (576x576 px on 1800x600 label)
        qr_vp <- viewport(x = 0.75, y = 0.5, width = 0.32, height = 0.96)
        pushViewport(qr_vp)
        grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
        popViewport()
        dev.off()
        unlink(temp_qr_file)
        
        generated_labels <- c(generated_labels, full_id)
        
        dbExecute(con, "INSERT INTO Labels (label_id, stage, site_id, sample_type, created_date)
          VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)",
          params = list(full_id, 1, site_id, sample_type))
      }
      
      poolReturn(con)
      
      icon_emoji <- if (sample_type == "P") "🌱" else "🌍"
      output$presamp_status <- renderUI({
        div(
          style = "padding: 15px; background: #e8f5e9; border-radius: 6px; margin-top: 15px; border-left: 4px solid #4caf50;",
          h5(paste("✓", icon_emoji, length(generated_labels), "pre-sampling labels generated")),
          p(strong("IDs:"), paste(generated_labels[1:min(3, length(generated_labels))], collapse = ", "),
            if (length(generated_labels) > 3) paste0(", ..."))
        )
      })
      
      showNotification(paste("✓", length(generated_labels), "labels generated!"), type = "message")
      
    }, error = function(e) {
      tryCatch(poolReturn(con), error = function(e2) {})
      output$presamp_status <- renderUI({
        div(
          style = "padding: 15px; background: #ffebee; border-radius: 6px; margin-top: 15px;",
          p("❌ Error:", e$message)
        )
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  }
  
  # ============ STAGE 2: PARTS PROCESSING LABELS ============
  
  observeEvent(input$btn_parts_generate, {
    generate_parts_labels()
  })
  
  generate_parts_labels <- function() {
    sample_id <- input$parts_sample_id
    label_date <- input$parts_date
    
    if (sample_id == "") {
      showNotification("❌ Please enter a sample ID (e.g., ST0001-P0001)", type = "error")
      return()
    }
    
    parts <- list(
      SH = input$parts_sh_count,
      RT = input$parts_rt_count,
      ND = input$parts_nd_count,
      LF = input$parts_lf_count
    )
    
    total_parts <- sum(unlist(parts))
    if (total_parts < 1) {
      showNotification("❌ Please specify at least 1 part", type = "error")
      return()
    }
    
    output$parts_status <- renderUI({
      div(
        style = "padding: 15px; background: #e3f2fd; border-radius: 6px; margin-top: 15px;",
        p("🔄 Generating part labels...")
      )
    })
    
    tryCatch({
      labels_dir <- "data/labels"
      if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
      
      con <- poolCheckout(pool)
      generated_labels <- character()
      
      for (part_code in names(parts)) {
        count <- parts[[part_code]]
        if (count < 1) next
        
        for (i in 1:count) {
          part_num <- sprintf("%03d", i)
          full_id <- sprintf("%s-%s%s", sample_id, part_code, part_num)
          
          dup_check <- dbGetQuery(con, 
            paste0("SELECT label_id FROM Labels WHERE label_id = '", full_id, "'"))
          
          if (nrow(dup_check) > 0) {
            showNotification(paste("⚠️", full_id, "already exists - skipping"), type = "warning")
            next
          }
          
          label_file <- file.path(labels_dir, paste0(full_id, ".png"))
          set.seed(as.integer(charToRaw(full_id)) %% 2147483647)
          qr_obj <- qr_code(full_id)
          temp_qr_file <- tempfile(fileext = ".png")
          png(temp_qr_file, width = 400, height = 400, bg = "white")
          plot(qr_obj)
          dev.off()
          qr_img <- png::readPNG(temp_qr_file)
          
          png(label_file, width = 1800, height = 600, res = 150, bg = "white")
          grid.newpage()
          grid.text(full_id, x = 0.27, y = 0.75,
            gp = gpar(fontsize = 44, fontface = "bold", family = "monospace"), just = "centre")
          grid.text(as.character(label_date), x = 0.27, y = 0.25,
            gp = gpar(fontsize = 40, fontface = "bold", family = "monospace"), just = "centre")
          
          qr_vp <- viewport(x = 0.75, y = 0.5, width = 0.32, height = 0.96)
          pushViewport(qr_vp)
          grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
          popViewport()
          dev.off()
          unlink(temp_qr_file)
          
          generated_labels <- c(generated_labels, full_id)
          
          dbExecute(con, "INSERT INTO Labels (label_id, stage, sample_id, part_code, created_date)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)",
            params = list(full_id, 2, sample_id, part_code))
        }
      }
      
      poolReturn(con)
      
      output$parts_status <- renderUI({
        div(
          style = "padding: 15px; background: #e8f5e9; border-radius: 6px; margin-top: 15px; border-left: 4px solid #4caf50;",
          h5(paste("✓", length(generated_labels), "part labels generated")),
          p(strong("IDs:"), paste(generated_labels[1:min(3, length(generated_labels))], collapse = ", "),
            if (length(generated_labels) > 3) paste0(", ..."))
        )
      })
      
      showNotification(paste("✓", length(generated_labels), "part labels generated!"), type = "message")
      
    }, error = function(e) {
      tryCatch(poolReturn(con), error = function(e2) {})
      output$parts_status <- renderUI({
        div(
          style = "padding: 15px; background: #ffebee; border-radius: 6px; margin-top: 15px;",
          p("❌ Error:", e$message)
        )
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  }
  
  # ============ STAGE 3: SAMPLE USE LABELS ============
  
  observeEvent(input$btn_use_generate, {
    generate_use_labels()
  })
  
  generate_use_labels <- function() {
    part_id <- input$use_part_id
    label_date <- input$use_date
    
    if (part_id == "") {
      showNotification("❌ Please enter a part ID (e.g., ST0001-P0001-SH001)", type = "error")
      return()
    }
    
    uses <- list(
      GW = input$use_gw_count,
      DE = input$use_de_count,
      RE = input$use_re_count,
      IS = input$use_other_count
    )
    
    total_uses <- sum(unlist(uses))
    if (total_uses < 1) {
      showNotification("❌ Please specify at least 1 use", type = "error")
      return()
    }
    
    output$use_status <- renderUI({
      div(
        style = "padding: 15px; background: #e3f2fd; border-radius: 6px; margin-top: 15px;",
        p("🔄 Generating use labels...")
      )
    })
    
    tryCatch({
      labels_dir <- "data/labels"
      if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
      
      con <- poolCheckout(pool)
      generated_labels <- character()
      
      for (use_code in names(uses)) {
        count <- uses[[use_code]]
        if (count < 1) next
        
        for (i in 1:count) {
          use_num <- sprintf("%02d", i)
          full_id <- sprintf("%s-%s%s", part_id, use_code, use_num)
          
          dup_check <- dbGetQuery(con,
            paste0("SELECT label_id FROM Labels WHERE label_id = '", full_id, "'"))
          
          if (nrow(dup_check) > 0) {
            showNotification(paste("⚠️", full_id, "already exists - skipping"), type = "warning")
            next
          }
          
          label_file <- file.path(labels_dir, paste0(full_id, ".png"))
          set.seed(as.integer(charToRaw(full_id)) %% 2147483647)
          qr_obj <- qr_code(full_id)
          temp_qr_file <- tempfile(fileext = ".png")
          png(temp_qr_file, width = 400, height = 400, bg = "white")
          plot(qr_obj)
          dev.off()
          qr_img <- png::readPNG(temp_qr_file)
          
          png(label_file, width = 1800, height = 600, res = 150, bg = "white")
          grid.newpage()
          grid.text(full_id, x = 0.27, y = 0.75,
            gp = gpar(fontsize = 44, fontface = "bold", family = "monospace"), just = "centre")
          grid.text(as.character(label_date), x = 0.27, y = 0.25,
            gp = gpar(fontsize = 40, fontface = "bold", family = "monospace"), just = "centre")
          
          qr_vp <- viewport(x = 0.75, y = 0.5, width = 0.32, height = 0.96)
          pushViewport(qr_vp)
          grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
          popViewport()
          dev.off()
          unlink(temp_qr_file)
          
          generated_labels <- c(generated_labels, full_id)
          
          dbExecute(con, "INSERT INTO Labels (label_id, stage, part_id, use_code, created_date)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)",
            params = list(full_id, 3, part_id, use_code))
        }
      }
      
      poolReturn(con)
      
      output$use_status <- renderUI({
        div(
          style = "padding: 15px; background: #e8f5e9; border-radius: 6px; margin-top: 15px; border-left: 4px solid #4caf50;",
          h5(paste("✓", length(generated_labels), "use labels generated")),
          p(strong("IDs:"), paste(generated_labels[1:min(3, length(generated_labels))], collapse = ", "),
            if (length(generated_labels) > 3) paste0(", ..."))
        )
      })
      
      showNotification(paste("✓", length(generated_labels), "use labels generated!"), type = "message")
      
    }, error = function(e) {
      tryCatch(poolReturn(con), error = function(e2) {})
      output$use_status <- renderUI({
        div(
          style = "padding: 15px; background: #ffebee; border-radius: 6px; margin-top: 15px;",
          p("❌ Error:", e$message)
        )
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  }
  
  # ============================================================
  # INVENTORY TAB
  # ============================================================
  
  # Display total sample count
  output$inventory_total_count <- renderText({
    # Reactive triggers
    input$btn_presamp_plant
    input$btn_presamp_soil
    input$btn_parts_generate
    input$btn_use_generate
    
    con <- poolCheckout(pool)
    total_samples <- dbGetQuery(con, 
      "SELECT COUNT(DISTINCT site_id) as count FROM Labels WHERE stage = 1"
    )$count
    poolReturn(con)
    total_samples
  })
  
  # Render inventory table
  output$inventory_table <- DT::renderDataTable({
    # Reactive triggers
    input$btn_presamp_plant
    input$btn_presamp_soil
    input$btn_parts_generate
    input$btn_use_generate
    
    search_term <- input$inventory_search
    status_filter <- input$inventory_status_filter
    
    con <- poolCheckout(pool)
    
    # Get all unique labels with their hierarchy - NO aggregation
    query <- "
      SELECT DISTINCT
        CASE 
          WHEN stage = 1 THEN label_id
          WHEN stage = 2 THEN part_id
          WHEN stage = 3 THEN label_id
        END as sample_id,
        stage,
        site_id,
        sample_type,
        COALESCE(sample_status, 'label_created') as sample_status,
        COALESCE(storage_location, '') as storage_location
      FROM Labels
      ORDER BY site_id, stage, sample_id
    "
    
    inventory_data <- dbGetQuery(con, query)
    poolReturn(con)
    
    # Filter by search term if provided
    if (!is.na(search_term) && search_term != "") {
      inventory_data <- inventory_data[grepl(search_term, inventory_data$sample_id, ignore.case = TRUE) |
                                      grepl(search_term, inventory_data$site_id, ignore.case = TRUE), ]
    }
    
    # Add status column based on stage
    inventory_data$Status <- sapply(inventory_data$stage, function(stage) {
      switch(stage,
        "1" = "Created",
        "2" = "Processing",
        "3" = "Complete",
        "Unknown"
      )
    })
    
    # Filter by status if provided
    if (!is.na(status_filter) && status_filter != "") {
      inventory_data$Status_Value <- sapply(inventory_data$Status, function(s) tolower(substring(s, 1, 1)))
      status_map <- list("c" = "created", "s" = "stored", "p" = "processing", "c" = "complete")
      inventory_data <- inventory_data[tolower(inventory_data$Status) == status_filter, ]
    }
    
    # Select columns to display - remove Count column
    display_data <- data.frame(
      "Site" = inventory_data$site_id,
      "Sample/Part/Use" = inventory_data$sample_id,
      "Type" = inventory_data$sample_type,
      "Stage" = sapply(inventory_data$stage, function(s) {
        switch(s, "1" = "Pre-Sampling", "2" = "Parts", "3" = "Use", s)
      }),
      "Status" = inventory_data$Status,
      "Location" = sapply(inventory_data$storage_location, function(x) if(is.na(x) || x == "") "-" else x)
    )
    
    DT::datatable(display_data,
      rownames = FALSE,
      options = list(
        pageLength = 20,
        lengthMenu = c(10, 20, 50),
        searching = FALSE,
        columnDefs = list(
          list(targets = 0, render = JS("function(data) { return '<strong>' + data + '</strong>'; }")),
          list(targets = 4, render = JS("function(data) {
            if(data === 'Complete') return '<span style=\"color: #4caf50; font-weight: bold;\">✓ ' + data + '</span>';
            if(data === 'Processing') return '<span style=\"color: #ff9800; font-weight: bold;\">⚙ ' + data + '</span>';
            if(data === 'Created') return '<span style=\"color: #2196f3;\">' + data + '</span>';
            return data;
          }"))
        )
      )
    )
  }, server = TRUE)
  
}

# ============================================================
# HELPER FUNCTION -Generate Processing IDs
# ============================================================

generate_proc_id <- function() {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Processing")
  poolReturn(con)
  count <- result$count[1] + 1
  sprintf("PROC%06d", count)
}

# ============================================================
# RUN APPLICATION
# ============================================================

shinyApp(ui = ui, server = server)
