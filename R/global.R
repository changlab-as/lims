# global.R
# Sourced automatically by Shiny before app.R.
# Handles: library loading, helper sourcing, and shared pool initialization.

# ── Libraries ─────────────────────────────────────────────────────────────────
library(shiny)
library(bslib)
library(shinyjs)
library(DT)
library(RSQLite)
library(qrcode)
library(pool)
library(dplyr)
library(DBI)
library(gridExtra)
library(grid)
library(base64enc)

# ── Helpers ───────────────────────────────────────────────────────────────────
source("R/helpers.R")

# ── Static directories ────────────────────────────────────────────────────────
if (!dir.exists("www")) dir.create("www")

# ── Database + connection pool ────────────────────────────────────────────────
db_path <- initialize_database()

pool <- dbPool(
  drv     = RSQLite::SQLite(),
  dbname  = db_path,
  minSize = 1,
  maxSize = 5
)

# Close pool cleanly when the app stops
onStop(function() poolClose(pool))
