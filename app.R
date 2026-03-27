# Chang lab LIMS Application - Minimal: Create Site

source("R/global.R")

# ============================================================
# UI
# ============================================================

ui <- page(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  shinyjs::useShinyjs(),
  tags$head(
    tags$style(HTML("
      body { background: #f8f9fa; }
      .site-card { max-width: 560px; margin: 40px auto; padding: 32px;
                   background: #fff; border-radius: 10px;
                   box-shadow: 0 2px 12px rgba(0,0,0,.08); }
      .site-card h3 { margin-bottom: 24px; }
      .status-box { margin-top: 16px; }
    "))
  ),

  div(class = "site-card",
    h3("🏕 Create Site"),
    p(style = "color:#666; margin-bottom:24px;",
      "Register a new field site. Coordinates can be added later."),

    textInput("create_site_id",
      label = "Site ID",
      placeholder = "e.g. ST0001"),
    helpText("Must match: ST followed by 4 digits (ST0001 – ST9999)"),

    textInput("create_site_description",
      label = "Site Name / Description",
      placeholder = "e.g. North meadow plot"),

    br(),
    actionButton("btn_create_site", "Create Site",
      class = "btn-primary", width = "100%"),

    div(class = "status-box",
      uiOutput("create_site_status")),

    hr(),
    h5("Existing Sites"),
    DT::dataTableOutput("existing_sites_table")
  )
)


# ============================================================
# SERVER LOGIC
# ============================================================

server <- function(input, output, session) {
  # Plant ID regex pattern - foolproof validation
  plant_id_pattern <- "^ST\\d{4}-P\\d{4}$"
  
  
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
}

# ============================================================
# RUN APPLICATION
# ============================================================

shinyApp(ui = ui, server = server)

