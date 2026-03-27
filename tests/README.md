# LIMS Test Suite - Complete Documentation

## Overview

The LIMS application includes a comprehensive test suite to validate all functionality. Tests are organized into several categories:

- **Comprehensive Unit Tests** (NEW): 25+ tests across 10 functional areas
- **Run Tests**: Main unified test runner
- **Label Generation Tests**: Validate QR code and label creation
- **UI Tests**: Validate Shiny components and application startup
- **Database Tests**: Validate schema and data operations
- **Integration Tests**: Validate complete workflows

---

## 🎯 NEW: Comprehensive Test Suite (v1.0)

### What's New
A complete production-ready test suite has been added with:
- **25+ comprehensive tests** covering all functions
- **10 test suites** organized by functional area
- **1500+ lines of documentation**
- **QR code square format validation** (CRITICAL)
- **Edge case and performance testing**

### Run the New Test Suite
```R
# Best option: Full test runner with reports
source("tests/run_comprehensive_tests.R")

# Or: Run tests directly
library(testthat)
test_file("tests/test_complete_functions.R")
```

### View Test Summary
```R
# Display organized summary table
source("tests/TEST_SUMMARY.R")
```

### Included Documentation
1. **`TEST_DOCUMENTATION.md`** — Detailed explanation of each test (500+ lines)
2. **`LABEL_FORMAT_REFERENCE.md`** — Format specs & examples (400+ lines)
3. **`MASTER_TEST_GUIDE.md`** — Quick start & integration guide (400+ lines)

---

## Quick Start

### Run All Tests (Original Test Suite)
```bash
cd /Users/cychang/Desktop/lab/lims
Rscript tests/run_tests.R
```

**Expected Output:**
```
============================================================ 
TEST SUMMARY
============================================================ 
Total Tests:  5
Passed:       5 ✓
Failed:       0 ✗
============================================================ 

✓ ALL TESTS PASSED
```

### Run New Comprehensive Suite
```R
source("tests/run_comprehensive_tests.R")
```

**Expected Output:**
```
═══════════════════════════════════════════════════════════
LIMS COMPREHENSIVE TEST SUITE COMPLETE
═══════════════════════════════════════════════════════════
Tests include:
✓ Database initialization and schema validation
✓ Site and Sample ID format validation
✓ QR code generation and square format validation
✓ Pre-sampling, Parts, and Use label generation
✓ Duplicate label rejection
✓ Inventory table unique row display (no counts)
✓ Status tracking and filtering
✓ Coordinate validation (latitude/longitude)
✓ Edge cases and error handling
✓ Large dataset handling (100+ labels)
═══════════════════════════════════════════════════════════
```

### Run Individual Test
```bash
Rscript tests/test_label_generation.R
```

---

## Test Files Reference

### Main Test Runner

#### `run_tests.R` (PRIMARY)
**Status**: Active - Main unified test suite
**Purpose**: Runs 5 comprehensive tests and provides summary report
**What it tests**:
1. **Plant Label Generation** - Validates plant labels with QR codes
   - QR code generation with seeded reproducibility
   - Text positioning inside QR bounds (y=0.75 for ID, y=0.25 for date)
   - PNG output at 1800×600px resolution
   - Tests 1 plant: ST0001-P0001
   
2. **Equipment Label Generation** - Validates equipment labels
   - Multiple equipment items (U01, Z01, F01)
   - Equipment ID and character name text
   - Same layout as plant labels
   
3. **Shiny App Loading** - Checks app.R validity
   - R syntax validation
   - No parsing errors or missing dependencies
   
4. **Database Initialization** - Validates schema and operations
   - Equipment table schema creation
   - Insert and query operations
   - SQLite connection handling
   
5. **QR Code Reproducibility** - Confirms consistent generation
   - Seeded generation produces identical QR codes
   - Same input produces identical output when seed is reset

**Output Locations**:
- Plant labels: `data/test_labels/`
- Equipment labels: `data/test_equipment_labels/`

---

### Label Generation Tests

#### `test_label_generation.R`
**Status**: Active
**Purpose**: Tests basic plant label generation code
**What it tests**:
- Generates 4 test labels for site ST0001 (P0001-P0004)
- QR code creation with grid graphics
- PNG output format
- Proper file naming convention
- Output directory: `data/test_labels/`

**Run**:
```bash
Rscript tests/test_label_generation.R
```

#### `test_square_qr.R`
**Status**: Active
**Purpose**: Verifies QR codes are square (not rectangular)
**What it tests**:
- Generates 2 test labels (ST0001-P0001, ST0001-P0002)
- Square QR code layout
- Proper aspect ratio verification
- Output directory: `data/test_labels_square/`

