# FROM python:3.6
# Image needs an R installation

FROM rocker/shiny:4.0.5

RUN apt-get update && apt-get install -y nano python3 python3-dev python3-pip libpq-dev libcurl4-gnutls-dev libssl-dev && apt-get clean all

# Install Quarto
RUN wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.3.450/quarto-1.3.450-linux-amd64.deb
RUN apt install -y -f ./quarto-1.3.450-linux-amd64.deb

ENV TERM xterm

WORKDIR /usr/src/backend

# Copy the app
ADD ./app /usr/src/app

# Install R packages
RUN Rscript /usr/src/app/00_install_packages.R

# Copy code to backend directory
ADD ./backend /usr/src/backend
RUN rm -rf /usr/src/backend/ClusterAdminStatsApp/migrations/*
RUN rm -rf /usr/src/backend/ClusterAdminStatsApp/__pycache__/*
RUN pip install -r /usr/src/backend/requirements.txt

# Django
ENV DJANGO_SETTINGS_MODULE "wui.settings.prod"

# see https://github.com/rpy2/rpy2/issues/771
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-11-openjdk-amd64/lib/server

# Copy run and init script
COPY ./docker/scas-backend/run_script.sh run_script.sh
COPY ./docker/scas-backend/init.sh init.sh

# Chmod init.sh
RUN chmod 755 /usr/src/backend/init.sh

# Run script
RUN chmod 750 run_script.sh
CMD /usr/src/backend/run_script.sh
