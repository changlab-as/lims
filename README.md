# Riverside Rhizobia LIMS - Complete Documentation

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Features](#core-features)
- [Installation & Setup](#installation--setup)
- [Usage Guide](#usage-guide)
- [Batch Label Generation](#batch-label-generation)
- [Mobile Scanning](#mobile-scanning)
- [Database Schema](#database-schema)
- [Workflows](#workflows)
- [Testing](#testing)

---

## Overview

A complete Laboratory Information Management System (LIMS) for the Riverside Rhizobia research lab, built with **R Shiny**. 

This system manages laboratory samples, automates tracking with QR codes, provides both desktop and mobile scanning, and maintains a comprehensive inventory database with audit trail capabilities.

---

## Quick Start

### 1. Install Dependencies
```r
source("packages.R")
```

### 2. Run the App
```r
shiny::runApp()
```
Opens at: **http://localhost:3838**

### 3. Generate Batch Labels (Optional)
```bash
Rscript generate_barcode_labels.R
```
Or use the "Label Generation" tab in the app.

### 4. Interactive Menu (Recommended)
```bash
Rscript quickstart.R
```
Then choose option 1 to run the app with an interactive menu.

---

## Core Features

- **Field Entry**: Create sampling sites and register plants with auto-generated sequential IDs
- **Batch Label Generation**: Generate printable QR code labels (PNG/PDF) before field work
- **Desktop Lab Check-In**: Barcode scanning with auto-focus between fields
- **Mobile Scanning**: iPhone/Android browser-based check-in via QR codes
- **Inventory Management**: Real-time database view with filtering and sorting
- **Duplicate Prevention**: Automatic detection of duplicate sample IDs at multiple levels
- **Processing Logs**: Complete audit trail of all lab activities (nodule isolation, DNA extraction, etc.)
- **SQLite Database**: Local persistent storage with automatic backup and schema initialization
- **QR Code Generation**: Automatic QR code generation for plant samples
- **Real-time Updates**: Database connection pooling and auto-refresh capabilities
- **Professional UI**: Responsive Bootstrap 4 dashboard with mobile-friendly design

---

## Installation & Setup

### System Requirements
- R 3.6+
- macOS, Windows, or Linux
- SQLite (included with R)

### Package Installation

In R or RStudio, run:
```r
source("packages.R")
```

This installs:
- `shiny` - Web application framework
- `bs4Dash` - Bootstrap 4 dashboard interface
- `shinyjs` - JavaScript interactions
- `DT` - Interactive data tables
- `RSQLite` - SQLite database driver
- `qrcode` - QR code generation
- `pool` - Database connection pooling
- `dplyr` - Data manipulation
- `DBI` - Database interface
- `gridExtra` - Grid layout for labels

### Run the Application

#### Option A: In RStudio
Open `app.R` and click "Run App", or run:
```r
shiny::runApp()
```

#### Option B: Command Line
```bash
R -e "shiny::runApp()"
```

#### Option C: Network Access (for mobile)
```r
shiny::runApp(host = "0.0.0.0", port = 3838)
```

---

## Usage Guide

### Field Entry Tab

#### Create New Site
1. Enter location name (e.g., "Riverside Site A")
2. Select sampling date
3. Click "Create Site" → receives auto-generated ID (ST0001, ST0002, etc.)

#### Add Plants to Site
1. Select a site from dropdown
2. Specify number of plants (1-100)
3. Click "Generate Plant Forms"
4. Fill in species, health status, and fridge location for each plant
5. Click "Save" for each plant → each receives auto-generated ID (ST0001-P0001, ST0001-P0002, etc.)

### Label Generation Tab

Pre-print labels before field work:
1. Select a site from dropdown
2. Specify plant index range (e.g., 1-20)
3. Choose format: PNG or PDF
4. Click "Generate Labels"
5. Labels saved in `data/labels/` directory (300 DPI, 2×2 inches)
6. Print on sticker sheets and stick on sample bags
7. **Duplicate checking**: Automatically marks IDs already in database

### Lab Check-In Tab (Desktop)

Use barcode scanner for fast entry:
1. Click "Scan Sample Barcode" field
2. Scan plant barcode with scanner (or manually enter plant_id)
3. Cursor **automatically moves** to "Scan Fridge Location"
4. Scan fridge location barcode
5. System automatically:
   - Updates fridge_loc in database
   - Logs entry to Processing table
   - Generates QR code display
   - Shows confirmation message

**Recent check-ins shown in live table below the form**

### Mobile Scan Tab (NEW - iPhone/Android)

Scan labels during lab check-in on mobile:
1. From any iPhone/Android on same WiFi:
   - Go to `http://{your_mac_ip}:3838` (find IP with `ifconfig`)
   - Or cloud deployment (see Cloud Deployment section)
2. Go to "Mobile Scan" tab
3. Enter plant ID from label (or scan QR code with phone camera)
4. Select fridge storage location
5. Tap "Check In Sample"
6. ✓ Automatically updates database with location and timestamp
7. See recent mobile check-ins in live table

### Inventory View Tab

1. **View All Plants**
   - Live table of all plants in database
   - Shows plant ID, site, species, health status, fridge location

2. **Filter Data**
   - Click filter box under any column
   - Filter by species, health status, or fridge location
   - Results update in real-time

3. **View Processing Records**
   - Scroll to "Processing Records" section
   - See all activities for each plant
   - Activity types: Nodule_Iso, DNA_Ext, Stem_Grow, Inventory_Checkin, Mobile_Checkin
   - Last 50 records shown

---

## Batch Label Generation

### In-App Generation
1. Go to **Label Generation** tab
2. Select site and plant range (e.g., P0001-P0020)
3. Choose PNG or PDF format
4. Click **Generate Labels**
5. Find files in `data/labels/` directory

### Command-Line Generation
```bash
Rscript generate_barcode_labels.R
```
Interactive prompts guide you through site selection and label count.

### Label Specifications
- **Size**: 2×2 inches (suitable for sticker sheets)
- **Resolution**: 300 DPI (print-quality)
- **Format**: QR code with Plant ID, Site ID, and Date
- **Layout**: Two-column format with QR code and text labels
- **Duplicate Detection**: Automatically skips existing plant IDs

---

## Mobile Scanning

### Local Network Setup

**Step 1: Run app with network access**
```r
shiny::runApp(host = "0.0.0.0", port = 3838)
```

**Step 2: Find your Mac's IP address**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example: inet 192.168.1.100
```

**Step 3: Access on iPhone/Android (same WiFi)**
- Open Safari/Chrome
- Enter: `http://192.168.1.100:3838`
- Go to "Mobile Scan" tab

### Cloud Deployment (Production)

**Using shinyapps.io (easiest):**
```r
install.packages("rsconnect")
rsconnect::deployApp()
```

This gives you a public URL: `https://yourname.shinyapps.io/lims/`

### QR Code Scanning Process

1. **iPhone**: Open Camera app → Point at label → Tap notification → Opens data
2. **Android**: Use built-in QR detection or third-party QR scanner app
3. **In App**: Paste scanned plant ID into Mobile Scan form

### Auto-Capture Feature

The Mobile Scan form uses JavaScript to detect when text is pasted:
- Most QR scanners paste data directly into the focused input field
- App auto-submits when complete plant ID detected (format: `ST0001-P0001`)
- Manual entry also available if needed

---

## Database Schema

### Sites Table
| Column | Type | Description |
|--------|------|-------------|
| site_id | TEXT (PK) | Auto-generated: ST0001, ST0002, etc. |
| location_name | TEXT | Name of sampling location |
| date_sampled | DATE | Collection date |

### Plants Table
| Column | Type | Description |
|--------|------|-------------|
| plant_id | TEXT (PK) | Auto-generated: ST0001-P0001, ST0001-P0002, etc. |
| site_id | TEXT (FK) | Reference to Sites table |
| species | TEXT | Plant species name |
| health_status | TEXT | Healthy, Stressed, or Diseased |
| fridge_loc | TEXT | Storage location |
| date_created | DATETIME | Creation timestamp |

### Processing Table
| Column | Type | Description |
|--------|------|-------------|
| proc_id | TEXT (PK) | Unique processing record ID |
| plant_id | TEXT (FK) | Reference to Plants table |
| type | TEXT | Activity type (Nodule_Iso, DNA_Ext, Stem_Grow, Inventory_Checkin, Mobile_Checkin) |
| date | DATETIME | Activity timestamp |
| technician | TEXT | Technician name (optional) |
| notes | TEXT | Additional notes |

### Database Location
- **Stored as**: `data/lims_db.sqlite`
- **Auto-created**: On first app start
- **Schema auto-initialized**: Tables created if missing
- **Backup**: Manual backup recommended before large operations

---

## Workflows

### Pre-Field Preparation

```
1. Create Sites in app → Get auto-generated site IDs (ST0001, ST0002, etc.)
2. Create Plants for each site → Get auto-generated plant IDs (ST0001-P0001, etc.)
3. Run Label Generation → Get PNG/PDF labels with QR codes
4. Print labels and stick to sample bags
```

### Field Work

```
1. Collect samples using pre-labeled bags
2. No scanning needed in field
3. Labels serve as identification and reference
```

### Lab Check-In - Option A: Desktop with Barcode Scanner

```
1. Scan sample barcode → Auto-move → Scan fridge location → ✓ Done
2. System updates database with location and timestamp
3. Complete audit trail recorded
```

### Lab Check-In - Option B: Mobile on iPhone/Android

```
1. Open app in Safari/Chrome → Mobile Scan tab
2. Enter plant ID (from label) or scan QR code
3. Select location from dropdown
4. Tap "Check In Sample"
5. ✓ Database auto-updates with location and timestamp
```

### Lab Check-In - Option C: Manual Entry (No Scanning)

```
1. Go to Lab Check-In tab
2. Manually type plant ID
3. Select location
4. Submit form
5. ✓ Recorded in database
```

### Inventory Tracking

```
1. Go to Inventory View tab
2. See all plants and their storage locations
3. Filter by species, health status, or fridge location
4. View processing timeline for each sample
5. Know exactly where each sample is stored
```

### Duplicate Prevention Workflow

The app implements **automatic duplicate checking** at multiple levels:

1. **During Field Entry**:
   - Systems prevents duplicate site names
   - Auto-incrementing prevents duplicate plant IDs

2. **During Label Generation**:
   - Pre-generation: Lists existing plants
   - Generation: Skips any already in database (marked ✗)
   - Prevents reprinting duplicate labels

3. **During Check-In**:
   - Mobile or Desktop scan validates plant_id exists
   - Non-existent IDs show error: "Plant ID not found"
   - Prevents accidental data entry of fake samples

---

## Network Troubleshooting

### "Connection Refused" or "Cannot Reach Server"
- ✓ Verify both devices on same WiFi
- ✓ Check firewall isn't blocking port 3838
- ✓ Verify you're using correct IP address
- ✓ Restart the app with `host = "0.0.0.0"`

### Phone Can Access App but Can't Scan
- ✓ Make sure QR code is clearly printed
- ✓ Ensure good lighting when scanning
- ✓ Use native camera app or dedicated QR scanner
- ✓ Check that app has camera permissions enabled

### QR Code Doesn't Auto-Fill
- ✓ Manually paste the scanned ID
- ✓ Manually type the plant ID in format: `ST0001-P0001`
- ✓ Check browser console for JavaScript errors (F12)

---

## Testing

The project includes a comprehensive test suite to validate all functionality. See [tests/README.md](tests/README.md) for complete testing documentation.

### Quick Test

```bash
Rscript tests/run_tests.R
```

Expected output:
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

### Development Workflow

After any code modification:
1. Update the relevant generation functions in `app.R`
2. Run the test suite: `Rscript tests/run_tests.R`
3. Verify all tests pass
4. Proceed if tests pass; debug if any test fails

---

## Project Structure

```
app.R                          # Main Shiny application
packages.R                     # Dependency installation script
generate_barcode_labels.R      # Standalone label generation
quickstart.R                   # Interactive startup menu
SETUP.md                       # (DEPRECATED - use this README)
MOBILE_SETUP.md               # (DEPRECATED - use this README)
MOBILE_SCANNING_GUIDE.md      # (DEPRECATED - use this README)
TEST_GUIDE.md                 # (DEPRECATED - use tests/README.md)
TEST_WORKFLOW.md              # (DEPRECATED - use tests/README.md)
.gitignore                    # Git exclusions
lims.Rproj                    # RStudio project file
data/
├── lims_db.sqlite           # SQLite database (auto-created)
├── labels/                  # Generated label files
├── test_labels/            # Test label output
├── test_equipment_labels/  # Equipment label test output
└── test_labels_horizontal/ # Horizontal label test output
tests/
├── README.md               # Test suite documentation
├── run_tests.R             # Main unified test runner
├── test_*.R                # Individual test scripts
www/                        # Static web assets
```

---

## Frequently Asked Questions

### Q: How do I backup my database?
**A:** Copy `data/lims_db.sqlite` to a backup location. The database is a standard SQLite file.

### Q: Can I use this on a Raspberry Pi?
**A:** Yes! Install R and Shiny on the Raspberry Pi, then run the app. Network access will work for mobile scanning.

### Q: How many plants can the system handle?
**A:** No hard limit. Performance depends on your hardware. Tested with 1000+ plant records.

### Q: Can I export data?
**A:** Use the Inventory View tab to view data in the table. You can right-click to copy/export from most browsers.

### Q: What if the database gets corrupted?
**A:** Delete `data/lims_db.sqlite` and restart the app. A fresh database will be created with the proper schema.

### Q: Can I run multiple instances?
**A:** Not on the same database file. If you need multiple instances, use different databases (create separate copies of the app folder).

### Q: How do I add custom fields to plants?
**A:** Edit the Plants table schema in the database initialization code in `app.R`, and add corresponding UI inputs.

---

## Security Notes

- When you stop the app, network access is blocked automatically
- Run the app on a secure network
- Close it when not in use if concerned about external access
- For production, use authentication mechanisms from shinyapps.io or similar platforms
- Database is stored locally without encryption (use secure storage if sensitive)

---

## Version History

- **1.0** - Initial release with all core features
- **1.1** - Added mobile scanning support
- **1.2** - Added duplicate prevention at multiple levels
- **1.3** - Added equipment label generation
- **1.4** - Added mobile scanning with QR auto-capture

---

## Support & Troubleshooting

### Common Issues

**App won't start**
- Verify all packages installed: `source("packages.R")`
- Check R syntax: `Rscript -e "parse(file = 'app.R')"`
- Look for missing columns in database

**Labels not generating**
- Check `data/` directory exists and is writable
- Verify site and plant records exist in database
- Check R console for error messages

**Mobile scanning not working**
- Ensure correct IP address (run `ifconfig`)
- Verify same WiFi network
- Check port 3838 is accessible
- Test with local scanning first

**Database errors**
- Delete `data/lims_db.sqlite` and restart app
- Verify `data/` directory is writable
- Check for file permissions issues

---

## Contributing

To contribute improvements:
1. Create a feature branch
2. Make changes and test thoroughly with `Rscript tests/run_tests.R`
3. Document changes in this README
4. Submit pull request with test results

---

**Last Updated**: March 2026
- [ ] Run `shiny::runApp()` - App starts successfully at http://localhost:3838
- [ ] Create a site in Field Entry tab
- [ ] Create 5 plants for the site
- [ ] Generate labels in Label Generation tab
- [ ] View labels in `data/labels/` directory
- [ ] Check-in a sample via Desktop tab
- [ ] Access app from iPhone on local network
- [ ] Check-in a sample via Mobile Scan tab
- [ ] View all check-ins in Inventory View tab

See **[TEST_WORKFLOW.md](TEST_WORKFLOW.md)** for detailed instructions.

---

## 🔧 System Requirements

- **R version**: 3.6+
- **Memory**: 512 MB minimum
- **Storage**: 50 MB for database + labels
- **Network**: WiFi for mobile scanning (optional)
- **Browser**: Safari (iOS), Chrome/Firefox (Android/Desktop)

---

## 📁 File Structure

```
lims/
├── app.R                          # Main Shiny application
├── packages.R                     # Dependency installer
├── generate_barcode_labels.R      # Standalone label generator
├── quickstart.R                   # Interactive quick-start menu
├── README.md                      # This file
├── SETUP.md                       # Detailed setup guide
├── MOBILE_SCANNING_GUIDE.md       # iPhone/Android guide
├── TEST_WORKFLOW.md               # Complete test walkthrough
├── data/
│   ├── lims_db.sqlite            # SQLite database (auto-created)
│   ├── labels/                   # Generated label files
│   └── barcodes/                 # Barcode images (optional)
└── www/
    └── qr_*.png                  # Verification QR codes (auto-generated)
```

---

## 🐛 Troubleshooting

### Packages missing
```r
source("packages.R")
```

### iPhone can't access app
- Verify both on same WiFi network
- Check firewall isn't blocking port 3838
- Use correct IP address from `ifconfig`

### Plant ID not found
- Verify ID exists in database (check Inventory View)
- Ensure correct spelling and format (e.g., ST0001-P0001)

### Database locked
- Close the app (Ctrl+C)
- Try again
- If persistent: Delete `data/lims_db.sqlite` to start fresh

See **[TEST_WORKFLOW.md](TEST_WORKFLOW.md)** for detailed troubleshooting.

---

**Built with ❤️ for the Riverside Rhizobia Research Lab**

*Laboratory Information Management System (LIMS) v1.0*
*R Shiny | SQLite | QR Codes | Mobile-Friendly*
