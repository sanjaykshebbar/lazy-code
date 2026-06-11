#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Detects whether Colima is installed system-wide.
# - Checks for the Colima binary in /usr/local/bin.
# - Verifies that the binary is executable and functional.
# - Returns exit code 0 if Colima is installed and working.
# - Returns exit code 1 if Colima is not installed or is corrupted.
###############################################################################

###############################################################################
# Define the expected Colima binary location.
###############################################################################
COLIMA_BIN="/usr/local/bin/colima"

###############################################################################
# Verify that the Colima binary exists and is executable.
###############################################################################
if [ -x "$COLIMA_BIN" ]; then

    ############################################################################
    # Verify that the Colima binary can execute successfully.
    ############################################################################
    if "$COLIMA_BIN" version >/dev/null 2>&1; then
        echo "Colima is installed and functional."
        exit 0
    else
        echo "Colima binary exists but is not functional."
        exit 1
    fi

else

    ############################################################################
    # Colima binary was not found.
    ############################################################################
    echo "Colima is not installed."
    exit 1

fi
