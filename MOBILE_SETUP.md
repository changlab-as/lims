# MOBILE SCANNING SETUP GUIDE

## Problem: Phone Cannot Access Client Page

By default, Shiny apps run on `localhost:3838` which is **only accessible from your computer**, not from other devices on the network.

## Solution: Configure App for Network Access

### Step 1: Update Your App Startup

Instead of running `shiny::runApp()`, use:

```r
shiny::runApp(host = "0.0.0.0", port = 3838)
```

Or create a file `run_app_network.R`:

```r
#!/usr/bin/env Rscript
source("app.R", local = TRUE)
shiny::runApp(host = "0.0.0.0", port = 3838)
```

Then run:
```bash
Rscript run_app_network.R
```

### Step 2: Find Your Computer's IP Address

**On Mac (Terminal):**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Look for something like: `inet 192.168.1.100`

**On Windows (Command Prompt):**
```bash
ipconfig
```

Look for "IPv4 Address" like `192.168.1.100`

### Step 3: Access on Your Phone

1. **Make sure your phone is on the same WiFi network** as your computer
2. Open your phone browser (Safari, Chrome, etc.)
3. Enter: `http://192.168.1.100:3838`
   - Replace `192.168.1.100` with YOUR computer's IP address
4. You should see the LIMS app

### Step 4: Test Mobile Scanning

1. Navigate to **"Mobile Scan"** tab
2. Open your phone's native camera app or QR scanner
3. Scan a label with the QR code
4. The plant ID should auto-fill in the **"Scanned Plant ID"** field
5. Select fridge location and click **"Check In Sample"**

## How Mobile Scanning Works

**Automatic Capture:**
- The app uses JavaScript to detect when text is pasted into the "Scanned Plant ID" field
- Most QR scanners paste the scanned data directly into the focused input field
- The app auto-submits when it detects a complete plant ID (format: `ST0001-P0001`)

**Manual Entry (if auto-capture doesn't work):**
1. Scan QR code separately
2. Copy the plant ID (ST0001-P0001)
3. Paste into "Scanned Plant ID" field
4. Select location and click "Check In Sample"

## Troubleshooting

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

## Generating Test Labels for Scanning

In the **"Label Generation"** tab:
1. Select a site (e.g., ST0001)
2. Set plant range (e.g., 1-10)
3. Click **"Generate Labels"**
4. Print or display labels on screen
5. Use phone camera to scan and test

## Security Note

When you stop the app, network access is blocked automatically. Make sure to run the app on a secure network and close it when not in use if you're concerned about external access.
