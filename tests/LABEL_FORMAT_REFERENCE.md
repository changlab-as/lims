# LIMS Label Format Quick Reference

## Label Hierarchy & Stages

```
STAGE 1: PRE-SAMPLING (Plant/Soil Collection)
├─ Format: ST####-P#### or ST####-S####
├─ Examples: ST0001-P0001, ST0001-S0001
├─ Database: Labels.stage = 1
└─ Sample Type: Plant or Soil

    ↓↓↓ After collection & processing ↓↓↓

STAGE 2: PARTS PROCESSING (Plant Sections)
├─ Format: ST####-[PS]####-XX###
├─ Examples: ST0001-P0001-SH001, ST0001-P0001-RT001
├─ Database: Labels.stage = 2
├─ Parent Link: Labels.sample_id = parent label
├─ Part Codes:
│   ├─ SH = Shoot
│   ├─ RT = Root
│   ├─ ND = Node
│   └─ LF = Leaf (optional)
└─ Count: Usually 2-5 parts per plant

    ↓↓↓ After use assignment ↓↓↓

STAGE 3: USE SAMPLES (Experimental Use)
├─ Format: ST####-[PS]####-XX###-XX##
├─ Examples: ST0001-P0001-SH001-GW01, ST0001-P0001-RT001-DE01
├─ Database: Labels.stage = 3
├─ Parent Link: Labels.part_id = parent label
├─ Use Codes:
│   ├─ GW = Greenhouse Watering
│   ├─ DE = Disease Evaluation
│   ├─ RE = Replicate Extraction
│   ├─ PR = Phenotypic Reaction
│   └─ TI = Tissue Imaging
└─ Count: Usually 1-3 per part
```

---

## Format Specifications

### STAGE 1: Site & Sample IDs

#### Site ID (ST####)
```
ST0001  = Site 1 (must be ST + exactly 4 digits)
ST0002  = Site 2
ST9999  = Site 9999 (max)
ST0000  = Site 0 (valid but unusual)
```
**Regex:** `^ST\d{4}$`

#### Plant Sample (ST####-P####)
```
ST0001-P0001  = Site 1, Plant Sample 1
ST0001-P0005  = Site 1, Plant Sample 5
ST0002-P0001  = Site 2, Plant Sample 1
```
**Regex:** `^ST\d{4}-P\d{4}$`

#### Soil Sample (ST####-S####)
```
ST0001-S0001  = Site 1, Soil Sample 1
ST0002-S0010  = Site 2, Soil Sample 10
```
**Regex:** `^ST\d{4}-S\d{4}$`

---

### STAGE 2: Parts Labels

#### Full Format (ST####-[PS]####-XX###)
```
Parent Sample: ST0001-P0001
    ├─ Part 1: ST0001-P0001-SH001  (Shoot)
    ├─ Part 2: ST0001-P0001-RT001  (Root)
    ├─ Part 3: ST0001-P0001-ND001  (Node)
    └─ Part 4: ST0001-P0001-LF001  (Leaf)
```

#### Part Code Legend
```
SH = Shoot (above-ground plant parts)
RT = Root (below-ground plant parts)
ND = Node (junction points)
LF = Leaf (expanded leaves)
ST = Stem (woody stems)
FL = Flower/Fruit
```

**Regex:** `^ST\d{4}-[PS]\d{4}-[A-Z]{2}\d{3}$`

---

### STAGE 3: Use Samples

#### Full Format (ST####-[PS]####-XX###-XX##)
```
Parent Part: ST0001-P0001-SH001
    ├─ Use 1: ST0001-P0001-SH001-GW01  (Greenhouse Watering)
    ├─ Use 2: ST0001-P0001-SH001-DE01  (Disease Evaluation)
    ├─ Use 3: ST0001-P0001-SH001-RE01  (Replicate Extraction)
    └─ Use 4: ST0001-P0001-SH001-PR01  (Phenotypic Reaction)
```

#### Use Code Legend
```
GW = Greenhouse Watering
DE = Disease Evaluation
RE = Replicate Extraction
PR = Phenotypic Reaction
TI = Tissue Imaging
GO = Genomic Observation
HO = Histological Observation
BC = Biosynthesis Characterization
```

**Regex:** `^ST\d{4}-[PS]\d{4}-[A-Z]{2}\d{3}-[A-Z]{2}\d{2}$`

---

## Database Table Structure

### Sites Table
```sql
CREATE TABLE Sites (
    site_id TEXT PRIMARY KEY,          -- ST0001, ST0002, etc
    site_name TEXT NOT NULL,           -- "Field Site 1"
    site_lat REAL,                     -- latitude (-90 to 90)
    site_long REAL,                    -- longitude (-180 to 180)
    date_created DATETIME
);
```

### Labels Table
```sql
CREATE TABLE Labels (
    label_id TEXT PRIMARY KEY,         -- Full label identifier
    stage INTEGER,                     -- 1, 2, or 3
    site_id TEXT,                      -- ST0001
    sample_type TEXT,                  -- 'plant', 'soil'
    sample_id TEXT,                    -- Parent sample (stage 2)
    part_code TEXT,                    -- 'SH', 'RT', 'ND'
    part_id TEXT,                      -- Parent part (stage 3)
    use_code TEXT,                     -- 'GW', 'DE', 'RE'
    sample_status TEXT,                -- Status enum
    storage_location TEXT,             -- Where stored
    collected_date DATETIME,           -- Collection timestamp
    created_date DATETIME,
    FOREIGN KEY(site_id) REFERENCES Sites(site_id)
);
```

