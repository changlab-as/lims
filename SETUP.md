# Riverside Rhizobia LIMS - Setup & Quick Start Guide

## Overview
A complete Laboratory Information Management System (LIMS) for the Riverside Rhizobia research lab, built with R Shiny.

## Features
- ✅ SQLite database with automated schema initialization
- ✅ Three-tab interface: Field Entry, Lab Check-In, Inventory View, Mobile Scan, Label Generation
- ✅ Barcode scanning with automatic focus management
- ✅ **Batch label generation** with QR codes for pre-field printing
- ✅ **Duplicate ID checking** - prevents duplicate sample IDs
- ✅ **Mobile scanning** from iPhone/Android for lab check-in
- ✅ QR code generation for plant samples
- ✅ Real-time database updates with connection pooling
- ✅ Professional bs4Dash UI with responsive design
- ✅ DataTables for advanced inventory management

## Database Schema

### Sites Table
```
site_id              TEXT (PK) - Format: ST0001, ST0002, etc.
location_name        TEXT      - Name of sampling location
date_sampled         DATE      - Date of collection
```

### Plants Table
```
plant_id             TEXT (PK) - Format: ST0001-P0001, ST0001-P0002, etc.
site_id              TEXT (FK) - Reference to Sites table
species              TEXT      - Plant species name
health_status        TEXT      - Healthy, Stressed, or Diseased
fridge_loc           TEXT      - Storage location in refrigerator
date_created         DATETIME  - Timestamp of creation
```

### Processing Table
```
proc_id              TEXT (PK) - Unique processing record ID
plant_id             TEXT (FK) - Reference to Plants table
type                 TEXT      - Nodule_Iso, DNA_Ext, Stem_Grow, or Inventory_Checkin
date                 DATETIME  - Processing date/time
technician           TEXT      - Name of technician performing work
notes                TEXT      - Additional notes or observations
```

## Installation

### 1. Install Required Packages
In R or RStudio, run:
```r
source("packages.R")
```

This will install:
- `shiny` - Web application framework
- `bs4Dash` - Bootstrap 4 dashboard interface
- `shinyjs` - JavaScript/JavaScript interactions
- `DT` - Interactive data tables
- `RSQLite` - SQLite database driver
- `qrcode` - QR code generation
- `pool` - Database connection pooling
- `dplyr` - Data manipulation utilities
- `DBI` - Database interface
- `gridExtra` - Grid layout for labels

### 2. Run the Application

#### Option A: In RStudio
Open `app.R` and click the "Run App" button, or run:
```r
shiny::runApp()
```

#### Option B: Command Line
From the project directory, run:
```r
R -e "shiny::runApp()"
```

## Usage Guide

### Field Entry Tab
1. **Create New Site**
   - Enter location name (e.g., "Riverside Site A")
   - Select sampling date
   - Click "Create Site" - receives auto-generated ID (ST0001, ST0002, etc.)

2. **Add Plants to Site**
   - Select a site from dropdown
   - Specify number of plants (1-100)
   - Click "Generate Plant Forms"
   - Enel Generation Tab (NEW)
Pre-print labels before field work:
1. Select a site from dropdown
2. Specify plant index range (e.g., 1-20)
3. Choose format: PNG or PDF
4. Click "Generate Labels"
5. Labels are saved in `data/labels/` directory
6. Print on 2x2 inch sticker label sheets (300 DPI recommended)
7. Stick labels on sample bags before field collection
8. **Duplicate checking**: Automatically skips IDs already in database

### Mobile Scan Tab (NEW - iPhone/Android)
Scan labels during lab check-in:
1. Open Safari/Chrome on your iPhone
2. Navigate to your LIMS app (local network or cloud)
3. Go to "Mobile Scan" tab
4. Enter plant ID from label (or scan QR code)
5. Select fridge storage location
6. Tap "Check In Sample"
7. ✓ Automatically updates database with location and timestamp
8. See recent mobile check-ins in live table

### Lab Check-In Tab
Barcode scanning with automatic focus:
1. Click in "Scan Sample Barcode" field
2. Scan plant barcode with scanner (or manually enter plant_id)
3. After entering sample ID, cursor automatically moves to "Scan Fridge Location"
4. Scan fridge location barcode
5. System automatically:
     - Updates fridge_loc in database
     - Logs entry to Processing table
     - Generates QR code
     - Shows confirmation message

