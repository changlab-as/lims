# R/helpers.R
# Database initialization, sequential ID generators, and label PNG utility.
# Sourced by global.R — pool is available as a global object.

# ── Database initialization ──────────────────────────────────────────────────

initialize_database <- function() {
  db_path <- "data/lims_db.sqlite"

  if (!dir.exists("data")) dir.create("data")

  con <- dbConnect(RSQLite::SQLite(), db_path)

  # Recreate Sites table to ensure schema is current
  dbExecute(con, "DROP TABLE IF EXISTS Sites")
  dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Plants (
      plant_id      TEXT PRIMARY KEY,
      site_id       TEXT NOT NULL,
      species       TEXT NOT NULL,
      health_status TEXT,
      fridge_loc    TEXT,
      date_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Processing (
      proc_id      TEXT PRIMARY KEY,
      plant_id     TEXT NOT NULL,
      equipment_id TEXT,
      type         TEXT NOT NULL,
      date         DATETIME DEFAULT CURRENT_TIMESTAMP,
      technician   TEXT,
      notes        TEXT,
      FOREIGN KEY(plant_id) REFERENCES Plants(plant_id)
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Equipment (
      equipment_id   TEXT PRIMARY KEY,
      character_name TEXT NOT NULL,
      category       TEXT NOT NULL,
      description    TEXT,
      date_created   DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Labels (
      label_id         TEXT PRIMARY KEY,
      stage            INTEGER,
      site_id          TEXT,
      sample_type      TEXT,
      sample_id        TEXT,
      part_code        TEXT,
      part_id          TEXT,
      use_code         TEXT,
      sample_status    TEXT DEFAULT 'label_created',
      storage_location TEXT,
      collected_date   DATETIME,
      created_date     DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")

  # Seed equipment data (Ghibli-named lab equipment)
  existing_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Equipment")
  if (existing_count$count[1] == 0) {
    equipment_data <- data.frame(
      equipment_id = c("U01", "Z01", "F01", "F02", "F03", "F04", "G01"),
      character_name = c(
        "Totoro, in B16-1",
        "Jiji, -30\u00b0C in R100",
        "Teto, 4C in R100",
        "Warawara, the large 2-door in the kitchen",
        "Ponyo, the small 2-door in my office",
        "Kodama, the fridge in the B05",
        "Laputa (Castle in the Sky)"
      ),
      category = c(
        "Ultra-Low Temperature (-80\u00b0C)",
        "Standard Freezers (-20\u00b0C to -30\u00b0C)",
        "Fridges (4C)", "Fridges (4C)", "Fridges (4C)", "Fridges (4C)",
        "Plant growth chamber"
      ),
      description = c(
        "Ultra-Low Freezer at -80C",
        "Freezer at -30C in R100",
        "Fridge at 4C in R100",
        "Large 2-door refrigerator in the kitchen",
        "Small 2-door refrigerator in my office",
        "Fridge in B05",
        "Plant growth chamber - Castle in the Sky"
      ),
      stringsAsFactors = FALSE
    )
    dbAppendTable(con, "Equipment", equipment_data)
  }

  dbDisconnect(con)
  return(db_path)
}

# ── Sequential ID generators ─────────────────────────────────────────────────
# These reference `pool` from the global environment (set in global.R).

generate_site_id <- function() {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Sites")
  poolReturn(con)
  sprintf("ST%04d", result$count[1] + 1)
}

generate_plant_id <- function(site_id) {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con,
    paste0("SELECT COUNT(*) as count FROM Plants WHERE site_id = '", site_id, "'"))
  poolReturn(con)
  sprintf("%s-P%04d", site_id, result$count[1] + 1)
}

check_duplicate_plant_id <- function(plant_id) {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con,
    paste0("SELECT COUNT(*) as count FROM Plants WHERE plant_id = '", plant_id, "'"))
  poolReturn(con)
  result$count[1] > 0
}

generate_proc_id <- function() {
  con <- poolCheckout(pool)
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Processing")
  poolReturn(con)
  sprintf("PROC%06d", result$count[1] + 1)
}


# ── Label PNG generation ──────────────────────────────────────────────────────
# Renders a single 1800×600 label: sample ID + date on the left, QR on the right.

generate_label_png <- function(full_id, label_date, label_file) {
  # Generate QR code into a temporary square PNG
  set.seed(as.integer(charToRaw(full_id)) %% 2147483647)
  qr_obj    <- qr_code(full_id)
  temp_file <- tempfile(fileext = ".png")
  png(temp_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  qr_img <- png::readPNG(temp_file)

  # Compose final label
  png(label_file, width = 1800, height = 600, res = 150, bg = "white")
  grid.newpage()
  grid.text(full_id, x = 0.27, y = 0.75,
    gp = gpar(fontsize = 44, fontface = "bold", family = "monospace"),
    just = "centre")
  grid.text(as.character(label_date), x = 0.27, y = 0.25,
    gp = gpar(fontsize = 40, fontface = "bold", family = "monospace"),
    just = "centre")

  # QR code viewport — fixed square aspect ratio (right side of label)
  qr_vp <- viewport(x = 0.75, y = 0.5, width = 0.32, height = 0.96)
  pushViewport(qr_vp)
  grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
  popViewport()
  dev.off()

  unlink(temp_file)
  invisible(label_file)
}
