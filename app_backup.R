# ==== Generate ID ==== # nolint: indentation_linter.
  nav_panel(
    "Generate Labels",
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
      )
    )
  )

# ==== Inventory ==== 
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
),

# ==== Scan ==== 
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

# ==== Site ====
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
)




# Chang lab LIMS Application
# Session-Based Batch Scanning Workflow for Hardware Barcode Scanners
# 
# State Machine:
# State 0 (Idle): Waiting for Equipment ID scan
# State 1 (Active): Locked to equipment, collecting plant ID scans
# Exit: Same equipment ID, FINISH barcode, or error

source("R/global.R")

# ============================================================
# UI DEFINITION - Two-Tab Interface
# ============================================================

ui <- page(
  theme = bslib::bs_theme(),
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(src = "scripts.js")
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
        
        # Generate QR code label PNG
        label_file <- file.path(labels_dir, paste0(full_id, ".png"))
        generate_label_png(full_id, label_date, label_file)
        
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
          generate_label_png(full_id, label_date, label_file)

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
          generate_label_png(full_id, label_date, label_file)

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
# RUN APPLICATION
# ============================================================

shinyApp(ui = ui, server = server)

