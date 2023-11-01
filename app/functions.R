# Functions

getcpuhours = function(datalist=datalist){
  paste(format(round(datalist$CPUh_totalsum / 1e6, 3), trim = TRUE), "M")
}

getgpuhours = function(datalist=datalist){
  paste(format(round(datalist$GPUh_totalsum / 1e6, 3), trim = TRUE), "M")
}

getnjobs = function(datalist=datalist){
  paste(format(round(datalist$Jobs_totalsum / 1e6, 3), trim = TRUE), "M")
}



## Adapted From www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)
## Gives count, mean,sum, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE2 <- function(data=NULL, measurevar=NULL, groupvars=NULL, na.rm=FALSE,
                       conf.interval=.95, .drop=TRUE) {
  library(plyr)
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sum = sum   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  
  # Rename the "mean" column 

  datac <- plyr::rename(datac, c("mean" = paste0(measurevar,"mean")))
  datac <- plyr::rename(datac, c("sum" = paste0(measurevar,"sum")))
  
  # set sd=0, if N = 1 NA is added but not stored in the db
  datac$sd=ifelse(is.na(datac$sd), 0, datac$sd)

  # datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  # ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  # datac$ci <- datac$se * ciMult
  
  return(datac)
}


listob_to_df=function(listobj){
  dft=t(data.frame(t(sapply(listobj,c))))
  rownames(dft)=rownames(listobj) 
  return(dft)
}

cast_df=function(tab=tab, valuevar ="Njobs"){
  tabjobscast_tmp=reshape2::acast(tab, Partition ~ JobYM, value.var=valuevar, fun.aggregate = sum)
  tabjobscast= data.frame(tabjobscast_tmp, check.names = F)
  tabjobscast$Total=rowSums(tabjobscast,na.rm = T)
  return(tabjobscast)
}

# Re-calculate mean and sd based on means and SDs
# the predict part will be kept
# the response part will be aggregated by sum using the aggregate function, must contains N,varn,nx
# Column name for the means is meanvarname, sd and N column required
# Column name for the new means is meansvaroutputname
# https://talkstats.com/threads/standard-deviation-of-multiple-sample-sets.7130/
aggregate_means = function(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobD+JobYM+Partition+MemCat+CPUCat+GPUCat+cluster_id", meanvarname="Qtimemean", meansvaroutputname="Qtimemean", dataf=dataf){
  
  dataf$varn = dataf$sd ^ 2 * dataf$N
  dataf$nx = dataf[[meanvarname]] * dataf$N
  
  # the predict 
  outdf=aggregate(reformulate(predict,response), data = dataf, FUN = sum, na.rm = TRUE)
  
  outdf[[meansvaroutputname]] = outdf$nx / outdf$N
  outdf$sd =  sqrt(outdf$varn / outdf$N)
  return(outdf)
  
}