2. **Features**
   - QR code displays for scanned sample
   - Recent check-ins shown in live table
   - Error handling for invalid plant IDs

### Inventory View Tab
1. **View All Plants**
   - Live table of all plants in database
   Key Workflows

### Recommended Field to Lab Workflow:

**Step 1: Pre-Field Label Preparation**
```
1. Create sites and initial plant records in Field Entry tab
2. Run: Rscript generate_barcode_labels.R
3. Select site and number of plants (20-100)
4. Print labels on 2x2" sticker sheets
5. Pack labeled empty bags for field
```

**Step 2: Field Collection**
```
1. Collect samples
2. Stick pre-printed label on each bag
3. Done! No scanning needed yet
```

**Step 3: Lab Check-In – Mobile Option (NEW)**
```
1. Bring samples back to lab  
2. Open iPhone → Safari → LIMS Mobile Scan tab
3. Enter plant ID or scan QR code
4. Select fridge location
5. Tap "Check In" → ✓ Database auto-updates
```

**Step 4: Lab Check-In – Desktop Option**
```
1. Use Lab Check-In tab with barcode scanner
2. Scan sample barcode → Auto-focus to fridge location
3. Scan fridge barcode → ✓ Auto-updates database
```

### Duplicate Prevention Workflow:

The app implements **automatic duplicate checking** at two levels:

1. **During Label Generation:**
   - Pre-generation: Lists all existing plants in selected site
   - Generation: Skips any          # Main Shiny application
├── packages.R                      # Dependency installation script
├── generate_barcode_labels.R       # Standalone label generation
├── SETUP.md                        # Setup & usage guide
├── MOBILE_SCANNING_GUIDE.md        # iPhone/Android setup guide
├── .gitignore                      # Git exclusions
├── data/
│   ├── lims_db.sqlite             # SQLite database (auto-created)
│   ├── labels/                    # Generated label files
│   └── barcodes/                  # Barcode images
└── www/
    └── qr_*.png          
3. **During Check-In:**
   - Mobile or Desktop scan validates plant_id exists
   - Non-existent IDs show error: "Plant ID not found"
   - Prevents accidental data entry of fake samples
   - Last 50 processing records
   - Shows all activities for each plant
   - Types include: Nodule_Iso, DNA_Ext, Stem_Grow, Inventory_Checkin, Mobile
   - Last 50 processing records
   - Shows all activities for each plant
   - Types include: Nodule_Iso, DNA_Ext, Stem_Grow, Inventory_Checkin

## Database Location
- Database file: `data/lims_db.sqlite`
- Automatically created on first run
- Backed up in `.gitignore` - never committed to version control

## QR Codes
- Generated automatically during check-in
- Stored in `www/qr_*.png`
- Excluded from git via `.gitignore`
- Displays in UI for verification

## Connection Pooling
- Uses `pool` package for efficient database handling
- Min: 1 connection, Max: 5 connections
- Automatically manages connections
- Proper cleanup on app shutdown

## Troubleshooting

### "Package not found" error
Run `source("packages.R")` to install all dependencies.

### Database locked error
- Ensure only one instance of the app is running
- Check that previous sessions properly closed
- Delete `lims_db.sqlite` and restart app to reinitialize

### QR codes not displaying
- Ensure `www/` directory exists (created automatically)
- Check file permissions
- Verify `qrcode` package is installed

## Performance Tips
- Connection pooling handles up to 5 concurrent operations
- DataTables filter on client-side for better performance
- Database queries limited to recent records where possible
- Automatic connection cleanup on session end

## Security Notes
- Database uses local SQLite (suitable for single-server deployments)
- For multi-server production use, consider PostgreSQL with proper authentication
- No user authentication in current version - implement if needed
- Sensitive data not currently encrypted - add if handling regulated data

## Support & Customization
- Modify database schema in `initialize_database()` function
- Customize UI colors and layout in the `ui` section
- Add new processing types in the dropdown selections
- Extend inventory view with additional data fields

## File Structure
```
lims/
├── app.R                 # Main Shiny application
├── packages.R            # Dependency installation script
├── SETUP.md              # This file
├── .gitignore            # Git exclusions
├── data/
│   └── lims_db.sqlite   # SQLite database (auto-created)
└── www/
    └── qr_*.png         # QR codes (auto-generated)
```

---
Built with ❤️ for the Riverside Rhizobia Research Lab
