from rest_framework import generics
from .models import Jobs,Nodes,YMDdata,ParamExcludePartition, Settings
from .serializers import JobsSerializer,JobsSerializerAll,NodesSerializer,NodesSerializerAll,JobsSerializerAll
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view,permission_classes,authentication_classes
from django.http import JsonResponse
from rest_framework.parsers import JSONParser
from rest_framework.renderers import JSONRenderer

from rest_framework.authentication import SessionAuthentication, BasicAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

import time
import os
from os import path
# rpy2
import rpy2.robjects as robjects
from rpy2.robjects.packages import importr
from rpy2.robjects.packages import STAP

from django.core.serializers import serialize
from django.db.models import Count

import json
import calendar
import datetime
from django.core.serializers.json import DjangoJSONEncoder
from datetime import date, timedelta
import sys
from django.test import RequestFactory
import pytz

from django.http import HttpResponse
import datetime

import io, base64
from django.conf import settings
import codecs
import subprocess
from dateutil import relativedelta

# Read the file with the R functions
f= open(path.relpath('../app/functions.R'), 'r')
string = f.read()
# Parse filter_data_api_v3 functon using STAP
filter_data_api_python= STAP(string, "filter_data_api_v3")
# get_datalist function
get_datalist_python= STAP(string, "get_datalist")

# plots functions
r = robjects.r
r.source('../app/functions.R')
r.source('../app/plots.R')
#p= open(path.relpath('../app/plots.R'), 'r')
#stringp = p.read()
# lineplot
#lineplot= STAP(stringp, "lineplot")


def get_partitions():
    """
    List all partitions
    """
    partitions =  Jobs.objects.all().values_list('Partition', flat=True).distinct()
    exclpartitions = ParamExcludePartition.objects.all().values_list('pname', flat=True).distinct()
    res = [i for i in partitions if i not in exclpartitions]
    return(res)

def get_clusters():
    """
    List all clusters
    """
    clusters =  Jobs.objects.all().values_list('cluster_id', flat=True).distinct()
    res = [i for i in clusters]
    return(res)


# Import jsonlite package
jsonlite_package=importr('jsonlite')
utils = importr('utils')

