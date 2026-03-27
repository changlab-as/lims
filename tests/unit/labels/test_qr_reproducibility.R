#!/usr/bin/env Rscript

# QR Code Reproducibility Test
# Validates that QR codes are generated consistently with seed-based generation

library(qrcode)

test_qr_reproducibility <- function() {
  test_name <- "QR Code Reproducibility"
  
  # Generate same QR twice with same seed
  test_id <- "REPRODUCE_TEST"
  
  # First generation
  set.seed(as.integer(charToRaw(test_id)) %% 2147483647)
  qr_1 <- qr_code(test_id)
  
  # Second generation with same seed
  set.seed(as.integer(charToRaw(test_id)) %% 2147483647)
  qr_2 <- qr_code(test_id)
  
  # Both should produce identical QR codes
  if (!all(dim(qr_1) == dim(qr_2))) {
    stop("QR reproducibility failed: different dimensions")
  }
  
  # Check that the QR matrices are identical
  if (!all(qr_1 == qr_2)) {
    stop("QR reproducibility failed: different content")
  }
  
  return(TRUE)
}

if (sys.nframe() == 0) {
  result <- test_qr_reproducibility()
  if (result) {
    cat("✓ QR Code Reproducibility Test PASSED\n")
  }
}
