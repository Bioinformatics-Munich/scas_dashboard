# https://blog.sellorm.com/2021/04/25/shiny-app-in-docker/

FROM rocker/shiny:4.0.5

RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev

# copy the app directory into the image
COPY ./app/* /srv/shiny-server/
ADD ./app/www /srv/shiny-server/www

# Install R packages
RUN Rscript /srv/shiny-server/00_install_packages.R

# copy Renv file
COPY ./docker/scas-frontend/.Renviron /srv/shiny-server/.Renviron

# copy print_log.sh
COPY ./docker/scas-frontend/print_log.sh /print_log.sh
RUN chmod 755 /print_log.sh

# run app
CMD ["/usr/bin/shiny-server"]
