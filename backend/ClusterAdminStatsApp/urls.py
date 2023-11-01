"""ClusterAdminStatsApp URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from . import views
from rest_framework.urlpatterns import format_suffix_patterns
from django.urls import path
from rest_framework.schemas import get_schema_view
from django.urls import include

from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
   openapi.Info(
      title="SCAS API",
      default_version='v1',
      description="SCAS dashboard API",
      terms_of_service="",
      contact=openapi.Contact(email=""),
      license=openapi.License(name="MIT License"),
   ),
   public=True,
   permission_classes=[permissions.AllowAny],
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', views.JobsList),
    path('api/<int:pk>/', views.JobsDetail.as_view()),
    path('api/partitions/', views.PartitionList),
    path('api/clusters/', views.ClusterList),    
    path('api/nodes/', views.NodesList),
    path('api/index/', views.Index),
    path("pubdash/", views.publicdash),
    path("docs/", schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]

urlpatterns = format_suffix_patterns(urlpatterns)
