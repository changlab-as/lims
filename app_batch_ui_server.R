
# ============================================================
# UI DEFINITION - Session-Based Batch Scanning
# ============================================================

ui <- page_fillable(
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
      
      // Force focus on scanner input every 2 seconds
      setInterval(function() {
        var elem = document.getElementById('master_scanner_input');
        if (elem && document.activeElement !== elem) {
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
      
      /* State 0: Equipment Selection Screen */
      .state-0-container {
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        height: 100vh;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        text-align: center;
        padding: 20px;
      }
      
      .state-0-container h1 {
        font-size: 48px;
        margin: 0 0 30px 0;
        font-weight: 700;
        letter-spacing: -1px;
      }
      
      .state-0-container p {
        font-size: 28px;
        margin: 20px 0;
        opacity: 0.95;
      }
      
      /* State 1: Batch Scanning */
      .state-1-container {
        display: flex;
        flex-direction: column;
        height: 100vh;
        background: #FFFFFF;
      }
      
      /* Equipment header - huge and visible from 2m away */
      .equipment-header {
        background: linear-gradient(135deg, #26A69A 0%, #00A19A 100%);
        color: white;
        padding: 30px 20px;
        text-align: center;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      }
      
      .equipment-header h1 {
        font-size: 56px;
        margin: 0;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
      }
      
      .equipment-header .subtitle {
        font-size: 20px;
        opacity: 0.95;
        margin-top: 8px;
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
    "))
  ),
  
  # Hidden scanner input - always receives focus
  textInput(
    inputId = "master_scanner_input",
    label = NULL,
    placeholder = "Scanner input (hidden)",
    value = ""
  ),
  
  # State 0: Equipment Selection (Idle)
  conditionalPanel(
    condition = "input.scan_state === 0",
    div(
      class = "state-0-container",
      h1("🔖 BATCH SCANNER"),
      p("Scan Equipment ID to Start"),
      p(style = "font-size: 18px; opacity: 0.8; margin-top: 40px;",
        "Available: U01 • Z01 • F01 • F02 • F03 • F04 • G01"
      )
    )
  ),
  
  # State 1: Batch Scanning (Active session)
  conditionalPanel(
    condition = "input.scan_state === 1",
    div(
      class = "state-1-container",
      
      # Equipment header - visible from 2m away
      div(
        class = "equipment-header",
        h1(textOutput("equipment_display")),
        div(class = "subtitle", "NOW LOADING INTO:")
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
    )
  ),
  
  # Invalid code warning (overlay, dismisses after 1.5s)
  uiOutput("invalid_warning_ui"),
  
  # Success flash (overlay, dismisses after 0.6s)
  uiOutput("success_flash_ui")
)

# ============================================================
# SERVER LOGIC - State Machine
# ============================================================

server <- function(input, output, session) {
  
  # Initialize state machine
  state <- reactiveValues(
    current_state = 0,  # 0 = Idle, 1 = Active
    equipment_id = NULL,
    equipment_name = NULL,
    batch_samples = character(),
    last_scanned = "",
    show_invalid = FALSE,
    invalid_code = "",
    show_success = FALSE,
    show_success_code = ""
  )
  
  # Plant ID regex pattern
  plant_id_pattern <- "^ST\\d{4}-P\\d{4}$"
  
  # ============================================================
  # MAIN SCANNER INPUT HANDLER
  # ============================================================
  
  observeEvent(input$master_scanner_input, {
    scan_input <- trimws(input$master_scanner_input)
    
    if (nchar(scan_input) == 0) return()
    
    # Handle multi-line input (batch/storage mode)
    scans <- strsplit(scan_input, "\n")[[1]]
    
    for (scan in scans) {
      scan <- trimws(scan)
      if (nchar(scan) == 0) next
      
      if (state$current_state == 0) {
        # STATE 0: Waiting for Equipment ID
        handle_equipment_scan(scan)
      } else if (state$current_state == 1) {
        # STATE 1: Active session - check for exit or plant sample
        handle_active_scan(scan)
      }
    }
    
    # Clear input for next scan
    shinyjs::runjs("document.getElementById('master_scanner_input').value = '';")
  }, priority = 10)
  
  # ============================================================
  # EQUIPMENT SCAN HANDLER (State 0)
  # ============================================================
  
  handle_equipment_scan <- function(scan) {
    # Check if valid equipment ID exists in database
    con <- poolCheckout(pool)
    result <- dbGetQuery(con, 
      paste0("SELECT character_name FROM Equipment WHERE equipment_id = '", scan, "'"))
    poolReturn(con)
    
    if (nrow(result) > 0) {
      # Valid equipment ID - start session
      state$current_state <- 1
      state$equipment_id <- scan
      state$equipment_name <- result$character_name[1]
      state$batch_samples <- character()
      state$last_scanned <- ""
      state$show_success <- TRUE
      state$show_success_code <- scan
      
      # Play starting beep
      shinyjs::runjs("playStartBeep();")
      
      # Auto-dismiss success after 0.6s
      shinyjs::delay(600, {
        state$show_success <- FALSE
      })
    } else {
      # Invalid equipment ID
      state$show_invalid <- TRUE
      state$invalid_code <- scan
      shinyjs::runjs("playErrorBeep();")
      
      # Auto-dismiss error after 1.5s
      shinyjs::delay(1500, {
        state$show_invalid <- FALSE
      })
    }
  }
  
  # ============================================================
  # ACTIVE SCAN HANDLER (State 1)
  # ============================================================
  
  handle_active_scan <- function(scan) {
    # Check for exit conditions
    if (scan == state$equipment_id || scan == "FINISH") {
      # Exit session - return to State 0
      state$current_state <- 0
      state$equipment_id <- NULL
      state$equipment_name <- NULL
      state$batch_samples <- character()
      state$last_scanned <- ""
      shinyjs::runjs("playStartBeep();")
      return()
    }
    
    # Check if scan matches Plant ID pattern
    if (grepl(plant_id_pattern, scan)) {
      # Valid plant ID - save to database
      save_batch_scan(scan)
      
      # Add to batch list
      state$batch_samples <- c(scan, state$batch_samples)  # Newest first
      state$last_scanned <- scan
      
      # Show success flash
      state$show_success <- TRUE
      state$show_success_code <- scan
      shinyjs::runjs("playSuccessBeep();")
      
      # Auto-dismiss after 0.6s
      shinyjs::delay(600, {
        state$show_success <- FALSE
      })
    } else {
      # Invalid scan
      state$show_invalid <- TRUE
      state$invalid_code <- scan
      shinyjs::runjs("playErrorBeep();")
      
      # Auto-dismiss after 1.5s
      shinyjs::delay(1500, {
        state$show_invalid <- FALSE
      })
    }
  }
  
  # ============================================================
  # DATABASE OPERATIONS
  # ============================================================
  
  save_batch_scan <- function(plant_id) {
    con <- poolCheckout(pool)
    
    # Check if plant exists
    plant_check <- dbGetQuery(con, 
      paste0("SELECT * FROM Plants WHERE plant_id = '", plant_id, "'"))
    
    if (nrow(plant_check) > 0) {
      # Create processing record
      proc_id <- generate_proc_id()
      
      dbExecute(con,
        "INSERT INTO Processing (proc_id, plant_id, equipment_id, type, date, notes) 
         VALUES (?, ?, ?, ?, datetime('now'), ?)",
        params = list(
          proc_id,
          plant_id,
          state$equipment_id,
          "Batch_Checkin",
          paste("Batch scanned into", state$equipment_name)
        )
      )
      
      # Update plant's fridge location
      dbExecute(con,
        paste0("UPDATE Plants SET fridge_loc = '", state$equipment_id, "' WHERE plant_id = '", plant_id, "'")
      )
    }
    
    poolReturn(con)
  }
  
  # ============================================================
  # REACTIVE OUTPUTS
  # ============================================================
  
  # State for Shiny reactive
  observe({
    shinyjs::runjs(sprintf("Shiny.setInputValue('scan_state', %d);", state$current_state))
  })
  
  # Equipment display (uppercase for visibility)
  output$equipment_display <- renderText({
    if (state$current_state == 1 && !is.null(state$equipment_name)) {
      sprintf("NOW LOADING INTO\n%s", toupper(state$equipment_name))
    } else {
      ""
    }
  })
  
  # Last scanned display (huge text)
  output$last_scanned_display <- renderText({
    if (state$current_state == 1) {
      if (nchar(state$last_scanned) > 0) {
        state$last_scanned
      } else {
        "waiting..."
      }
    } else {
      ""
    }
  })
  
  # Batch list UI - grows in real-time
  output$batch_list_ui <- renderUI({
    if (state$current_state == 1 && length(state$batch_samples) > 0) {
      lapply(seq_along(state$batch_samples), function(i) {
        sample_id <- state$batch_samples[i]
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
    } else if (state$current_state == 1) {
      div(
        style = "text-align: center; color: #999; margin-top: 40px; font-size: 18px;",
        "Waiting for scans..."
      )
    }
  })
  
  # Batch count
  output$batch_count <- renderText({
    if (state$current_state == 1) {
      length(state$batch_samples)
    } else {
      "0"
    }
  })
  
  # Invalid warning UI
  output$invalid_warning_ui <- renderUI({
    if (state$show_invalid) {
      div(
        class = "invalid-warning",
        h2("❌ INVALID"),
        p(state$invalid_code),
        p(style = "font-size: 16px; margin-top: 20px;", "Scan not recognized")
      )
    }
  })
  
  # Success flash UI
  output$success_flash_ui <- renderUI({
    if (state$show_success) {
      div(
        class = "success-flash",
        h2("✓ SUCCESS"),
        p(state$show_success_code)
      )
    }
  })
  
  # Keep input focused via shinyjs (backup method)
  observe({
    shinyjs::runjs("
      document.getElementById('master_scanner_input').focus();
    ")
  })
}

# ============================================================
# RUN APPLICATION
# ============================================================

shinyApp(ui = ui, server = server)
