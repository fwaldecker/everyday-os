#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# Run the installation script with the environment variables
python3 start_services.py
