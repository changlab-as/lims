#' labels UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
#' @importFrom DT renderDataTable
#'
#' @export
mod_labels_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::card(
        bslib::card_header("Create Labels"),
        bslib::card_body(
          shiny::selectizeInput(
            ns("site_id"), 
            "Select Site ID",
            choices = NULL,
            options = list(placeholder = "Search for site...")
          ),
          
          shiny::numericInput(
            ns("plant_id_start"),
            "Plant ID (start)",
            value = 1
          ),
          
          shiny::numericInput(
            ns("plant_id_end"),
            "Plant ID (end)",
            value = 20
          ),

          shiny::actionButton(
            ns("create_btn"),
            "Create Label",
            class = "btn-primary w-100"
          )
        )
      ),
      bslib::card(
        bslib::card_header("Created Labels"),
        DT::dataTableOutput(ns("labels_table"))
      )
    )
  )
}
    
#' labels Server Functions
#'
#' @noRd 
#' @export
mod_labels_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    labels_refresh <- shiny::reactiveVal(0)
    
    # Fetch available site IDs and update selectize choices
    shiny::observe({
      tryCatch({
        sites <- lims::db_site_fetch_all(pool)
        if (nrow(sites) > 0) {
          site_choices <- sites$site_id
          shiny::updateSelectizeInput(
            session,
            "site_id",
            choices = site_choices,
            selected = character(0)
          )
        }
      }, error = function(e) {
        # Silently fail if no sites exist yet
      })
    })
    
    # Reactive data frame to store generated plant IDs
    generated_labels <- shiny::reactiveVal(data.frame(
      site_id = character(),
      plant_id = character(),
      created_at = character(),
      stringsAsFactors = FALSE
    ))
    
    # Listen for create button click
    shiny::observeEvent(input$create_btn, {
      site_id <- input$site_id
      plant_id_start <- input$plant_id_start
      plant_id_end <- input$plant_id_end
      
      # Validate inputs
      if (is.null(site_id) || site_id == "") {
        shiny::showNotification(
          "Please select a Site ID",
          type = "error",
          duration = 5
        )
        return()
      }
      
      if (is.null(plant_id_start) || is.null(plant_id_end) || plant_id_start < 1 || plant_id_end > 999 || plant_id_start > plant_id_end) {
        shiny::showNotification(
          "Plant ID must be between 1 and 999, and start must be <= end",
          type = "error",
          duration = 5
        )
        return()
      }
      
      # Generate plant IDs in format: ST0001-P001, ST0001-P002, etc.
      plant_ids <- sprintf("%s-P%03d", site_id, seq(plant_id_start, plant_id_end, by = 1))
      num_plants <- length(plant_ids)
      
      tryCatch({
        # Create data frame with generated plant IDs
        new_labels <- data.frame(
          plant_id = plant_ids,
          site_id = rep(site_id, num_plants),
          created_at = rep(Sys.time(), num_plants),
          stringsAsFactors = FALSE
        )
        
        # Combine with existing labels
        current_labels <- generated_labels()
        all_labels <- rbind(current_labels, new_labels)
        generated_labels(all_labels)
        
        # Show success message
        shiny::showNotification(
          paste("Created", num_plants, "labels for", site_id),
          type = "message",
          duration = 5
        )
        
        # Trigger table refresh
        labels_refresh(labels_refresh() + 1)
        
      }, error = function(e) {
        shiny::showNotification(
          e$message,
          type = "error",
          duration = 5
        )
      })
    
    # Display labels table
    output$labels_table <- DT::renderDataTable({
      labels_refresh()
      
      # Get the generated labels
      labels_data <- generated_labels()
      
      if (nrow(labels_data) == 0) {
        # Return empty table with column names if no labels yet
        labels_data <- data.frame(
          plant_id = character(),
          site_id = character(),
          created_at = character()
        )
      }
      
      DT::datatable(
        labels_data,
        colnames = c("Plant ID", "Site ID", "Created At"),
        options = list(pageLength = 10)
      )
    })
    })
  })
}
    
## To be copied in the UI
# mod_labels_ui("labels_1")
    
## To be copied in the server
# mod_labels_server("labels_1")
