#!/usr/bin/env bash
set -e
echo "→ Installing dependencies..."
python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
echo "Please Install SuperCollider / Processing manually."
echo "→ Done!" 
