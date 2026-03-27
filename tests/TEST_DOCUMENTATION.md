# LIMS Comprehensive Test Suite Documentation

## Overview
This test suite provides comprehensive validation of all LIMS application functions, covering:
- Database schema and initialization
- ID format validation (Site, Sample, Part, Use)
- QR code generation and properties
- Label generation at all stages
- Inventory table display logic
- Coordinate validation
- Edge cases and error handling

## Test Structure

### Test Suite 1: Database Initialization
**File:** `test_complete_functions.R` (Lines 28-56)

Tests that verify proper database schema setup:
- Standard tables created (Sites, Labels, Equipment)
- All required columns present
- Foreign key relationships established

**Key Tests:**
- `Database initializes with correct schema`
- `Database schema has correct columns`

**Expected Results:** ✓ All tables exist with correct structure

---

### Test Suite 2: Site ID Generation
**File:** `test_complete_functions.R` (Lines 57-89)

Validates Site ID format and storage:

**Format:** `ST####` (exactly ST + 4 digits)
- Valid: ST0001, ST0002, ST9999, ST0000
- Invalid: S0001, ST001, st0001, ST00001

**Key Tests:**
- `Site creation generates valid ID format`
- `Site ID validation rejects invalid format`
- `Site ID validation accepts valid format`

**Expected Results:** 
- Valid format: PASS
- Invalid format: FAIL (properly rejected)

---

### Test Suite 3: Plant/Sample ID Generation
**File:** `test_complete_functions.R` (Lines 90-120)

Tests hierarchical label formats at different stages.

#### 2-Segment Format (Pre-sample stage)
**Format:** `ST####-[PS]####`
- Plant: `ST0001-P0001`
- Soil: `ST0001-S0001`

**Key Tests:**
- `Plant sample IDs follow correct 2-segment format`

---

#### 3-Segment Format (Parts processing stage)
**Format:** `ST####-[PS]####-XX###`
- Examples: `ST0001-P0001-SH001`, `ST0001-P0001-RT001`

**Part Codes:**
- SH = Shoot
- RT = Root
- ND = Node

**Key Tests:**
- `Part/3-segment IDs follow correct format`

---

#### 4-Segment Format (Use samples stage)
**Format:** `ST####-[PS]####-XX###-XX##`
- Examples: `ST0001-P0001-SH001-GW01`, `ST0001-P0001-RT001-DE01`

**Use Codes:**
- GW = Greenhouse watering
- DE = Disease evaluation
- RE = Replicate extraction

**Key Tests:**
- `Use/4-segment IDs follow correct format`

---

### Test Suite 4: QR Code Generation and Validation
**File:** `test_complete_functions.R` (Lines 121-156)

Validates QR code generation and properties.

**Critical Requirement:** QR codes must be **SQUARE** (width == height)

**Key Tests:**
- `QR code is generated as square image`
  - Reads generated PNG
  - Verifies dimensions[1] == dimensions[2]
  - FAILS if QR is not square

- `QR codes are readable`
  - Verifies QR object is valid matrix
  - Checks non-zero dimensions

**IMPORTANT:** If "QR code is generated as square image" test FAILS:
1. Check PNG generation code - may need to force square aspect ratio
2. Verify PNG parameters: `png(file, width=400, height=400)`
3. Ensure plot area is square, not rectangular

---

### Test Suite 5: Label Generation - Pre-Sampling
**File:** `test_complete_functions.R` (Lines 157-215)

Tests initial label creation for plant and soil samples.

**Key Tests:**

1. `Pre-sampling plant labels are created with correct format`
   - Creates 3 plant labels for site ST0001
   - Verifies format: `ST0001-P####`
   - Checks stage = 1
   - Expected: 3 labels created with correct format

2. `Pre-sampling soil labels are created with correct format`
   - Creates 2 soil labels for site ST0002
   - Verifies format: `ST0002-S####`
   - Checks stage = 1

