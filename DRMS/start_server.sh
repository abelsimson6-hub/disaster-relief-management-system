#!/bin/bash
# Start Django server on 0.0.0.0 for mobile access
# This allows connections from mobile devices on the same network

cd "$(dirname "$0")"
python manage.py runserver 0.0.0.0:8000

