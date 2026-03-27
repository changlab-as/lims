# mod_labels.R
labelsUI <- function(id) {
  ns <- NS(id)
  div(
    selectInput(ns("site_id"), "Site", choices = NULL),
    textInput(ns("sample_id"), "Sample ID", placeholder = "e.g. SAMPLE001"),
    selectInput(ns("sample_type"), "Sample Type",
      choices = c("Plant Tissue" = "plant_tissue", "Seed" = "seed", "Pollen" = "pollen", "Other" = "other")),
    br(),
    actionButton(ns("generate_btn"), "Generate Label", class = "btn-primary", width = "100%"),
    uiOutput(ns("generate_status"))
  )
}

labelsServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    observe({
      con <- poolCheckout(pool)
      on.exit(poolReturn(con))
      sites <- fetch_all_sites(con)
      site_choices <- setNames(sites$site_id, paste0(sites$site_id, " - ", sites$site_name))
      updateSelectInput(session, "site_id", choices = site_choices)
    })
    
    observeEvent(input$generate_btn, {
      site_id <- input$site_id
      sample_id <- trimws(input$sample_id)
      sample_type <- input$sample_type
      
      if (is.null(site_id) || site_id == "") {
        showNotification("❌ Please select a Site", type = "error", duration = 5)
        return()
      }
      if (sample_id == "") {
        showNotification("❌ Please enter a Sample ID", type = "error", duration = 5)
        return()
      }
      
      label_id <- paste0(site_id, "_", sample_id, "_", Sys.Date())
      
      con <- poolCheckout(pool)
      on.exit(poolReturn(con))
      
      try({
        insert_label(label_id, 1, site_id, sample_type, sample_id, con = con)
        
        output$generate_status <- renderUI({
          div(style = "padding:12px; background:#e8f5e9; border-radius:6px; border-left:4px solid #4caf50; margin-top:12px;",
            tags$b("✓ Label created: ", label_id)
          )
        })
        
        shinyjs::runjs(sprintf("document.getElementById('%s').value = '';", session$ns("sample_id")))
      }, silent = TRUE)
    })
  })
}
