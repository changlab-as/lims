#!/usr/bin/env Rscript
# Quick test to verify testthat is installed and unit tests work

library(testthat)

# Run the tests from tests/test_mod_sites.R
cat("\n🧪 Running unit tests for mod_sites...\n\n")

test_file("tests/test_mod_sites.R")

cat("\n✅ Tests completed\n")