**Run**:
```bash
Rscript tests/test_square_qr.R
```

#### `test_horizontal_labels.R`
**Status**: Active
**Purpose**: Tests horizontal label generation for label maker tape
**What it tests**:
- Generates 3 horizontal-format labels
- Different layout for thermal label printers
- Equipment-style text layout
- Output directory: `data/test_labels_horizontal/`

**Run**:
```bash
Rscript tests/test_horizontal_labels.R
```

#### `test_clean_labels.R`
**Status**: Legacy (Deprecated)
**Purpose**: Tests simplified label format without borders
**Note**: Functionality now integrated into `run_tests.R` Test 1

#### `test_equipment_labels.R`
**Status**: Legacy (Deprecated) 
**Purpose**: Tests equipment label generation with QR codes
**Note**: Functionality now integrated into `run_tests.R` Test 2

#### `test_new_label_format.R`
**Status**: Legacy (Deprecated)
**Purpose**: Tests new label format iteration
**Note**: Superseded by current label generation tests

#### `test_corrected_layout.R`
**Status**: Legacy (Deprecated)
**Purpose**: Tests corrected label layout with visible text
**Note**: Superseded by `test_square_qr.R`

#### `test_final_layout.R`
**Status**: Legacy (Deprecated)
**Purpose**: Tests final corrected layout using raster graphics
**Note**: Superseded by current label generation approach

#### `test_updated_labels.R`
**Status**: Legacy (Deprecated)
**Purpose**: Tests that all changes work correctly
**Note**: Functionality covered by `run_tests.R`

---

### UI Component Tests

#### `test_app.R`
**Status**: Active
**Purpose**: Unit test for LIMS Shiny App
**What it tests**:
1. **Syntax Validation** - Checks R syntax in app.R is valid
2. **Required Libraries** - Verifies all package dependencies are installed:
   - shiny, bs4Dash, shinyjs, DT, RSQLite, qrcode, pool, dplyr, DBI, gridExtra
3. **App Execution** - Attempts to load the app
4. **UI Parsing** - Validates UI structure can be parsed

**Run**:
```bash
Rscript tests/test_app.R
```

#### `test_ui_components.R`
**Status**: Active
**Purpose**: Tests minimal UI components in isolation
**What it tests**:
1. Basic navbar creation
2. Sidebar with menu items
3. Body with fluidRow and column layouts
4. bs4TabItems with bs4TabItem
5. Full bs4DashPage construction

**Use Case**: When debugging UI structure issues

**Run**:
```bash
Rscript tests/test_ui_components.R
```

#### `test_ui_only.R`
**Status**: Legacy (Debugging utility)
**Purpose**: Load just the UI from app.R to find exact errors
**Note**: Used when app.R parsing fails; helps isolate UI vs. server issues

#### `test_ui_binary_search.R`
**Status**: Legacy (Debugging utility)
**Purpose**: Binary search to find problematic line in UI
**Note**: Used during UI development to identify syntax errors

#### `test_minimal_ui.R`
**Status**: Legacy
**Purpose**: Minimal UI test for LIMS app
**Note**: Superseded by `test_ui_components.R`

#### `test_useShinyjs.R`
**Status**: Legacy
**Purpose**: Test bs4DashPage with useShinyjs
**Note**: Functionality verified in current tests

---

### Miscellaneous/Support Tests

#### `test_a_tag.R`
**Status**: Active
**Purpose**: Debug test for specific a() HTML tag
**What it tests**:
- Simple a() tag creation
- a() tag with download attribute
- a() tag with complex attributes
- Card with a() tag embedded

**Use Case**: When experiencing issues with download buttons or links

**Run**:
```bash
Rscript tests/test_a_tag.R
```

#### `test_bs4dash_functions.R`
**Status**: Active
**Purpose**: Test bs4Dash available functions
**What it tests**:
- Lists all available bs4Dash functions
- Useful for reference when building UI

**Run**:
```bash
Rscript tests/test_bs4dash_functions.R
```

---

### NEW: Comprehensive Unit Test Suite (v1.0)

#### `test_complete_functions.R` ⭐ NEW
**Status**: Active - Production ready
**Purpose**: Comprehensive unit testing for all LIMS functions
**What it tests** (25+ tests):
1. **Database Operations** (2 tests)
   - Schema initialization and validation
   - Table structure and column validation

2. **Site ID Generation** (3 tests)
   - Format: ST#### validation
   - Valid/invalid format detection
   - Database storage verification

3. **Sample ID Generation** (3 tests)
   - 2-segment format: ST####-[PS]####
   - 3-segment format: ST####-[PS]####-XX###
   - 4-segment format: ST####-[PS]####-XX###-XX##

