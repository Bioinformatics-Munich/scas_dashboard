#!/bin/bash
python3 manage.py makemigrations
python3 manage.py migrate --run-syncdb
python3 manage.py loaddata fixtures/settings.yaml
