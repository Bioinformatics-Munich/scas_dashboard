#!/bin/bash

# Start the main process
export DJANGO_SETTINGS_MODULE="wui.settings.prod"
python3 manage.py collectstatic --no-input
/usr/local/bin/gunicorn wui.wsgi:application --limit-request-line 8190 -w 2 --timeout 6000 -b :8000
