#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # External resources
    golem_add_external_resources(),
    
    # Main app with navbar
    shiny::navbarPage(
      title = "Chang Lab LIMS",
      
      # HOME TAB
      shiny::tabPanel(
        "Home",
        mod_home_ui("home")
      ),
      
      # SITES TAB (placeholder)
      shiny::tabPanel(
        "Sites",
        mod_sites_ui("sites")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(ext = 'png'),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "lims"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
