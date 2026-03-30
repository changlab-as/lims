#!/usr/bin/env Rscript
# Initialize renv and install dependencies

# Install renv if not present
if (!require("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Initialize renv
renv::init(bare = TRUE)

# Install dependencies from DESCRIPTION
renv::install()

cat("✓ renv initialized and dependencies installed!\n")
