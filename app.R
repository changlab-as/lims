# LIMS Shiny Application
# Professional modular structure using Shiny modules
# Global configuration and modules are sourced by global.R

# ============================================================
# USER INTERFACE
# ============================================================

ui <- page_navbar(
  title = "🧪 Chang Lab LIMS",
  theme = bslib::bs_theme(bootswatch = "flatly"),
  
  # Navigation panels
  nav_panel("Create Sites", sitesUI("sites")),
  
  # Header with CSS and JavaScript initialization
  header = tagList(
    shinyjs::useShinyjs(),
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"))
  ),
  
  # Footer
  footer = tags$footer(
    style = "margin-top: 40px; padding: 20px; border-top: 1px solid #ddd; text-align: center; color: #999;",
    "Chang Lab LIMS v1.0 | Built with Shiny"
  ),
  
  id = "main_navbar"
)

# ============================================================
# SERVER LOGIC
# ============================================================

server <- function(input, output, session) {
  # Initialize modules
  sitesServer("sites")
}

# ============================================================
# RUN APPLICATION
# ============================================================

shinyApp(ui = ui, server = server)


