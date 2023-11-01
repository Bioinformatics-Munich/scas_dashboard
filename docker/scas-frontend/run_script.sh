#!/bin/bash
# /usr/local/bin/R -e "shiny::runApp('/srv/shiny-server',port=3838, host='0.0.0.0')"
/usr/local/bin/Rscript -e "shiny::runApp('/srv/shiny-server',port=3838, host='0.0.0.0')"  --vanilla |& tee -a /log.txt