#!/bin/bash

#cd ~/Documents/shells/machine_learning/mvc

source venv/bin/activate

gunicorn --bind 127.0.0.1:8000 wsgi:application
