# Install required packages for Riverside Rhizobia LIMS
# Run this file once to install all dependencies

packages_needed <- c(
  "shiny",           # Shiny web framework
  "bs4Dash",         # Bootstrap 4 Dashboard
  "shinyjs",         # JavaScript interactions
  "DT",              # DataTables for R
  "RSQLite",         # SQLite database driver
  "qrcode",          # QR code generation
  "pool",            # Connection pooling for databases
  "dplyr",           # Data manipulation
  "DBI",             # Database interface
  "gridExtra",       # Grid layout for labels
  "png"              # PNG image reading/writing
)

for (pkg in packages_needed) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  } else {
    cat(sprintf("%s is already installed\n", pkg))
  }
}

cat("\nAll required packages are installed!\n")
cat("To run the app, use: shiny::runApp('app.R')\n")
