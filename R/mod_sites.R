# mod_sites.R
sitesUI <- function(id) {
  ns <- NS(id)
  div(
    textInput(ns("site_id"), "Site ID", placeholder = "e.g. ST0001"),
    helpText("Format: ST followed by 4 digits (ST0001 – ST9999)"),
    textInput(ns("site_name"), "Site Name", placeholder = "e.g. North meadow plot"),
    br(),
    actionButton(ns("create_btn"), "Create Site", class = "btn-primary", width = "100%"),
    uiOutput(ns("create_status"))
  )
}

sitesServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$create_btn, {
      site_id <- trimws(input$site_id)
      site_name <- trimws(input$site_name)
      
      if (site_id == "") {
        showNotification("❌ Please enter a Site ID", type = "error", duration = 5)
        return()
      }
      if (!grepl("^ST\\d{4}$", site_id)) {
        showNotification("❌ Site ID must be ST followed by 4 digits", type = "error", duration = 5)
        return()
      }
      if (site_name == "") {
        showNotification("❌ Please enter a site name", type = "error", duration = 5)
        return()
      }
      
      con <- poolCheckout(pool)
      on.exit(poolReturn(con))
      
      if (check_site_exists(site_id, con)) {
        showNotification(paste("❌ Site", site_id, "already exists"), type = "error", duration = 5)
        return()
      }
      
      tryCatch({
        insert_site(site_id, site_name, con = con)
        
        output$create_status <- renderUI({
          div(style = "padding:12px; background:#e8f5e9; border-radius:6px; border-left:4px solid #4caf50; margin-top:12px;",
            tags$b("✓ Site created: ", site_id)
          )
        })
        
        shinyjs::runjs(sprintf("document.getElementById('%s').value = '';", session$ns("site_id")))
        shinyjs::runjs(sprintf("document.getElementById('%s').value = '';", session$ns("site_name")))
      }, error = function(e) {
        showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
      })
    })
  })
}
