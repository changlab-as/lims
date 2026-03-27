#!/usr/bin/env Rscript

# UI Components & Rendering Test
# Validates that app.R loads without errors and all UI components are created correctly
# Catches issues like invalid input parameters (e.g., textInput with style)

test_app_loading <- function() {
  test_name <- "App Loading & UI Rendering"
  
  if (!file.exists("app.R")) {
    stop("app.R not found")
  }
  
  tryCatch({
    # Parse app.R for syntax errors
    parse(file = "app.R")
    
    # Source app.R in isolated environment to catch UI rendering errors
    # This checks all input() and output() components
    app_env <- new.env()
    source("app.R", local = app_env, echo = FALSE)
    
    # Verify that ui and server objects exist
    if (!exists("ui", where = app_env)) {
      stop("UI object not created after sourcing app.R")
    }
    if (!exists("server", where = app_env)) {
      stop("Server function not created after sourcing app.R")
    }
    
    # Additional validation: Check that ui is callable
    ui_obj <- get("ui", envir = app_env)
    if (!is.function(ui_obj) && !inherits(ui_obj, "shiny.tag")) {
      stop("UI object is not a valid Shiny tag/function")
    }
    
    return(TRUE)
    
  }, error = function(e) {
    stop(sprintf("Error loading app.R: %s", e$message))
  })
}

if (sys.nframe() == 0) {
  result <- test_app_loading()
  if (result) {
    cat("✓ App Loading Test PASSED\n")
  }
}
