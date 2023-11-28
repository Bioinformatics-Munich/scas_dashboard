## app.R ##
library(shiny)
library(shinydashboard)
library(plyr)
library(dplyr)
library(readr)
library(ggplot2)
library(here)
library(stringr)
library(DT)
library(reshape2)
library(RColorBrewer)
library(patchwork)
library(scales)
library(httr)
library(jsonlite)
library(shinyjs)
library(shinyBS)
# Switch off warnings
# options(warn=-1)

# source see also 
source(here::here('module_login.R'))

# Source functions.R
source(here::here('functions.R'))
source(here::here('plots.R'))

#res = GET("http://127.0.0.1:8000/api/",authenticate("admin", "admin"), query = list(from="2022-10-01", to="2022-12-31", returndata="FALSE"))
#datalist=get_datalist(res, partitions_selected=c("normal_q","interactive_cpu_p","interactive_gpu_p","cpu_p","gpu_p","bcf_p"),clusters_selected = c("slurm1","slurm2"))
# lines plots width
lpwidth <<- "90%"
boxsize <<- 12


ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title="SCAS Dashboard",tags$li(class = "dropdown btn btn-primary", actionButton("logout", "Logout",icon("power-off")))),
  dashboardSidebar(
    sidebarMenu(
      # icons: https://shiny.rstudio.com/reference/shiny/0.14/icon.html
      id = "tabs",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Charts", icon = icon("bar-chart-o"),startExpanded = TRUE,
               menuSubItem("Jobs and CPU hours", tabName = "subitem1"),
               menuSubItem("Memory and Cores", tabName = "subitem2"),
               menuSubItem("Job pending and run times", tabName = "subitem3"),
               menuSubItem("Job pending times per day", tabName = "subitem4"),
               menuSubItem("Distribution of usage", tabName = "subitem5"),
               menuSubItem("Utilization", tabName = "subitem6"),
               menuSubItem("Utilization per day", tabName = "subitem7")
      ),
      menuItem("Tables", icon = icon("table"),startExpanded = FALSE,
               menuSubItem("Utilization", tabName = "tables"),
               menuSubItem("Job and C(G)PU stats", tabName = "tablesstats")
      ),
      menuItem("Plot settings", icon = icon("gears"),startExpanded = FALSE,
               uiOutput("slider0"),
               uiOutput("slider1"),
               uiOutput("slider2")
      )
    ),
    uiOutput("Clusters"),
    uiOutput("Partitions"),
    # Select date range to be plotted # use -12 month as start
    dateRangeInput("date", "Date range", start = as.Date(seq(as.Date(format(Sys.Date(),format="%Y-%m-01")), length = 2, by = "-12 months")[2]), end = Sys.Date(),
                   min = NULL, max = Sys.Date()),
    actionButton("update" ,"Update View", icon("refresh"), class = "btn btn-warning")
  
    
  ),
  dashboardBody(
    
    tags$head(
      # Note the wrapping of the string in HTML()
      tags$style(HTML("
      .cover{
          opacity:1.0;
          background-image:url('cluster.png');
          background-repeat: no-repeat;
		  background-size: 100% 100%;
		  position:fixed;
          width:100%;
          height:100%;
          top:0px;
          left:0px;
          z-index:2000;
      }
      .sticky_footer {    position:fixed;    bottom:0;    right:0;    left:0;    background:#3c8dbc; color: white;   z-index: 1000;    opacity: 1; vertical-align:middle; text-align:center;}
      
                      
      ")),
      tags$link(rel = "shortcut icon", href = "favicon.ico")
    ),
    useShinyjs(),  # Include shinyjs     
    div(
        class = "container",
        
        column(
          width = 12,
          
          # section 2.2.2 - login form ----
          login_ui(id = "module_login", title = "Please login"),
          
          # section 2.2.3 - app ----
          #uiOutput(outputId = "display_content_module"),
        )
    ),
    div(class = "sticky_footer", HTML("<em>SCAS dashboard version 1.0</em>")),
    tabItems(
      
    tabItem("dashboard",
            fluidRow(
              column(
                div(
                  id = "welcome",
                  class = "panel",
                  tags$div(class = "panel-heading h3", id = NULL,
                           NULL,
                           "Welcome to SCAS Dashboard"
                  ),
                  tags$div(class = "panel-body", id = NULL,
                           NULL,
                           p("The Slurm Cluster Admin Statistics (SCAS) dashboard has been developed to gain insights on the usage of one (or more) SLURM clusters.", HTML("<br>"),
                           "It has been developed using ",a("shinydashboard",href="https://rstudio.github.io/shinydashboard")," for the frontend and 
                             and the ",a("Django REST framework",href="https://www.django-rest-framework.org/"), " for the backend."),
                  ),
                ),

                div(
                  id = "start",
                  class = "panel",
                  tags$div(class = "panel-heading h3", id = NULL,
                           NULL,
                           "Getting started"
                  ),
                  tags$div(class = "panel-body", id = NULL,
                           NULL,
                           p("Start the dashboard by selecting the partitions and the date range to analyze and hit the", HTML("<b>Update View</b>")," button. If you change the time range or the selected paritions, please update the dashboard by using the ", HTML("<b>Update View</b>")," button.")
                  ),
                ),                
                div(
                  id = "contact",
                  class = "panel",
                  tags$div(class = "panel-heading h3", id = NULL,
                           NULL,
                           "Contact"
                  ),
                  tags$div(class = "panel-body", id = NULL,
                           NULL,
                           p("The dashboard is available on github. Please use the github issues if there are any questions.")
                  ),
                ),                 
                hidden(
                div(
                  id = "dashheader",
                  class = "panel",
                  tags$div(class = "panel-heading h3", id = NULL,
                           NULL,
                           "Dashboard overview"
                  ),
                  tags$div(class = "panel-body", id = NULL,
                           NULL,
                           p("Below are the summary statistics for the selcted partitions and time frame.")
                  ),
              
              )),
              # Dynamic infoBoxes
              fluidRow(
              infoBoxOutput("cpuhrsBox"),
              infoBoxOutput("gpuhrsBox")
              ),
              fluidRow(
              infoBoxOutput("njobsBox"),
              infoBoxOutput("nuniqusers")
              ),
              width=6),
          ),
    ),
    tabItem("tables",
            
            fluidRow(
              
              column(
                h2("Data tables"),
                DT::dataTableOutput("utilization_partitions"),width=12
              ),
              column(
                DT::dataTableOutput("utilization_nodes"),width=12
              )              
              
              
            )
    ),

    tabItem("tablesstats",
            
            fluidRow(
              
              column(
                h2("Data tables"),
                DT::dataTableOutput("cpuhrstab"),width=12
              ),
              column(
                DT::dataTableOutput("gpuhrstab"),width=12
              ),             
              column(
                DT::dataTableOutput("njobstab"),width=12
              )
            )
    ),    
          
    tabItem("subitem1",
            
            div(
              id = "divsub1",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Compute jobs, CPU and GPU hours history"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown below are the summary statistics for the selcted partitions and time frame.")
              ),
              
              tabBox(
                title = "",
                # The id lets us use input$tabset1 on the server to find the current tab
                id = "tabset0", height = "650px", width = "100%",
                tabPanel("Jobs per month", box(
                  width=boxsize,
                  plotOutput(outputId = "lineplot", height = "500px", width = "40%"),
                )),
                tabPanel("CPU hours per month", box(
                  width=boxsize,
                  plotOutput(outputId = "lineplot2", height = "500px", width = "40%"),
                )),              
                tabPanel("GPU hours per month", box(
                  width=boxsize,
                  plotOutput(outputId = "lineplot3", height = "500px", width = "40%"), 
                ))
              ),
            ),
            
    ),
    
    tabItem("subitem2",
            div(
              id = "divsub2",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Contingency table of jobs completed and CPU hours by Memory Category and CPU category"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown below are the summary statistics for the selcted partitions and time frame.")
              ),
              tabBox(
                title = "",
                # The id lets us use input$tabset1 on the server to find the current tab
                id = "tabset0", height = "650px", width = "100%",
                tabPanel("CPUs", box(
                  width=boxsize,
                  plotOutput(outputId = "memcpujobs",height=550, width=lpwidth),
                )),
                tabPanel("GPUs", box(
                  width=boxsize,
                  plotOutput(outputId = "memgpujobs",height=550, width=lpwidth),
                ))
              ),
            ),
    ),
 
    tabItem("subitem3",
            div(
              id = "divsub3",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Job pending and run times"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Job pending times (A-D) and job run times (E-H). Shown are the mean queuing times per month, the error bars show the standard deviation of the queuing times.")
              ),
              tabBox(
                title = "",
                # The id lets us use input$tabset1 on the server to find the current tab
                id = "tabset0", height = "1100px", width = "100%",
                tabPanel("Job pending times", box(
                  width=boxsize,
                  plotOutput(outputId = "pendingtimes",height=1000, width=lpwidth),
                )),
                tabPanel("Job run times", box(
                  width=boxsize,
                  plotOutput(outputId = "runtimes",height=1000, width=lpwidth),
                ))
              ),
            ),
    ),

    tabItem("subitem4",
            div(
              id = "divsub4",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Job pending times per day"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown are the the average job pending times per day, the average job pending times per day for jobs without any pending reason (other than Priority or Resources) and the average of the mean job pending times per user and day. The latter 2 plot are shown to take into account that jobs can be pending due to various reasons or dependencies (e.g. job dependencies or max. concurrent running jobs per user).
                         If you change the time range or the selected paritions, please update the dashboard by using the ", HTML("<b>Update View</b>")," button.")
              ),
              tabBox(
                title = "",
                # The id lets us use input$tabset1 on the server to find the current tab
                id = "tabset0", height = "650px", width = "100%",
                tabPanel("Average job pending times per day", box(
                  width=boxsize,
                  plotOutput(outputId = "pendingtimesperday",height=550, width=lpwidth),
                )),
                tabPanel("Average job pending times per day for jobs w/o pending reason (other than Priority or Resources)", box(
                  width=boxsize,
                  plotOutput(outputId = "pendingtimesperdayNoneReason",height=550, width=lpwidth),
                )),
                tabPanel("Average of mean job pending times per user and day", box(
                  width=boxsize,
                  plotOutput(outputId = "MeanOfMeanPendingTimesPerUserPerDay",height=550, width=lpwidth),
                ))
              ),
            ),
    ),
    tabItem("subitem7",
            div(
              id = "divsub7",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Utilization per day"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown are the Utilization of the selected partition. Calculated by contasting used C(G)PU hours and theoretical C(G)PU hours. If you change the time range or the selected paritions, please update the dashboard by using the ", HTML("<b>Update View</b>")," button.")
              ),
              tabBox(
                title = "",
                # The id lets us use input$tabset1 on the server to find the current tab
                id = "tabset0", height = "650px", width = "100%",
                tabPanel("Utilization CPUs per day", box(
                  width=boxsize,
                  plotOutput(outputId = "utilizazion_per_day_CPU",height=550, width=lpwidth),
                )),
                tabPanel("Utilization GPUs per day", box(
                  width=boxsize,
                  plotOutput(outputId = "utilizazion_per_day_GPU",height=550, width=lpwidth),
                ))
              ),
            ),
    ),    
       
    
    
    
    tabItem("subitem5",
            
            div(
              id = "divsub4",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "CPU hours used by users"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown below are the summary statistics for the selcted partitions and time frame.")
              ),            
              # h2("Job pending times per day"),
              plotOutput(outputId = "percuserscpuhrs", height = "650px", width = "60%"),
            ),
    ),
    
    tabItem("subitem6",
            
            div(
              id = "divsub4",
              class = "panel",
              tags$div(class = "panel-heading h3", id = NULL,
                       NULL,
                       "Cluster utilization"
              ),
              tags$div(class = "panel-body", id = NULL,
                       NULL,
                       p("Shown below are the summary statistics for the selcted partitions and time frame.")
              ),
            tabBox(
              title = "",
              # The id lets us use input$tabset1 on the server to find the current tab
              id = "tabset1", height = "650px", width = "100%",
              tabPanel("CPU", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots0", height = "550px", width = lpwidth)
              )),
              tabPanel("GPU", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots1", height = "550px", width = lpwidth)
              )),              
              tabPanel("Nodes", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots2", height = "550px", width = lpwidth)
              )),
              tabPanel("by CPUs", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots3", height = "550px", width = lpwidth)
              )),
              tabPanel("by GPUs", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots4", height = "550px", width = lpwidth)
              )),              
              tabPanel("by Memory", box(
                width=boxsize,
                plotOutput(outputId = "utilizationplots5", height = "550px", width = lpwidth)
              ))
            ),
            ),
    )
    )

  )
  
)

