#' Home Page Module UI
#'
#' Display lab logo and LIMS description
#'
#' @param id Module ID
#'
#' @return Shiny UI
#'
#' @export
mod_home_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::div(
    class = "home-page",
    style = "text-align: center; padding: 60px 20px;",
    
    # Logo placeholder (we'll add your actual logo here)
    shiny::div(
      class = "logo-container",
      style = "margin-bottom: 40px;",
      shiny::tags$img(
        src = "www/logo.png",
        height = "300px",
        alt = "Lab Logo"
      )
    ),
    
    # Title
    shiny::h1("Chang Lab LIMS", style = "color: #2c3e50; margin-bottom: 20px;"),
    
    # Subtitle
    shiny::h3("Laboratory Information Management System", 
              style = "color: #7f8c8d; font-weight: 300; margin-bottom: 40px;"),
    
    # Description
    shiny::div(
      class = "description",
      style = "max-width: 600px; margin: 0 auto; line-height: 1.8; color: #34495e; font-size: 16px;",
      shiny::p(
        "Track your lab samples from collection to storage and use.",
        shiny::br(),
        "Manage sample sites, generate QR codes for quick identification, ",
        "and maintain complete records of sample storage locations and usage history."
      )
    ),
    
    # Quick stats (optional - can expand later)
    shiny::div(
      class = "quick-stats",
      style = "margin-top: 60px; display: flex; justify-content: center; gap: 40px;",
      shiny::div(
        style = "text-align: center;",
        shiny::h2("0", style = "color: #3498db; margin: 0;"),
        shiny::p("Sites", style = "color: #7f8c8d; margin: 5px 0 0 0;")
      ),
      shiny::div(
        style = "text-align: center;",
        shiny::h2("0", style = "color: #2ecc71; margin: 0;"),
        shiny::p("Samples", style = "color: #7f8c8d; margin: 5px 0 0 0;")
      ),
      shiny::div(
        style = "text-align: center;",
        shiny::h2("0", style = "color: #e74c3c; margin: 0;"),
        shiny::p("Scans", style = "color: #7f8c8d; margin: 5px 0 0 0;")
      )
    ),
    
    # Footer note
    shiny::div(
      style = "margin-top: 80px; color: #95a5a6; font-size: 14px;",
      shiny::p("Use the navigation tabs above to get started")
    )
  )
}

#' Home Page Module Server
#'
#' @param id Module ID
#'
#' @return Module server logic
#'
#' @export
mod_home_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Home page is mostly static - no server logic needed yet
  })
}