# view publicdash
def publicdash(request):

    # Get settings
    obj = Settings.objects.get(name="presentation_n_month_back")
    presentation_n_month_back = getattr(obj, "value")
    print("presentation_n_month_back: "+ presentation_n_month_back)
    
    obj = Settings.objects.get(name="slide_speed")
    slide_speed = getattr(obj, "value")
    print("slide_speed: "+ slide_speed)

    obj = Settings.objects.get(name="slide_title")
    slide_title = getattr(obj, "value")
    print("slide_title: "+ slide_title)

    obj = Settings.objects.get(name="slide_subtitle")
    slide_subtitle = getattr(obj, "value")
    print("slide_subtitle: "+ slide_subtitle)

    obj = Settings.objects.get(name="slide_width")
    slide_width = getattr(obj, "value")
    print("slide_width: "+ slide_width)

    obj = Settings.objects.get(name="slide_footer")
    slide_footer = getattr(obj, "value")
    print("slide_footer: "+ slide_footer)

    obj = Settings.objects.get(name="slide_width")
    slide_width = getattr(obj, "value")
    print("slide_width: "+ slide_width)

    obj = Settings.objects.get(name="slide_height")
    slide_height = getattr(obj, "value")
    print("slide_height: "+ slide_height)

    obj = Settings.objects.get(name="slide_image_size")
    slide_image_size = getattr(obj, "value")
    print("slide_image_size: "+ slide_image_size)


    now = datetime.datetime.now()
    dback = now - relativedelta.relativedelta(months=int(presentation_n_month_back))
    fromgenerate=dback.strftime('%Y-%m') + "-01"
    togenerate =now.strftime('%Y-%m-%d')
    print(fromgenerate)
    print(togenerate)

    # get partitions
    partitions=get_partitions()
    #print(partitions)

    # get clusters
    clusters = get_clusters()
    #print(clusters)

    data=JobsListInternal(fromdate=fromgenerate,todate=togenerate)
    dataj=json.dumps(data)
    # print(testout)
    #get_datalist()
    datalist=get_datalist_python.get_datalist(res=dataj, partitions_selected = partitions, clusters_selected = clusters, api=str("TRUE"))
    p1=robjects.r.lineplot1(datalist=datalist, linesize=int(2), base_size=int(18))
    robjects.r.ggsave(plot=p1, filename=settings.MEDIA_ROOT+"/l1.png", width=20, height=6)
    p2=robjects.r.lineplot2(datalist=datalist, linesize=int(2), base_size=int(18))
    robjects.r.ggsave(plot=p2, filename=settings.MEDIA_ROOT+"/l2.png", width=15, height=6)
    p3=robjects.r.lineplot3(datalist=datalist, linesize=int(2), base_size=int(18))
    robjects.r.ggsave(plot=p3, filename=settings.MEDIA_ROOT+"/l3.png", width=15, height=6)

    combined=robjects.r.combine_lineplots(lineplot1=p1,lineplot2=p2,lineplot3=p3 )
    robjects.r.ggsave(plot=combined, filename=settings.MEDIA_ROOT+"/lplots.png", width=15, height=12)

    cont_plot1 = robjects.r.cont_plot1(datalist=datalist, txtsize=int(6), base_size=int(18))
    robjects.r.ggsave(plot=cont_plot1, filename=settings.MEDIA_ROOT+"/cont_plot1.png", width=15, height=6)
    cont_plot2 = robjects.r.cont_plot2(datalist=datalist, txtsize=int(6), base_size=int(18))
    robjects.r.ggsave(plot=cont_plot2, filename=settings.MEDIA_ROOT+"/cont_plot2.png", width=15, height=6)

    con_combined=robjects.r.combine_conplots(cont_plot1,cont_plot2)
    robjects.r.ggsave(plot=con_combined, filename=settings.MEDIA_ROOT+"/con_combined.png", width=15, height=12)


    runtimes = con_combined=robjects.r.runtimes(datalist=datalist, linesize=int(2), base_size=int(18))
    robjects.r.ggsave(plot=runtimes, filename=settings.MEDIA_ROOT+"/runtimes.png", width=15, height=6)

    pendingtimes = con_combined=robjects.r.pendingtimes(datalist=datalist, linesize=int(2), base_size=int(18))
    robjects.r.ggsave(plot=pendingtimes, filename=settings.MEDIA_ROOT+"/pendingtimes.png", width=15, height=6)
    
    pending_run_combined=robjects.r.combine_conplots(runtimes,pendingtimes)
    robjects.r.ggsave(plot=pending_run_combined, filename=settings.MEDIA_ROOT+"/pending_run_combined.png", width=20, height=12)

    pending_no_reason=con_combined=robjects.r.av_pending_per_day_no_reason(datalist=datalist, base_size=int(16))
    pending_peruser=con_combined=robjects.r.av_pending_user_day(datalist=datalist, base_size=int(16))
    robjects.r.ggsave(plot=pending_peruser, filename=settings.MEDIA_ROOT+"/pending_peruser.png", width=15, height=6)
    robjects.r.ggsave(plot=pending_no_reason, filename=settings.MEDIA_ROOT+"/pending_no_reason.png", width=15, height=6)

    pending_combined=robjects.r.combine_conplots(pending_no_reason,pending_peruser)
    robjects.r.ggsave(plot=pending_combined, filename=settings.MEDIA_ROOT+"/pending_combined.png", width=15, height=12)

    util_per_day_cpu=con_combined=robjects.r.util_per_day_cpu(datalist=datalist, base_size=int(18))
    robjects.r.ggsave(plot=util_per_day_cpu, filename=settings.MEDIA_ROOT+"/util_per_day_cpu.png", width=15, height=6)

    util_per_day_gpu=con_combined=robjects.r.util_per_day_cpu(datalist=datalist, base_size=int(18))
    robjects.r.ggsave(plot=util_per_day_gpu, filename=settings.MEDIA_ROOT+"/util_per_day_gpu.png", width=15, height=6)

    util_combined=robjects.r.combine_conplots(util_per_day_cpu,util_per_day_gpu)
    robjects.r.ggsave(plot=util_combined, filename=settings.MEDIA_ROOT+"/util_combined.png", width=15, height=12)

    # Create qmd
    qmd = open(settings.MEDIA_ROOT+"/public.qmd", "w")
    # head='---\ntitle: "HPC Cluster Statistics"\nauthor: "SCAS Dashboard"\nformat:\n revealjs:\n  auto-slide: %s\n  loop: true\n  \nfooter: "SCAS Dashboard"\nembed-resources: true\n---\n' % slide_speed
    # head='---\ntitle: "Habits"\nauthor: "John Doe"\nformat:\n revealjs:\n  auto-slide: 5000\n  loop: true\n  \nfooter: "SCAS Dashboard"\n  width: 100%\n  height: 100%\nembed-resources: true\n---\n'
