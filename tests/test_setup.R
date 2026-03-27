# Test Setup and Configuration
# Ensures all test dependencies are available

# Check and install required packages for testing
required_packages <- c("testthat", "RSQLite", "DBI")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, quiet = TRUE)
  }
}

# Load all required packages
library(testthat)
library(RSQLite)
library(DBI)

# Source the logic modules that are tested
# (These need to be available during testing)
source("R/segments/01_site_management/logic.R", local = FALSE)

cat("✓ Test environment ready\n")
