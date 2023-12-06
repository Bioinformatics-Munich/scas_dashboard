from django.db import models
from datetime import time
from django.conf import settings

class Settings(models.Model):
    name=models.CharField(max_length=150, unique=True)
    value=models.CharField(max_length=1500)
    description=models.CharField(max_length=350)
    def __str__(self):
        return str(self.name)
    class Meta:
        verbose_name = 'Settings'
        verbose_name_plural = 'Settings'


class YMDdata(models.Model):
    YMD=models.CharField(max_length=25, unique=True)
    jobscounts=models.IntegerField()
    data=models.JSONField()
    # Create a string representation
    def __str__(self):
        return str(self.YMD)
    class Meta:
        verbose_name = 'YMDdata'
        verbose_name_plural = 'YMDdata'

class ParamExcludePartition(models.Model):
    pname=models.CharField(max_length=150, unique=True)
    def __str__(self):
        return str(self.pname)
    class Meta:
        verbose_name = 'ExcludePartition'
        verbose_name_plural = 'ExcludePartition'

class Nodes(models.Model):
    HOSTNAME=models.CharField(max_length=100)
    CPUS=models.IntegerField()
    MEMORY=models.IntegerField()
    GRES=models.CharField(max_length=100,blank = True)
    GPUS=models.IntegerField()
    cluster_id=models.CharField(max_length=25)

    @classmethod
    def create(cls, data):
        node = cls()
        # set regular fields
        for field, value in data.items():
            setattr(node, field, value)
        """
        Format the raw data and set the additional fields
        """
        # set GPUs
        if node.GRES:
            d = dict(x.split(":",1) for x in node.GRES.split(","))
            # Also check if we need to split the keys could be gpu:a100_3g.20gb:4(S:0-1) or gpu:2(S:0-1),mps:1K(S:0-1)
            # print(d)
            d2={}
            for dk in d:
                d2[dk.split(":")[0]]=d[dk]
            if 'gpu' in d2:
                # can be 2, 2(S:0-1) or a100_3g.20gb:4(S:0-1)
                # split first on : 
                sp = d2['gpu'].split(":")
                if len(sp) > 2:
                    ngpus = sp[1].split("(",1)[0]
                else:
                    ngpus = sp[0].split("(",1)[0]
                node.GPUS = int(ngpus)
            else:
                node.GPUS = 0
        else:
            node.GPUS = 0
        return(node)

    # Create a string representation
    def __str__(self):
        return str(self.HOSTNAME)
    class Meta:
        verbose_name = 'Nodes'
        verbose_name_plural = 'Nodes'

class Jobs(models.Model):
    # as inputs, we use the output as it is from the sacct command
    # fields that needs reformatting are added in the save function
    created_date = models.DateTimeField(auto_now_add=True)
    cluster_id=models.CharField(max_length=25)
    JobIDRaw=models.IntegerField()
    Account=models.CharField(max_length=25)
    User=models.CharField(max_length=50)
    State=models.CharField(max_length=50)
    Partition=models.CharField(max_length=25)
    ReqCPUS=models.IntegerField()
    ReqMem=models.CharField(max_length=25)
    Timelimit=models.CharField(max_length=25)
    Submit=models.DateTimeField()
    Start=models.DateTimeField()
    End=models.DateTimeField()
    NodeList=models.CharField(max_length=3000)
    ReqTRES=models.CharField(max_length=3000)
    ReqGPUS=models.IntegerField()
    Node=models.CharField(max_length=50)
    Reason=models.CharField(max_length=250,default="None")
    Qtime=models.IntegerField()
    Runtime=models.IntegerField()
    CPUhours=models.FloatField()
    GPUhours=models.FloatField()
    ReqMemTotal=models.FloatField()
    JobYM=models.CharField(max_length=10)
    JobYMD=models.CharField(max_length=10)
    JobD=models.CharField(max_length=10)
    MemCat=models.CharField(max_length=10)
    CPUCat=models.CharField(max_length=10)
    GPUCat=models.CharField(max_length=10)

    class Meta:
        unique_together = (("cluster_id","JobIDRaw"),)
        verbose_name = 'Jobs'
        verbose_name_plural = 'Jobs'

    @classmethod
    def create(cls, data):
        job = cls()
        # set regular fields
        for field, value in data.items():
            setattr(job, field, value)
        """
        Format the raw data and set the additional fields
        """
        # Select only one node for Node field
        # node[02,13-14]
        # node[05,07,09,11,14,19,26]
        # node[06-07,16,21]
        # rm [] from string
        nodestring = job.NodeList.replace('[', '')
        nodestring = nodestring.replace(']', '')
        nodestring = nodestring.split(",")[0]
        nodestring = nodestring.split("-")[0]
        job.Node = nodestring
        

        # Format ReqGPUS
        d = dict(x.split("=") for x in job.ReqTRES.split(","))
        if 'gres/gpu' in d:
            job.ReqGPUS = int(d['gres/gpu'])
        else:
            job.ReqGPUS = 0

        # Get total memory, is available from the mem= in ReqTRES
        if "mem" in d:
            job.ReqMemTotal = float(d['mem'].replace('G', ''))
        else:
            job.ReqMemTotal = float(0)

        # Calculate qtime : time until job started
        tdelta = job.Start - job.Submit
        job.Qtime = round(tdelta.total_seconds()/60)

        # Caclulate Runtime in minutes
        tdeltarun = job.End - job.Start
        job.Runtime = round(tdeltarun.total_seconds()/60)

        # Calculate CPUhours and GPUhours
        job.CPUhours = (job.Runtime * job.ReqCPUS) / 60
        job.GPUhours = (job.Runtime * job.ReqGPUS) / 60

        # Dates
        job.JobYM=job.Start.strftime("%Y-%m")
        job.JobYMD=job.Start.strftime("%Y-%m-%d")
        job.JobD=job.Start.strftime("%d")

        # Categories
        if job.ReqMemTotal <= 10:
            job.MemCat="<=10GB"
        if job.ReqMemTotal > 10:
            job.MemCat="10-50GB"
        if job.ReqMemTotal > 50:
            job.MemCat=">50GB"

        if job.ReqCPUS == 1:
            job.CPUCat="1CPU"
        if job.ReqCPUS > 1:
            job.CPUCat="2-10CPUs"
        if job.ReqCPUS > 10:
            job.CPUCat=">10CPUs"

        job.GPUCat="none"
        if job.ReqGPUS == 1:
            job.GPUCat="1GPU"
        if job.ReqGPUS > 1:
            job.GPUCat="2-10GPUs"
        if job.ReqGPUS > 10:
            job.GPUCat=">10GPUs"

        return(job)
        #super(Jobs, self).save(*args, **kwargs)

    # Create a string representation
    def __str__(self):
        return str(self.JobIDRaw)
