#' Labels Module (QR Code Label Generation)
#'
#' This module handles label generation with QR codes
#'
#' @param id Module namespace ID
#'
#' @export
mod_labels_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::div(class = "site-card",
    shiny::h3("📋 Generate Labels"),
    
    shiny::selectInput(ns("site_id"), "Site", choices = NULL),
    
    shiny::textInput(ns("sample_id"), 
                    "Sample ID", 
                    placeholder = "e.g. SAMPLE001"),
    
    shiny::selectInput(ns("sample_type"), 
                      "Sample Type",
                      choices = c(
                        "Plant Tissue" = "plant_tissue",
                        "Seed" = "seed",
                        "Pollen" = "pollen",
                        "Other" = "other"
                      )),
    
    shiny::br(),
    shiny::actionButton(ns("generate_btn"), "Generate Label",
                       class = "btn-primary", width = "100%"),
    
    shiny::uiOutput(ns("generate_status"))
  )
}

#' @rdname mod_labels_ui
#' @export
mod_labels_server <- function(id, pool) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # Update site choices dynamically
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
    
    # Handle Generate Label button
    shiny::observeEvent(input$generate_btn, {
      site_id <- input$site_id
      sample_id <- trimws(input$sample_id)
      sample_type <- input$sample_type
      
      # Validation
      if (is.null(site_id) || site_id == "") {
        shiny::showNotification("❌ Please select a Site", 
                               type = "error", duration = 5)
        return()
      }
      
      if (!validate_sample_id(sample_id)) {
        shiny::showNotification("❌ Please enter a Sample ID", 
                               type = "error", duration = 5)
        return()
      }
      
      # Generate label ID
      label_id <- paste0(site_id, "_", sample_id, "_", Sys.Date())
      
      # Database operations
      con <- pool::poolCheckout(pool)
      on.exit(pool::poolReturn(con))
      
      tryCatch({
        insert_label(label_id, 1, site_id, sample_type, sample_id, con = con)
        
        # Success message
        output$generate_status <- shiny::renderUI({
          shiny::div(style = "padding:12px; background:#e8f5e9; 
                     border-radius:6px; border-left:4px solid #4caf50; 
                     margin-top:12px;",
            shiny::tags$b("✓ Label generated: ", label_id)
          )
        })
        
        # Clear inputs
        shinyjs::runjs(sprintf(
          "document.getElementById('%s').value = '';", 
          session$ns("sample_id")
        ))
        
      }, error = function(e) {
        shiny::showNotification(paste("❌ Error:", e$message), 
                               type = "error", duration = 5)
      })
    })
  })
}
