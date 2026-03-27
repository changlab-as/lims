# mod_template.R
# TEMPLATE: Copy this file to create a new Shiny module
# Instructions:
# 1. Copy this file and rename to: mod_YOUR_FEATURE.R
# 2. Replace "template" with your feature name throughout
# 3. Remove this comment block
# 4. Add your UI elements and server logic
# 5. Source in global.R: source("R/mod_your_feature.R")
# 6. Add to app.R UI: nav_panel("Your Feature", templateUI("template"))
# 7. Add to app.R server: templateServer("template")

# ============================================================
# Module: Template Feature
# ============================================================

templateUI <- function(id) {
  ns <- NS(id)  # Create namespace
  
  div(
    # Header
    h3("📌 Feature Title"),
    p(style = "color:#666; margin-bottom:24px;",
      "Description of what this module does."),

    # Input Section
    div(style = "background:#f9f9f9; padding:20px; border-radius:8px; margin-bottom:20px;",
      h5("Input Section"),
      
      textInput(ns("input1"),
        label = "First Input",
        placeholder = "Enter something"),

      selectInput(ns("select1"),
        label = "Choose Option",
        choices = c("Option 1", "Option 2", "Option 3")),

      br(),
      actionButton(ns("action_btn"), "Submit",
        class = "btn-primary", width = "100%"),

      # Status message area
      div(class = "status-box",
        uiOutput(ns("action_status")))
    ),

    # Output Section
    hr(),
    h5("Results"),
    DT::dataTableOutput(ns("results_table"))
  )
}

templateServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive trigger for table refresh
    action_trigger <- reactive({
      input$action_btn
    })
    
    # ── Handle action button ───────────────────────────────────
    
    observeEvent(input$action_btn, {
      # Get input values
      value1 <- trimws(input$input1)
      value2 <- input$select1
      
      # Validation
      if (value1 == "") {
        showNotification("❌ Please fill in all fields", 
          type = "error", duration = 5)
        return()
      }
      
      # Database operations (if needed)
      con <- poolCheckout(pool)
      on.exit(poolReturn(con))
      
      # Do something...
      # data <- fetch_data(con)
      
      # Show success
      output$action_status <- renderUI({
        div(style = "padding:16px; background:#e8f5e9; border-radius:6px;
                     border-left:4px solid #4caf50; margin-top:12px;",
          tags$b("✓ Action completed"),
          tags$p(tags$b("Input: "), value1),
          tags$p(tags$b("Selected: "), value2)
        )
      })
      
      # Clear inputs (optional)
      shinyjs::runjs(sprintf("document.getElementById('%s').value = '';", 
                             session$ns("input1")))
      
      showNotification("✓ Action successful", type = "message", duration = 4)
    })
    
    # ── Render results table ───────────────────────────────────
    
    output$results_table <- DT::renderDataTable({
      # Make table react to action_trigger
      action_trigger()
      
      # Fetch data
      con <- poolCheckout(pool)
      on.exit(poolReturn(con))
      
      # Replace with actual data fetching
      data <- data.frame(
        Column1 = c("Value 1", "Value 2", "Value 3"),
        Column2 = c("Data A", "Data B", "Data C"),
        Column3 = c(100, 200, 300)
      )
      
      # Handle empty results
      if (nrow(data) == 0) {
        return(DT::datatable(data.frame(
          Column1 = character(),
          Column2 = character(),
          Column3 = numeric()
        ), rownames = FALSE, options = list(dom = 't')))
      }
      
      # Render table
      DT::datatable(data,
        rownames = FALSE,
        options = list(
          pageLength = 10,
          searching = TRUE,
          ordering = TRUE,
          paging = TRUE,
          scrollY = "400px",
          dom = 'lfrtip'
        ),
        selection = 'none'
      )
    }, server = TRUE)
  })
}
