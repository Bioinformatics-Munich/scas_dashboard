#!/usr/bin/env python3
import argparse
import pandas as pd
import sys
import json
import configparser
import math
import subprocess
import io
from datetime import datetime, timedelta
from random import randint, randrange, choice

# A: Thomas Walzthoeni, 2022
# D: Generates test data for the slurm dashboard
parser = argparse.ArgumentParser(description="Generates test data for the slurm dashboard.")
parser.add_argument("--numdays", help="'Number of days from today to generate jobs'", default=365, type=int)
parser.add_argument('--nodesfile', help="File with nodes data.", default="./nodes.template", type=str, required=False)
parser.add_argument('--output', help="File with jos created.", default="./jobs.out", type=str, required=False)

args = parser.parse_args()

# Start on dayx
# Take a node and check if it is free
# If yes generate a job, if no skip

# set GPUs
# gpu:2,mps:1K
def get_gpus(input):
    # print(input)
    if input == "(null)":
        return pd.Series(0)
    d = dict(x.rsplit(":",1) for x in input.split(","))
    # Also check if we need to split the keys could be gpu:a100_3g.20gb
    d2={}
    GPUS = 0
    for dk in d:
        d2[dk.split(":")[0]]=d[dk]
        if 'gpu' in d2:
            GPUS = int(d2['gpu'])
        else:
            GPUS = 0
    return pd.Series(GPUS)

# 2 read the nodes data
dfnodes = pd.read_csv(args.nodesfile, header = None, sep='|',
       names = [
        'HOSTNAME',
        'CPUS',
        'MEMORY',
        'GRES',
      ]
    )

# Add GPUs
dfnodes[["GPUS"]] = dfnodes["GRES"].apply(get_gpus)


# Create jobs
formatstr = "%Y-%m-%dT%H:%M:%S"
startdate = datetime.now() - timedelta(days = args.numdays)
# datetime(2022, 12, 28, 23, 55, 59)
print("Startdate:" + startdate.strftime(formatstr))
# Calc diff to today in days
orgdiff = datetime.now() - startdate
#print(orgdiff.days)

# Create one job for each node
# Set a starttime, then create a random submit, start and end time
lastid=1
# Select Reasons
strings = ['None','None','None','None','None','None','None','None','None','QOSMaxJobsPerUserLimit','Dependency','ReqNodeNotAvail']
# Open output
fileout = open(args.output, "w")
fileout.writelines("JobIDRaw|Account|User|State|Partition|ReqCPUS|ReqMem|Timelimit|Submit|Start|End|NodeList|ReqTRES|Reason\n")

# Simulate an increase of GPU use over time
# with longer pending times for the GPUs

while startdate < datetime.now() - timedelta(days = 3):

    # calc diff startdate to now
    diff = datetime.now() - startdate
    # print(diff.days)
    #sys.exit()
    for index, row in dfnodes.iterrows():
        # print(row['HOSTNAME'], row['CPUS'],row['MEMORY'], row['GPUS'],)
        # gen user
        user = 'user.%s' % (randint(1, 100))
        # Gen number of cores
        ncores=randint(1, row['CPUS'])
        # Gen memory
        mem=int(randint(1, row['MEMORY'])/1000)
        # Submit time
        submit = startdate + timedelta(minutes = randint(1, 240) )
        # Start time
        start = submit + timedelta(minutes = randint(1, 240) )
        # end time max 1 day 
        endtime = start + timedelta(minutes = randint(1, 1440) )

        # billing string which contains gpus if any
        if row['GPUS'] > 0:
            qu="gpu"
            
            # add more jobs dependant on the orgdiff.days/diff.days
            njobstoadd=int(orgdiff.days/diff.days)
            #print(njobstoadd)
            # Increase if gpu = 16
            if row['GPUS']==16:
                #njobstoadd = int(njobstoadd * 2)
                if njobstoadd >2:
                    njobstoadd = 2
            else:
                njobstoadd = njobstoadd
                if njobstoadd >1:
                    njobstoadd = 1
            for i in range(njobstoadd):
                # jobid
                id = lastid
                # Submit time
                submit = startdate + timedelta(minutes = randint(1, 240) )
                # Start time
                factorrandom=randint(1,10)
                if row['GPUS']==16:
                    start = submit + timedelta(minutes = randint(1, orgdiff.days - diff.days+240) )
                    # select >=10 gpus
                    billing= 'billing=10,cpu=%s,gres/gpu=%s,mem=%sG,node=1' % (ncores, randint(10, row['GPUS']), mem)
                else:
                    # select gpus
                    billing= 'billing=10,cpu=%s,gres/gpu=%s,mem=%sG,node=1' % (ncores, randint(1, row['GPUS']), mem)                    
                    start = submit + timedelta(minutes = randint(1, 240) )
                # end time max 1 day 
                endtime = start + timedelta(minutes = randint(1, 1440) )
                jobstr = '%s|hpc|%s|COMPLETED|%s|%s|%sG|3-00:00:00|%s|%s|%s|%s|%s|%s\n' %(id, user, qu, ncores, mem, submit.strftime(formatstr) , start.strftime(formatstr), endtime.strftime(formatstr), row['HOSTNAME'], billing, choice(strings))           
                fileout.writelines(jobstr)
                lastid = lastid +1
        else:
            # jobid
            id = lastid
            qu="cpu"
            billing= 'billing=10,cpu=%s,mem=%sG,node=1' % (ncores,mem)
            jobstr = '%s|hpc|%s|COMPLETED|%s|%s|%sG|3-00:00:00|%s|%s|%s|%s|%s|%s\n' %(id, user, qu, ncores, mem, submit.strftime(formatstr) , start.strftime(formatstr), endtime.strftime(formatstr), row['HOSTNAME'], billing, choice(strings))
            fileout.writelines(jobstr)
            lastid = lastid +1

    # Move startdate + 1-3 days
    startdate = startdate + timedelta(days = 1)

fileout.close()
print(str(id)+ " jobs written to " + args.output)
sys.exit()