from django.contrib import admin
from .models import Jobs,YMDdata,ParamExcludePartition, Nodes, Settings
from django import forms

@admin.action(description="Delete all jobs, Nodes, and YMDdata")
def delete_all(modeladmin, request, queryset):
    Jobs.objects.all().delete()
    Nodes.objects.all().delete()
    YMDdata.objects.all().delete()
    # queryset.update(status="p")

class JobsAdmin(admin.ModelAdmin):
    list_display = (
        "JobIDRaw",
         "JobYM",
         "NodeList",
         "CPUhours",
         "cluster_id",
         "Reason",
    )
    search_fields = ['JobYM',"NodeList","cluster_id",]
    actions = [delete_all]

class YMDdataAdmin(admin.ModelAdmin):
    list_display = (
        "YMD",
         "jobscounts",
    )
    search_fields = ['YMD',"jobscounts",]

class NodesAdmin(admin.ModelAdmin):
    list_display = (
        "HOSTNAME",
         "CPUS",
         "MEMORY",
         "GRES",
         "GPUS",
         "cluster_id"

    )
    search_fields = ['HOSTNAME',"cluster_id",]

class SettingsAdmin(admin.ModelAdmin):
    list_display = ("name","value","description",
    )
    search_fields = ["name",]

# Register your models here.
admin.site.register(Jobs,JobsAdmin)
admin.site.register(YMDdata,YMDdataAdmin)
admin.site.register(Nodes, NodesAdmin)
admin.site.register(Settings, SettingsAdmin)

class MyModelForm(forms.ModelForm):
    pname = forms.ModelChoiceField(queryset=Jobs.objects.all().values_list('Partition', flat=True).distinct(), to_field_name='Partition')

class MyModelAdmin(admin.ModelAdmin):
    fields = ('pname',)
    list_display = ('pname',)
    form = MyModelForm

admin.site.register(ParamExcludePartition, MyModelAdmin)

