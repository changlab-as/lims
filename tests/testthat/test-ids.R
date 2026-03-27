library(testthat)

# Test ID generators and validation functions

test_that("Site ID format validation works correctly", {
  expect_true(validate_site_id("ST0001"))
  expect_true(validate_site_id("ST9999"))
  expect_true(validate_site_id("ST0000"))
  
  expect_false(validate_site_id("ST001"))   # Too few digits
  expect_false(validate_site_id("ST00001"))  # Too many digits
  expect_false(validate_site_id("st0001"))   # Lowercase
  expect_false(validate_site_id("ST000A"))   # Contains letter
  expect_false(validate_site_id(""))         # Empty
})

test_that("Site ID generation creates properly formatted IDs", {
  for (i in 1:10) {
    site_id <- generate_site_id()
    expect_match(site_id, "^ST\\d{4}$")
    expect_length(site_id, 1)
  }
})

test_that("Plant ID generation creates properly formatted IDs", {
  for (i in 1:10) {
    plant_id <- generate_plant_id("ST0001")
    expect_match(plant_id, "^P\\d{4}$")
    expect_length(plant_id, 1)
  }
})

test_that("Processing ID generation creates properly formatted IDs", {
  for (i in 1:10) {
    proc_id <- generate_proc_id()
    expect_match(proc_id, "^PR\\d{4}$")
    expect_length(proc_id, 1)
  }
})

test_that("Sample ID validation works correctly", {
  expect_true(validate_sample_id("SAMPLE001"))
  expect_true(validate_sample_id("S123"))
  expect_true(validate_sample_id("A"))
  
  expect_false(validate_sample_id(""))
  expect_false(validate_sample_id("   "))  # Only whitespace
})

test_that("Multiple generated IDs are unique", {
  site_ids <- replicate(100, generate_site_id())
  expect_equal(length(unique(site_ids)), length(site_ids))
  
  plant_ids <- replicate(100, generate_plant_id("ST0001"))
  expect_equal(length(unique(plant_ids)), length(plant_ids))
})