3. `Duplicate labels are rejected`
   - Attempts to create same label twice
   - Verifies second attempt fails (PRIMARY KEY constraint)
   - Expected: Error on duplicate insertion

---

### Test Suite 6: Label Generation - Parts Processing
**File:** `test_complete_functions.R` (Lines 216-279)

Tests parts label generation and hierarchical relationships.

**Hierarchy:**
```
Plant Sample (ST0001-P0001) [Stage 1]
├── Plant Part 1 (ST0001-P0001-SH001) [Stage 2]
├── Plant Part 2 (ST0001-P0001-RT001) [Stage 2]
└── Plant Part 3 (ST0001-P0001-SH002) [Stage 2]
```

**Key Tests:**

1. `Parts labels are generated with correct format and hierarchy`
   - Parent: ST0001-P0001
   - Parts generated: 2 shoots (SH), 1 root (RT)
   - Verifies stage = 2
   - Verifies parent-child link in sample_id field
   - Expected: 3 part labels with correct format

2. `Parts labels properly link to parent samples`
   - Creates 2 plant samples
   - Each gets 2 part labels
   - Verifies count per parent
   - Expected: Each parent correctly shows 2 parts

---

### Test Suite 7: Label Generation - Use Samples
**File:** `test_complete_functions.R` (Lines 280-325)

Tests use sample creation from parts.

**Hierarchy:**
```
Part Label (ST0001-P0001-SH001) [Stage 2]
├── Use Sample 1 (ST0001-P0001-SH001-GW01) [Stage 3]
├── Use Sample 2 (ST0001-P0001-SH001-GW02) [Stage 3]
└── Use Sample 3 (ST0001-P0001-SH001-DE01) [Stage 3]
```

**Key Tests:**
- `Use labels are generated with correct format`
  - Creates full hierarchy: plant → part → use
  - Generates 2 GW codes, 1 DE code
  - Expected: 3 use labels with correct format

---

### Test Suite 8: Inventory Table Display
**File:** `test_complete_functions.R` (Lines 326-388)

Tests that inventory shows individual samples (NOT counted/aggregated).

**KEY PRINCIPLE:** Inventory should display **unique rows**, not aggregated counts.

**Example:**
- If database has 3 plant samples: `ST0001-P0001`, `ST0001-P0002`, `ST0001-P0003`
- Inventory should show: 3 ROWS (not "3" in a count column)

**Key Tests:**

1. `Inventory table shows unique samples (not counts)`
   - Creates 3 plant samples
   - Queries without GROUP BY (shows all rows)
   - Verifies result has NO "count" column
   - Expected: 3 rows returned, NOT aggregated

2. `Inventory table correctly displays status`
   - Creates labels with different statuses:
     - "label_created"
     - "collected"
     - "processed"
   - Verifies all statuses present
   - Expected: All 3 status values visible

3. `Inventory table search filters correctly`
   - Creates labels in 2 sites (ST0001, ST0002)
   - Search for "ST0001"
   - Expected: Returns only ST0001 labels

---

### Test Suite 9: Coordinate Validation
**File:** `test_complete_functions.R` (Lines 389-442)

Tests geographic coordinate validation.

**Latitude Range:** -90 to +90 degrees
- Valid: -90, -45, 0, 45, 90
- Invalid: -91, -100, 100, 91

**Longitude Range:** -180 to +180 degrees
- Valid: -180, -90, 0, 90, 180
- Invalid: -181, -200, 200, 181

**Key Tests:**

1. `Latitude values are validated correctly`
2. `Longitude values are validated correctly`
3. `Coordinates are stored in database with correct precision`
   - Stores: 37.7749, -122.4194
   - Retrieves and verifies precision (4 decimal places)

---

### Test Suite 10: Edge Cases and Error Handling
**File:** `test_complete_functions.R` (Lines 443-510)

Tests robustness in unusual scenarios.

**Key Tests:**

1. `Empty database doesn't break queries`
   - Query returns 0 rows, not error
   - Result is still data.frame

2. `Null values are handled correctly in storage_location`
   - Label created without location specified
   - Verifies NULL or empty string handling

