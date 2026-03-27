#!/usr/bin/env Rscript
# Package Installation Script for Riverside Rhizobia LIMS

packages <- c(
  "shiny",        # Web application framework
  "bs4Dash",      # Bootstrap 4 dashboard (legacy support)
  "bslib",        # Bootstrap theming engine (new)
  "shinyjs",      # JavaScript interaction & audio playback
  "DT",           # DataTables for interactive tables
  "RSQLite",      # SQLite database driver
  "qrcode",       # QR code generation
  "pool",         # Database connection pooling
  "dplyr",        # Data manipulation
  "DBI",          # Database interface
  "gridExtra",    # Grid layouts for labels
  "grid",         # Graphics grid
  "base64enc"     # Base64 encoding for images
)

# Check and install missing packages
missing_packages <- packages[!packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages, repos = "https://cran.r-project.org/")
} else {
  cat("All packages already installed.\n")
}

# Load all packages
cat("Loading packages...\n")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("ERROR: Failed to load package:", pkg, "\n")
    stop(paste("Package", pkg, "failed to load"))
  }
}

cat("✓ All packages ready!\n")
cat("Ready to run: shiny::runApp()\n")
