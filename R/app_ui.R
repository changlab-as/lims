#' App UI
#'
#' Main application UI combining all modules
#'
#' @export
app_ui <- function() {
  shiny::page_navbar(
    title = "🧪 Chang Lab LIMS",
    theme = bslib::bs_theme(bootswatch = "flatly"),
    
    # Navigation panels
    shiny::nav_panel("Create Sites", mod_inventory_ui("inventory")),
    shiny::nav_panel("Generate Labels", mod_labels_ui("labels")),
    shiny::nav_panel("Batch Scan", mod_batch_scan_ui("batch_scan")),
    
    # Header with CSS and JavaScript initialization
    header = shiny::tagList(
      shinyjs::useShinyjs(),
      shiny::tags$head(
        shiny::tags$link(
          rel = "stylesheet", 
          type = "text/css", 
          href = "styles.css"
        )
      )
    ),
    
    # Footer
    footer = shiny::tags$footer(
      style = "margin-top: 40px; padding: 20px; border-top: 1px solid #ddd; 
               text-align: center; color: #999;",
      "Chang Lab LIMS v0.1.0 | Built with Shiny + Golem"
    ),
    
    id = "main_navbar"
  )
}
