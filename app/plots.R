library(ggplot2)
library(patchwork)
library(reshape2)

lineplot1 = function(datalist=datalist, linesize=2, base_size=7){
      # Sum Njobs, might be that the same partitions were used on diff clusters
      tab1=aggregate(Njobs~JobYM+Partition, data=datalist$tabjobs,sum)
      p3=ggplot(tab1, aes(x=JobYM, y=Njobs, colour=Partition, group=Partition)) + 
        geom_line(size=linesize) + scale_y_log10() + 
        geom_point() + theme_bw(base_size = base_size) + ggtitle("Jobs per month") + ylab("Number of jobs") + xlab("Year-month") +
        theme(axis.text.x = element_text(angle = 45, hjust=1))
      return(p3)
}

lineplot2 = function(datalist=datalist, linesize=2, base_size=7){
  # Sum Njobs, might be that the same partitions were used on diff clusters
  tab2=aggregate(CPUhourssum~JobYM+Partition, data=datalist$tabCPUhsums,sum)
  p4=ggplot(tab2, aes(x=JobYM, y=CPUhourssum, colour=Partition, group=Partition)) + 
    geom_line(size=linesize) + scale_y_log10() + 
    geom_point() + theme_bw(base_size = base_size) + ggtitle("CPU hours per month") + ylab("CPU hours") + xlab("Year-month") +
    theme(axis.text.x = element_text(angle = 45, hjust=1))
  return(p4)
}

lineplot3 = function(datalist=datalist, linesize=2, base_size=7){
  # Sum Njobs, might be that the same partitions were used on diff clusters
  tab3=aggregate(GPUhourssum~JobYM+Partition, data=datalist$tabGPUhsums,sum)
  p4=ggplot(tab3, aes(x=JobYM, y=GPUhourssum, colour=Partition, group=Partition)) + 
    geom_line(size=linesize) + scale_y_log10() + 
    geom_point() + theme_bw(base_size = base_size) + ggtitle("GPU hours per month") + ylab("GPU hours") + xlab("Year-month") +
    theme(axis.text.x = element_text(angle = 45, hjust=1))
  p4
  return(p4)
}

combine_lineplots = function(lineplot1=p1,lineplot2=p2,lineplot3=p3 ){
p <- lineplot1 / lineplot2 / lineplot3
return (p)
}

combine_conplots = function(p1=p1,p2=p2 ){
p <- p1 / p2
return (p)
}

