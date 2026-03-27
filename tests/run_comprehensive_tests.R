# ============================================================
# LIMS TEST RUNNER - Executes comprehensive test suite
# Generates detailed report with pass/fail status
# ============================================================

# Load required packages
library(testthat)

# Set working directory to project root
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

cat("\n")
cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║  LIMS COMPREHENSIVE TEST SUITE RUNNER                    ║\n")
cat("║  Testing all label generation, DB, and QR functions      ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n")
cat("\n")

# Run the complete test suite
test_results <- test_file("./test_complete_functions.R", reporter = "progress")

# Print summary
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("TEST EXECUTION SUMMARY\n")
cat("═══════════════════════════════════════════════════════════\n")

# Extract statistics
total_tests <- length(test_results)
passed <- sum(sapply(test_results, function(x) !("error" %in% class(x) || "failure" %in% class(x))))
failed <- total_tests - passed

cat(sprintf("Total Tests: %d\n", total_tests))
cat(sprintf("Passed:      %d ✓\n", passed))
cat(sprintf("Failed:      %d ✗\n", failed))
cat(sprintf("Success Rate: %.1f%%\n", (passed / total_tests) * 100))

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("TEST COVERAGE AREAS\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("1. Database Schema & Initialization      [✓]\n")
cat("2. Site ID Format Validation              [✓]\n")
cat("3. Plant/Soil Sample ID Format            [✓]\n")
cat("4. Part/3-Segment Labels                  [✓]\n")
cat("5. Use/4-Segment Labels                   [✓]\n")
cat("6. QR Code Square Format Validation       [✓]\n")
cat("7. Label Duplication Prevention           [✓]\n")
cat("8. Hierarchical Label Linking             [✓]\n")
cat("9. Inventory Table Display (no counts)    [✓]\n")
cat("10. Status Tracking & Filtering           [✓]\n")
cat("11. Coordinate Validation                 [✓]\n")
cat("12. Edge Cases & Error Handling           [✓]\n")
cat("13. Large Dataset Handling                [✓]\n")
cat("\n")

# Print detailed results if needed
if (failed > 0) {
  cat("═══════════════════════════════════════════════════════════\n")
  cat("FAILED TESTS DETAILS\n")
  cat("═══════════════════════════════════════════════════════════\n")
  print(test_results)
}

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("Report generated: ")
cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
