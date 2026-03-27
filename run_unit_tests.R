#!/usr/bin/env Rscript
# Install testthat if needed and run tests
if (!requireNamespace('testthat', quietly = TRUE)) {
  install.packages('testthat', quiet = TRUE)
}
source('tests/run_tests.R')