# function to aggregate data
get_datalist=function(res=NULL,partitions_selected = c("cpu_p","gpu_p"), clusters_selected = c("slurm1","slurm2"),api="FALSE"){
  # print(res)
  # get data
  if (api=="TRUE"){
  DATALISTS_json <<- fromJSON(res)
  }else{
  if (status_code(res) == 200) { 
    # get data
    DATALISTS_json <<- fromJSON(rawToChar(res$content))
  }else{
    return()
  }
  }

    utilization_partition=NULL
    utilization_nodes=NULL
    
    datalist=list("utilization_partition"=NULL,"utilization_nodes"=NULL,
                  "tabCPUhsumscast" = NULL, "tabGPUhsumscast" = NULL, "tabjobscast"=NULL, "tabjobs"=NULL, 
                  "tabCPUhsums"=NULL, "tabGPUhsums"=NULL, "Jobs_totalsum"=NULL, "CPUh_totalsum"=NULL, "GPUh_totalsum"=NULL,"tabQtimesNoneReason"=NULL)
    
    # data is a list of lists per day
    for (daylist in DATALISTS_json){
      
      for (listtmp in daylist){
        
        res_rmp=fromJSON(listtmp)
        
        # There can be some cols missing if all NAs, recalc utilization_GPU,utilization_CPU 
        datalist$utilization_partition = rbind(datalist$utilization_partition,res_rmp$utilization_partition[,c("Partition","JobYM", "cluster_id", "CPUhourssumsum", "theoretical_CPU_hourssum","GPUhourssumsum", "theoretical_GPU_hourssum")])
        # recalc utilizationCPUS, utilizationGPUS
        datalist$utilization_nodes = rbind(datalist$utilization_nodes,res_rmp$utilization_nodes[,c("HOSTNAME","cluster_id","Partition", "JobYM","JobYMD","Node","N","CPUhourssum", "ndays","GPUhourssum", "CPUS", "MEMORY", "GPUS", "theoretical_CPU_hours", "theoretical_GPU_hours")])
        
        datalist$tabjobs = rbind(datalist$tabjobs,res_rmp$tabjobs)
        datalist$tabCPUhsums = rbind(datalist$tabCPUhsums,res_rmp$tabCPUhsums)
        datalist$tabGPUhsums = rbind(datalist$tabGPUhsums,res_rmp$tabGPUhsums)
        datalist$tabGCPUcat = rbind(datalist$tabGCPUcat,res_rmp$tabGCPUcat)
        
        datalist$tabCPUhsumsCat = rbind(datalist$tabCPUhsumsCat,res_rmp$tabCPUhsumsCat)
        datalist$tabGPUhsumsCat = rbind(datalist$tabGPUhsumsCat,res_rmp$tabGPUhsumsCat)
        datalist$tabQtimes = rbind(datalist$tabQtimes,res_rmp$tabQtimes)
        datalist$tabQtimesNoneReason = rbind(datalist$tabQtimesNoneReason,res_rmp$tabQtimesNoneReason)
        datalist$tabRuntimes = rbind(datalist$tabRuntimes,res_rmp$tabRuntimes)
        datalist$tabCPUUsers = rbind(datalist$tabCPUUsers,res_rmp$tabCPUUsers)
      }
      
    }
    
    # capture.output(datalist, file = "My_New_File.txt")
    
    # Aggregate util partitions per YM, since data is per day
    tmp=aggregate(cbind(CPUhourssumsum,theoretical_CPU_hourssum,GPUhourssumsum,theoretical_GPU_hourssum) ~ Partition+JobYM+cluster_id , data = datalist$utilization_partition, FUN = sum, na.rm = TRUE)
    tmp$utilization_CPU = tmp$CPUhourssumsum * 100 / tmp$theoretical_CPU_hourssum
    tmp$utilization_GPU = tmp$GPUhourssumsum * 100 / tmp$theoretical_GPU_hourssum
    datalist$utilization_partition = tmp
    
    # Calc partition util per day
    tmpp = datalist$utilization_nodes
    tmpp = aggregate(cbind(CPUhourssum,theoretical_CPU_hours,GPUhourssum,theoretical_GPU_hours) ~ Partition+JobYMD+cluster_id , data = tmpp, FUN = sum, na.rm = TRUE)
    tmpp$utilization_CPU = tmpp$CPUhourssum * 100 / tmpp$theoretical_CPU_hours
    tmpp$utilization_GPU = tmpp$GPUhourssum * 100 / tmpp$theoretical_GPU_hours
    # since the CPU hours are recorded on the day where the job completed, it can happen that util is > 100% for a day.
    # cap to 100% per day
    tmpp$utilization_CPU=ifelse(tmpp$utilization_CPU > 100, 100, tmpp$utilization_CPU)
    tmpp$utilization_GPU=ifelse(tmpp$utilization_GPU > 100, 100, tmpp$utilization_GPU)
    datalist$utilization_partition_day = tmpp
    
    # Calc node util per YM
    tmp=datalist$utilization_nodes
    tmp=aggregate(cbind(theoretical_CPU_hours,theoretical_GPU_hours,CPUhourssum,GPUhourssum, N) ~ HOSTNAME +cluster_id +Partition +JobYM+Node + CPUS + MEMORY + GPUS, data = datalist$utilization_nodes, FUN = sum, na.rm = TRUE)
    tmp$utilizationCPUS = tmp$CPUhourssum * 100 / tmp$theoretical_CPU_hours
    tmp$utilizationGPUS = tmp$GPUhourssum * 100 / tmp$theoretical_GPU_hours
    datalist$utilization_nodes_YM = tmp
    
    # aggregate n job per YM
    tmp=aggregate(Njobs ~ JobYM+Partition+cluster_id, data = datalist$tabjobs, FUN = sum, na.rm = TRUE)
    datalist$tabjobs=tmp
    
    # aggregate njobs per YM
    tmp=aggregate(Njobs ~ JobYM+GPUCat+CPUCat+MemCat+Partition+cluster_id, data = datalist$tabGCPUcat, FUN = sum, na.rm = TRUE)
    datalist$tabGCPUcat = tmp
    
    # Mean of means and sds
    # https://talkstats.com/threads/standard-deviation-of-multiple-sample-sets.7130/
    datalist$tabCPUhsums = aggregate_means(response="cbind(CPUhourssum,N,varn,nx)",predict="Partition+JobYM+cluster_id+JobYM", meanvarname="CPUhoursmean", meansvaroutputname="CPUhoursmean", dataf=datalist$tabCPUhsums)
    datalist$tabGPUhsums = aggregate_means(response="cbind(GPUhourssum,N,varn,nx)",predict="Partition +JobYM+cluster_id+JobYM", meanvarname="GPUhoursmean", meansvaroutputname="GPUhoursmean", dataf=datalist$tabGPUhsums)
    datalist$tabCPUhsumsCat = aggregate_means(response="cbind(CPUhourssum,N,varn,nx)",predict="MemCat+CPUCat+JobYM+Partition+cluster_id", meanvarname="CPUhoursmean", meansvaroutputname="CPUhoursmean", dataf=datalist$tabCPUhsumsCat)
    datalist$tabGPUhsumsCat = aggregate_means(response="cbind(GPUhourssum,N,varn,nx)",predict="MemCat+GPUCat+JobYM+Partition+cluster_id", meanvarname="GPUhoursmean", meansvaroutputname="GPUhoursmean", dataf=datalist$tabGPUhsumsCat)
    datalist$tabQtimesUsers = aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobD+JobYM+Partition+MemCat+CPUCat+GPUCat+cluster_id+User", meanvarname="Qtimemean", meansvaroutputname="Qtimemean", dataf=datalist$tabQtimes)  
    datalist$tabQtimes = aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobD+JobYM+Partition+MemCat+CPUCat+GPUCat+cluster_id", meanvarname="Qtimemean", meansvaroutputname="Qtimemean", dataf=datalist$tabQtimes)
    datalist$tabQtimesNoneReason = aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobD+JobYM+Partition+MemCat+CPUCat+GPUCat+cluster_id", meanvarname="Qtimemean", meansvaroutputname="Qtimemean", dataf=datalist$tabQtimesNoneReason)
    datalist$tabRuntimes = aggregate_means(response="cbind(Runtimesum,N,varn,nx)",predict="JobYMD+JobD+JobYM+Partition+MemCat+CPUCat+GPUCat+cluster_id", meanvarname="Runtimemean", meansvaroutputname="Runtimemean", dataf=datalist$tabRuntimes)
    datalist$tabCPUUsers = aggregate_means(response="cbind(CPUhourssum,N,varn,nx)",predict="User+Partition+cluster_id", meanvarname="CPUhoursmean", meansvaroutputname="CPUhoursmean", dataf=datalist$tabCPUUsers)
    
    # Filter by partitions
    for (listn in names(datalist)){
      # print(listn)
      tmpdf = NULL
      tmpdf=datalist[[listn]]
      tmpdf = tmpdf[tmpdf[["Partition"]] %in% partitions_selected, ]
      datalist[[listn]] = tmpdf
    }
    
    # Filter by clusters
    for (listn in names(datalist)){
      #print(listn)
      tmpdf = NULL
      tmpdf=datalist[[listn]]
      #print(tmpdf)
      tmpdf = tmpdf[tmpdf[["cluster_id"]] %in% clusters_selected, ]
      datalist[[listn]] = tmpdf
    }  
    
    # Sums
    datalist$CPUh_totalsum = sum(datalist$tabCPUhsums$CPUhourssum, na.rm = T)
    datalist$GPUh_totalsum = sum(datalist$tabGPUhsums$GPUhourssum, na.rm = T)
    datalist$Jobs_totalsum = sum(datalist$tabjobs$Njobs, na.rm = T)
    datalist$uniqusers = length(unique(datalist$tabCPUUsers$User))
    # Cast dfs
    datalist$tabjobscast=cast_df(datalist$tabjobs, valuevar ="Njobs")
    datalist$tabCPUhsumscast=cast_df(datalist$tabCPUhsums, valuevar ="CPUhourssum")
    datalist$tabGPUhsumscast=cast_df(datalist$tabGPUhsums, valuevar ="GPUhourssum")
  #}
  
  # print(datalist)
  # capture.output(datalist, file = "/My_New_File.txt")
  return(datalist)
}

