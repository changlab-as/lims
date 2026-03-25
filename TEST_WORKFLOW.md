# Riverside Rhizobia LIMS - Complete Test Workflow

This guide walks you through testing all features of the LIMS system from start to finish.

## Part 1: Initial Setup (5 minutes)

### Step 1: Verify Installation
```bash
cd /Users/cychang/Desktop/lab/lims
R
```

In R console:
```r
source("packages.R")
```

Output should show: `All packages ready!`

### Step 2: Start the App
```r
shiny::runApp()
```

The app will open at: **http://localhost:3838**

---

## Part 2: Test Field Entry (10 minutes)

### Create Your First Site:

1. Click **Field Entry** tab
2. Under "New Site" section:
   - Location Name: `Test Site A`
   - Date Sampled: Today's date
   - Click **Create Site**
   - Note the auto-generated ID: `ST0001`

3. Site appears in "Site Information" table

### Create Plant Records:

1. Select **Site**: `ST0001 - Test Site A` from dropdown
2. Number of Plants: `5`
3. Click **Generate Plant Forms**
4. Fill in each plant:
   ```
   Plant 1: Species: Rhizobium leguminosarum | Health: Healthy | Fridge: Fridge A - Shelf 1
   Plant 2: Species: Rhizobium etli | Health: Healthy | Fridge: Fridge A - Shelf 1
   Plant 3: Species: Bradyrhizobium | Health: Stressed | Fridge: Fridge A - Shelf 2
   Plant 4: Species: Rhizobium leguminosarum | Health: Diseased | Fridge: Fridge B - Shelf 1
   Plant 5: Species: Azospirillum | Health: Healthy | Fridge: Fridge B - Shelf 1
   ```
5. Click **Save** for each plant
6. ✓ Each plant receives auto-generated ID: `ST0001-P0001`, `ST0001-P0002`, etc.

**Expected Result:** 5 plants created with sequential IDs

---

## Part 3: Test Label Generation (10 minutes)

### Generate Batch Labels:

1. Click **Label Generation** tab
2. Select Site: `ST0001 - Test Site A`
3. Start Plant Index: `1`
4. End Plant Index: `5`
5. Output Format: `PNG (High Resolution)`
6. Click **Generate Labels**

**Expected Result:**
- See status: "✓ Labels Generated"
- PNG files created in `data/labels/`
  - `ST0001-P0001.png`, `ST0001-P0002.png`, etc.

### Verify Label Files:
```bash
ls -la data/labels/
# Should show: ST0001-P0001.png through ST0001-P0005.png
```

### Test Duplicate Detection:

1. In Label Generation tab, try again with same site and indices
2. Click **Generate Labels**

**Expected Result:**
- Should generate without error
- (Duplicate detection in label generation shows which ones exist)

---

## Part 4: Test Lab Check-In (Desktop) (10 minutes)

### Test Sample Check-In:

1. Click **Lab Check-In** tab
2. "Scan Sample Barcode" field:
   - Type: `ST0001-P0001`
   - Cursor should **auto-move** to "Scan Fridge Location" ✓
3. "Scan Fridge Location" field:
   - Type: `Fridge A - Shelf 1`
   - Press Enter

**Expected Result:**
- ✓ Check-in successful notification
- Fridge location updated in database
- QR code displays for `ST0001-P0001`
- Entry appears in "Recent Check-Ins" table

### Test Error Handling:

1. Enter invalid plant ID: `ST0001-P9999`
2. Enter fridge loc: `Fridge A - Shelf 1`

**Expected Result:**
- ❌ Error: "Plant ID not found!"
- Input cleared for next scan

---

## Part 5: Test Mobile Scan (iPhone/Android) (15 minutes)

### Setup Mobile Access:

**Step 1: Get Your Mac's IP Address**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example: inet 192.168.1.100
```

**Step 2: On Your iPhone (same WiFi network)**
- Open Safari
- Address bar: `http://192.168.1.100:3838`
- Go to **Mobile Scan** tab

### Test Mobile Check-In:

1. iPhone Mobile Scan form:
   - Plant ID: `ST0001-P0002`
   - Fridge Location: `Fridge A - Shelf 2`
   - Tap **Check In Sample**

**Expected Result:**
- ✓ Check-in successful notification
- Entry appears in "Recent Mobile Check-Ins" table (visible on iPhone and desktop)
- Plant location updated in database

### Test Mobile with QR Code (Advanced):

1. Print one of the generated labels from `data/labels/`
2. On iPhone Camera app:
   - Point at printed QR code
   - Tap notification that appears
   - Should open the QR data
   - Copy the Plant ID
   - Paste into Mobile Scan form
   - Complete check-in

