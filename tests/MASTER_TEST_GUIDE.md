# LIMS Comprehensive Test Suite - Master Guide

## Quick Start

### Run All Tests
```R
# In RStudio, run:
source("tests/run_comprehensive_tests.R")
```

### View Results
- **Summary:** Shows pass/fail counts and success rate
- **Failed Tests:** Lists specific test names and errors
- **Coverage:** 13 functional areas, 25+ individual tests

---

## What's Included

### Test Files Created

1. **`test_complete_functions.R`** (Main Test Suite)
   - 25+ comprehensive test cases
   - ~510 lines of test code
   - Covers all label generation and database functions

2. **`run_comprehensive_tests.R`** (Test Runner)
   - Executes all tests with formatted output
   - Generates summary report
   - Optional detailed failure reporting

3. **`TEST_DOCUMENTATION.md`** (Detailed Docs)
   - 400+ lines of comprehensive documentation
   - Explains each test and expected results
   - Troubleshooting guide
   - Performance benchmarks

4. **`LABEL_FORMAT_REFERENCE.md`** (Quick Reference)
   - Label format specifications
   - Validation rules
   - Common examples
   - Error messages and solutions

---

## Test Coverage Summary

### 1. Database Operations (2 tests)
```
✓ Schema initialization
✓ Column validation
✓ Table structure
✓ Foreign key relationships
```

### 2. Site IDs (3 tests)
```
✓ Format validation: ST####
✓ Reject invalid formats
✓ Accept valid formats
```

### 3. Sample/Plant IDs (3 tests)
```
✓ 2-segment format: ST####-[PS]####
✓ 3-segment format: ST####-[PS]####-XX###
✓ 4-segment format: ST####-[PS]####-XX###-XX##
```

### 4. QR Codes (2 tests)
```
✓ Square image format (CRITICAL)
✓ QR code readability
```

### 5. Pre-Sampling Labels (3 tests)
```
✓ Plant label generation
✓ Soil label generation
✓ Duplicate rejection
```

### 6. Parts Processing (2 tests)
```
✓ Part label format
✓ Parent-child relationships
```

### 7. Use Samples (1 test)
```
✓ Use label generation (full 4-segment)
```

### 8. Inventory Display (3 tests)
```
✓ Unique rows (NOT counts)
✓ Status tracking
✓ Search/filter functionality
```

### 9. Coordinates (3 tests)
```
✓ Latitude validation (-90 to 90)
✓ Longitude validation (-180 to 180)
✓ Precision preservation
```

### 10. Edge Cases (3 tests)
```
✓ Empty database handling
✓ Null value handling
✓ Large dataset (100+ labels)
```

---

## Running Specific Tests

### In RStudio

#### Option 1: Run All Tests from Test File
```R
library(testthat)
test_file("tests/test_complete_functions.R")
```

#### Option 2: Run Single Test
```R
library(testthat)

test_that("Site ID validation accepts valid format", {
  valid_ids <- c("ST0001", "ST0002", "ST9999")
  for (id in valid_ids) {
    is_valid <- grepl("^ST\\d{4}$", id)
    expect_true(is_valid)
  }
})
```

#### Option 3: Run via Command Line
```R
Rscript tests/run_comprehensive_tests.R
```

---

## Expected Output

### Success Scenario
```
═══════════════════════════════════════════════════════════
LIMS COMPREHENSIVE TEST SUITE RUNNER
═══════════════════════════════════════════════════════════

✓ | Database initializes with correct schema
✓ | Database schema has correct columns
✓ | Site creation generates valid ID format
...
[25+ more tests]

═══════════════════════════════════════════════════════════
TEST EXECUTION SUMMARY
═══════════════════════════════════════════════════════════
Total Tests: 25
Passed:      25 ✓
Failed:      0 ✗
Success Rate: 100.0%

═══════════════════════════════════════════════════════════
TEST COVERAGE AREAS
═══════════════════════════════════════════════════════════
1. Database Schema & Initialization      [✓]
2. Site ID Format Validation              [✓]
3. Plant/Soil Sample ID Format            [✓]
4. Part/3-Segment Labels                  [✓]
5. Use/4-Segment Labels                   [✓]
6. QR Code Square Format Validation       [✓]
...
```

---

## Key Test Points

### Critical: QR Code Must Be Square

⚠️ **Most Important Single Test:**
```
"QR code is generated as square image"
```

**Why it matters:**
- Scanning reliability
- Print alignment
- Mobile app compatibility
- Label placement on physical medium

**If this test fails:**
1. Your label generation code has a bug
2. PNG width/height parameters are different
3. Shiny is resizing the image
4. Check: `png(file, width=400, height=400)`

---

### Label Format Requirements

Each test validates specific regex patterns:

| Stage | Format | Regex | Example |
|-------|--------|-------|---------|
| 1 | Site+Sample | `^ST\d{4}-[PS]\d{4}$` | ST0001-P0001 |
| 2 | Site+Sample+Part | `^ST\d{4}-[PS]\d{4}-[A-Z]{2}\d{3}$` | ST0001-P0001-SH001 |
| 3 | Full 4-segment | `^ST\d{4}-[PS]\d{4}-[A-Z]{2}\d{3}-[A-Z]{2}\d{2}$` | ST0001-P0001-SH001-GW01 |

