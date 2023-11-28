# A: Thomas Walzthoeni, 2021
# D: Install R packages
# R packages
#list.of.packages <- c('rmarkdown', "shiny","shinydashboard", "dplyr", "dplyr", "readr","ggplot2","here","stringr","DT","reshape2","RColorBrewer","patchwork","httr","jsonlite","shinyjs","Rcpp")
#new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
#if(length(new.packages)>0) install.packages(new.packages)
install.packages(c(
                   "rmarkdown", "shiny","shinydashboard", "dplyr", "readr","ggplot2","here","stringr","DT","reshape2","RColorBrewer","patchwork","httr","jsonlite","shinyjs","Rcpp","shinyBS"
),repos="https://packagemanager.rstudio.com/cran/__linux__/focal/2022-12-27")
