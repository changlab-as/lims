# iPhone/Android Mobile Scanning Setup Guide

## Overview
The LIMS app now supports mobile scanning where users can scan QR codes from their iPhone or Android phone to automatically check in samples with their storage locations.

## Two Deployment Options

### Option 1: Local Testing (No Internet Needed)
**Best for: Lab testing and local network use**

1. **On macOS, run the Shiny app:**
   ```r
   shiny::runApp()
   ```
   The app runs at: `http://localhost:3838`

2. **On the same WiFi network:**
   - Find your Mac's IP address: Open Terminal and run `ifconfig | grep "inet "`
   - Replace `localhost` with your Mac's IP (e.g., `192.168.1.100:3838`)
   - Go to **Mobile Scan** tab in the app on your iPhone browser
   - Scan the QR code label or manually enter the plant ID

### Option 2: Production Deployment (Cloud)
**Best for: Multi-site field work with internet**

**Using shinyapps.io (simplest):**
```r
# Install deployment tools
install.packages("rsconnect")

# Deploy from R
rsconnect::deployApp()
```

This gives you a public URL like: `https://yourname.shinyapps.io/lims/`

---

## iPhone Scanning Workflow

### Step 1: Print Labels (Before Field Work)
1. In the Shiny app, go to **Label Generation** tab
2. Select your site and number of plants (e.g., 20)
3. Click "Generate Labels" → stores PNG files in `data/labels/`
4. **Print** the labels on sticker label sheets (2x2 inches recommended)
5. **Stick** labels on your sample bags in the field

### Step 2: Field Work
- Collect samples with labeled bags
- No need to scan in the field—labels are just ID references

### Step 3: Lab Check-In via Mobile
1. Come back to lab with samples
2. **On iPhone/Android:**
   - Open Safari/Chrome browser
   - Navigate to your app URL (local network or cloud)
   - Go to **Mobile Scan** tab
   - Manually enter the plant ID from the label (or open QR scanner):
     - iPhone native: Open Camera app → scan QR → tap notification → opens in browser
     - Or use built-in QR app if available

3. **In the Mobile Scan form:**
   - Plant ID field shows: `ST0001-P0001`
   - Select fridge location from dropdown
   - Tap "Check In Sample"
   - ✓ Automatically updates database and logs timestamp

---

## How to Make QR Codes Link to Your App

### Currently: QR codes contain just the plant ID
When scanned with a QR app, they display: `ST0001-P0001`

### Future Enhancement: QR codes link to your app
To make QR codes that directly open the mobile check-in page:

```r
# In generate_barcode_labels.R, modify the plant_id to:
# If deploying to production:
qr_url <- paste0("https://yourname.shinyapps.io/lims/?plant_id=", plant_id)

# If on local network:
qr_url <- paste0("http://192.168.1.100:3838/?plant_id=", plant_id)

qr_obj <- qr_code(qr_url)
```

Then in the Shiny app UI, add:
```r
observe({
  query <- parseQueryString(session$clientData$url_search)
  if (!is.null(query$plant_id)) {
    updateTextInput(session, "mobile_plant_id", value = query$plant_id)
  }
})
```

---

## Testing Mobile Scanning Locally

### Test Setup on macOS:

**Terminal 1 - Run the app:**
```bash
cd /Users/cychang/Desktop/lab/lims
R -e "shiny::runApp()"
```

**Terminal 2 - Find your IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Example output: `inet 192.168.1.100`

**On your iPhone (same WiFi):**
1. Open Safari
2. Enter: `http://192.168.1.100:3838`
3. Go to "Mobile Scan" tab
4. Enter a plant ID that exists in your database

---

## Duplicate ID Prevention

The app automatically prevents duplicate plant IDs:
- When creating plants in Field Entry, IDs auto-increment (ST0001-P0001, ST0001-P0002, etc.)
- If you try to check-in a non-existent plant ID, you get an error: "Plant ID not found"
- Label generation skips any IDs that already exist in the database (shown with ✗ mark)

---

## Sample Workflow

### Pre-Field Preparation:
```
1. Run: Rscript generate_barcode_labels.R
2. Select site: ST0001
3. Generate: 20 labels (P0001 - P0020)
4. Print on 2x2" labels
5. Pack in field
```

### Field Collection:
```
1. Collect samples
2. Stick label on each bag
3. No scanning needed yet
```

### Lab Check-In:
```
1. Bring samples back to lab
2. Open iPhone → Browser → LIMS app Mobile Scan tab
3. Enter plant ID from label → Select fridge location → Check In
4. ✓ Database auto-updates with location and timestamp
```

### Inventory Management:
```
1. Go to Inventory View tab
2. See all plants and their storage locations
3. Filter by species, health status, or location
4. Know exactly where each sample is stored
```

---

## Troubleshooting

### iPhone can't reach the app
- Make sure both devices are on same WiFi
- Check firewall isn't blocking port 3838
- Verify IP address is correct with `ifconfig`

### Plant ID not found error
- Verify the ID was entered correctly (case-sensitive)
- Make sure the plant was created in Field Entry tab before checking in
- Check Inventory View to see all plants

### Labels not printing correctly
- PNG files need 2x2 inch label paper (or adjust DPI in script)
- Use 300 DPI for best quality
- Test with standard printer first before thermal printer

### Database locked error
- Close the app and try again
- Only one Shiny app instance can access the database at a time
- Delete `data/lims_db.sqlite` to start fresh

---

## Configuration Tips

### For Production (shinyapps.io):
```r
# In Shiny app global section, add:
options(shiny.maxRequestSize = 100 * 1024^2)  # 100 MB max upload
options(shiny.usecairo = TRUE)  # Better graphics rendering
```

### For Local Network (Mac):
```bash
# Allow macOS firewall to accept connections
# System Preferences → Security & Privacy → Firewall Options
# Add R to allowed apps
```

---

Created with ❤️ for the Riverside Rhizobia Lab
