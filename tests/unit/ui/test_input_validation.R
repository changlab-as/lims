#!/usr/bin/env Rscript

# Input Validation Test
# Validates that plant ID format validation works correctly

test_input_validation <- function() {
  test_name <- "Plant ID Input Validation"
  
  # Test cases for plant ID pattern
  valid_patterns <- c("ST0001-P0001", "ST1234-P5678", "ST9999-P9999")
  invalid_patterns <- c("ST001-P001", "ST0001P0001", "P0001-ST0001", "invalid", "")
  
  pattern <- "^ST\\d{4}-P\\d{4}$"
  
  # Test valid patterns
  for (id in valid_patterns) {
    if (!grepl(pattern, id)) {
      stop(sprintf("Valid ID rejected: %s", id))
    }
  }
  
  # Test invalid patterns
  for (id in invalid_patterns) {
    if (grepl(pattern, id)) {
      stop(sprintf("Invalid ID accepted: %s", id))
    }
  }
  
  return(TRUE)
}

if (sys.nframe() == 0) {
  result <- test_input_validation()
  if (result) {
    cat("✓ Input Validation Test PASSED\n")
  }
}