4. **QR Code Generation** (2 tests) ⚠️ CRITICAL
   - **Square format validation** (width == height)
   - QR code readability

5. **Pre-Sampling Labels** (3 tests)
   - Plant label generation
   - Soil label generation
   - Duplicate label prevention

6. **Parts Processing** (2 tests)
   - Part label format validation
   - Parent-child relationship verification

7. **Use Sample Labels** (1 test)
   - Full 4-segment label generation with hierarchy

8. **Inventory Display** (3 tests)
   - Unique rows display (not aggregated counts)
   - Status tracking
   - Search/filter functionality

9. **Geographic Coordinates** (3 tests)
   - Latitude validation (-90 to 90)
   - Longitude validation (-180 to 180)
   - Coordinate precision verification

10. **Edge Cases** (3 tests)
    - Empty database handling
    - Null value handling
    - Large dataset handling (100+ labels)

**Coverage**: 510+ lines of code, validates all functions

**Run**:
```R
library(testthat)
test_file("test_complete_functions.R")
```

---

#### `run_comprehensive_tests.R` ⭐ NEW
**Status**: Active - Test runner with reporting
**Purpose**: Execute comprehensive test suite with formatted output and summary

**Features**:
- Progress reporting during test execution
- Summary statistics (pass/fail count, success rate)
- Test coverage overview
- Detailed failure reporting
- Execution time tracking

**Run**:
```R
source("run_comprehensive_tests.R")
```

**Expected Output**:
```
Total Tests: 25
Passed:      25 ✓
Failed:      0 ✗
Success Rate: 100.0%
```

---

#### `TEST_DOCUMENTATION.md` ⭐ NEW
**Status**: Active - Reference documentation
**Purpose**: Comprehensive documentation of all 25+ tests

**Contents** (500+ lines):
- Detailed explanation of each test suite
- Expected behavior and results
- Common failure scenarios and solutions
- Performance benchmarks
- Troubleshooting guide with examples
- Database schema reference

**Use**: Reference when tests fail or when adding new tests

---

#### `LABEL_FORMAT_REFERENCE.md` ⭐ NEW
**Status**: Active - Quick reference guide
**Purpose**: Label format specifications and validation rules

**Contents** (400+ lines):
- Label hierarchy and stage definitions (Stage 1, 2, 3)
- Format specifications with regex patterns
- Database table structure
- Validation rules for all ID types
- Common examples and batch operations
- Print label templates
- Error messages and solutions
- Testing checklist

**Use**: Quick reference for format requirements

---

#### `MASTER_TEST_GUIDE.md` ⭐ NEW
**Status**: Active - Integration and guide document
**Purpose**: Quick start guide and CI/CD integration

**Contents** (400+ lines):
- Quick start instructions
- Complete coverage summary table
- Expected output examples
- Key test points and concepts
- Troubleshooting guide
- CI/CD integration examples
- Performance notes
- Dependency requirements

**Use**: Getting started and integrating tests into build pipeline

---

#### `TEST_SUMMARY.R` ⭐ NEW
**Status**: Active - Visual summary generator
**Purpose**: Display organized summary of test suite in console

**Features**:
- Formatted test organization table
- Label format quick reference with examples
- Format validation patterns
- Database schema visualization
- Statistics and metrics
- Execution times
- Troubleshooting quick guide

**Run**:
```R
source("TEST_SUMMARY.R")
```

---

### Comprehensive Test Suite Summary

**Total New Files**: 5
- 1 main test file (510+ lines)
- 1 test runner (50 lines)
- 4 documentation files (1500+ lines)

**Test Coverage**:
- ✅ Database operations
- ✅ All label formats (2, 3, 4-segment)
- ✅ QR code format (square validation)
- ✅ Label hierarchy and relationships
- ✅ Inventory table logic
- ✅ Coordinate validation
- ✅ Edge cases (empty DB, nulls, large data)
- ✅ Error conditions

**Quality Assurance**:
- 25+ individual test cases
- Regex validation for all formats
- Hierarchical relationship testing
- Performance testing (100+ labels)
- Comprehensive error handling

**Documentation**:
- 1500+ lines of documentation
- Quick reference guides
- Integration examples
- Troubleshooting guides

---

#### `test_comprehensive_start.R`
**Status**: Active
**Purpose**: Comprehensive LIMS App start test
**What it tests**:
- Complete app initialization
- Database setup
- All dependencies loaded
- UI renders properly
- Server logic initializes

**Run**:
```bash
Rscript tests/test_comprehensive_start.R
```