# title-slide-attributes:
#  data-background-image: %s
#  data-background-size: contain
#  data-background-opacity: "0.5"
    head = """---
title: "{}"
title-slide-attributes:
  data-background-image: "../static/cluster.png"
  data-background-opacity: "1.0"
  data-background-size: 100%, cover
  data-background-position: 2% 98%, center 
author: "{}"
format:
 revealjs:
  auto-slide: {}
  loop: true
  width: {}
  height: {}
  theme: default
  css: ../static/style.css
footer: "{}"
embed-resources: true
---
""".format(slide_title,slide_subtitle,slide_speed,slide_width,slide_height,slide_footer)

    qmd.write(head)
    qmd.write('\n')

    # slide
    qmd.write("## Summary {.centerhead}\n")
    
    l = 'Statistics date range: from %s to %s  \n' % (str(fromgenerate),str(togenerate))
    qmd.write(l)    
    
    l = 'Cluster: %s  \n' % str(','.join(clusters))
    qmd.write(l)
    l = 'Partitions: %s  \n' % str(','.join(partitions))
    qmd.write(l)

    l = 'Active users: %s  \n' % (str(datalist.rx2('uniqusers')[0]))
    qmd.write(l)

    njobs= con_combined=robjects.r.getnjobs(datalist=datalist)
    l = 'Completed jobs: %s  \n' % (str(njobs[0]))
    qmd.write(l)

    cpuhours = con_combined=robjects.r.getcpuhours(datalist=datalist)
    l = 'CPU hours used: %s  \n' % (str(cpuhours[0]))
    qmd.write(l)

    gpuhours = con_combined=robjects.r.getgpuhours(datalist=datalist)
    l = 'GPU hours used: %s  \n' % (str(gpuhours[0]))
    qmd.write(l)

    qmd.write('\n')


    # slide
    qmd.write("## Jobs and CPU/GPU hours used {.centerhead}\n")
    l = '![](lplots.png){height="%s"}\n' % str(slide_image_size)
    qmd.write(l)
    qmd.write('\n')

    # slide
    qmd.write("## Jobs and CPU/GPU hours used {.centerhead}\n")
    l = '![](con_combined.png){height="%s"}\n' % str(slide_image_size)
    qmd.write(l)
    qmd.write('\n')    

    # slide
    qmd.write("## Job run and pending times {.centerhead}\n")
    l = '![](pending_run_combined.png){height="%s"}\n' % str(slide_image_size)
    qmd.write(l)    
    qmd.write('\n')   

    # slide
    qmd.write("## Job run and pending times {.centerhead}\n")
    l = '![](pending_combined.png){height="%s"}\n' % str(slide_image_size)
    qmd.write(l)  
    qmd.write('\n') 
    
    # slide
    qmd.write("## Cluster utilization {.centerhead}\n")
    l = '![](util_combined.png){height="%s"}\n' % str(slide_image_size)
    qmd.write(l)
    qmd.write('\n')   

    # close file
    qmd.close()

    # Render
    cmd = "quarto render " + settings.MEDIA_ROOT+"/public.qmd --no-cache"
    returned_value = subprocess.call(cmd, shell=True)
    print(returned_value)

    # Add line to reload page every 12 hours
    with open(settings.MEDIA_ROOT+"/public.html", encoding="utf8") as in_file, codecs.open(settings.MEDIA_ROOT+"/dashboard.html", "w", "utf-8") as out_file:
        for line in in_file:
            out_file.write(line)
            if line.strip() == '<html lang="en"><head>':
                out_file.write('<meta http-equiv="refresh" content="43200" >\n')

    p = open(settings.MEDIA_ROOT+"/dashboard.html", encoding="utf8")
    stringp = p.read()

    return HttpResponse(stringp)

