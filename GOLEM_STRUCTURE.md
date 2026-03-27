# Golem Framework Structure - LIMS Application

## Project Structure

```
lims/
├── R/
│   ├── app_ui.R              # Main UI combining all modules
│   ├── app_server.R          # Main server orchestrating modules
│   ├── run_app.R             # Application launcher
│   ├── fct_db_utils.R        # Database utility functions
│   ├── mod_inventory.R       # Sites/Plant management module
│   ├── mod_labels.R          # Label generation module
│   ├── mod_batch_scan.R      # Batch scanning module
│   └── mod_template.R        # Template for new modules
├── tests/
│   ├── testthat.R            # Testthat configuration
│   └── testthat/
│       ├── test-ids.R        # ID generation and validation tests
│       ├── test-db_operations.R  # Database operation tests
│       └── test-modules.R    # Module integration tests
├── dev/
│   └── 01_start.R            # Development workflow guide
├── data/                      # Data directory (created at runtime)
├── www/                       # Static assets (CSS, JS, images)
├── DESCRIPTION               # Package metadata
├── NAMESPACE                 # Package exports
└── .Rbuildignore            # Files to exclude from build
```

## Key Differences from Previous Structure

### Old Structure
- Single-file `app.R` with mixed UI/server logic
- Database functions scattered across `utils_db.R`
- No standardized module pattern
- Limited testing infrastructure

### New Golem Structure
- **Separation of Concerns**: UI, server, and database logic clearly separated
- **Module Pattern**: Each feature is a self-contained module (`mod_*.R`)
- **Database Layer**: All database operations in `fct_db_utils.R`
- **Shared Pool**: Connection pool passed to all modules
- **Comprehensive Testing**: Unit, integration, and module-level tests
- **Package Infrastructure**: Proper DESCRIPTION, NAMESPACE, etc.

## Running the Application

```r
# Development workflow
source("dev/01_start.R")

# Or directly
library(lims)
run_app()
```

## Module Structure

Each module follows the pattern:

```r
# UI Function
mod_feature_ui <- function(id) {
  ns <- NS(id)
  # Return UI elements with namespaced IDs
}

# Server Function
mod_feature_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    # Use pool for database operations
  })
}
```

## Database Functions

All database operations are in `R/fct_db_utils.R`:
- `initialize_database()` - Create schema
- `insert_site()`, `fetch_all_sites()`, etc. - CRUD operations
- `generate_site_id()`, `validate_site_id()` - ID management
- All functions accept explicit `con` parameter for testability

## Testing

```r
# Run all tests
devtools::test()

# Run specific test file
devtools::test_file("tests/testthat/test-ids.R")

# Test specific function in interactive mode
test_file("tests/testthat/test-db_operations.R")
```

## Adding a New Module

1. Copy `R/mod_template.R` to `R/mod_newfeature.R`
2. Implement `mod_newfeature_ui()` and `mod_newfeature_server()`
3. Add to `app_ui()` in `R/app_ui.R`:
   ```r
   shiny::nav_panel("New Feature", mod_newfeature_ui("newfeature"))
   ```
4. Add to `app_server()` in `R/app_server.R`:
   ```r
   mod_newfeature_server("newfeature", pool = pool)
   ```

## Adding New Database Functions

1. Add to `R/fct_db_utils.R`
2. Document with roxygen comments
3. Test in `tests/testthat/test-db_operations.R`
4. Add to NAMESPACE (via roxygen `@export`)

## Development Commands

```r
# Load package with all changes
devtools::load_all()

# Check for errors
devtools::check()

# Run tests
devtools::test()

# Build documentation (from roxygen comments)
devtools::document()

# Build package
devtools::build()
```

## Testing Strategy

### Unit Tests (test-ids.R)
- ID generation and validation
- Regex pattern matching
- Input sanitization

### Database Tests (test-db_operations.R)
- Uses `:memory:` SQLite database
- Tests CRUD operations
- Tests data integrity
- No dependencies on external files

### Integration Tests (test-modules.R)
- Uses `shiny::testServer()`
- Tests module interactions
- Verifies database writes from modules
- Tests UI rendering

## Benefits of Golem Structure

✅ **Scalability**: Easy to add new modules and features  
✅ **Testability**: All functions are testable with explicit dependencies  
✅ **Maintainability**: Clear separation of concerns  
✅ **Professional**: Follows R package standards  
✅ **Reusability**: Modules can be shared across projects  
✅ **Documentation**: Roxygen comments generate help files  
