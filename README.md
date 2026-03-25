# Riverside Rhizobia LIMS
## Laboratory Information Management System

**A complete R Shiny application for managing laboratory samples, sample tracking, and inventory.**

### 🎯 Core Features

- **Field Entry**: Create sampling sites and register plants with auto-generated sequential IDs
- **Batch Label Generation**: Generate printable QR code labels (PNG/PDF) before field work
- **Desktop Lab Check-In**: Barcode scanning with auto-focus between fields
- **Mobile Scanning**: iPhone/Android browser-based check-in via QR codes
- **Inventory Management**: Real-time database view with filtering and sorting
- **Duplicate Prevention**: Automatic detection of duplicate sample IDs
- **Processing Logs**: Complete audit trail of all lab activities
- **SQLite Database**: Local persistent storage with automatic backup

---

## 🚀 Quick Start

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

---

## 📖 Documentation

- **[SETUP.md](SETUP.md)** - Detailed setup and usage guide
- **[MOBILE_SCANNING_GUIDE.md](MOBILE_SCANNING_GUIDE.md)** - iPhone/Android scanning setup
- **[TEST_WORKFLOW.md](TEST_WORKFLOW.md)** - Complete end-to-end test walkthrough
- **[quickstart.R](quickstart.R)** - Interactive menu for common tasks

---

## 🔄 Workflow Overview

### Pre-Field Preparation
```
1. Create Sites in app → Get auto-generated site IDs (ST0001, ST0002, etc.)
2. Create Plants for each site → Get auto-generated plant IDs (ST0001-P0001, etc.)
3. Run Label Generation → Gets PNG/PDF labels with QR codes
4. Print labels and stick to sample bags
```

### Field Work
```
1. Collect samples using pre-labeled bags
2. No scanning needed in field
```

### Lab Check-In
```
Option A - Desktop with barcode scanner:
→ Scan sample barcode → Auto-move → Scan fridge location → ✓ Done

Option B - Mobile on iPhone/Android:
→ Open app in Safari → Mobile Scan tab → Enter plant ID → Select location → ✓ Done
```

### Inventory Tracking
```
1. Go to Inventory View tab
2. See all plants and their storage locations
3. Filter by species, health status, or fridge location
4. View processing timeline
```

---

## 💾 Database Schema

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

---

## 🏷️ Batch Label Generation

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
- **Resolution**: 300 DPI (print quality)
- **Format**: QR code with Plant ID, Site ID, and Date
- **Duplicate Detection**: Automatically skips existing plant IDs

---

## 📱 Mobile Scanning (iPhone/Android)

### Local Network Access
```bash
# Find your Mac's IP address
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example: inet 192.168.1.100

# On iPhone (same WiFi):
# Open Safari → http://192.168.1.100:3838
# Go to "Mobile Scan" tab
```

### Scanning Process
1. Click on "Scan QR Code" field (or manually enter plant ID)
2. Select fridge storage location
3. Tap "Check In Sample"
4. ✓ Database automatically updates with timestamp

### QR Code Scanning
- iOS: Open Camera app → Point at label → Tap notification → Opens data
- Android: Similar process with built-in QR detection

See **[MOBILE_SCANNING_GUIDE.md](MOBILE_SCANNING_GUIDE.md)** for cloud deployment options.

---

## 🛡️ Duplicate Prevention

The app implements automatic duplicate checking at multiple levels:

1. **Auto-Incrementing IDs**: Sequential IDs ensure uniqueness
2. **Label Generation**: Skips IDs already in database (marked ✗)
3. **Check-In Validation**: Rejects non-existent plant IDs with error
4. **Database Constraints**: SQL constraints prevent duplicate writes

---

## 🚀 Easiest Way to Start Testing

### Option 1: Interactive Menu (Recommended)
```bash
cd /Users/cychang/Desktop/lab/lims
Rscript quickstart.R
```
Then choose option 1 to run the app.

### Option 2: Direct R Command
```r
shiny::runApp()
```

### Option 3: From VS Code Terminal
```bash
cd /Users/cychang/Desktop/lab/lims
R -e "shiny::runApp()"
```

---

## 📊 Testing Checklist

- [ ] Run `source("packages.R")` - All packages installed
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
