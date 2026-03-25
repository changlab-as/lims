# Riverside Rhizobia LIMS Application
# Complete Laboratory Information Management System built with R Shiny

# Load required libraries
library(shiny)
library(bs4Dash)
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

# UI Definition
ui <- tagList(
  shinyjs::useShinyjs(),
  
  tags$head(
    tags$style(HTML("
      /* Force full-width everything */
      body { margin: 0; padding: 0; }
      .navbar { margin-bottom: 0; }
      
      /* Full width page wrapper */
      .tab-content { padding: 0 !important; }
      .shiny-tab-panel { width: 100% !important; }
      
      /* Container full width */
      .container-fluid { width: 100vw !important; padding: 0 !important; margin-left: calc(50% - 50vw); }
      
      /* Card full width - override bs4Dash defaults */
      .card { 
        width: 100% !important; 
        margin: 0 !important; 
        margin-bottom: 15px !important;
        border-radius: 0.25rem;
      }
      .bs4-card { width: 100% !important; }
      .card-header { width: 100%; }
      .card-body { 
        width: 100% !important; 
        overflow-x: auto; 
        box-sizing: border-box;
      }
      
      /* DataTable full width */
      .dataTables_wrapper { width: 100% !important; display: block !important; }
      .dataTables_length { display: inline-block; }
      .dataTables_filter { display: inline-block; float: right; }
      .dataTables_info { display: block; margin-top: 10px; }
      .dataTables_paginate { display: block; margin-top: 10px; }
      .dataTable { width: 100% !important; }
      .dataTables_scrollHeadInner { width: 100% !important; }
      .dataTables_scrollBodyInner { width: 100% !important; }
      
      /* DT specific */
      div.dataTables_wrapper div.dataTables_length { width: auto; }
      div.dataTables_wrapper div.dataTables_filter { width: auto; }
      div.dataTables_wrapper div.dataTables_info { width: auto; }
      div.dataTables_wrapper div.dataTables_paginate { width: auto; }
      
      /* Mobile responsiveness */
      @media (max-width: 768px) {
        .dataTables_wrapper { overflow-x: auto; }
        table.dataTable { font-size: 12px; }
        .card-body table { font-size: 11px; }
      }
      
      /* Navbar nav */
      .navbar-nav { margin-left: auto; }
      .navbar-brand { margin-right: 20px; }
    "))
  ),
  
  navbarPage(
    title = "Chang Lab LIMS",
    position = "static-top",
    collapsible = TRUE,
    theme = bs_theme(
      version = 4,
      preset = "minty",
      bg = "#FFFFFF",
      fg = "#1C1C1C",
      primary = "#00A19A",
      secondary = "#78909C",
      success = "#26A69A",
      info = "#009688",
      warning = "#FFA726",
      danger = "#EF5350"
    ),
  
  tabPanel(
    "Home",
    div(style = "padding: 20px 40px; min-height: 100vh;",
      bs4Card(style = "width: 100%;",
        title = "About This System",
        closable = FALSE,
        collapsible = FALSE,
        status = "teal",
        solidHeader = TRUE,
        p(
          "The Chang Lab Laboratory Information Management System (LIMS) is a comprehensive platform designed to streamline laboratory operations and sample tracking. Built for the Chang Lab, this system enables efficient management of field sampling, lab check-ins, equipment tracking, and label generation for plant and equipment inventory."
        )
      )
    )
  ),
  
  tabPanel(
    "Field Entry",
    div(style = "padding: 20px 40px; min-height: 100vh;",
        
        h2("Field Sampling Entry"),
        
        # Create new site section
        bs4Card(
          title = "New Site",
          closable = FALSE,
          collapsible = FALSE,
          status = "info",
          solidHeader = TRUE,
          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin-bottom: 15px;",
            textInput(
              inputId = "site_name",
              label = "Site name",
              placeholder = "e.g., NTU campus"
            ),
            textInput(
              inputId = "site_lat",
              label = "Latitude",
              placeholder = "e.g., 5678"
            ),
            textInput(
              inputId = "site_long",
              label = "Longitude",
              placeholder = "e.g., 1234"
            )
          ),
          actionButton(
            inputId = "btn_create_site",
            label = "Create Site",
            class = "btn-success btn-sm"
          ),
          br(), br(),
          verbatimTextOutput("site_creation_msg")
        ),
        
        br(),
        
        # Site Information table
        bs4Card(
          title = "Site Information",
          closable = FALSE,
          collapsible = FALSE,
          status = "warning",
          solidHeader = TRUE,
          DT::dataTableOutput("sites_table")
        )
    )
  ),
  
  tabPanel(
    "Sample Check-In",
    div(style = "padding: 20px 40px; min-height: 100vh;",
        
        h2("Sample Check-In (Mobile Scanner)"),
        
        bs4Card(
          title = "Scan QR Code",
          closable = FALSE,
          collapsible = FALSE,
          status = "info",
          solidHeader = TRUE,
          
          p("Use your phone camera or QR scanner to scan the plant label QR code."),
          p(strong("This will auto-upload the check-in data to the system.")),
          
          textInput(
            inputId = "mobile_plant_id",
            label = "Scanned Plant ID",
            placeholder = "ST0001-P0001 (auto-filled when QR scanned)"
          ),
          
          selectInput(
            inputId = "mobile_fridge_loc",
            label = "Equipment/Fridge Location",
            choices = ""
          ),
          
          actionButton(
            inputId = "btn_mobile_checkin",
            label = "Check In Sample",
            class = "btn-success btn-lg"
          ),
          
          br(), br(),
          
          uiOutput("mobile_result_message")
        ),
        
        br(),
        
        bs4Card(
          title = "Recent Mobile Check-Ins",
          closable = FALSE,
          collapsible = FALSE,
          status = "success",
          solidHeader = TRUE,
          
          DT::dataTableOutput("mobile_checkins_log")
        )
    )
  ),
  
  tabPanel(
    "Label Generation",
    div(style = "padding: 20px 40px; min-height: 100vh;",
        h2("Batch Label Generation"),
        
        bs4Card(
          title = "Generate Labels for Site",
          closable = FALSE,
          collapsible = FALSE,
          status = "info",
          solidHeader = TRUE,
          
          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-bottom: 15px;",
            selectInput(
              inputId = "label_site_select",
              label = "Select Site",
              choices = ""
            ),
            
            numericInput(
              inputId = "label_start_index",
              label = "Start Plant Index",
              value = 1,
              min = 1
            ),
            
            numericInput(
              inputId = "label_end_index",
              label = "End Plant Index",
              value = 20,
              min = 1
            ),
            
            selectInput(
              inputId = "label_format",
              label = "Output Format",
              choices = c("PNG (Individual)" = "png", 
                         "PDF (Printable)" = "pdf")
            )
          ),
          
          actionButton(
            inputId = "btn_generate_labels",
            label = "Generate Labels",
            class = "btn-primary btn-lg"
          ),
          
          br(), br(),
          
          uiOutput("label_generation_status")
        )
    )
  ),
  
  tabPanel(
    "Equipment Labels",
    div(style = "padding: 20px 40px; min-height: 100vh;",
        
        h2("Equipment QR Labels"),
        
        bs4Card(
          title = "Equipment Inventory with Labels",
          closable = FALSE,
          collapsible = FALSE,
          status = "success",
          solidHeader = TRUE,
          
          DT::dataTableOutput("equipment_inventory_table")
        ),
        
        br(),
        
        bs4Card(
          title = "Equipment QR Code Labels",
          closable = FALSE,
          collapsible = FALSE,
          status = "info",
          solidHeader = TRUE,
          
          p("All equipment QR codes:"),
          br(),
          
          uiOutput("equipment_qr_labels_display")
        )
    )
  ),
  
  tabPanel(
    "Inventory View",
    div(style = "padding: 20px 40px; min-height: 100vh;",
        h2("Inventory View"),
        
        bs4Card(
          title = "All Plants",
          closable = FALSE,
          collapsible = FALSE,
          status = "primary",
          solidHeader = TRUE,
          
          DT::dataTableOutput("inventory_table")
        ),
        
        br(),
        
        bs4Card(
          title = "Processing Records",
          closable = FALSE,
          collapsible = FALSE,
          status = "secondary",
          solidHeader = TRUE,
          
          DT::dataTableOutput("processing_table")
        )
    )
  )
)
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    current_sample = NULL,
    current_fridge = NULL,
    plant_count = 0
  )
  
  # ===== FIELD ENTRY SERVER =====
  
  # Create new site
  observeEvent(input$btn_create_site, {
    if (input$site_name == "") {
      output$site_creation_msg <- renderText("Please enter a site name")
      return()
    }
    
    if (input$site_lat == "") {
      output$site_creation_msg <- renderText("Please enter latitude")
      return()
    }
    
    if (input$site_long == "") {
      output$site_creation_msg <- renderText("Please enter longitude")
      return()
    }
    
    site_id <- generate_site_id()
    con <- poolCheckout(pool)
    
    dbExecute(con, 
      "INSERT INTO Sites (site_id, site_name, site_lat, site_long) VALUES (?, ?, ?, ?)",
      params = list(site_id, input$site_name, input$site_lat, input$site_long)
    )
    
    poolReturn(con)
    
    output$site_creation_msg <- renderText(
      paste("✓ Site created successfully! Site ID:", site_id)
    )
    
    # Update site selector
    updateSelectInput(session, "select_site_for_plants",
      choices = get_site_choices()
    )
  })
  
  # Get available sites for dropdown
  get_site_choices <- function() {
    con <- poolCheckout(pool)
    sites <- dbGetQuery(con, 
      "SELECT site_id, site_name FROM Sites ORDER BY site_id DESC")
    poolReturn(con)
    
    if (nrow(sites) == 0) return(character(0))
    setNames(sites$site_id, 
      paste0(sites$site_id, " - ", sites$site_name))
  }
  
  # Get equipment choices for fridge location dropdown
  get_equipment_choices <- function() {
    con <- poolCheckout(pool)
    equipment <- dbGetQuery(con, 
      "SELECT equipment_id, character_name FROM Equipment ORDER BY equipment_id")
    poolReturn(con)
    
    if (nrow(equipment) == 0) return(character(0))
    setNames(equipment$equipment_id, 
      paste0(equipment$equipment_id, " | ", equipment$character_name))
  }
  
  # Render sites table
  output$sites_table <- DT::renderDataTable({
    con <- poolCheckout(pool)
    sites <- dbGetQuery(con, "SELECT * FROM Sites ORDER BY site_id DESC")
    poolReturn(con)
    
    DT::datatable(sites, options = list(pageLength = 5))
  })
  
  # Update site selector dynamically
  observe({
    updateSelectInput(session, "select_site_for_plants",
      choices = get_site_choices()
    )
  })
  
  # Generate plant entry forms
  observeEvent(input$btn_add_plants, {
    if (input$select_site_for_plants == "") {
      showNotification("Please select a site first", type = "error")
      return()
    }
    
    values$plant_count <- input$num_plants
  })
  
  # Render dynamic plant entry forms
  output$plant_entry_forms <- renderUI({
    if (values$plant_count == 0) return(NULL)
    
    lapply(1:values$plant_count, function(i) {
      fluidRow(
        column(3, textInput(paste0("species_", i), paste("Plant", i, "- Species"))),
        column(3, selectInput(paste0("health_", i), "Health Status",
          choices = c("Healthy", "Stressed", "Diseased"))),
        column(3, textInput(paste0("fridge_", i), "Fridge Location")),
        column(2, tags$br(),
          actionButton(paste0("btn_save_plant_", i), "Save", class = "btn-sm btn-success"))
      )
    })
  })
  
  # Save individual plants
  observeEvent(input$btn_add_plants, {
    for (i in 1:values$plant_count) {
      local({
        idx <- i
        observeEvent(input[[paste0("btn_save_plant_", idx)]], {
          plant_id <- generate_plant_id(input$select_site_for_plants)
          species <- input[[paste0("species_", idx)]]
          health <- input[[paste0("health_", idx)]]
          fridge <- input[[paste0("fridge_", idx)]]
          
          if (species == "" || is.null(species)) {
            showNotification("Please enter species name", type = "error")
            return()
          }
          
          con <- poolCheckout(pool)
          dbExecute(con,
            "INSERT INTO Plants (plant_id, site_id, species, health_status, fridge_loc) 
             VALUES (?, ?, ?, ?, ?)",
            params = list(plant_id, input$select_site_for_plants, species, health, fridge)
          )
          poolReturn(con)
          
          showNotification(
            paste("Plant saved:", plant_id),
            type = "message"
          )
        })
      })
    }
  })
  
  # Generate and display QR code
  generate_qr_code <- function(plant_id) {
    tryCatch({
      qr_file <- paste0("www/qr_", plant_id, ".png")
      if (!file.exists("www")) dir.create("www")
      
      qr_obj <- qr_code(plant_id)
      png(qr_file, width = 400, height = 400)
      plot(qr_obj)
      dev.off()
    }, error = function(e) {
      cat("QR code generation error:", e$message, "\n")
    })
  }
  
  # Display scan results
  output$scan_result_ui <- renderUI({
    if (is.null(values$current_sample)) return(NULL)
    
    bs4Card(
      title = "Current Scan",
      closable = FALSE,
      collapsible = FALSE,
      status = "warning",
      
      p(strong("Sample ID:"), values$current_sample),
      if (!is.null(values$current_fridge)) {
        p(strong("Fridge Location:"), values$current_fridge)
      }
    )
  })
  
  # Display QR code
  output$qr_code_display <- renderUI({
    if (is.null(values$current_sample)) return(NULL)
    
    bs4Card(
      title = "QR Code",
      closable = FALSE,
      collapsible = FALSE,
      status = "info",
      
      img(src = paste0("qr_", values$current_sample, ".png"),
        width = "250px", height = "250px")
    )
  })
  
  # ===== INVENTORY VIEW SERVER =====
  
  # Inventory table - all plants
  output$inventory_table <- DT::renderDataTable({
    input$btn_add_plants # Refresh when new plants added
    
    con <- poolCheckout(pool)
    inventory <- dbGetQuery(con,
      "SELECT plant_id, site_id, species, health_status as 'Health Status', 
              fridge_loc as 'Fridge Location', date_created as 'Created'
       FROM Plants
       ORDER BY plant_id DESC"
    )
    poolReturn(con)
    
    DT::datatable(
      inventory,
      options = list(
        pageLength = 15,
        columnDefs = list(list(width = "150px", targets = "_all"))
      ),
      filter = "top"
    )
  })
  
  # Processing records table
  output$processing_table <- DT::renderDataTable({
    con <- poolCheckout(pool)
    processing <- dbGetQuery(con,
      "SELECT proc_id, plant_id, type, date, technician, notes
       FROM Processing
       ORDER BY date DESC
       LIMIT 50"
    )
    poolReturn(con)
    
    if (nrow(processing) == 0) {
      return(data.frame(Message = "No processing records yet"))
    }
    
    DT::datatable(
      processing,
      options = list(pageLength = 10)
    )
  })
  
  # ===== MOBILE SCAN SERVER =====
  
  # Update label site selector
  observe({
    updateSelectInput(session, "label_site_select",
      choices = get_site_choices()
    )
  })
  
  # Update equipment choices for fridge location
  observe({
    updateSelectInput(session, "mobile_fridge_loc",
      choices = get_equipment_choices()
    )
  })
  
  # Mobile check-in button
  observeEvent(input$btn_mobile_checkin, {
    if (input$mobile_plant_id == "") {
      showNotification("Please enter or scan a plant ID", type = "error")
      return()
    }
    
    con <- poolCheckout(pool)
    
    # Check for duplicate/existing plant
    plant_check <- dbGetQuery(con,
      paste0("SELECT * FROM Plants WHERE plant_id = '", input$mobile_plant_id, "'")
    )
    
    if (nrow(plant_check) == 0) {
      poolReturn(con)
      showNotification(
        paste("Error: Plant ID", input$mobile_plant_id, "not found in database"),
        type = "error"
      )
      return()
    }
    
    # Update fridge location
    dbExecute(con,
      "UPDATE Plants SET fridge_loc = ? WHERE plant_id = ?",
      params = list(input$mobile_fridge_loc, input$mobile_plant_id)
    )
    
    # Log to processing table
    proc_id <- paste0("PROC", gsub("-|:", "", Sys.time()))
    dbExecute(con,
      "INSERT INTO Processing (proc_id, plant_id, type, date, notes) 
       VALUES (?, ?, ?, ?, ?)",
      params = list(proc_id, input$mobile_plant_id, "Mobile_Checkin", 
                    Sys.time(), paste("Mobile check-in to:", input$mobile_fridge_loc))
    )
    
    poolReturn(con)
    
    # Show success
    showNotification(
      paste("✓ Mobile check-in successful!", input$mobile_plant_id, "→", input$mobile_fridge_loc),
      type = "message",
      duration = 3
    )
    
    # Clear and log
    output$mobile_result_message <- renderUI({
      bs4Card(
        title = "Check-In Successful",
        closable = FALSE,
        status = "success",
        p(strong("Plant ID:"), input$mobile_plant_id),
        p(strong("Location:"), input$mobile_fridge_loc),
        p(strong("Time:"), Sys.time())
      )
    })
  })
  
  # Auto-submit when QR code is scanned (detects valid plant ID format)
  observe({
    input$mobile_plant_id
    
    # Check if input has valid format: ST0001-P0001
    plant_id <- input$mobile_plant_id
    if (nchar(plant_id) > 0 && grepl("^ST\\d{4}-P\\d{4}$", plant_id)) {
      # Valid plant ID detected - auto-trigger check-in after brief delay
      shinyjs::runjs("
        setTimeout(function() {
          // Auto-submit the check-in button if there's a valid plant ID
          if ($('#mobile_plant_id').val().match(/^ST\\d{4}-P\\d{4}$/)) {
            $('#btn_mobile_checkin').click();
            // Auto-focus back to plant ID field for next scan
            setTimeout(function() { $('#mobile_plant_id').val('').focus(); }, 500);
          }
        }, 100);
      ")
    }
  })
  
  # Mobile check-ins log
  output$mobile_checkins_log <- DT::renderDataTable({
    input$btn_mobile_checkin
    
    con <- poolCheckout(pool)
    mobile_logs <- dbGetQuery(con,
      "SELECT p.plant_id, p.site_id, p.species, p.fridge_loc, pr.date
       FROM Plants p
       LEFT JOIN Processing pr ON p.plant_id = pr.plant_id
       WHERE pr.type = 'Mobile_Checkin'
       ORDER BY pr.date DESC
       LIMIT 30"
    )
    poolReturn(con)
    
    if (nrow(mobile_logs) == 0) {
      return(data.frame(Message = "No mobile check-ins yet"))
    }
    
    DT::datatable(mobile_logs, options = list(pageLength = 10))
  })
  
  # ===== LABEL GENERATION SERVER =====
  
  # Generate batch labels with QR codes
  observeEvent(input$btn_generate_labels, {
    if (input$label_site_select == "") {
      showNotification("Please select a site", type = "error")
      return()
    }
    
    site_id <- input$label_site_select
    start_idx <- input$label_start_index
    end_idx <- input$label_end_index
    
    if (start_idx > end_idx) {
      showNotification("Start index must be less than end index", type = "error")
      return()
    }
    
    output$label_generation_status <- renderUI({
      bs4Card(
        title = "Generating...",
        closable = FALSE,
        status = "info",
        p("Please wait, generating labels...")
      )
    })
    
    # Create labels directory
    labels_dir <- "data/labels"
    if (!dir.exists(labels_dir)) dir.create(labels_dir, recursive = TRUE)
    
    tryCatch({
      # Generate individual PNG files for each label (horizontal format for label maker tape)
      # Layout: Large ID text on left, QR code on right, no overlapping
      for (i in start_idx:end_idx) {
        plant_id <- sprintf("%s-P%04d", site_id, i)
        label_file <- file.path(labels_dir, paste0(plant_id, ".png"))
        
        # Create horizontal label (1800x600 pixels at 150 DPI)
        library(grid)
        
        # Set seed based on plant_id for reproducible QR codes
        set.seed(as.integer(charToRaw(plant_id)) %% 2147483647)
        
        # First, generate QR code to temporary file
        qr_obj <- qr_code(plant_id)
        temp_qr_file <- tempfile(fileext = ".png")
        png(temp_qr_file, width = 400, height = 400, bg = "white")
        plot(qr_obj)
        dev.off()
        qr_img <- png::readPNG(temp_qr_file)
        
        # Now create label with text and QR
        png(label_file, width = 1800, height = 600, res = 150, bg = "white")
        
        grid.newpage()
        
        # LEFT COLUMN: Plant ID (top) and Date (bottom) - direct positioning
        # Plant ID - positioned inside QR bounds, below upper edge
        grid.text(plant_id, 
                  x = 0.27, y = 0.75, 
                  gp = gpar(fontsize = 48, fontface = "bold", family = "monospace"),
                  just = "centre")
        
        # Date - positioned inside QR bounds, above lower edge
        grid.text(as.character(Sys.Date()), 
                  x = 0.27, y = 0.25, 
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
      }
      
      # Create PDF version if requested
      if (input$label_format == "pdf") {
        pdf_file <- file.path(labels_dir, paste0(site_id, "_labels.pdf"))
        num_labels <- (end_idx - start_idx + 1)
        
        # Create PDF with 4 labels per page
        pdf(pdf_file, width = 8.5, height = 11, onefile = TRUE)
        
        label_count <- 0
        for (i in start_idx:end_idx) {
          plant_id <- sprintf("%s-P%04d", site_id, i)
          
          if (label_count %% 4 == 0 && label_count > 0) {
            # New page after 4 labels
            plot.new()
          }
          
          label_count <- label_count + 1
        }
        
        dev.off()
      }
      
      # Prepare status message
      format_msg <- switch(input$label_format,
        "png" = "PNG files (individual labels)",
        "pdf" = "PDF file"
      )
      
      output$label_generation_status <- renderUI({
        bs4Card(
          title = "✓ Labels Generated",
          closable = FALSE,
          status = "success",
          p(strong("Generated:"), (end_idx - start_idx + 1), "labels"),
          p(strong("Format:"), format_msg),
          p(strong("Site:"), site_id),
          p(strong("ID Range:"), sprintf("P%04d to P%04d", start_idx, end_idx)),
          p(strong("Location:"), file.path(labels_dir)),
          br(),
          p("Files ready for printing. Find them in:", code(labels_dir))
        )
      })
      
      showNotification(
        paste("Generated", (end_idx - start_idx + 1), "labels for", site_id),
        type = "message",
        duration = 5
      )
      
    }, error = function(e) {
      output$label_generation_status <- renderUI({
        bs4Card(
          title = "Error",
          closable = FALSE,
          status = "danger",
          p("Error generating labels:"),
          p(code(e$message))
        )
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # ===== EQUIPMENT LABELS SERVER =====
  
  # Populate equipment choices dynamically
  observe({
    con <- poolCheckout(pool)
    equipment_data <- dbGetQuery(con, "SELECT equipment_id, character_name, category FROM Equipment ORDER BY equipment_id")
    poolReturn(con)
    
    if (nrow(equipment_data) > 0) {
      choices <- setNames(equipment_data$equipment_id, 
                          paste0(equipment_data$equipment_id, " | ", equipment_data$character_name))
      updateCheckboxGroupInput(session, "selected_equipment", choices = choices)
    }
  })
  
  # Equipment inventory table
  output$equipment_inventory_table <- DT::renderDataTable({
    con <- poolCheckout(pool)
    equipment <- dbGetQuery(con,
      "SELECT equipment_id, character_name, category, description
       FROM Equipment
       ORDER BY equipment_id"
    )
    poolReturn(con)
    
    # Create styled HTML with colored badges
    badge_html <- sapply(1:nrow(equipment), function(i) {
      eq_id <- equipment$equipment_id[i]
      char_name <- equipment$character_name[i]
      category <- equipment$category[i]
      
      # Determine color and initial based on category
      if (grepl("Ultra-Low", category)) {
        badge_color <- "#9C27B0"  # Purple
      } else if (grepl("Standard Freezers", category)) {
        badge_color <- "#2196F3"  # Blue
      } else if (grepl("Fridges", category)) {
        badge_color <- "#4CAF50"  # Green
      } else if (grepl("growth chamber", category)) {
        badge_color <- "#FF9800"  # Orange
      } else {
        badge_color <- "#757575"  # Gray
      }
      
      initial <- substr(char_name, 1, 1)
      
      HTML(paste0(
        '<div style="display: flex; align-items: center; gap: 10px;">',
        '<div style="width: 40px; height: 40px; border-radius: 50%; background-color: ', badge_color, 
        '; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 18px;">',
        initial,
        '</div>',
        '<div>',
        '<strong>', eq_id, '</strong><br/>',
        '<small>', char_name, '</small>',
        '</div>',
        '</div>'
      ))
    })
    
    # Create data frame with styled display
    display_df <- data.frame(
      Badge = badge_html,
      Category = equipment$category,
      Description = equipment$description,
      stringsAsFactors = FALSE
    )
    
    DT::datatable(
      display_df,
      escape = FALSE,  # Allow HTML rendering
      options = list(
        pageLength = 10,
        columnDefs = list(
          list(width = "200px", targets = 0)
        )
      )
    )
  })
  
  # Display QR code labels for all equipment in grid format
  output$equipment_qr_labels_display <- renderUI({
    con <- poolCheckout(pool)
    equipment <- dbGetQuery(con,
      "SELECT * FROM Equipment ORDER BY equipment_id"
    )
    poolReturn(con)
    
    if (nrow(equipment) == 0) {
      return(p("No equipment available", style = "color: gray;"))
    }
    
    # Generate QR codes and create grid display
    label_boxes <- lapply(1:nrow(equipment), function(idx) {
      equipment_id <- equipment$equipment_id[idx]
      character_name <- equipment$character_name[idx]
      category <- equipment$category[idx]
      
      # Determine border color based on category
      if (grepl("Ultra-Low", category)) {
        border_color <- "#9C27B0"  # Purple
        bg_light <- "#F3E5F5"
      } else if (grepl("Standard Freezers", category)) {
        border_color <- "#2196F3"  # Blue
        bg_light <- "#E3F2FD"
      } else if (grepl("Fridges", category)) {
        border_color <- "#4CAF50"  # Green
        bg_light <- "#E8F5E9"
      } else if (grepl("growth chamber", category)) {
        border_color <- "#FF9800"  # Orange
        bg_light <- "#FFF3E0"
      } else {
        border_color <- "#757575"  # Gray
        bg_light <- "#F5F5F5"
      }
      
      # Generate QR code 
      set.seed(as.integer(charToRaw(equipment_id)) %% 2147483647)
      qr_obj <- qr_code(equipment_id)
      
      # Save QR as temporary PNG and convert to base64 for embedding
      temp_qr_file <- tempfile(fileext = ".png")
      png(temp_qr_file, width = 200, height = 200, bg = "white")
      plot(qr_obj)
      dev.off()
      
      # Read and encode image
      qr_img_base64 <- base64enc::dataURI(file = temp_qr_file, mime = "image/png")
      unlink(temp_qr_file)
      
      # Create card as plain HTML div
      div(
        style = paste0("border: 3px solid ", border_color, "; border-radius: 8px; padding: 15px; ",
                      "background-color: ", bg_light, "; margin-bottom: 15px; text-align: center; ",
                      "flex: 0 0 calc(50% - 10px); min-width: 300px;"),
        h4(equipment_id, style = paste0("color: ", border_color, "; margin: 0 0 5px 0;")),
        p(strong(character_name), style = "margin: 0 0 10px 0; font-size: 14px;"),
        p(style = "font-size: 12px; color: #666; margin: 0 0 10px 0;", category),
        img(src = qr_img_base64, style = "width: 150px; height: 150px; border: 1px solid #ccc;"),
        p(style = "font-size: 11px; color: #999; margin-top: 8px;", "Scan QR to identify equipment")
      )
    })
    
    # Wrap in a flex container for proper grid layout
    do.call(tagList, c(
      list(div(style = "display: flex; flex-wrap: wrap; gap: 20px; margin-top: 15px;",
        do.call(tagList, label_boxes)
      )),
      list(br())
    ))
  })
  
  # Pool is managed globally and shared across sessions
  # Do not close it in onStop to avoid "closed pool" errors
}

# Run the application
shinyApp(ui = ui, server = server)