cont_plot1 = function(datalist=datalist, txtsize=6, base_size=7){

    # Cast df CPUs
    tabjobscast_tmp=reshape2::acast(datalist$tabGCPUcat, CPUCat ~ MemCat, value.var = "Njobs", fun.aggregate = sum, na.rm = TRUE)
    # melt
    tab0 <- melt(tabjobscast_tmp)
    # Cast df GPUs
    tabjobscast_tmpg=reshape2::acast(datalist$tabGCPUcat, GPUCat ~ MemCat, value.var = "Njobs", fun.aggregate = sum, na.rm = TRUE)
    # melt
    tab1 <- melt(tabjobscast_tmpg)    
    colnames(tab0) = c("CPUCategory","MemCategory","Njobs")
    mylevelsCPU <- c("1CPU", "2-10CPUs" , ">10CPUs")
    mylevelsMem <- c("<=10GB", "10-50GB" , ">50GB")

    colnames(tab1) = c("GPUCategory","MemCategory","Njobs")
    mylevelsGPU <- c("none","1GPU", "2-10GPUs" , ">10GPUs")

    tab0$CPUCategory = factor(tab0$CPUCategory,levels=mylevelsCPU)
    tab0$MemCategory = factor(tab0$MemCategory,levels=mylevelsMem)

    tab1$GPUCategory = factor(tab1$GPUCategory,levels=mylevelsGPU)
    tab1$MemCategory = factor(tab1$MemCategory,levels=mylevelsMem)    
    
    p1=ggplot(tab0, aes(CPUCategory, MemCategory)) +
    geom_tile(aes(fill = Njobs)) + 
    geom_text(aes(label = round(Njobs, 1)),size=txtsize) + theme_bw(base_size = base_size) +
    scale_fill_gradient(low = "white", high = "red") + ggtitle("Jobs run in selected partitions") + ylab("Requested Memory") + xlab("Requested CPUs (cores)") +
    scale_x_discrete(expand=c(0,0)) + 
    scale_y_discrete(expand=c(0,0)) + labs(fill = "# jobs")

    datafiltCPUhsums = summarySE2(datalist$tabCPUhsumsCat, measurevar="CPUhourssum", groupvars=c("MemCat","CPUCat"))
    # remove NAs
    datafiltCPUhsums$CPUCat = factor(datafiltCPUhsums$CPUCat,levels=mylevelsCPU)
    datafiltCPUhsums$MemCat = factor(datafiltCPUhsums$MemCat,levels=mylevelsMem)
    
    p2=ggplot(datafiltCPUhsums, aes(CPUCat, MemCat)) +
      geom_tile(aes(fill = CPUhourssumsum)) +
      geom_text(aes(label = round(CPUhourssumsum, 1)),size=txtsize) + theme_bw(base_size = base_size) +
      scale_fill_gradient(low = "white", high = "red") + ggtitle("CPU hours spent in selected partitions") + ylab("Requested Memory") + xlab("Requested CPUs (cores)") +
      scale_x_discrete(expand=c(0,0)) + 
      scale_y_discrete(expand=c(0,0)) + labs(fill = "CPU hours")

    # p1 + p2 + p3 + p4 +plot_annotation(tag_levels = 'A') + plot_layout(ncol = 2, nrow=2, widths = c(rep(5,4)) , heights = c(8))
    pall=p1 + p2 +plot_annotation(tag_levels = list(c("A", "B")) ) + plot_layout(ncol = 2, nrow=1, widths = c(rep(6,2)) , heights = c(8))
    return(pall)

}

cont_plot2 = function(datalist=datalist, txtsize=6, base_size=7){
  
  # Cast df GPUs
  tabjobscast_tmpg=reshape2::acast(datalist$tabGCPUcat, GPUCat ~ MemCat, value.var = "Njobs", fun.aggregate = sum, na.rm = TRUE)
  # melt
  tab1 <- melt(tabjobscast_tmpg)    
  colnames(tab1) = c("GPUCategory","MemCategory","Njobs")
  # remove rows with none, they are from CPUs
  tab1=tab1[tab1$GPUCategory != "none",]
  mylevelsGPU <- c("1GPU", "2-10GPUs" , ">10GPUs")
  mylevelsMem <- c("<=10GB", "10-50GB" , ">50GB")
  #print(tab1)
  tab1$Njobs=ifelse(tab1$GPUCategory=="none",0,tab1$Njobs)
  tab1$GPUCategory = factor(tab1$GPUCategory,levels=mylevelsGPU)
  tab1$MemCategory = factor(tab1$MemCategory,levels=mylevelsMem)

  p3=ggplot(tab1, aes(GPUCategory, MemCategory)) +
    geom_tile(aes(fill = Njobs)) +
    geom_text(aes(label = round(Njobs, 1)),size=txtsize) + theme_bw(base_size = base_size) +
    scale_fill_gradient(low = "white", high = "red") + ggtitle("Jobs run in GPU partitions") + ylab("Requested Memory") + xlab("Requested GPUs") +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(fill = "# jobs")   
  
  datafiltGPUhsums = summarySE2(datalist$tabGPUhsumsCat, measurevar="GPUhourssum", groupvars=c("MemCat","GPUCat"))
  # remove rows with none
  datafiltGPUhsums=datafiltGPUhsums[datafiltGPUhsums$GPUCat != "none",]
  datafiltGPUhsums$GPUCat = factor(datafiltGPUhsums$GPUCat,levels=mylevelsGPU)
  datafiltGPUhsums$MemCat = factor(datafiltGPUhsums$MemCat,levels=mylevelsMem)
  
  p4=ggplot(datafiltGPUhsums, aes(GPUCat, MemCat)) +
    geom_tile(aes(fill = GPUhourssumsum)) +
    geom_text(aes(label = round(GPUhourssumsum, 1)),size=txtsize) + theme_bw(base_size = base_size) +
    scale_fill_gradient(low = "white", high = "red") + ggtitle("GPU hours spent in selected partitions") + ylab("Requested Memory") + xlab("Requested GPUs") +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(fill = "GPU hours")     
  
  pall = p3 + p4 +plot_annotation(tag_levels = list(c("C", "D")) ) + plot_layout(ncol = 2, nrow=1, widths = c(rep(6,2)) , heights = c(8))
  return(pall)
  
}

