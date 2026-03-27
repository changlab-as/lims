#' Batch Scan Module (Barcode Scanner)
#'
#' This module handles batch scanning of samples
#'
#' @param id Module namespace ID
#'
#' @export
mod_batch_scan_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::div(class = "site-card",
    shiny::h3("📱 Batch Scan"),
    
    shiny::textInput(ns("scanner_input"), 
                    "Scanner Input", 
                    placeholder = "Hold Alt+S and scan barcode"),
    
    shiny::selectInput(ns("site_id"), "Site", choices = NULL),
    
    shiny::br(),
    shiny::actionButton(ns("quick_scan_btn"), "Quick Scan",
                       class = "btn-primary", width = "100%"),
    
    shiny::uiOutput(ns("scan_status")),
    
    shiny::hr(),
    shiny::h4("Recent Scans"),
    DT::dataTableOutput(ns("scans_table"))
  )
}

#' @rdname mod_batch_scan_ui
#' @export
mod_batch_scan_server <- function(id, pool) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # Reactive trigger for table updates
    scans_trigger <- shiny::reactive({
      input$quick_scan_btn
      input$scanner_input  # Also trigger on scanner input
    })
    
    # Update site choices
    shiny::observe({
      con <- pool::poolCheckout(pool)
      on.exit(pool::poolReturn(con))
      
      sites <- fetch_all_sites(con)
      
      if (nrow(sites) > 0) {
        site_choices <- setNames(
          sites$site_id, 
          paste0(sites$site_id, " - ", sites$site_name)
        )
        shiny::updateSelectInput(session, "site_id", choices = site_choices)
      }
    })
    
    # Handle quick scan button
    shiny::observeEvent(input$quick_scan_btn, {
      scan_data <- trimws(input$scanner_input)
      site_id <- input$site_id
      
      if (scan_data == "") {
        shiny::showNotification("❌ Please scan or enter a barcode", 
                               type = "error", duration = 5)
        return()
      }
      
      if (is.null(site_id) || site_id == "") {
        shiny::showNotification("❌ Please select a Site", 
                               type = "error", duration = 5)
        return()
      }
      
      # Parse scanned data (format: SAMPLE_ID|TYPE)
      parts <- strsplit(scan_data, "\\|")[[1]]
      sample_id <- if (length(parts) > 0) trimws(parts[1]) else scan_data
      
      # Generate scan ID
      scan_id <- paste0(site_id, "_", format(Sys.time(), "%Y%m%d%H%M%S"))
      
      # Database operations
      con <- pool::poolCheckout(pool)
      on.exit(pool::poolReturn(con))
      
      tryCatch({
        insert_batch_scan(scan_id, site_id, sample_id, "scanner_1", con = con)
        
        # Play success beep
        shinyjs::runjs("
          const audioContext = new (window.AudioContext || window.webkitAudioContext)();
          const oscillator = audioContext.createOscillator();
          const gainNode = audioContext.createGain();
          oscillator.connect(gainNode);
          gainNode.connect(audioContext.destination);
          oscillator.frequency.value = 800;
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
          oscillator.start();
          oscillator.stop(audioContext.currentTime + 0.1);
        ")
        
        # Success message
        output$scan_status <- shiny::renderUI({
          shiny::div(style = "padding:12px; background:#e8f5e9; 
                     border-radius:6px; border-left:4px solid #4caf50; 
                     margin-top:12px;",
            shiny::tags$b("✓ Scan recorded: ", sample_id)
          )
        })
        
        # Clear input
        shinyjs::runjs(sprintf(
          "document.getElementById('%s').value = '';", 
          session$ns("scanner_input")
        ))
        
      }, error = function(e) {
        shiny::showNotification(paste("❌ Error:", e$message), 
                               type = "error", duration = 5)
      })
    })
    
    # Render scans table
    output$scans_table <- DT::renderDataTable({
      scans_trigger()
      
      con <- pool::poolCheckout(pool)
      on.exit(pool::poolReturn(con))
      
      scans <- fetch_all_batch_scans(con)
      
      if (nrow(scans) == 0) {
        return(DT::datatable(data.frame(
          Scan_ID = character(),
          Site = character(),
          Sample = character(),
          Time = character()
        ), rownames = FALSE))
      }
      
      scans_display <- scans %>%
        dplyr::select(scan_id, site_name, sample_id, scan_time) %>%
        dplyr::rename(
          Scan_ID = scan_id,
          Site = site_name,
          Sample = sample_id,
          Time = scan_time
        ) %>%
        dplyr::arrange(desc(Time))
      
      DT::datatable(scans_display,
        rownames = FALSE,
        options = list(
          pageLength = 10,
          ordering = TRUE,
          paging = TRUE
        )
      )
    }, server = TRUE)
  })
}