# Generate utilization stats
genutilizationstats_oneday <- function(data=data, measurevar="CPUhours") {
  
  # Sum CPU/GPU hours by month
  tabNodehsums <- suppressWarnings(summarySE2(data, measurevar=measurevar, groupvars=c("Partition","JobYM","JobYMD", "Node", "cluster_id")))

  # Set ndays
  tabNodehsums$ndays = 1
  
  return(tabNodehsums)
  
}

# Process jobs data
# Generate stats for all partitions and cluster_id per day
# This version only accepts a single day, data is stored in the db
filter_data_api_v3 = function(datajobs=datajobs,data_nodes=data_nodes, fromdate = "2022-10-02", returndata="FALSE" ){
  
  cat(file=stderr(), paste0("filter_data_api_v3 start: ", format(Sys.time())))
  cat(file=stderr(), paste0("filter_data_api_v3: nrows in data -> ", nrow(datajobs)[1]))
  cat(file=stderr(), paste0("filter_data_api_v3: filtering from ",format(fromdate)," to ", format(fromdate)))
  # cat(file=stderr(), paste0("filter_data_api_v3: ",colnames(datajobs)))
  
  # Filter by date range using data$Start
  data = datajobs[ (datajobs$Start >= as.POSIXct(fromdate)) & (datajobs$Start <= as.POSIXct(fromdate)), ]
  cat(file=stderr(), paste0("filter_data_api_v3: nrows in data after filter -> ", nrow(data)[1]))
  #print(data)
  # Summary table for number of jobs
  tabjobs=as.data.frame(table(data$JobYM, data$Partition, data$cluster_id),stringsAsFactors = F)
  colnames(tabjobs) = c("JobYM","Partition","cluster_id","Njobs")
  
  # Summary for CPU hours (includes also the GPU partitions)
  tabCPUhsums <- summarySE2(data, measurevar="CPUhours", groupvars=c("Partition","JobYM","cluster_id"))
  
  # Summary but for GPU hours
  tabGPUhsums <- summarySE2(data, measurevar="GPUhours", groupvars=c("Partition","JobYM","cluster_id"))
  
  # Contingency tables CPUs/GPUs and Memory Category
  tabGCPUcat=as.data.frame(table(data$JobYM, data$GPUCat, data$CPUCat, data$MemCat, data$Partition, data$cluster_id),stringsAsFactors = F)
  colnames(tabGCPUcat) = c("JobYM","GPUCat","CPUCat","MemCat","Partition","cluster_id","Njobs")
  
  # Summary of CPU/GPUhours by "MemCat","CPUCat","JobYM","Partition","cluster_id"
  tabCPUhsumsCat = summarySE2(data, measurevar="CPUhours", groupvars=c("MemCat","CPUCat","JobYM","Partition","cluster_id"))
  tabGPUhsumsCat = summarySE2(data, measurevar="GPUhours", groupvars=c("MemCat","GPUCat","JobYM","Partition","cluster_id")) 
  
  # Qtimes tab
  tabQtimes=summarySE2(data, measurevar="Qtime", groupvars=c("JobYMD","JobD","JobYM","Partition","MemCat","CPUCat","GPUCat","cluster_id","User"))

  # Qtimes only for the jobs that had pending reason none
  tabQtimesNoneReason=summarySE2(data[data$Reason=="None",], measurevar="Qtime", groupvars=c("JobYMD","JobD","JobYM","Partition","MemCat","CPUCat","GPUCat","cluster_id","User"))

  # Runtimes tab
  tabRuntimes= summarySE2(data, measurevar="Runtime", groupvars=c("JobYMD","JobD","JobYM","Partition","MemCat","CPUCat","GPUCat","cluster_id"))  
  
  # Users
  tabCPUUsers = summarySE2(data, measurevar="CPUhours", groupvars=c("User","Partition","cluster_id"))
  
  ### Utilization ###
  
  # Sum CPU/GPU hours by day
  tabNodehsumsCPU = genutilizationstats_oneday(data=data, measurevar="CPUhours")
  tabNodehsumsGPU = genutilizationstats_oneday(data=data, measurevar="GPUhours")
  
  # Merge by Node
  tabNodehsums=merge(tabNodehsumsCPU[,c('Partition','JobYM','JobYMD','Node','N','CPUhourssum','ndays',"cluster_id")],tabNodehsumsGPU[,c('Partition','JobYM','JobYMD','Node','N','GPUhourssum',"cluster_id")], by=c('Partition','JobYM','JobYMD','Node','N',"cluster_id"))
  #print(tabNodehsums)
  #print(data_nodes)
  # Add node info
  tabNodehsums$HOSTNAME = tabNodehsums$Node
  utilization_nodes=merge(tabNodehsums, data_nodes,by=c("HOSTNAME","cluster_id"))
  
  # Calculate theoretical CPU and GPU hours
  utilization_nodes$theoretical_CPU_hours = utilization_nodes$CPUS * utilization_nodes$ndays * 24
  utilization_nodes$theoretical_GPU_hours = utilization_nodes$GPUS * utilization_nodes$ndays * 24

  # remove duplicates
  utilization_nodes=utilization_nodes[!duplicated(utilization_nodes), ]

  # Aggregate CPU and GPU hours per partition and month
  #print(utilization_nodes)
  CPUhours_partition <- summarySE2(utilization_nodes, measurevar="CPUhourssum", groupvars=c("Partition","JobYM","cluster_id"))
  GPUhours_partition <- summarySE2(utilization_nodes, measurevar="GPUhourssum", groupvars=c("Partition","JobYM","cluster_id"))
  
  # Aggregate theoretical CPU and GPU hours per partition and month
  theoretical_CPUhours_partition <- summarySE2(utilization_nodes, measurevar="theoretical_CPU_hours", groupvars=c("Partition","JobYM","cluster_id"))
  theoretical_GPUhours_partition <- summarySE2(utilization_nodes, measurevar="theoretical_GPU_hours", groupvars=c("Partition","JobYM","cluster_id"))
  
  # Merge
  utilization_partition_CPU = merge(CPUhours_partition[,c("Partition","JobYM","CPUhourssumsum","cluster_id")],
                                    theoretical_CPUhours_partition[,c("Partition","JobYM","cluster_id","theoretical_CPU_hourssum")],by=c("Partition","JobYM","cluster_id"))
  
  utilization_partition_GPU = merge(GPUhours_partition[,c("Partition","JobYM","GPUhourssumsum","cluster_id")],
                                    theoretical_GPUhours_partition[,c("Partition","JobYM","cluster_id","theoretical_GPU_hourssum")],by=c("Partition","JobYM","cluster_id"))
  
  
  utilization_partition = merge(utilization_partition_CPU,utilization_partition_GPU, by=c("Partition","JobYM","cluster_id"))
  utilization_partition$utilization_CPU = (utilization_partition$CPUhourssumsum * 100) / utilization_partition$theoretical_CPU_hourssum
  utilization_partition$utilization_GPU = (utilization_partition$GPUhourssumsum * 100) / utilization_partition$theoretical_GPU_hourssum
  
  if (returndata=="TRUE"){
    return(toJSON(list("utilization_partition"=utilization_partition,"utilization_nodes"=utilization_nodes,"tabjobs"=tabjobs, 
                       "tabCPUhsums"=tabCPUhsums, "tabGPUhsums"=tabGPUhsums, "tabGCPUcat"=tabGCPUcat, "tabCPUhsumsCat"=tabCPUhsumsCat,"tabGPUhsumsCat"=tabGPUhsumsCat,
                       "tabQtimes"=tabQtimes,"tabQtimesNoneReason"=tabQtimesNoneReason,"tabRuntimes"=tabRuntimes, "tabCPUUsers"=tabCPUUsers,"datajobs"=datajobs,"data_nodes"=data_nodes)))
  }else{
    return(toJSON(list("utilization_partition"=utilization_partition,"utilization_nodes"=utilization_nodes,"tabjobs"=tabjobs, 
                       "tabCPUhsums"=tabCPUhsums, "tabGPUhsums"=tabGPUhsums, "tabGCPUcat"=tabGCPUcat, "tabCPUhsumsCat"=tabCPUhsumsCat,"tabGPUhsumsCat"=tabGPUhsumsCat,
                       "tabQtimes"=tabQtimes,"tabQtimesNoneReason"=tabQtimesNoneReason,"tabRuntimes"=tabRuntimes, "tabCPUUsers"=tabCPUUsers)))
  }
}