pendingtimes = function(datalist=datalist, linesize=2, base_size=7){
  
  ls=linesize
  lls=linesize - 0.5
  
  # datafilt=datalist$tabQtimes
  pd <- position_dodge(0.5) # move them .05 to the left and right
  
  datafiltsum0=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYM+Partition", meanvarname="Qtimemean", meansvaroutputname="Qtime", data=datalist$tabQtimes )
  # print(datalist$tabQtimes)
  p1=ggplot(datafiltsum0, aes(x=JobYM, y=Qtime, colour=Partition, group=Partition)) + 
    geom_errorbar(aes(ymin=Qtime, ymax=Qtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Jobs pending time by Partition") + ylab("Time (Min.)") + xlab("Year-month")+ ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
  datafiltsum1=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYM+MemCat", meanvarname="Qtimemean",meansvaroutputname="Qtime", data=datalist$tabQtimes )
  datafiltsum1 = datafiltsum1[complete.cases(datafiltsum1),]
  
  p2=ggplot(datafiltsum1, aes(x=JobYM, y=Qtime, colour=MemCat, group=MemCat)) + 
    geom_errorbar(aes(ymin=Qtime, ymax=Qtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Jobs pending time by Memory Category") + ylab("Time (Min.)") + xlab("Year-month") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
  datafiltsum2=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYM+CPUCat", meanvarname="Qtimemean", meansvaroutputname="Qtime", data=datalist$tabQtimes )
  
  p3=ggplot(datafiltsum2, aes(x=JobYM, y=Qtime, colour=CPUCat, group=CPUCat)) + 
    geom_errorbar(aes(ymin=Qtime, ymax=Qtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Jobs pending time by CPU Category") + ylab("Time (Min.)") + xlab("Year-month") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
  datafiltsum3=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYM+GPUCat", meanvarname="Qtimemean", meansvaroutputname="Qtime", data=datalist$tabQtimes )
  # remove entries with none
  datafiltsum3=datafiltsum3[datafiltsum3$GPUCat != "none",]
  
  p4=ggplot(datafiltsum3, aes(x=JobYM, y=Qtime, colour=GPUCat, group=GPUCat)) + 
    geom_errorbar(aes(ymin=Qtime, ymax=Qtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Jobs pending time by GPU Category") + ylab("Time (Min.)") + xlab("Year-month") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))

  # Create single plot
  pall= p1 + p2 + p3 + p4 + plot_annotation(tag_levels = list(c("A", "B", "C", "D"))) 
  #+ plot_layout(nrow = 2, widths = c(5,5,5,5) , heights = c(5))  
  return(pall)
  
}

runtimes = function(datalist=datalist, linesize=2, base_size=7){
  
  ls=linesize
  lls=linesize - 0.5
  # datafilt=datalist$tabQtimes
  pd <- position_dodge(0.5) # move them .05 to the left and right
  
  ## Job run times
  datafiltsum3=aggregate_means(response="cbind(Runtimesum,N,varn,nx)",predict="JobYM+Partition", meanvarname="Runtimemean", meansvaroutputname="Runtime", data=datalist$tabRuntimes )
  
  p4=ggplot(datafiltsum3, aes(x=JobYM, y=Runtime, colour=Partition, group=Partition)) + 
    geom_errorbar(aes(ymin=Runtime, ymax=Runtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Job run time by Partition") + ylab("Time (Min.)") + xlab("Year-month") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
  datafiltsum4=aggregate_means(response="cbind(Runtimesum,N,varn,nx)",predict="JobYM+MemCat", meanvarname="Runtimemean", meansvaroutputname="Runtime", data=datalist$tabRuntimes )
  datafiltsum4 = datafiltsum4[complete.cases(datafiltsum4),]
  p5=ggplot(datafiltsum4, aes(x=JobYM, y=Runtime, colour=MemCat, group=MemCat)) + 
    geom_errorbar(aes(ymin=Runtime, ymax=Runtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Job run time by Memory Category") + ylab("Time (Min.)") + xlab("Year-month") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
  datafiltsum5=aggregate_means(response="cbind(Runtimesum,N,varn,nx)",predict="JobYM+CPUCat", meanvarname="Runtimemean", meansvaroutputname="Runtime", data=datalist$tabRuntimes )
  p6=ggplot(datafiltsum5, aes(x=JobYM, y=Runtime, colour=CPUCat, group=CPUCat)) + 
    geom_errorbar(aes(ymin=Runtime, ymax=Runtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Job run time by CPU Category") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))

  datafiltsum6=aggregate_means(response="cbind(Runtimesum,N,varn,nx)",predict="JobYM+GPUCat", meanvarname="Runtimemean", meansvaroutputname="Runtime", data=datalist$tabRuntimes )
  # remove entries with none
  datafiltsum6=datafiltsum6[datafiltsum6$GPUCat != "none",]
  # print(datafiltsum6)
  p7=ggplot(datafiltsum6, aes(x=JobYM, y=Runtime, colour=GPUCat, group=GPUCat)) + 
    geom_errorbar(aes(ymin=Runtime, ymax=Runtime+sd), width=.5, size=lls, position=pd) +
    geom_line(position=pd,size=ls) +
    geom_point(position=pd) + theme_bw(base_size = base_size) + ggtitle("Job run time by GPU Category") + ylab("Time (Min.)") + xlab("Year-month") + theme(axis.text.x = element_text(angle = 45, hjust=1))
  
    
  # Create single plot
  pall = p4 + p5 + p6 + p7 + plot_annotation(tag_levels = list(c("E", "F", "G", "H"))) 
  # + plot_layout(ncol = 3, widths = c(5,5,5) , heights = c(5)) 
  return(pall)
  
}


av_pending_user_day = function(datalist=datalist, base_size=7){

  # We now create the mean of these means
  datafiltsum0 = summarySE2(datalist$tabQtimesUsers, measurevar="Qtimemean", groupvars=c("JobYMD","JobYM","JobD"))
  datafiltsum0$QtimeCat = cut(datafiltsum0$Qtimemeanmean, breaks=c(0,60,120,180,240,300,360,420,480,600,720,Inf),include.lowest=TRUE,labels=c("0-1h","1-2h","2-3h","3-4h","4-5h","5-6h", "6-7h", "7-8h","8-10h", "10-12h", ">12h"))
  
  colfunc<-colorRampPalette(c("lightblue","red"))
  myColors <- colfunc(length(levels(datafiltsum0$QtimeCat)))
  names(myColors) <- levels(datafiltsum0$QtimeCat)

  tmp=datafiltsum0[,c("JobYM","JobD","QtimeCat")]
  for (ym in unique(tmp$JobYM)){
    # Always use 1-31
    #for (d in unique(tmp$JobD)){
    for (d in sprintf("%02d", 1:31)){
      len=nrow( tmp[ym == tmp$JobYM & d==tmp$JobD,])
      
      if (len == 0){
        tmp=rbind(tmp,data.frame(JobYM=ym,JobD=d,QtimeCat="NA"))
        myColors["NA"]="white"
      }
    }
  } 
  
  
  colScale <- scale_fill_manual(name = "Pending time",values = myColors, drop = FALSE, na.value="white")    
  #partitions_names <- paste0("Partitions: ",paste(input$checkGroup, collapse = ", "))
  
  p1=ggplot(tmp, aes(x=JobD, y=JobYM)) +
    geom_tile(aes(fill = QtimeCat),color = "black",lwd = 0.25,linetype = 1) +
    ylab("Year-month") + xlab("Day") + colScale + theme_bw(base_size = base_size) +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(title = "Average of mean job pending times per user and day") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  
  rf=prop.table(table(tmp$QtimeCat))
  p2 = ggplot(data=data.frame(rf), aes(x=Var1, y=Freq)) + geom_bar(stat="identity", color="black", fill=myColors) + 
    xlab("Average of mean job pending times") + ylab("Relative frequency") +  theme_bw(base_size = base_size) + theme(axis.text.x = element_text(angle = 45, hjust=1))
  pall=p1 + p2 + plot_layout(ncol = 2, widths = c(7,3) , heights = c(5))
  return(pall)
}

av_pending_per_day = function(datalist=datalist, base_size=7){
  
  datafiltsum0=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobYM+JobD", meanvarname="Qtimemean", meansvaroutputname="Qtime", data=datalist$tabQtimes )
  datafiltsum0$QtimeCat = cut(datafiltsum0$Qtime, breaks=c(0,60,120,180,240,300,360,420,480,600,720,Inf),include.lowest=TRUE,labels=c("0-1h","1-2h","2-3h","3-4h","4-5h","5-6h", "6-7h", "7-8h","8-10h", "10-12h", ">12h"))
  
  colfunc<-colorRampPalette(c("lightblue","red"))
  myColors <- colfunc(length(levels(datafiltsum0$QtimeCat)))
  names(myColors) <- levels(datafiltsum0$QtimeCat)
  
  tmp=datafiltsum0[,c("JobYM","JobD","QtimeCat")]
  for (ym in unique(tmp$JobYM)){
    for (d in sprintf("%02d", 1:31)){
      
      len=nrow( tmp[ym == tmp$JobYM & d==tmp$JobD,])
      
      if (len == 0){
        tmp=rbind(tmp,data.frame(JobYM=ym,JobD=d,QtimeCat="NA"))
        myColors["NA"]="white"
      }
    }
  } 
  
  colScale <- scale_fill_manual(name = "Pending time",values = myColors, drop = FALSE, na.value="white")
  
  #partitions_names <- paste0("Partitions: ",paste(input$checkGroup, collapse = ", "))
  
  p1=ggplot(tmp, aes(x=JobD, y=JobYM)) +
    geom_tile(aes(fill = QtimeCat),color = "black",lwd = 0.25,linetype = 1) +
    ylab("Year-month") + xlab("Day") + colScale + theme_bw(base_size = base_size) +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(title = "Average job pending times of jobs per day") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))     
  
  rf=prop.table(table(tmp$QtimeCat))
  p2 = ggplot(data=data.frame(rf), aes(x=Var1, y=Freq)) + geom_bar(stat="identity", color="black", fill=myColors) + 
    xlab("Average job pending times") + ylab("Relative frequency") +  theme_bw(base_size = base_size)  + theme(axis.text.x = element_text(angle = 45, hjust=1))
  pall = p1 + p2 + plot_layout(ncol = 2, widths = c(7,3) , heights = c(5))
  
  return(pall)
}

av_pending_per_day_no_reason = function(datalist=datalist, base_size=7){
  
  datafiltsum0=aggregate_means(response="cbind(Qtimesum,N,varn,nx)",predict="JobYMD+JobYM+JobD", meanvarname="Qtimemean", meansvaroutputname="Qtime", data=datalist$tabQtimesNoneReason )
  datafiltsum0$QtimeCat = cut(datafiltsum0$Qtime, breaks=c(0,60,120,180,240,300,360,420,480,600,720,Inf),include.lowest=TRUE,labels=c("0-1h","1-2h","2-3h","3-4h","4-5h","5-6h", "6-7h", "7-8h","8-10h", "10-12h", ">12h"))
  
  colfunc<-colorRampPalette(c("lightblue","red"))
  myColors <- colfunc(length(levels(datafiltsum0$QtimeCat)))
  names(myColors) <- levels(datafiltsum0$QtimeCat)
  
  
  tmp=datafiltsum0[,c("JobYM","JobD","QtimeCat")]
  for (ym in unique(tmp$JobYM)){
    for (d in sprintf("%02d", 1:31)){
      
      len=nrow( tmp[ym == tmp$JobYM & d==tmp$JobD,])
      
      if (len == 0){
        tmp=rbind(tmp,data.frame(JobYM=ym,JobD=d,QtimeCat="NA"))
        myColors["NA"]="white"
      }
    }
  } 
  
  colScale <- scale_fill_manual(name = "Pending time",values = myColors, drop = FALSE, na.value="white")        
  #partitions_names <- paste0("Partitions: ",paste(input$checkGroup, collapse = ", "))
  
  p1=ggplot(tmp, aes(x=JobD, y=JobYM)) +
    geom_tile(aes(fill = QtimeCat),color = "black",lwd = 0.25,linetype = 1) +
    ylab("Year-month") + xlab("Day") + colScale + theme_bw(base_size = base_size) +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + ggtitle(label = "Average job pending times of jobs per day",subtitle="Jobs pending for priority or resources") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))    
  
  rf=prop.table(table(tmp$QtimeCat))
  p2 = ggplot(data=data.frame(rf), aes(x=Var1, y=Freq)) + geom_bar(stat="identity", color="black", fill=myColors) + 
    xlab("Average job pending times") + ylab("Relative frequency") +  theme_bw(base_size = base_size)  + theme(axis.text.x = element_text(angle = 45, hjust=1))
  pall = p1 + p2 + plot_layout(ncol = 2, widths = c(7,3) , heights = c(5))
  return(pall)
  
}

util_per_day_cpu = function(datalist=datalist, base_size=7){

  dataset=datalist$utilization_partition_day
  
  get_YM = function(dstr){
    paste0(unlist(strsplit(dstr, split = "-"))[1],"-",unlist(strsplit(dstr, split = "-"))[2])
  }
  get_D = function(dstr){
    paste0(unlist(strsplit(dstr, split = "-"))[3])
  }      
  
  dataset$JobYM=sapply(dataset$JobYMD,get_YM)
  dataset$JobD=sapply(dataset$JobYMD,get_D)
  
  # Aggregate the partitions
  tmp=aggregate(cbind(theoretical_CPU_hours,CPUhourssum) ~ JobYM+JobD, data = dataset, FUN = sum, na.rm = TRUE)      
  
  # Calc utilization
  tmp$utilization = tmp$CPUhourssum * 100 / tmp$theoretical_CPU_hours
  # since the CPU hours are recorded on the day where the job completed, it can happen that util is > 100% for a day.
  # cap to 100% per day
  tmp$utilization=ifelse(tmp$utilization > 100, 100, tmp$utilization)
  
  tmp$UtilCat = cut(tmp$utilization, breaks=c(0,10,20,30,40,50,60,70,80,100),include.lowest=TRUE,labels=c("0-10%","10-20%","20-30%","30-40%","40-50%","50-60%", "60-70%", "70-80%","80-100%"))
  
  colfunc<-colorRampPalette(c("lightblue","red"))
  myColors <- colfunc(length(levels(tmp$UtilCat)))
  names(myColors) <- levels(tmp$UtilCat)
  
  
  tmp=tmp[,c("JobYM","JobD","UtilCat")]
  for (ym in unique(tmp$JobYM)){
    for (d in sprintf("%02d", 1:31)){
      
      len=nrow( tmp[ym == tmp$JobYM & d==tmp$JobD,])
      
      if (len == 0){
        tmp=rbind(tmp,data.frame(JobYM=ym,JobD=d,UtilCat="NA"))
        myColors["NA"]="white"
      }
    }
  } 
  
  colScale <- scale_fill_manual(name = "Utilization %",values = myColors, drop = FALSE, na.value="white")
  # partitions_names <- paste0("Partitions: ",paste(input$checkGroup, collapse = ", "))
  # partitions_names <- "test"
  p1=ggplot(tmp, aes(x=JobD, y=JobYM)) +
    geom_tile(aes(fill = UtilCat),color = "black",lwd = 0.25,linetype = 1) +
    ylab("Year-month") + xlab("Day") + colScale + theme_bw(base_size = base_size) +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(title = "Utilization % per day") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  
  rf=prop.table(table(tmp$UtilCat))
  p2 = ggplot(data=data.frame(rf), aes(x=Var1, y=Freq)) + geom_bar(stat="identity", color="black", fill=myColors) + 
    xlab("Utilization % per day") + ylab("Relative frequency") +  theme_bw(base_size = base_size) + theme(axis.text.x = element_text(angle = 45, hjust=1))
  pall=p1 + p2 + plot_layout(ncol = 2, widths = c(7,3) , heights = c(5))
  return(pall)
  
}

util_per_day_gpu = function(datalist=datalist, base_size=7){
  
  dataset=datalist$utilization_partition_day
  
  get_YM = function(dstr){
    paste0(unlist(strsplit(dstr, split = "-"))[1],"-",unlist(strsplit(dstr, split = "-"))[2])
  }
  get_D = function(dstr){
    paste0(unlist(strsplit(dstr, split = "-"))[3])
  }      
  
  dataset$JobYM=sapply(dataset$JobYMD,get_YM)
  dataset$JobD=sapply(dataset$JobYMD,get_D)
  
  # some partitions have no gpus
  dataset = dataset[complete.cases(dataset),]
  
  # Aggregate the partitions
  tmp=aggregate(cbind(theoretical_GPU_hours,GPUhourssum) ~ JobYM+JobD, data = dataset, FUN = sum, na.rm = TRUE)      
  
  # Calc utilization
  tmp$utilization = tmp$GPUhourssum * 100 / tmp$theoretical_GPU_hours
  # since the CPU hours are recorded on the day where the job completed, it can happen that util is > 100% for a day.
  # cap to 100% per day
  tmp$utilization=ifelse(tmp$utilization > 100, 100, tmp$utilization)
  
  tmp$UtilCat = cut(tmp$utilization, breaks=c(0,10,20,30,40,50,60,70,80,100),include.lowest=TRUE,labels=c("0-10%","10-20%","20-30%","30-40%","40-50%","50-60%", "60-70%", "70-80%","80-100%"))
  
  colfunc<-colorRampPalette(c("lightblue","red"))
  myColors <- colfunc(length(levels(tmp$UtilCat)))
  names(myColors) <- levels(tmp$UtilCat)
  
  
  tmp=tmp[,c("JobYM","JobD","UtilCat")]
  for (ym in unique(tmp$JobYM)){
    for (d in sprintf("%02d", 1:31)){
      
      len=nrow( tmp[ym == tmp$JobYM & d==tmp$JobD,])
      
      if (len == 0){
        tmp=rbind(tmp,data.frame(JobYM=ym,JobD=d,UtilCat="NA"))
        myColors["NA"]="white"
      }
    }
  } 
  
  colScale <- scale_fill_manual(name = "Utilization %",values = myColors, drop = FALSE, na.value="white")
  # partitions_names <- paste0("Partitions: ",paste(input$checkGroup, collapse = ", "))
  # partitions_names <- "test"
  p1=ggplot(tmp, aes(x=JobD, y=JobYM)) +
    geom_tile(aes(fill = UtilCat),color = "black",lwd = 0.25,linetype = 1) +
    ylab("Year-month") + xlab("Day") + colScale + theme_bw(base_size = base_size) +
    scale_x_discrete(expand=c(0,0)) +
    scale_y_discrete(expand=c(0,0)) + labs(title = "Utilization % per day") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))  
  
  #p1
  
  rf=prop.table(table(tmp$UtilCat))
  p2 = ggplot(data=data.frame(rf), aes(x=Var1, y=Freq)) + geom_bar(stat="identity", color="black", fill=myColors) + 
    xlab("Utilization % per day") + ylab("Relative frequency") +  theme_bw(base_size = base_size) + theme(axis.text.x = element_text(angle = 45, hjust=1))
  pall=p1 + p2 + plot_layout(ncol = 2, widths = c(7,3) , heights = c(5))
  return(pall)
  
}


usage_roc = function(datalist=datalist, linesize=2, base_size=7){

  datafilt=datalist$tabCPUUsers
  dfsummary=suppressWarnings(summarySE2(datafilt, measurevar="CPUhourssum", groupvars=c("User")))
  percentagesall = cumsum(rep(100/nrow(dfsummary),nrow(dfsummary)))
  cpuhourscs=cumsum(dfsummary$CPUhourssumsum[order(dfsummary$CPUhourssumsum)])
  cpuhourscsperc = 100*cpuhourscs / sum(dfsummary$CPUhourssumsum)
  dataf = data.frame(percentages=percentagesall,cpuhourscs=cpuhourscs, stringsAsFactors = F)
  
  # per partition
  upartitions = unique(datafilt$Partition)
  dfsummarypart=suppressWarnings(summarySE2(datafilt, measurevar="CPUhourssum", groupvars=c("User","Partition")))
  datafpart=NULL
  for (part in upartitions){
    dfsub=dfsummarypart[dfsummarypart$Partition==part,]
    cumspart=cumsum(dfsub$CPUhourssumsum[order(dfsub$CPUhourssumsum)])
    cumspartperc = 100*cumspart / sum(dfsub$CPUhourssumsum)
    percentages = cumsum(rep(100/nrow(dfsub),nrow(dfsub)))
    datafpart=rbind(datafpart,data.frame(Partition=part,Csumshoursperc=cumspartperc, Percentages=percentages))
  }
  
  # Add all partitions
  datafpart=rbind(datafpart,data.frame(Partition="All partitions",Csumshoursperc=cpuhourscsperc, Percentages=percentagesall))
  
  # Order
  datafpart=datafpart=datafpart[order(datafpart$Partition),]
  
  datafpart$Partition=factor(datafpart$Partition,levels=unique(datafpart$Partition))
  labs = c(levels(datafpart$Partition), "Equal usage")
  # table(datafpart$Partition)
  
  plpart=ggplot(datafpart, aes(x=Csumshoursperc, y=Percentages, color=Partition)) + geom_line(size=linesize) +
    theme_bw(base_size = base_size) + ggtitle("CPU hours used % vs. percentage of users") + ylab("Percentage of users (%)") + xlab("CPU hours (%)")+
    geom_abline( aes(slope=1, intercept=0, color = "orange"), linetype="dashed", size=linesize) +
    scale_colour_manual(name='Partitions',labels = labs, values=c( rainbow(length(labs)-2),"black","gray") )
  return(plpart)
}
