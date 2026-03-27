# Test Runner for LIMS Unit Tests
# Runs all segment tests and reports results

# Setup test environment first
source("tests/test_setup.R")

# Identify test directory
test_dir <- "tests/segments"

if (!dir.exists(test_dir)) {
  stop(paste("Test directory not found:", test_dir))
}

# Get all test files
test_files <- list.files(test_dir, pattern = "^test_.*\\.R$", full.names = TRUE)

if (length(test_files) == 0) {
  stop("No test files found in tests/segments/")
}

cat("\n🧪 Running LIMS Unit Tests\n")
cat(paste(rep("=", 50), collapse = ""), "\n\n")

# Run all tests
for (test_file in test_files) {
  cat(sprintf("Testing: %s\n", basename(test_file)))
}

# Run tests with reporting
results <- testthat::test_dir(test_dir, reporter = "progress")

# Summary
cat("\n", paste(rep("=", 50), collapse = ""), "\n", sep = "")
cat("Test Summary:\n")
if (!is.null(results$.data)) {
  # Extract test results
  results_df <- as.data.frame(results)
  total_tests <- nrow(results_df)
  passed <- sum(results_df$result == "PASS", na.rm = TRUE)
  failed <- sum(results_df$result == "FAIL", na.rm = TRUE)
  skipped <- sum(results_df$result == "SKIP", na.rm = TRUE)
  
  cat(sprintf("✓ Passed: %d\n", passed))
  cat(sprintf("✗ Failed: %d\n", failed))
  if (skipped > 0) cat(sprintf("⊝ Skipped: %d\n", skipped))
  cat(sprintf("Total: %d\n", total_tests))
}

cat("\n")
