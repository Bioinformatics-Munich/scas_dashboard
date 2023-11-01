# https://blog.sellorm.com/2021/04/25/shiny-app-in-docker/

FROM rocker/shiny:4.0.5

RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev

# install required R packages
RUN R -e 'install.packages(c(\
"rmarkdown", "shiny","shinydashboard", "dplyr", "readr","ggplot2","here","stringr","DT","reshape2","RColorBrewer","patchwork","httr","jsonlite","shinyjs","Rcpp" \
            ), \
            repos="https://packagemanager.rstudio.com/cran/__linux__/focal/2022-12-27"\
          )'

# copy the app directory into the image
COPY ./app/* /srv/shiny-server/
ADD ./app/www /srv/shiny-server/www

# copy Renv file
COPY ./docker/scas-frontend/.Renviron /srv/shiny-server/.Renviron

# run app
CMD ["/usr/bin/shiny-server"]
