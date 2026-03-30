test_that("Site ID format is valid", {
  valid_id <- "ST0001"
  invalid_id <- "ST00001"
  
  expect_true(validate_site_id(valid_id))
  expect_false(validate_site_id(invalid_id))
})

test_that("Site ID is generated in correct format", {
  for (i in 1:10) {
    id <- generate_site_id()
    expect_match(id, "^ST\\d{4}$")
  }
})

test_that("Sample ID validation works", {
  expect_true(validate_sample_id("SAMPLE-001"))
  expect_false(validate_sample_id(""))
  expect_false(validate_sample_id(NA))
})

test_that("Generated IDs are unique", {
  ids <- vapply(1:100, function(i) generate_site_id(), character(1))
  expect_equal(length(unique(ids)), length(ids))
})
