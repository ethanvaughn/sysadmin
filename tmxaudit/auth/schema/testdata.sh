#!/bin/bash

# Load test users and groups for development

../bin/useradd.pl -c "Ethan Vaughn" -u 40000 -d /u01/home/sysadmin -g sysadmin evaughn
../bin/useradd.pl -c "Jon Eicher" -u 40001 -d /u01/home/sysadmin -g sysadmin jeicher