# Functions
def get_date(YMD):
    return( date( int(str(YMD).split("-")[0]),int(str(YMD).split("-")[1]),int(str(YMD).split("-")[2]) ) )

def get_from_to_date(ymdict,fromdate,todate):
    # check if from or to date needs to be adjusted
    # 1. Check if the fromdate is in the JobYM month, then take this date
    if ymdict['JobYM'].split("-")[0] == fromdate.split("-")[0] and ymdict['JobYM'].split("-")[1] == fromdate.split("-")[1]:
        fromgenerate = fromdate
    else:
        # 2. the fromdate is in another month, then take the first day of the month
        first_day = datetime.date(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]), 1)
        fromgenerate=first_day.strftime('%Y-%m-%d')
        # 3. check if the todate is from that month
    if ymdict['JobYM'].split("-")[0] == todate.split("-")[0] and ymdict['JobYM'].split("-")[1] == todate.split("-")[1]:
        togenerate = todate
    else:
        # 4. if not then get the last day of the month
        _, num_days = calendar.monthrange(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]))
        # get last day of the month
        last_day = datetime.date(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]), num_days)
        togenerate=last_day.strftime('%Y-%m-%d')
    return fromgenerate, togenerate

def get_from_to_date_ymdict(ymdict):
    # 1. Get the firstday of the YM
    first_day = datetime.date(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]), 1)
    fromgenerate=first_day.strftime('%Y-%m-%d')
    # 2. get the last day of the month
    _, num_days = calendar.monthrange(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]))
    last_day = datetime.date(int(ymdict['JobYM'].split("-")[0]), int(ymdict['JobYM'].split("-")[1]), num_days)
    togenerate=last_day.strftime('%Y-%m-%d')
    return fromgenerate, togenerate

