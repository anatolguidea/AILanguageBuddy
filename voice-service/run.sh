#!/bin/bash

# Check if python3 exists
if ! command -v python3 &> /dev/null
then
    echo "Python3 could not be found. Please install Python 3.11 or higher."
    exit 1
fi

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Load .env variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Run the server
echo "Starting Voice Service on port 8000..."
uvicorn main:app --reload --host 0.0.0.0 --port 8000
