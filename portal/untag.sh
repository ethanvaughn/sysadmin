#!/bin/bash

# Excluded from PROD:
cvs tag -d PROD deps/ schema/ test.pl vacuum.sql untag.sh

exit 0

