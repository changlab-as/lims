#' Inventory Module (Sites and Plant Management)
#'
#' This module handles site creation and management
#'
#' @param id Module namespace ID
#'
#' @export
mod_inventory_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::div(class = "site-card",
    shiny::textInput(ns("site_id"), "Site ID", placeholder = "e.g. ST0001"),
    shiny::helpText("Format: ST followed by 4 digits (ST0001 – ST9999)"),
    shiny::textInput(ns("site_name"), "Site Name", placeholder = "e.g. North meadow plot"),
    shiny::br(),
    shiny::actionButton(ns("create_btn"), "Create Site", 
                       class = "btn-primary", width = "100%"),
    shiny::uiOutput(ns("create_status"))
  )
}

#' @rdname mod_inventory_ui
#' @export
mod_inventory_server <- function(id, pool) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # Handle Create Site button
    shiny::observeEvent(input$create_btn, {
      site_id <- trimws(input$site_id)
      site_name <- trimws(input$site_name)
      
      # Validation
      if (site_id == "") {
        shiny::showNotification("❌ Please enter a Site ID", 
                               type = "error", duration = 5)
        return()
      }
      
      if (!validate_site_id(site_id)) {
        shiny::showNotification("❌ Site ID must be ST followed by 4 digits", 
                               type = "error", duration = 5)
        return()
      }
      
      if (site_name == "") {
        shiny::showNotification("❌ Please enter a site name", 
                               type = "error", duration = 5)
        return()
      }
      
      # Database operations
      con <- pool::poolCheckout(pool)
      on.exit(pool::poolReturn(con))
      
      if (check_site_exists(site_id, con)) {
        shiny::showNotification(paste("❌ Site", site_id, "already exists"), 
                               type = "error", duration = 5)
        return()
      }
      
      tryCatch({
        insert_site(site_id, site_name, con = con)
        
        # Success message
        output$create_status <- shiny::renderUI({
          shiny::div(style = "padding:12px; background:#e8f5e9; 
                     border-radius:6px; border-left:4px solid #4caf50; 
                     margin-top:12px;",
            shiny::tags$b("✓ Site created: ", site_id)
          )
        })
        
        # Clear inputs
        shinyjs::runjs(sprintf(
          "document.getElementById('%s').value = '';", 
          session$ns("site_id")
        ))
        shinyjs::runjs(sprintf(
          "document.getElementById('%s').value = '';", 
          session$ns("site_name")
        ))
        
      }, error = function(e) {
        shiny::showNotification(paste("❌ Error:", e$message), 
                               type = "error", duration = 5)
      })
    })
  })
}
