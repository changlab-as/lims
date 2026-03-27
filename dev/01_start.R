# Golem Development Configuration
# This file guides the development workflow for the LIMS package

# 1. Run this script first (once per session):
# setwd("~/Desktop/lab/lims")
# devtools::load_all()

# 2. During development, use:
devtools::load_all()

# 3. Test interactively:
lims::run_app()

# 4. Run unit tests:
devtools::test()

# 5. Check the package:
devtools::check()

# 6. Load app with golem features:
library(shiny)
library(lims)
