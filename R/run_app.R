#' Run the LIMS Application
#'
#' Launches the Shiny application with database pool
#'
#' @export
run_app <- function() {
  
  # Initialize database
  db_path <- initialize_database()
  
  # Create connection pool
  pool <- pool::dbPool(
    drv     = RSQLite::SQLite(),
    dbname  = db_path,
    minSize = 1,
    maxSize = 5
  )
  
  # Cleanup on app stop
  shiny::onStop(function() {
    pool::poolClose(pool)
  })
  
  # Run the application
  shiny::shinyApp(
    ui = app_ui,
    server = function(input, output, session) {
      app_server(input, output, session, pool)
    }
  )
}