---

## Part 6: Test Inventory View (10 minutes)

### View All Plants:

1. Click **Inventory View** tab
2. See table with all plants:
   ```
   | plant_id      | site_id | species              | Health Status | Fridge Location |
   |---------------|---------|----------------------|---------------|-----------------|
   | ST0001-P0001  | ST0001  | Rhizobium leguminosarum | Healthy | Fridge A - Shelf 1 |
   | ST0001-P0002  | ST0001  | Rhizobium etli      | Healthy       | Fridge A - Shelf 2 |
   | ... etc       |         |                      |               |                 |
   ```

### Test Filtering:

1. Click on filter box under any column
2. Try filtering by species: `Rhizobium leguminosarum`
3. Try filtering by fridge location: `Fridge B`

**Expected Result:**
- Table updates to show only matching records

### View Processing Records:

1. Scroll down to "Processing Records" section
2. Should see entries for:
   - Type: `Inventory_Checkin` (from desktop lab check-in)
   - Type: `Mobile_Checkin` (from iPhone check-in)

---

## Part 7: Test Duplicate Prevention (5 minutes)

### Create Duplicate Plant ID:

1. Go to **Field Entry** tab
2. Create a second site: `ST0002 - Test Site B`
3. Add 5 plants to this new site

**Expected Result:**
- New plants get IDs: `ST0002-P0001` through `ST0002-P0005`
- NO conflicts with ST0001 plants

### Try Manual Duplicate:

1. Go to **Label Generation** tab
2. Select `ST0001`
3. Start: `1`, End: `3`
4. Generate

**Expected Result:**
- Generates successfully (or shows status of which IDs already exist)

---

## Part 8: Full Workflow End-to-End (20 minutes)

### Simulate Complete Lifecycle:

**Phase 1: Pre-Field Preparation**
```
1. Create Site: "Riverside Field 3"
2. Create 20 plants (hypothetically)
3. Run: generate_barcode_labels.R
4. Print labels (use data/labels/*.png files)
5. Attach to 20 empty sample bags
```

**Phase 2: Field Collection**
```
1. Collect samples and place in labeled bags
2. No scanning needed
```

**Phase 3: Lab Check-In**
```
1. Desktop option:
   - Scan sample barcode → Auto-move → Scan fridge location → Check in
   
2. Mobile option:
   - Open iPhone LIMS → Mobile Scan tab
   - Enter plant ID or scan QR → Select fridge → Check in
```

**Phase 4: Verification**
```
1. Go to Inventory View
2. See all plants with storage locations
3. See processing timeline
4. Generate report of all check-ins
```

---

## Testing Checklist

- [ ] ✓ All packages installed without errors
- [ ] ✓ Shiny app runs at http://localhost:3838
- [ ] ✓ Site creation works with auto-generated IDs
- [ ] ✓ Plant creation works with sequential IDs
- [ ] ✓ Label generation creates PNG files
- [ ] ✓ Duplicate detection works (no duplicate IDs)
- [ ] ✓ Desktop barcode scanning auto-focuses
- [ ] ✓ Desktop check-in updates database
- [ ] ✓ iPhone can access app on local network
- [ ] ✓ Mobile check-in updates database
- [ ] ✓ Inventory View shows all plants
- [ ] ✓ Filtering works in Inventory View
- [ ] ✓ Processing records logged correctly
- [ ] ✓ Error handling for invalid IDs

---

## Troubleshooting During Testing

### iPhone can't access app
- Verify both on same WiFi
- Check IP address: `ifconfig | grep "inet "`
- Try: `http://192.168.1.100:3838` (replace with your IP)

### App won't start
```bash
# Check if port 3838 is in use
lsof -i :3838
# Kill if needed: kill -9 <PID>
```

### Missing packages
```r
source("packages.R")
```

### Database locked error
- Close app (Ctrl+C)
- Try again
- If persistent, delete `data/lims_db.sqlite` and restart

### Labels not generating
- Check `data/labels/` directory exists
- Verify gridExtra is installed: `require("gridExtra")`

---

## Next Steps After Testing

1. **For Production:** See MOBILE_SCANNING_GUIDE.md for cloud deployment options
2. **For Customization:** Modify dropdown options for health_status and fridge_loc
3. **For Automation:** Add more processing types (Nodule_Iso, DNA_Ext, etc.)
4. **For Analysis:** Export data to CSV from Inventory View table

---

Created with ❤️ for the Riverside Rhizobia Lab
