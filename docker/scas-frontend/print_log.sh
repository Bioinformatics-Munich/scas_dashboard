#!/bin/bash
cat $(find /var/log/shiny-server -type f -exec ls -t1 {} +| head -1)