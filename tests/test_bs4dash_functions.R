#!/usr/bin/env Rscript
# Test bs4Dash available functions

cat("\n=== Testing bs4Dash Functions ===\n\n")

library(bs4Dash)

# List all bs4 prefixed functions
cat("Functions starting with 'bs4':\n")
bs4_funcs <- grep("^bs4", ls(getNamespace("bs4Dash")), value = TRUE)
for (func in sort(bs4_funcs)) {
  cat(sprintf("  - %s\n", func))
}

cat("\n\nSearching for Row/Column functions:\n")
row_col <- grep("row|column|Row|Column", ls(getNamespace("bs4Dash")), value = TRUE, ignore.case = TRUE)
for (func in sort(row_col)) {
  cat(sprintf("  - %s\n", func))
}

cat("\n\nTesting if bs4Row exists:\n")
if (exists("bs4Row")) {
  cat("✓ bs4Row exists\n")
} else {
  cat("✗ bs4Row does NOT exist\n")
}

cat("\nTesting if bs4Column exists:\n")
if (exists("bs4Column")) {
  cat("✓ bs4Column exists\n")
} else {
  cat("✗ bs4Column does NOT exist\n")
}

cat("\n\nAll available bs4Dash functions:\n")
all_bs4 <- ls(getNamespace("bs4Dash"))
for (i in 1:min(30, length(all_bs4))) {
  cat(sprintf("%2d. %s\n", i, all_bs4[i]))
}

if (length(all_bs4) > 30) {
  cat(sprintf("... and %d more\n", length(all_bs4) - 30))
}