---

### Inventory Table Logic

**Important Concept:** Inventory should show **individual rows**, not aggregated counts.

**Wrong (aggregated):**
```
ST0001-P0001  | count: 5
ST0001-P0002  | count: 3
```

**Correct (individual rows):**
```
ST0001-P0001
ST0001-P0002
ST0001-P0003
```

Test validates: `Should NOT have "count" column`

---

## Troubleshooting

### "All tests passed" but app doesn't work

1. Verify you're importing test results correctly
2. Check that app code matches test assumptions
3. Ensure database schema is identical to test setup
4. Run tests against actual database, not just in-memory

### "QR code test fails"

**Symptom:** `dimensions[1] != dimensions[2]`

**Solutions:**
1. Check PNG generation code - ensure width==height
2. Verify Shiny isn't resizing image
3. Use `dev.off()` to finalize PNG properly

### "Duplicate label test fails"

**Symptom:** No error on duplicate insertion

**Solutions:**
1. Add `PRIMARY KEY` constraint to label_id in database
2. Check schema with: `PRAGMA table_info(Labels)`
3. Ensure `label_id` column has PRIMARY KEY

### "Inventory table test fails"

**Symptom:** Returns "count" column or aggregated data

**Solutions:**
1. Remove `GROUP BY` from query
2. Show all rows: `SELECT * FROM Labels`
3. Don't aggregate or count

---

## Test Maintenance

### Adding New Tests

**Location:** `test_complete_functions.R`

**Template:**
```R
test_that("Clear description of what is tested", {
  # Arrange: Set up test data
  
  # Act: Execute code being tested
  
  # Assert: Verify results
  expect_true(condition)
  expect_equal(actual, expected)
  expect_true(!is.null(result))
})
```

### Updating for Schema Changes

If your database schema changes:

1. Update `setup_test_db()` function at top of test file
2. Update column names in relevant tests
3. Re-run: `source("run_comprehensive_tests.R")`

---

## Documentation Files

### Included Documentation

1. **test_complete_functions.R** (510 lines)
   - Main test code with inline comments
   - Test suites 1-10
   - Setup functions

2. **TEST_DOCUMENTATION.md** (500+ lines)
   - Detailed explanation of each test
   - Expected results and failure scenarios
   - Performance benchmarks
   - Troubleshooting guide

3. **LABEL_FORMAT_REFERENCE.md** (400+ lines)
   - Format specifications with regex
   - Database table structure
   - Validation rules
   - Common examples
   - Print templates

4. **MASTER_TEST_GUIDE.md** (This file)
   - Quick start instructions
   - Coverage summary
   - Troubleshooting
   - Maintenance guide

---

## Performance Notes

**Expected Execution Times:**

| Category | Time |
|----------|------|
| Database tests | < 1 sec |
| ID validation tests | < 1 sec |
| QR code tests | 1-3 sec (PNG I/O) |
| Label generation tests | < 1 sec |
| Inventory tests | < 1 sec |
| Coordinate tests | < 1 sec |
| Edge case tests | < 1 sec |
| **Total** | **5-10 sec** |

If tests take >10 seconds, investigate:
- Disk I/O during QR generation
- Database performance
- System resources

---

## Validation Checklist

Use this before deploying:

- [ ] All 25+ tests pass
- [ ] QR code square test passes (CRITICAL)
- [ ] Duplicate prevention test passes
- [ ] Inventory shows rows (not counts)
- [ ] Coordinate validation passes
- [ ] Large dataset test passes
- [ ] Edge case tests pass
- [ ] No database connection leaks

---

## CI/CD Integration

### Run Tests in Pipeline

```yaml
# Example GitHub Actions
- name: Run LIMS Tests
  run: |
    Rscript -e 'source("tests/run_comprehensive_tests.R")'
```

### Check for Failures

```bash
# Will exit with status 1 if any test fails
Rscript tests/run_comprehensive_tests.R && echo "All tests passed"
```

---

## Dependencies Required

```R
installed_packages <- c(
  "testthat",    # Test framework
  "DBI",         # Database interface
  "RSQLite",     # SQLite driver
  "qrcode",      # QR code generation
  "png"          # PNG manipulation
)

for (pkg in installed_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
  }
}
```

---

## Summary

This comprehensive test suite provides:

✓ **Complete Coverage:** 25+ tests across 10 functional areas
✓ **Format Validation:** Regex patterns for all label types
✓ **Database Testing:** Schema, relationships, constraints
✓ **QR Code Validation:** Critical square format check
✓ **Edge Cases:** Empty DB, nulls, large datasets
✓ **Documentation:** 4 detailed reference files
✓ **Quick Reference:** Format specifications and error solutions

**Next Steps:**
1. Run tests: `source("tests/run_comprehensive_tests.R")`
2. Review results
3. Fix any failures
4. Integrate into CI/CD pipeline
5. Maintain as codebase evolves

---

**Questions?** See `TEST_DOCUMENTATION.md` or `LABEL_FORMAT_REFERENCE.md`

**Last Updated:** 2024
**Test Suite Version:** 1.0
**Status:** Ready for production use