# Module server function
datalistServer <- function(id, stringsAsFactors) {
  moduleServer(
    id,
    ## Below is the module function
    function(input, output, session) {
      # The selected file, if any
      userFile <- reactive({
        # If no file is selected, don't do anything
        validate(need(input$file, message = FALSE))
        input$file
      })
      

      
      # Return the reactive that yields the data frame
      return(datalist)
    }
  )    
}

# Params
initiated=FALSE
lastfrom=""
lastto=""

# Get db hostname:port from env var or use localhost
dbhostname <<- Sys.getenv("DB_HOSTNAME_PORT")
if (dbhostname == ""){
  dbhostname <<- "localhost:8000"
  print("localhost is used for db hostname")
}else{
  print(Sys.getenv("DB_HOSTNAME_PORT"))
  print("is used for db hostname")
}
# print(dbhostname)

server <- function(input, output, session) { 

  # Auth see also https://towardsdatascience.com/r-shiny-authentication-incl-demo-app-a599b86c54f7
  
  # check credentials vs API
  validate_password_module <- callModule(
    module   = validate_pwd, 
    id       = "module_login"
  )

  # For development / login on button click with user and pass provided here
  #validate_password_module <- callModule(
  #  module   = validate_pwd_dev, 
  #  id       = "module_login",
  #  user = "admin",
  #  pwd = "admin"
  #)

  # Check if initiated
  initiated <- eventReactive(input$update, {
    return(TRUE)
  }
  )
  
  # Remove welcome msg
  observeEvent(input$update, {
    removeUI(selector = "div#welcome")
    removeUI(selector = "div#start")
    removeUI(selector = "div#contact")
  })

  output$boxContentUI <- renderUI({
    input$titleId
    pre(paste(sample(letters,10), collapse = ", "))
  })   

  # logout
  observeEvent(input$logout, {
    session$reload();
  })  

  # observe checkGroup and change button color if changed
  observeEvent(
    {input$checkGroup
    input$date}, {
    removeClass(id = "update", class = "btn-primary")
    addClass(id = "update", class = "btn-warning")
  })   
  
      
  output$slider0 <- renderUI({
    
    sliderInput("slider0", "base size:",
                min = 1, max = 40, value = 20
    )
    
  })   
  
  
  output$slider1 <- renderUI({
    
    sliderInput("slider1", "linesize:",
                min = 1, max = 5, value = 3
    )
    
  })  
  
  output$slider2 <- renderUI({
    
    sliderInput("slider2", "textsize:",
                min = 1, max = 10, value = 8
    )
    
  })   

  # This checks the login
  # validate_password_module checks the login and loads the data and partitions
  # inserts the partitions in the ui
  output$Partitions <- renderUI({
    
    # only proceeds if True
    req(validate_password_module())
    tipify(checkboxGroupInput("checkGroup", 
                       h3("Slurm partitions"), 
                       choices = partitions,
                       selected = partitions),partitionstooltips)
  })
  
  #bsTooltip("Partitions", "Tooltip works", placement = "bottom", trigger = "hover", options = NULL)
  output$Clusters <- renderUI({
    
    # only proceeds if True
    req(validate_password_module())
    checkboxGroupInput("checkGroupClus", 
                       h3("Slurm clusters"), 
                       choices = clusters,
                       selected = clusters)
  })  

  # reacitive
  # datalist=reactive(get_datalist(res=res,partitions = input$checkGroup , clusters_selected = input$checkGroupClus))
    
  
  # The username and pass are set as global variables in the module_login when the user logs in
  # Upon successful login, the data is loaded there from the API using the provided credentials
  datalist <- eventReactive(
    {input$update
    # input$checkGroup
    input$checkGroupClus
    }, {

    # Update the line and textsizes
    base_size <<- input$slider0
    linesize <<- input$slider1
    txtsize <<- input$slider2

    # If slider not changed, no value is provided use default then
    if (length(base_size) == 0){base_size <<- 20}
    if (length(linesize) == 0){linesize <<- 3}
    if (length(txtsize) == 0){txtsize <<- 8}

    #print(paste0("base_size ",base_size))
    #print(paste0("linesize ",linesize))
    #print(paste0("txtsize ",txtsize))    
    
    if ( lastfrom != as.character(input$date[1]) || lastto != as.character(input$date[2]) ){
    # print("Call API")
    # Get the data from the API
    # print(username)
  
    # gen url
    apiurl=paste0("http://",dbhostname,"/api/")
    
    res <<- GET(apiurl,authenticate(username, pass), query = list(from=input$date[1], to=input$date[2]))
    lastfrom <<- as.character(input$date[1])
    lastto <<- as.character(input$date[2])
    }
    #print(res)
    
    # wait for initial click on the update button
    initiated()
    # change button color
    removeClass(id = "update", class = "btn-warning")
    addClass(id = "update", class = "btn-primary")
    # return datalist
    get_datalist(res=res,partitions = input$checkGroup, clusters_selected = input$checkGroupClus)     
  }, ignoreNULL = TRUE)
  
  output$cpuhrsBox <- renderInfoBox({
    datalist = datalist()
    shinyjs::show(id = "dashheader")
    infoBox(
      "CPU hours", paste(format(round(datalist$CPUh_totalsum / 1e6, 3), trim = TRUE), "M") , icon = icon("hourglass"),
      color = "purple"
    )
  })

  output$gpuhrsBox <- renderInfoBox({
    datalist = datalist()
    infoBox(
      "GPU hours", paste(format(round(datalist$GPUh_totalsum / 1e6, 3), trim = TRUE), "M") , icon = icon("hourglass"),
      color = "purple"
    )
  })
    
  output$njobsBox <- renderInfoBox({
    datalist = datalist()
    infoBox(
      "Compute jobs", paste(format(round(datalist$Jobs_totalsum / 1e6, 3), trim = TRUE), "M"), icon = icon("list"),
      color = "purple"
    )
  }) 
  # https://shiny.rstudio.com/reference/shiny/0.14/icon.html
  output$nuniqusers <- renderInfoBox({
    datalist = datalist()
    infoBox(
      "Users", datalist$uniqusers, icon = icon("users"),
      color = "purple"
    )
  })   

  # Tables  
  output$cpuhrstab = DT::renderDataTable({
    
    datalist = datalist()
    
    tabledisplay= as.data.frame(t(datalist$tabCPUhsumscast))
    # add rownames as column
    tabledisplay = cbind(data.frame(month_partition=rownames(tabledisplay)), tabledisplay)
    tabledisplay[is.na(tabledisplay)] <- 0
    
    datatable( data = tabledisplay,
               extensions = 'Buttons',
               rownames= FALSE,
               caption="Table 1: CPU hours used for the selected time period and partitions.",
               colnames = c("Month/partition"="month_partition"),
               options = list( searching = FALSE,
                               dom = "Blfrtip"
                               ,buttons = 
                                 list("copy", list(
                                   extend = "collection",
                                   buttons = c("csv", "excel", "pdf"),
                                   text = "Download"
                                 ) ) # end of buttons customization
                               
                               # customize the length menu
                               ,lengthMenu = list( c(10, 20, -1) # declare values
                                                   ,c(10, 20, "All") # declare titles
                               ) # end of lengthMenu customization
                               ,pageLength = 10
                               
                               
               ) # end of options
               
    ) %>% formatRound(names(as.data.frame(t(datalist$tabCPUhsumscast))), digits = 1)
    
    
    
  })

  output$gpuhrstab = DT::renderDataTable({
    
    datalist = datalist()
    
    tabledisplay= as.data.frame(t(datalist$tabGPUhsumscast))
    # add rownames as column
    tabledisplay = cbind(data.frame(month_partition=rownames(tabledisplay)), tabledisplay)
    tabledisplay[is.na(tabledisplay)] <- 0
    
    datatable( data = tabledisplay,
               extensions = 'Buttons',
               rownames= FALSE,
               caption="Table 2: GPU hours used for the selected time period and partitions.",
               colnames = c("Month/partition"="month_partition"),
               options = list( searching = FALSE,
                               dom = "Blfrtip"
                               ,buttons = 
                                 list("copy", list(
                                   extend = "collection",
                                   buttons = c("csv", "excel", "pdf"),
                                   text = "Download"
                                 ) ) # end of buttons customization
                               
                               # customize the length menu
                               ,lengthMenu = list( c(10, 20, -1) # declare values
                                                   ,c(10, 20, "All") # declare titles
                               ) # end of lengthMenu customization
                               ,pageLength = 10
                               
                               
               ) # end of options
               
    ) %>% formatRound(names(as.data.frame(t(datalist$tabGPUhsumscast))), digits = 1)
  })
    
  output$njobstab = DT::renderDataTable({
    
    datalist = datalist()
    tabledisplay= as.data.frame(t(datalist$tabjobscast))
    # add rownames as column
    tabledisplay = cbind(data.frame(month_partition=rownames(tabledisplay)), tabledisplay)
    tabledisplay[is.na(tabledisplay)] <- 0
    
    datatable( data = tabledisplay,
               extensions = 'Buttons',
               rownames= FALSE,
               caption="Table 3: Number of compute jobs for the selected time period and partitions.",
               colnames = c("Month/partition"="month_partition"),
               options = list( searching = FALSE,
                               dom = "Blfrtip"
                               ,buttons = 
                                 list("copy", list(
                                   extend = "collection",
                                   buttons = c("csv", "excel", "pdf"),
                                   text = "Download"
                                 ) ) # end of buttons customization
                               
                               # customize the length menu
                               ,lengthMenu = list( c(10, 20, -1) # declare values
                                                   ,c(10, 20, "All") # declare titles
                               ) # end of lengthMenu customization
                               ,pageLength = 10
                               
                               
               ) # end of options
               
    ) %>% formatRound(names(as.data.frame(t(datalist$tabCPUhsumscast))), digits = 1)
    
  })  

  output$utilization_partitions = DT::renderDataTable({
    
    datalist = datalist()
    
    tabledisplay= datalist$utilization_partition[,c("Partition","JobYM","CPUhourssumsum","theoretical_CPU_hourssum","GPUhourssumsum","theoretical_GPU_hourssum","utilization_CPU","utilization_GPU")]

        datatable( data = tabledisplay,
               extensions = 'Buttons',
               rownames= FALSE,
               caption="Table 1: Utilization of partitions (used CPU/GPU hours vs.theoretical).",
               colnames = c("CPU hours used"="CPUhourssumsum", "CPU hours theoretical"="theoretical_CPU_hourssum", "GPU hours used"="GPUhourssumsum", "GPU hours theoretical"="theoretical_GPU_hourssum",
                           "Utilization CPU (%)"="utilization_CPU", "Utilization GPU (%)"="utilization_GPU"),
               options = list( searching = FALSE,
                               dom = "Blfrtip"
                               ,buttons = 
                                 list("copy", list(
                                   extend = "collection",
                                   buttons = c("csv", "excel", "pdf"),
                                   text = "Download"
                                 ) ) # end of buttons customization
                               
                               # customize the length menu
                               ,lengthMenu = list( c(10, 20, -1) # declare values
                                                   ,c(10, 20, "All") # declare titles
                               ) # end of lengthMenu customization
                               ,pageLength = 10
                               
                               
               ) # end of options
               
    ) %>% formatRound(c("CPU hours used","CPU hours theoretical","GPU hours used","GPU hours theoretical","Utilization CPU (%)","Utilization GPU (%)"), digits = 1)
  })   

  output$utilization_nodes = DT::renderDataTable({
    
    datalist = datalist()
    
    tabledisplay= datalist$utilization_nodes_YM[,c("Partition","JobYM","Node","CPUS","GPUS","MEMORY","CPUhourssum","GPUhourssum","theoretical_CPU_hours","theoretical_GPU_hours","utilizationCPUS","utilizationGPUS")]

    
    datatable( data = tabledisplay,
               extensions = 'Buttons',
               rownames= FALSE,
               caption="Table 2: Utilization of nodes (used CPU/GPU hours vs.theoretical).",
               colnames = c("Memory(GB)"="MEMORY","CPU hours used"="CPUhourssum", "CPU hours theoretical"="theoretical_CPU_hours",
                            "GPU hours used"="GPUhourssum", "GPU hours theoretical"="theoretical_GPU_hours","Utilization CPUS (%)"="utilizationCPUS","Utilization GPUS (%)"="utilizationGPUS"),
               options = list( searching = FALSE,
                               dom = "Blfrtip"
                               ,buttons = 
                                 list("copy", list(
                                   extend = "collection",
                                   buttons = c("csv", "excel", "pdf"),
                                   text = "Download"
                                 ) ) # end of buttons customization
                               
                               # customize the length menu
                               ,lengthMenu = list( c(10, 20, -1) # declare values
                                                   ,c(10, 20, "All") # declare titles
                               ) # end of lengthMenu customization
                               ,pageLength = 10
                               
                               
               ) # end of options
               
    ) %>% formatRound(c("CPU hours used","GPU hours used","CPU hours theoretical","GPU hours theoretical",
                        "Utilization CPUS (%)","Utilization GPUS (%)"), digits = 1)
  })  
  
  
  # Jobs and CPU hours plots
    output$lineplot <- renderPlot({
      # lineplots
      datalist = datalist()
      # save datalist, used to create jossplot
      # saveRDS(datalist, file = "datalist.rds")
      
      p3 = lineplot1(datalist, linesize=linesize, base_size = base_size)
      p3
    })

    output$lineplot2 <- renderPlot({
      # lineplots
      datalist = datalist()
      p4 = lineplot2(datalist, linesize=linesize, base_size = base_size)
      p4
    })
    
    output$lineplot3 <- renderPlot({
      # lineplots
      datalist = datalist()
      p5 = lineplot3(datalist, linesize=linesize, base_size = base_size)
      p5
    })

  # Memory and Cores section  
  output$memcpujobs <- renderPlot({
    
    # contingency plot
    datalist = datalist()

    p=cont_plot1(datalist, txtsize=txtsize, base_size=base_size)
    p    
  })

  # Memory and Cores section  
  output$memgpujobs <- renderPlot({
    
    # contingency plot
    datalist = datalist()
    p=cont_plot2(datalist, txtsize=txtsize, base_size=base_size)
    p      

  })  
  
  # Pending times
  output$pendingtimes <- renderPlot({
    datalist = datalist()
    p = pendingtimes(datalist, linesize=linesize, base_size = base_size)
    p
    
  })  

  # runtimes
  output$runtimes <- renderPlot({
    datalist = datalist()
    p = runtimes(datalist, linesize=linesize, base_size = base_size)
    p

    
  })    
    

  output$MeanOfMeanPendingTimesPerUserPerDay <- renderPlot({
    # As barplots
    datalist = datalist()
    p=av_pending_user_day(datalist, base_size = base_size)
    p
  })

  output$pendingtimesperday <- renderPlot({
    # As barplots
    datalist = datalist()
    p=av_pending_per_day(datalist, base_size = base_size)
    p
  })  

  output$pendingtimesperdayNoneReason <- renderPlot({
    # As barplots
    datalist = datalist()
    p=av_pending_per_day_no_reason(datalist, base_size = base_size)
    p
    
  })
  
    
  output$utilizazion_per_day_CPU <- renderPlot({
    datalist = datalist()
    p=util_per_day_cpu(datalist, base_size = base_size)
    p
  })  

  output$utilizazion_per_day_GPU <- renderPlot({
    datalist = datalist()
    p=util_per_day_gpu(datalist, base_size = base_size)
    p
  })  
    
   
  output$percuserscpuhrs <- renderPlot({
    datalist = datalist()
    p = usage_roc(datalist=datalist, linesize=linesize, base_size = base_size)
    p

  }) 
  
  output$utilizationplots0 <- renderPlot({
    datalist = datalist()

    tmp=datalist$utilization_partition
    tmp$cluster_partition = with(tmp,paste(cluster_id,Partition))
    # ceil 100
    tmp$utilization_CPU=ifelse(tmp$utilization_CPU>100,100,tmp$utilization_CPU)
    p1=ggplot(tmp, aes(x=JobYM, y=utilization_CPU, colour=Partition, group=interaction(Partition,cluster_id), linetype=cluster_id)) + 
      geom_line(size=linesize) + scale_y_continuous(labels = comma) +
      geom_point() + theme_bw(base_size = base_size) + ggtitle("Utilization of CPUs") + ylab("Utilization (%)") + xlab("Year-month") +
      theme(axis.text.x = element_text(angle = 45, hjust=1))

    # Create plot
    p1
    
    
  })  
  
  output$utilizationplots1 <- renderPlot({
    datalist = datalist()

    tmp=datalist$utilization_partition
    tmp=tmp[complete.cases(tmp),]
    # ceil 100
    tmp$utilization_GPU=ifelse(tmp$utilization_GPU>100,100,tmp$utilization_GPU)
    pg1=ggplot(tmp, aes(x=JobYM, y=utilization_GPU, colour=Partition, group=interaction(Partition,cluster_id), linetype=cluster_id)) + 
      geom_line(size=linesize) + scale_y_continuous(labels = comma) +
      geom_point() + theme_bw(base_size = base_size) + ggtitle("Utilization of GPUs") + ylab("Utilization (%)") + xlab("Year-month") +
      theme(axis.text.x = element_text(angle = 45, hjust=1))
    
    # Create plot
    pg1
    
    
  }) 

  output$utilizationplots2 <- renderPlot({
    datalist = datalist()
    
    tmp=datalist$utilization_nodes_YM
    tmp$node_partition = with(tmp,paste(cluster_id,Node))     

    tmp=tmp[,c("JobYM","Node","utilizationCPUS")]
    for (ym in unique(tmp$JobYM)){
      for (no in unique(tmp$Node)){
        
        len=nrow( tmp[ym == tmp$JobYM & no==tmp$Node,])
        
        if (len == 0){
          tmp=rbind(tmp,data.frame(JobYM=ym,Node=no,utilizationCPUS=NA))
        }
      }
    }
    
    # ceil 100
    tmp$utilizationCPUS=ifelse(tmp$utilizationCPUS>100,100,tmp$utilizationCPUS)
        
    p2=ggplot(tmp, aes(x=JobYM,y=Node)) +
      geom_tile(aes(fill=utilizationCPUS),color = "black",lwd = 0.25,linetype = 1) +
      scale_fill_gradient(low = "white", high = "red", na.value="lightgray") +
      scale_x_discrete(expand=c(0,0)) + 
      scale_y_discrete(expand=c(0,0)) +       
      ggtitle("Utilization of nodes") + ylab("Year-month") + xlab("Day")+theme_bw(base_size = base_size)+labs(fill="Utilization CPU (%)")+
      theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position = 'bottom')
    
    p2        
    
  }) 

  output$utilizationplots3 <- renderPlot({
    datalist = datalist()
    
    tmp=datalist$utilization_nodes_YM
    tmp=tmp[order(tmp$CPUS),]
    tmp$CPUS = factor(tmp$CPUS)

    # Aggregate
    response="utilizationCPUS"
    predict="JobYM+CPUS+cluster_id"
    outdf=aggregate(reformulate(predict,response), data = tmp[,c("JobYM","CPUS","utilizationCPUS","cluster_id")], FUN = mean, na.rm = TRUE)
  
    colfunc<-colorRampPalette(c("lightblue","red","black"))
    myColors <- colfunc(length(levels(tmp$CPUS)))
    names(myColors) <- levels(tmp$CPUS)
    colScale <- scale_color_manual(name = "CPUs",values = myColors, drop = FALSE)  

    # ceil 100
    outdf$utilizationCPUS=ifelse(outdf$utilizationCPUS>100,100,outdf$utilizationCPUS)        
        
    p3=ggplot(outdf, aes(x=JobYM, y=utilizationCPUS, colour=CPUS, group=interaction(CPUS,cluster_id), linetype=cluster_id)) + 
      geom_line(size=linesize) + scale_y_continuous(labels = comma) +
      geom_point() + theme_bw(base_size = base_size) + ggtitle("Utilization of nodes by CPUs") + ylab("Utilization (%)") + xlab("Year-month") +
      theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position = 'bottom') +colScale

    # Create single plot
    p3
    
    
  }) 

  output$utilizationplots4 <- renderPlot({
    datalist = datalist()
    
    tmp=datalist$utilization_nodes_YM
    tmp=tmp[complete.cases(tmp),]
    tmp=tmp[order(tmp$GPUS),]
    tmp$GPUS = factor(tmp$GPUS)

    # Aggregate
    response="utilizationGPUS"
    predict="JobYM+GPUS+cluster_id"
    outdf=aggregate(reformulate(predict,response), data = tmp[,c("JobYM","GPUS","utilizationGPUS", "cluster_id")], FUN = mean, na.rm = TRUE)

    colfunc<-colorRampPalette(c("lightblue","red","black"))
    myColors <- colfunc(length(levels(tmp$GPUS)))
    names(myColors) <- levels(tmp$GPUS)
    colScale <- scale_color_manual(name = "GPUs",values = myColors, drop = FALSE)     

    # ceil 100
    outdf$utilizationGPUS=ifelse(outdf$utilizationGPUS>100,100,outdf$utilizationGPUS)           
        
    pg3=ggplot(outdf, aes(x=JobYM, y=utilizationGPUS, colour=GPUS, group=interaction(GPUS,cluster_id), linetype=cluster_id)) + 
      geom_line(size=linesize) + scale_y_continuous(labels = comma) +
      geom_point() + theme_bw(base_size = base_size) + ggtitle("Utilization of nodes by GPUs") + ylab("Utilization (%)") + xlab("Year-month")+
      theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position = 'bottom')+colScale
    
    # Create single plot
   pg3
    
    
  }) 
  
    
  output$utilizationplots5 <- renderPlot({
    datalist = datalist()
    
    tmp = datalist$utilization_nodes_YM
    tmp$MEMORY = as.character(tmp$MEMORY/1000)
    
    tmp$MemCat = cut(as.numeric(tmp$MEMORY), breaks=c(0,250,500,750,1000,Inf),include.lowest=TRUE,labels=c("<250GB","250-500GB","500-750GB","750-1TB",">1TB"))

    # Aggregate
    response="utilizationCPUS"
    predict="JobYM+MemCat+cluster_id"
    outdf=aggregate(reformulate(predict,response), data = tmp[,c("JobYM","MemCat","cluster_id","utilizationCPUS")], FUN = mean, na.rm = TRUE)

    colfunc<-colorRampPalette(c("lightblue","red","black"))
    myColors <- colfunc(length(levels(tmp$MemCat)))
    names(myColors) <- levels(tmp$MemCat)
    colScale <- scale_color_manual(name = "Memory category",values = myColors, drop = FALSE)
    
    # ceil 100
    outdf$utilizationCPUS=ifelse(outdf$utilizationCPUS>100,100,outdf$utilizationCPUS)       
        
    p4=ggplot(outdf, aes(x=JobYM, y=utilizationCPUS, colour=MemCat, group=interaction(MemCat,cluster_id), linetype=cluster_id)) + 
      geom_line(size=linesize) + scale_y_continuous(labels = comma) +
      geom_point() + theme_bw(base_size = base_size) + ggtitle("Utilization of nodes by memory") + ylab("Utilization (%)") + xlab("Year-month")+colScale+
      theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position = 'bottom')
    
    # Create single plot
    p4
    
    
  })
  
  output$txt <- renderText({
    icons <- paste(input$checkGroup, collapse = ", ")
    from=input$date[1]
    to=input$date[2]
    timefromto= paste(as.POSIXct(from), as.POSIXct(to),sep=" to ")
    paste("Selected partitions: ", icons, "; Timeframe:", timefromto)
    # Filter the data
    #datalist=filter_data(data, partitions = unlist(input$checkGroup))
  })

  
}

shinyApp(ui, server)