#### `test_runnable.R`
**Status**: Active
**Purpose**: Simple LIMS App runnable test
**What it tests**:
- Basic app can start
- Core functionality accessible
- No syntax errors

**Run**:
```bash
Rscript tests/test_runnable.R
```

---

## Test Output Artifacts

### Generated Test Directories

Tests create output in these locations:
- `data/test_labels/` - Plant label test output
- `data/test_labels_square/` - Square QR code test output  
- `data/test_labels_horizontal/` - Horizontal label test output
- `data/test_equipment_labels/` - Equipment label test output

### Cleaning Test Output
```bash
rm -rf data/test_labels* data/test_equipment_labels
```

---

## Development Workflow

### After Code Modification

1. **Update the relevant generation functions** in `app.R`
2. **Run the test suite**:
   ```bash
   Rscript tests/run_tests.R
   ```
3. **Verify all tests pass** - See the final TEST SUMMARY
4. **Proceed if tests pass**; debug if any test fails

### Debugging Failed Tests

**Step 1: Identify which test failed**
- Look at TEST SUMMARY output
- Check which tests show ✗ FAILED

**Step 2: Run the specific test**
```bash
# Example: If Test 1 failed
Rscript tests/test_label_generation.R
```

**Step 3: Review error message**
- R will show error details in console
- Check generated files in output directories
- Review modified code in app.R

**Step 4: Fix and retest**
- Make correction in app.R
- Run specific test again
- Run full suite: `Rscript tests/run_tests.R`

### Adding New Tests

To add a new test to `run_tests.R`:

```r
# Add new test function
run_test("New Test Name", function() {
  # Your test code here
  # Use stop("Error message") to fail
  # Use cat("info") to print debug info
})
```

---

## Troubleshooting

### Test Fails: "Package not found"
```
✗ Failed: Package 'xyz' could not be found
```

**Solution**: Install missing package
```r
install.packages("xyz")
source("packages.R")
```

### Test Fails: "File permission denied"
```
✗ Failed: Cannot create directory
```

**Solution**: Check permissions on `data/` directory
```bash
chmod 755 data/
```

### Test Fails: "SQLite error"
```
✗ Failed: database is locked
```

**Solution**: Close other instances of the app; only one can access DB at a time
```bash
# Or delete and rebuild
rm data/lims_db.sqlite
Rscript tests/run_tests.R
```

### Test Fails: "PNG device not available"
```
✗ Failed: unable to start device PNG
```

**Solution**: Reinstall graphics packages
```r
install.packages(c("png", "gridExtra"))
```

### Test Passes But Labels Look Wrong
1. Check output files in test directories
2. Open PNG files to verify QR codes are visible
3. Verify text is readable and positioned correctly
4. Adjust coordinates in `app.R` if needed

---

## Test Statistics

| Category | Total | Active | Deprecated |
|----------|-------|--------|------------|
| Main Test Runner | 1 | 1 | 0 |
| Label Generation | 9 | 3 | 6 |
| UI Components | 7 | 2 | 5 |
| Support Tests | 4 | 4 | 0 |
| **Total** | **21** | **10** | **11** |

---

## Deprecated Files

The following test files are deprecated and superseded by `run_tests.R`:
- `test_clean_labels.R` - Functionality in Test 1
- `test_equipment_labels.R` - Functionality in Test 2
- `test_new_label_format.R` - Replaced by `test_square_qr.R`
- `test_corrected_layout.R` - Replaced by `test_square_qr.R`
- `test_final_layout.R` - Replaced by current approach
- `test_updated_labels.R` - Covered by `run_tests.R`
- `test_ui_only.R` - Debugging utility, not needed with current UI
- `test_ui_binary_search.R` - Debugging utility, not needed with current UI
- `test_minimal_ui.R` - Replaced by `test_ui_components.R`
- `test_useShinyjs.R` - Functionality verified in current tests
- `test_ui_binary_search.R` - Legacy debugging tool

These can be safely deleted as they are no longer used in the primary workflow.

---

## Best Practices

### Before Committing Code
```bash
Rscript tests/run_tests.R
```
All tests should pass before committing.

### Before Deploying to Production
1. Run full test suite multiple times
2. Manually test critical workflows
3. Verify database integrity
4. Test on target deployment platform

### Regular Maintenance
- Run tests monthly even without code changes
- Clean up old test outputs: `rm -rf data/test_*`
- Review test failures for pattern analysis
- Update tests when adding new features

---

## Integration with CI/CD

To integrate with GitHub Actions or similar:

```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: r-lib/actions/setup-r@v2
      - run: Rscript tests/run_tests.R
```

---

**Last Updated**: March 2026
