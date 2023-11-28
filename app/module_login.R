# UI component
login_ui <- function(id, title) {
    
    ns <- NS(id) # namespaced id
    
    # define ui part
    div(
        id = ns("login"),
        
        
        div(
            class = "cover",
            div(
                style = "width: 500px; max-width: 100%; margin: 0 auto; margin-top: 250px;",
                class="well",
            h4(class = "text-center", title),
            #p(class = "text-center", tags$small("Login form")),
            
            textInput(
                inputId     = ns("ti_user_name_module"),
                label       = tagList(icon("user"), "User Name"),
                placeholder = "Enter user name"
            ),
            
            passwordInput(
                inputId     = ns("ti_password_module"), 
                label       = tagList(icon("unlock-alt"), "Password"), 
                placeholder = "Enter password"
            ), 
            
            div(
                class = "text-center",
                actionButton(
                    inputId = ns("ab_login_button_module"), 
                    label   = "Log in",
                    class   = "btn-primary"
                )
            )
        )
        )
    )
}

# SERVER component
validate_pwd <- function(input, output, session, user_col, pwd_col) {
    
  eventReactive(input$ab_login_button_module, {
    # check correctness
    validate <- FALSE

    # Get db hostname from env var or use localhost
    dbhostname <<- Sys.getenv("DB_HOSTNAME_PORT")
    if (dbhostname == ""){
      dbhostname <<- "localhost:8000"
    }        
    
    # Get the Partitions
    apiurlpart=paste0("http://",dbhostname,"/api/partitions/")
    # Get the Partitions
    respart = GET(apiurlpart,authenticate(input$ti_user_name_module, input$ti_password_module))
    
    # Get the Clusters
    apiurlclus=paste0("http://",dbhostname,"/api/clusters/")
    resclus = GET(apiurlclus,authenticate(input$ti_user_name_module, input$ti_password_module))  

    # Get the Partitions tooltips
    apiurltooltips=paste0("http://",dbhostname,"/api/partitionstooltips/")
    restooltips = GET(apiurltooltips,authenticate(input$ti_user_name_module, input$ti_password_module))     
    
    if ( (status_code(respart) == 200) && (status_code(resclus) == 200) && (status_code(restooltips) == 200) ) {
      
      
      # get partitions
      partitionsjson <- fromJSON(rawToChar(respart$content))
      vectorize_fromJSON <- Vectorize(fromJSON)
      
      partitions <<- tryCatch({
        as.data.frame(vectorize_fromJSON(partitionsjson))[,1]
      },
      error = function(err) {
        return("NA")
      })
 
      # get partitionstooltips
      partitionstooltipsjson <- fromJSON(rawToChar(restooltips$content))

      partitionstooltips <<- tryCatch({
        as.data.frame(vectorize_fromJSON(partitionstooltipsjson))[,1]
      },
      error = function(err) {
        return("NA")
      })      
           
      # get clusters
      clustersjson <- fromJSON(rawToChar(resclus$content))
      # clusters <<- as.data.frame(vectorize_fromJSON(clustersjson))[,1]    

      clusters <<- tryCatch({
        as.data.frame(vectorize_fromJSON(clustersjson))[,1]
      },
      error = function(err) {
        return("NA")
      })
      
      
      # set validate
      validate <- TRUE
      
      
      # set username and pass
      username <<- input$ti_user_name_module
      pass <<- input$ti_password_module  
      
      
    }
    
    # hide login form when user is confirmed
    if (validate) {
      shinyjs::hide(id = "login")
    }
    
    validate
  })
}

# Login function for dev
validate_pwd_dev <- function(input, output, session, user_col, pwd_col) {
    
  
        eventReactive(input$ab_login_button_module, {
        # check correctness
        validate <- FALSE

        # Get db hostname from env var or use localhost
        dbhostname <<- Sys.getenv("DB_HOSTNAME_PORT")
        if (dbhostname == ""){
          dbhostname <<- "localhost:8000"
        }        
        
        
        # Get the Partitions
        apiurl=paste0("http://",dbhostname,"/api/partitions/")
        respart = GET(apiurl,authenticate(user_col, pwd_col))

        # Get the Clusters
        apiurl=paste0("http://",dbhostname,"/api/clusters/")
        resclus = GET(apiurl,authenticate(user_col, pwd_col))
                
        if ( (status_code(respart) == 200) && (status_code(resclus) == 200) ) {
            
            
            # get partitions
            partitionsjson <- fromJSON(rawToChar(respart$content))
            vectorize_fromJSON <- Vectorize(fromJSON)
            partitions <<- as.data.frame(vectorize_fromJSON(partitionsjson))[,1]

            # get clusters
            clustersjson <- fromJSON(rawToChar(resclus$content))
            clusters <<- as.data.frame(vectorize_fromJSON(clustersjson))[,1]    
            #print(clusters)
            # set validate
            validate <- TRUE
            
            # set username and pass
            username <<- user_col
            pass <<- pwd_col        
            
        }
        
        # hide login form when user is confirmed
        if (validate) {
            shinyjs::hide(id = "login")
        }
        
        validate
        })
}