3. `Large quantity of labels can be generated`
   - Creates 100 labels for one site
   - Verifies all inserted successfully
   - Tests database performance

---

## Running the Tests

### Option 1: Run All Tests
```R
source("run_comprehensive_tests.R")
```

### Option 2: Run Specific Test File
```R
library(testthat)
test_file("test_complete_functions.R")
```

### Option 3: Run Specific Test
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

---

## Interpreting Results

### Full Success
```
✓ All tests pass
✓ No errors reported
✓ Database operations work correctly
✓ Labels generated with correct format
✓ QR codes are square
```

### Common Failures & Solutions

#### QR Code Not Square
```
✗ "QR code is generated as square image" FAILED
  Error: width != height
```
**Solution:**
- Ensure PNG output is square: `png(file, width=400, height=400)`
- Check plot dimensions are preserved
- Verify image is not being resized by Shiny

#### Duplicate Label Test Fails
```
✗ "Duplicate labels are rejected" FAILED
```
**Solution:**
- Verify PRIMARY KEY constraint on label_id
- Check database schema creation

#### Inventory Count Instead of Rows
```
✗ "Inventory table shows unique samples" FAILED
  Error: Result has 'count' column
```
**Solution:**
- Remove GROUP BY from query
- Show all individual rows
- Do NOT aggregate/count

---

## Test Maintenance

### Adding New Tests
1. Create new `test_that()` block
2. Add to appropriate suite (1-10)
3. Include clear test description
4. Use consistent naming pattern

### Updating for Schema Changes
If database schema changes:
1. Update `setup_test_db()` function
2. Update relevant test expectations
3. Re-run full test suite

---

## Performance Benchmarks

Expected execution times:
- Database tests: < 1 second
- Label generation tests: < 2 seconds
- QR code tests: 1-3 seconds (image I/O)
- Large dataset test (100 labels): < 2 seconds
- **Total suite**: 5-10 seconds

If tests take longer, check disk I/O during QR code generation.

---

## QR Code Test Details

### Why Square Format Matters
⚠️ **Critical for:**
- Label scanning consistency
- Mobile app scanning
- Proper barcode placement on physical labels
- Print alignment

### Square Format Verification
Test reads PNG and checks: `dimensions[1] == dimensions[2]`

Where:
- `dimensions[1]` = image width (pixels)
- `dimensions[2]` = image height (pixels)

### If Test Fails
1. In your label generation code, ensure:
   ```R
   png(filename, width=400, height=400, bg="white")
   plot(qr_code_object)
   dev.off()
   ```

2. Do NOT use different width/height values

3. Do NOT let Shiny resize the image

---

## Coverage Summary

| Area | Tests | Coverage |
|------|-------|----------|
| Database | 2 | Schema, columns |
| Site IDs | 3 | Format, validation |
| Sample IDs | 3 | 2-seg, 3-seg, 4-seg formats |
| QR Codes | 2 | Square format, readability |
| Pre-sample | 3 | Plant, soil, duplicates |
| Parts | 2 | Format, hierarchy |
| Use samples | 1 | format, hierarchy |
| Inventory | 3 | Unique rows, status, search |
| Coordinates | 3 | Lat/lon validation, storage |
| Edge cases | 3 | Empty DB, nulls, large data |
| **Total** | **25+** | **Complete function coverage** |

---

## Questions & Troubleshooting

**Q: Tests fail on first run?**
A: Ensure all dependencies installed: `install.packages(c("DBI", "RSQLite", "qrcode", "png", "testthat"))`

**Q: QR code test fails but labels print fine?**
A: Check print preview - may look square but file isn't. Verify PNG generation parameters.

**Q: Database tests run slow?**
A: Normal for SQLite. If > 5 seconds, check disk space and I/O activity.

**Q: Inventory test shows counts instead of rows?**
A: Your query has GROUP BY. Remove aggregation to show individual rows.

---

Last Updated: 2024
Test Suite Version: 1.0
