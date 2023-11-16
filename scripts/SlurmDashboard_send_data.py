#!/usr/bin/env python3
import argparse
import pandas as pd
import requests
import sys
import json
import configparser
import math
import subprocess
import io
from datetime import datetime, timedelta

# A: Thomas Walzthoeni, 2022
# D: Sends data from slurm commands or files as json to the slurm dashboard api
parser = argparse.ArgumentParser(description="Sends data from slurm as json to the slurm cluster admin stats api.")
parser.add_argument("--apiurl", help="API address, for local dev use http://127.0.0.1:8000.", default="https://127.0.0.1", type=str)
parser.add_argument("--clusterid", help="ClusterID: default is slurm1", default="slurm1", type=str)
parser.add_argument('--conf', help="Configuration file with user=username and password=password. default: login.conf", default="login.conf", type=str)
parser.add_argument('--nodesfile', help="File with nodes data. Optional, if not provided data is generated using the slurm commands.", required=False)
parser.add_argument('--jobsfile', help="File with jobs data. Optional, if not provided data is generated using the slurm commands.", required=False)
parser.add_argument('--datestart', help="Date (YYYY-MM-DD) or number n which will then calculate n Days before today. Default: 7",default=7,required=False)
parser.add_argument('--dateend', help="Date (YYYY-MM-DD) or number n which will calculate n Days before today. Default: 0",default=0,required=False)
parser.add_argument('--junksize', help="Uploads to API are done in junks of njobs. Default: 100000",default=100000,required=False)
parser.add_argument('--test', action='store_true', help="If this argument is used, data will be generated but won't be sent to the API.")
parser.add_argument('--indexonly', action='store_true', help="Only run the indexing step.")
parser.add_argument('--force', action='store_true', help="Force indexing to be rerun.")
parser.add_argument('--skipsslverification', action='store_true', help="Skip ssl certificate verification.")

args = parser.parse_args()

def is_tool(name):
    """Check whether `name` is on PATH."""

    from distutils.spawn import find_executable

    return find_executable(name) is not None

# 1 Parse the auth file and get the username and password
config = configparser.ConfigParser()
with open(args.conf, 'r') as f:
    config_string = f.read()
# read the config
config.read_string("[Auth]\n"+config_string)

# ssl verification
verify=True
if args.skipsslverification:
    print("--skipsslverification is used")
    verify=False

# Set dates
startdate = None
enddate = None

#print(args.datestart)
#print(args.dateend)
#sys.exit()

# Generate the dates, if no files are used for upload
# Relevant to use the indexing then w/o dates
if args.nodesfile is None or args.jobsfile is None:

    if args.datestart:
        if "-" in str(args.datestart):
            startdate=args.datestart
        else:
            startdate=datetime.now() + timedelta(days=int(args.datestart)*(-1))
            startdate=startdate.strftime("%Y-%m-%d")

        if "-" in str(args.dateend):
            enddate=args.dateend
        else:
            enddate=datetime.now() + timedelta(days=int(args.dateend)*(-1))
            enddate=enddate.strftime("%Y-%m-%d")
   
print("Generating data from: " + str(startdate))
print("Generating data to: " + str(enddate))


if args.indexonly:
    if args.test:
        print("--test indexing not run.")  
        sys.exit()
    else: 
        # Get request to update the index
        print("--indexonly is used, will only run the indexing, use --force to force re-indexing.")  
        params={}
        params["from"] = startdate
        params["to"] = enddate
        if args.force:
            params["force"] = True
        else:
            params["force"] = False
        x = requests.get(args.apiurl+"/api/index/", auth=(config.get("Auth", "user"), config.get("Auth", "password")), params=params, verify=verify )
        print(x.text)
        sys.exit()

# Read or get the nodes
if args.nodesfile:

    # 2 read the nodes data
    dfnodes = pd.read_csv(args.nodesfile, header = None, sep='|',
       names = [
        'HOSTNAME',
        'CPUS',
        'MEMORY',
        'GRES',
      ]
    )
else:
    if is_tool("sinfo"):
        p = subprocess.Popen('sinfo -o "%n|%c|%m|%G" --noheader', stdout=subprocess.PIPE, shell=True)
        (output, err) = p.communicate()
        p_status = p.wait()
        s = ''.join(map(chr, output))
        buffer = io.StringIO(s)
        dfnodes = pd.read_csv(filepath_or_buffer = buffer, header = None, sep='|',
           names = [
            'HOSTNAME',
            'CPUS',
            'MEMORY',
            'GRES',
          ]
        )
    else:
        sys.exit("Error: sinfo not available")

# Add the cluster_id
dfnodes=dfnodes.assign(cluster_id=args.clusterid)

# Replace (null)
dfnodes.loc[dfnodes["GRES"] == "(null)", "GRES"] = ""
df_nodes_dict = dfnodes.to_dict('records')

# Create the dict
n = {}
n['nodes'] = json.dumps(df_nodes_dict)

# send data to api
if args.test:
    print("--test no uploads to API")
    print(dfnodes)
else:
    x = requests.post(args.apiurl+"/api/nodes/", auth=(config.get("Auth", "user"), config.get("Auth", "password")), data = n, verify=verify)
    print(x.text)

# Read/get jobs data
if args.jobsfile:
    df = pd.read_csv(args.jobsfile, sep='|', keep_default_na=False,na_values=['NaN'])
    cmd="none: localfile is used"
else:
    if is_tool("sacct"):   
        cmd="sacct --format=JobIDRaw,Account,User,State,Partition,ReqCPUS,ReqMem,Timelimit,Submit,Start,End,Node,Reqtres,Reason -S %s -E %s -X --state=CD --allusers --units=G -P" % (startdate,enddate)
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        (output, err) = p.communicate()
        p_status = p.wait()
        s = ''.join(map(chr, output))
        buffer = io.StringIO(s)   
        df = pd.read_csv(filepath_or_buffer = buffer, sep='|',keep_default_na=False,na_values=['NaN'])
    else:
        sys.exit("Error: sacct not available")
        
# Get the numrows
nrows=len(df.index)

# Some jobs have Start=None, or Start=Unknown filter
df=df.loc[df['Start'] != "None"]
df=df.loc[df['Start'] != "Unknown"]

# Split upload into chunks of 100k
junksize=args.junksize
njunks=math.ceil(nrows / junksize)
print( str(len(df.index))+str(" rows read.") )

for j in range(0,njunks):
    
    index_start=j*junksize
    index_end=((j+1)*junksize)
    
    print("Processing junk "+str(j+1)+"/"+str(njunks)+" from "+ str(index_start) + " to " + str(index_end))
    
    df_tmp = df[index_start:index_end]

    # Add the cluster_id
    df_tmp=df_tmp.assign(cluster_id=args.clusterid)
    df_dict = df_tmp.to_dict('records')

    # Create the dict
    d = {}
    d['jobs'] = json.dumps(df_dict)

    if args.test:
        print("--test no uploads to API")
        print("Sacct command: "+cmd)
        print(df_tmp)
    else:
        # send data to api
        x = requests.post(args.apiurl+"/api/", auth=(config.get("Auth", "user"), config.get("Auth", "password")), data = d, verify=verify)
        print(x.text)

        # Get request to update the index
        params={}
        params["from"] = startdate
        params["to"] = enddate
        if args.force:
            params["force"] = True
        else:
            params["force"] = False
        x = requests.get(args.apiurl+"/api/index/", auth=(config.get("Auth", "user"), config.get("Auth", "password")), params=params, verify=verify)
        print(x.text)       
