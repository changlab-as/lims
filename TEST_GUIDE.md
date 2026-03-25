# LIMS Test System

## Overview
The LIMS application now uses a unified test suite (`run_tests.R`) to validate functionality whenever code changes are made. This replaces the previous individual test scripts.

## Running Tests

Execute all tests with:
```bash
Rscript run_tests.R
```

## Test Coverage

The test suite includes 5 comprehensive tests:

1. **Plant Label Generation** - Validates plant labels with:
   - QR code generation with seeded reproducibility
   - Text positioning inside QR bounds (y=0.75 for ID, y=0.25 for date)
   - PNG output at 1800×600px resolution

2. **Equipment Label Generation** - Validates equipment labels with:
   - Multiple equipment items (U01, Z01, F01)
   - Equipment ID and character name text
   - Same layout as plant labels

3. **Shiny App Loading** - Checks:
   - app.R syntax validity
   - No parsing errors or missing dependencies

4. **Database Initialization** - Validates:
   - Equipment table schema creation
   - Insert and query operations
   - SQLite connection handling

5. **QR Code Reproducibility** - Confirms:
   - Seeded generation produces consistent QR codes
   - Same input produces identical output when seed is reset

## Expected Output

Successful test run:
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

## Test Output Locations

Generated test artifacts are saved to:
- **Plant labels**: `data/test_labels/`
- **Equipment labels**: `data/test_equipment_labels/`

## Development Workflow

**After any code modification:**

1. Update the relevant generation functions in `app.R`
2. Run the test suite: `Rscript run_tests.R`
3. Verify all 5 tests pass
4. Proceed if tests pass; debug if any test fails

## Deprecated Files

The following individual test scripts are deprecated and superseded by `run_tests.R`:
- `test_clean_labels.R` (now integrated into Test 1)
- `test_equipment_labels.R` (now integrated into Test 2)

These can be safely deleted as they are no longer used.

## Label Positioning Details

### Text Alignment (Current - Inside QR Bounds)
- QR code viewport: y ∈ [0.025, 0.975]
- First text row (ID/Equipment): y = 0.75 (inside upper area)
- Second text row (Date/Character): y = 0.25 (inside lower area)

### Layout Structure
```
Left Side (x = 0.27):
  ┌─────────────────────────┐
  │    [First Line] (48pt)  │ ← y = 0.75
  │                         │
  │   [Second Line] (36pt)  │ ← y = 0.25
  └─────────────────────────┘

Right Side (x = 0.75):
  ┌─────────────────┐
  │                 │
  │    QR Code      │
  │   (Square)      │
  │                 │
  └─────────────────┘
```

## Troubleshooting

If tests fail:

```
✗ Plant Label Generation - Check if temp file creation works
  · Verify /tmp or temp directory is writable
  · Check PNG and grid libraries are installed

✗ Shiny App Loading - Check app.R syntax
  · Use: Rscript -e "parse(file = 'app.R')"
  · Look for missing parentheses or brackets

✗ Database Tests - Check RSQLite installation
  · Install with: install.packages("RSQLite")

✗ QR Code Tests - Check qrcode package
  · Install with: install.packages("qrcode")
```