### Status Values
```
'label_created'    = Label printed but not used
'collected'        = Sample collected/harvested
'processed'        = Sample prepared for analysis
'analyzed'         = Data collection complete
'archived'         = Storage/archival status
```

---

## Validation Rules

### Site ID Requirements
- ✓ Format: **ST** + 4 digits (0000-9999)
- ✓ Must be unique
- ✓ Required for all labels
- ✗ Reject: S0001, ST001, st0001, ST1

### Sample ID Requirements
- ✓ Format: ST####-[PS]####
- ✓ Must be unique (PRIMARY KEY)
- ✓ P = Plant, S = Soil
- ✗ Cannot start with anything except ST

### Part Code Requirements
- ✓ Format: (Parent)-XX### (2 letters + 3 digits)
- ✓ Must reference valid parent sample
- ✓ Parent must be stage 1 (collected)
- ✗ Cannot create part without parent

### Use Code Requirements
- ✓ Format: (Parent)-XX## (2 letters + 2 digits)
- ✓ Must reference valid parent part
- ✓ Parent must be stage 2 (part label)
- ✗ Cannot create use without part

---

## QR Code Specifications

### Square Image Requirement ⚠️
- **Width:** 400 pixels
- **Height:** 400 pixels
- **Aspect Ratio:** 1:1 (MUST be square)
- **Format:** PNG
- **Background:** White
- **Data:** Full label ID (all 4 segments)

### QR Content
```
QR Data String Examples:
- Stage 1: "ST0001-P0001"
- Stage 2: "ST0001-P0001-SH001"
- Stage 3: "ST0001-P0001-SH001-GW01"
```

### Image Properties
```
File Size: ~5-15 KB (PNG)
Color Depth: 8-bit
DPI: 300+ recommended for printing
Print Size: 2" × 2" minimum
```

**CRITICAL TEST:** <br>
If QR code is rectangular (not square), scanning and printing will fail.

---

## Common Examples

### Complete Workflow Example

```
1. CREATE SITE
   ID: ST0001
   
2. COLLECT SAMPLES
   Plant 1: ST0001-P0001
   Plant 2: ST0001-P0002
   Soil:    ST0001-S0001
   
3. PROCESS PLANT 1 PARTS
   Shoot 1: ST0001-P0001-SH001
   Root 1:  ST0001-P0001-RT001
   
4. CREATE USE SAMPLES
   From SH001:
     ST0001-P0001-SH001-GW01  (Greenhouse)
     ST0001-P0001-SH001-DE01  (Disease eval)
     ST0001-P0001-SH001-RE01  (Extraction)
   
   From RT001:
     ST0001-P0001-RT001-GW01
     ST0001-P0001-RT001-BC01  (Biosynthesis)
```

---

## Batch Generation Examples

### Generate Plant Samples for Site
```R
site_id <- "ST0001"
n_plants <- 5

for (i in 1:n_plants) {
  label_id <- sprintf("%s-P%04d", site_id, i)
  # Insert to database
}
# Result: ST0001-P0001, ST0001-P0002, ..., ST0001-P0005
```

### Generate Parts from Plant
```R
plant_id <- "ST0001-P0001"
parts <- list(SH = 2, RT = 1)

for (code in names(parts)) {
  for (i in 1:parts[[code]]) {
    part_id <- sprintf("%s-%s%03d", plant_id, code, i)
    # Insert to database
  }
}
# Result: ST0001-P0001-SH001, ST0001-P0001-SH002, ST0001-P0001-RT001
```

### Generate Uses from Part
```R
part_id <- "ST0001-P0001-SH001"
uses <- list(GW = 1, DE = 1, RE = 1)

for (code in names(uses)) {
  for (i in 1:uses[[code]]) {
    use_id <- sprintf("%s-%s%02d", part_id, code, i)
    # Insert to database
  }
}
# Result: ST0001-P0001-SH001-GW01, ST0001-P0001-SH001-DE01, ST0001-P0001-SH001-RE01
```

---

## Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| Duplicate key | Label already exists | Check if label created previously |
| Parent not found | Missing parent sample | Create parent sample first |
| Stage mismatch | Creating stage 2 from stage 2 | Ensure parent is correct stage |
| Invalid format | ID doesn't match regex | Check format against specification |
| QR not square | PNG dimensions unequal | Set width=height in png() call |

---

## Print Label Template

### Physical Label Layout (2" × 2" minimum)
```
┌─────────────────────┐
│                     │  ← 0.5" margin
│  QR CODE  │ Label:  │
│  (400x400 │ ST0001- │
│   px)     │ P0001-  │
│           │ SH001-  │
│           │ GW01    │
│           │         │
│           │ Date:   │
│           │ 2024-   │
│           │ 01-15   │
│                     │  ← 0.5" margin
└─────────────────────┘
```

---

## Testing Checklist

- [ ] All site IDs match format `ST####`
- [ ] All plant/soil IDs match format `ST####-[PS]####`
- [ ] All part IDs match format `ST####-[PS]####-XX###`
- [ ] All use IDs match format `ST####-[PS]####-XX###-XX##`
- [ ] QR codes are square (400×400 px)
- [ ] No duplicate labels
- [ ] All parents exist before creating children
- [ ] Stages correct (1, 2, or 3)
- [ ] Coordinates valid (lat: -90 to 90, lon: -180 to 180)

---

**Version:** 1.0  
**Last Updated:** 2024  
**Maintained By:** LIMS Development Team