# use ymd as param
def JobsListInternal(fromdate="2022-01-01",todate="2023-01-01"):
    """
    Return stats on the selcected date, or create new jobs.
    """
    #print(fromdate)
    #print(todate)
    #print(returndata)
    # Get the data of the nodes
    nodes=Nodes.objects.all()
    serializer_nodes = NodesSerializerAll(nodes, many=True)
    data_nodes = jsonlite_package.fromJSON(json.dumps(serializer_nodes.data))

    # Get jobs in range
    # Add 1 day to the to date, filter is not inclusive on the last day
    startdate=datetime.datetime.strptime(fromdate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
    enddate=datetime.datetime.strptime(todate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
    # The jobrange for the enddate needs to be adjusted to the very end of the day
    jobscountsYMD = Jobs.objects.filter(Start__range=[startdate, enddate+timedelta(days=0.9999999)]).values('JobYMD').annotate(total=Count('JobYMD'))
    # Get a list of all days in the the db
    ymdlist = [ sub['JobYMD'] for sub in list(jobscountsYMD) ]
    # Get or create stats and return the results based on the YM where we have jobs
    DATALISTS_json={}

    # Get the object from the db
    YMDdataobjs=YMDdata.objects.filter(YMD__in=ymdlist)

    for YMDobj in YMDdataobjs:
        # Add to DATALISTS_json
        DATALISTS_json[YMDobj.YMD]=str(YMDobj.data)

    return DATALISTS_json



####### API ##########

@api_view(['GET'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def PartitionTooltip(request):
    """
    Send partitions Tooltip
    """
    if request.method == 'GET':
        # Get settings
        obj = Settings.objects.get(name="partitions_tooltip")
        partitions_tooltip_value = getattr(obj, "value")
        print("partitions_tooltip_value: "+ partitions_tooltip_value)
        return Response(json.dumps(partitions_tooltip_value))


@api_view(['GET'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def Index(request):
    """
    Update YMDdata
    """
    if request.method == 'GET':
        # get time
        start = time.time()
        # from and to date
        fromdate = request.query_params.get('from')
        todate = request.query_params.get('to')
        # Force recal
        force=request.query_params.get('force')

        if fromdate and todate:
            # select days
            startdate=datetime.datetime.strptime(fromdate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
            enddate=datetime.datetime.strptime(todate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
            jobscountsYMD = Jobs.objects.filter(Start__range=[startdate, enddate+timedelta(days=0.9999999)]).values('JobYMD').annotate(total=Count('JobYMD'))
        else:
            # all days
            # Get njobs per JobYMD based on the jobs in the db
            jobscountsYMD = Jobs.objects.values('JobYMD').annotate(total=Count('JobYMD'))
        # Get a list of all days in the the db
        ymdlist = [ sub['JobYMD'] for sub in list(jobscountsYMD) ]
        # Get the YMD objects from the db
        YMDdataobjs=YMDdata.objects.values('YMD', 'jobscounts')
        # Lookup hash
        YMDdataobjs_lookup = dict((item['YMD'], item["jobscounts"]) for item in list(YMDdataobjs))
        recal=False
        newcal=False
        # Get the data of the nodes
        nodes=Nodes.objects.all()
        serializer_nodes = NodesSerializerAll(nodes, many=True)
        data_nodes = jsonlite_package.fromJSON(json.dumps(serializer_nodes.data))
        for ymddict in list(jobscountsYMD):
            if ymddict['JobYMD'] in YMDdataobjs_lookup:
                # check if it has the same number of jobs set
                if YMDdataobjs_lookup[ymddict['JobYMD']]==ymddict["total"]:
                    if force=="True":
                        recal=True
                    else:
                        recal=False
                else:
                    recal=True
            else:
                newcal=True
            if recal or newcal:
                print(str(ymddict['JobYMD'])+ " Entry in db has diff number of jobs, is not indexed so far or force param is used.")
                startdate=get_date(str(ymddict['JobYMD']))
                jobs = Jobs.objects.filter(JobYMD=str(ymddict['JobYMD']))
                serializer = JobsSerializerAll(jobs, many=True)
                datajobs = jsonlite_package.fromJSON(json.dumps(serializer.data))
                # Call R function
                datalist=filter_data_api_python.filter_data_api_v3(datajobs=datajobs,data_nodes=data_nodes,fromdate=str(startdate))
                # Save to database
                if newcal:
                    YMDdataobjnew = YMDdata.objects.create(YMD=ymddict['JobYMD'], jobscounts=len(jobs), data=str(datalist))
                    newcal=False
                if recal:
                    YMDobj = YMDdata.objects.filter(YMD=ymddict['JobYMD'])[0]
                    YMDobj.jobscounts=len(jobs)
                    YMDobj.data=str(datalist)
                    YMDobj.save()
                    recal=False
        # get time
        end = time.time()

        return Response({
            'success': True,
            'message': "Index updated. " + " Runtime (s): " + str(end - start),
        }, status=status.HTTP_201_CREATED)


@api_view(['GET', 'POST'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def NodesList(request):
    """
    List all Nodes, or create a new Nodes.
    """
    if request.method == 'GET':
        nodes =  Nodes.objects.all()
        serializer = NodesSerializerAll(nodes, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        # get time
        start = time.time()
        # get the data
        nodes = request.data.get('nodes', '')
        try:
            nodes = json.loads(nodes)
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid nodes data.',
            }, 400)

        # filter nodes that alrady exist
        newnodes=[]
        # Create a list of hostnames
        hostnames = [ sub['HOSTNAME'] for sub in nodes ]

        # get jobs from db
        foundn=Nodes.objects.filter(HOSTNAME__in=hostnames,cluster_id=nodes[0]['cluster_id'])

        # excl nodes that are already in the db
        exclude_ids = [item.HOSTNAME for item in foundn]
        newnodes = [d for d in nodes if d['HOSTNAME'] not in exclude_ids]
        skipped = len(nodes) - len(newnodes)

        # Create serializer
        serializer = NodesSerializer(data=newnodes,many=True)

        if serializer.is_valid():
            serializer.save()
            # end time
            end = time.time()

            return Response({
                'success': True,
                'message': 'Added '+str(len(newnodes))+" nodes. Skipped "+str(skipped)+" nodes because they were already in the database." + " Runtime (s): " + str(end - start),
            }, status=status.HTTP_201_CREATED)
        #else:
        #    print(serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def PartitionList(request):
    """
    List all partitions
    """
    if request.method == 'GET':
        partitions =  Jobs.objects.all().values_list('Partition', flat=True).distinct()
        exclpartitions = ParamExcludePartition.objects.all().values_list('pname', flat=True).distinct()
        res = [i for i in partitions if i not in exclpartitions]
        # print(res)
        return Response(json.dumps(list(res)))

@api_view(['GET'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def ClusterList(request):
    """
    List all Clusters
    """
    if request.method == 'GET':
        partitions =  Jobs.objects.all().values_list('cluster_id', flat=True).distinct()
        return Response(json.dumps(list(partitions)))


@api_view(['GET', 'POST'])
@authentication_classes([SessionAuthentication, BasicAuthentication])
@permission_classes([IsAuthenticated])
def JobsList(request):
    """
    Return stats on the selcected date, or create new jobs.
    """
    if request.method == 'GET':

        fromdate = request.query_params.get('from')
        todate = request.query_params.get('to')
        # returndata = request.query_params.get('returndata')
        if fromdate is None or todate is None:
            return Response({
                    'success': False,
                    'message': 'fromdate and todate must be specified as Y-M_D string e.g. ?from=2022-01-01&to=2022-03-02',
                }, 400)

        # print(fromdate)
        # print(todate)
        #print(returndata)

        # Get the data of the nodes
        #nodes=Nodes.objects.all()
        #serializer_nodes = NodesSerializerAll(nodes, many=True)
        #data_nodes = jsonlite_package.fromJSON(json.dumps(serializer_nodes.data))

        # Get jobs in range
        # Add 1 day to the to date, filter is not inclusive on the last day
        startdate=datetime.datetime.strptime(fromdate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
        enddate=datetime.datetime.strptime(todate, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
        # The jobrange for the enddate needs to be adjusted to the very end of the day
        jobscountsYMD = Jobs.objects.filter(Start__range=[startdate, enddate+timedelta(days=0.9999999)]).values('JobYMD').annotate(total=Count('JobYMD'))
        # Get a list of all days in the the db
        ymdlist = [ sub['JobYMD'] for sub in list(jobscountsYMD) ]
        # Get or create stats and return the results based on the YM where we have jobs
        DATALISTS_json={}

        # Get the object from the db
        YMDdataobjs=YMDdata.objects.filter(YMD__in=ymdlist)

        for YMDobj in YMDdataobjs:
            # Add to DATALISTS_json
            DATALISTS_json[YMDobj.YMD]=str(YMDobj.data)

        return Response(DATALISTS_json)

    elif request.method == 'POST':

        # get time
        start = time.time()
        # get the data
        jobs = request.data.get('jobs', '')
        try:
            jobs = json.loads(jobs)
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid jobs data.',
            }, 400)

        # filter jobs that alrady exist
        newjobs=[]
        # Create a list of jobids
        jobids = [ sub['JobIDRaw'] for sub in jobs ]
        # get jobs from db with this cluster_id
        foundj=Jobs.objects.filter(JobIDRaw__in=jobids,cluster_id=jobs[0]['cluster_id'])
        # excl jobs that are already in the db
        exclude_ids = [item.JobIDRaw for item in foundj]
        newjobs = [d for d in jobs if d['JobIDRaw'] not in exclude_ids]
        skipped = len(jobs) - len(newjobs)

        # Create serializer
        serializer = JobsSerializer(data=newjobs,many=True)

        if serializer.is_valid():
            serializer.save()
            # end time
            end = time.time()

            return Response({
                'success': True,
                'message': 'Added '+str(len(newjobs))+" jobs. Skipped "+str(skipped)+" jobs because they were already in the database." + " Runtime (s): " + str(end - start),
            }, status=status.HTTP_201_CREATED)
        #else:
        #    print(serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class JobsDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Jobs.objects.all()
    serializer_class = JobsSerializer
