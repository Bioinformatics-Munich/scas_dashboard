from rest_framework import serializers
from .models import Jobs,Nodes
import sys

# is used if the JobsSerializer is called with many=True
class JobListSerializer(serializers.ListSerializer):
    def create(self, validated_data):
        # create the objects / create will add the additional fields to the objects
        jobs = [Jobs.create(item) for item in validated_data]
        # bulk create in db
        return Jobs.objects.bulk_create(jobs)

class JobsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Jobs
        exclude = ('ReqGPUS','Node','Qtime','ReqMemTotal','JobYM','JobYMD','JobD','MemCat','CPUCat','GPUCat','CPUhours','GPUhours','Runtime','created_date',)
        list_serializer_class = JobListSerializer

class JobsSerializerAll(serializers.ModelSerializer):
    class Meta:
        model = Jobs
        exclude = ('created_date','JobIDRaw','Account','State','ReqTRES','ReqGPUS',)
        #exclude = ()

# is used if the NodeSerializer is called with many=True
class NodesListSerializer(serializers.ListSerializer):
    def create(self, validated_data):
        # create the objects / create will add the additional fields to the objects
        nodes = [Nodes.create(item) for item in validated_data]
        # bulk create in db
        return Nodes.objects.bulk_create(nodes)

class NodesSerializer(serializers.ModelSerializer):
    class Meta:
        model = Nodes
        exclude = ('GPUS',)
        list_serializer_class = NodesListSerializer

class NodesSerializerAll(serializers.ModelSerializer):
    class Meta:
        model = Nodes
        exclude = ('id',)
