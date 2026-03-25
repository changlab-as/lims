#!/usr/bin/env Rscript
# Start LIMS app with network access for mobile devices
# Run this to access app from phone on same WiFi

source("app.R", local = TRUE)

# Get local IP for user reference
get_local_ip <- function() {
  ips <- system("ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'", intern = TRUE)
  if (length(ips) > 0) {
    # Usually the first one is the WiFi IP
    return(ips[1])
  }
  return("192.168.x.x")
}

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║     LIMS Mobile Scanning - Network Enabled                    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

ip <- get_local_ip()
cat("📱 Mobile Access Information\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat(sprintf("Computer IP Address: %s\n", ip))
cat("Port: 3838\n")
cat(sprintf("URL: http://%s:3838\n\n", ip))
cat("📖 Instructions:\n")
cat("1. Make sure your phone is on the same WiFi network\n")
cat("2. Open browser on phone and enter the URL above\n")
cat("3. Go to 'Mobile Scan' tab\n")
cat("4. Scan QR codes with your phone camera\n\n")
cat("Press Ctrl+C to stop the server\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Start app listening on all network interfaces
shiny::runApp(host = "0.0.0.0", port = 3838)
