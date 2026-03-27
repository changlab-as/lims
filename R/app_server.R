#' App Server
#'
#' Application server orchestrating all modules
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param pool Database connection pool
#'
#' @export
app_server <- function(input, output, session, pool) {
  
  # Initialize all modules with the shared pool
  mod_inventory_server("inventory", pool = pool)
  mod_labels_server("labels", pool = pool)
  mod_batch_scan_server("batch_scan", pool = pool)
}
