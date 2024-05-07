---
title: 'SCAS dashboard: A tool to intuitively and interactively analyze Slurm cluster usage'

tags:
  - Slurm
  - HPC
  - dashboard
  - python
  - R
  - shiny
  - containers

authors:
  - name: Thomas Walzthoeni
    affiliation: 1
    corresponding: true
    orcid: 0009-0009-3995-709X
  - name: Bom Bahadur Singiali
    affiliation: 2
  - name: N. William Rayner
    affiliation: 3
    orcid: 0000-0003-0510-4792
  - name: Francesco Paolo Casale
    affiliation: "4,5,6"
  - name: Christoph Feest
    affiliation: "4,7"	
    orcid: 0000-0002-0772-7267
  - name: Carsten Marr
    affiliation: 4
    orcid: 0000-0003-2154-4552
  - name: Alf Wachsmann
    affiliation: 2
    orcid: 0000-0002-7736-3059

affiliations:
 - name: Core Facility Genomics, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 1
 - name: Digital Transformation & IT, Helmholtz Munich, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 2
 - name: Institute of Translational Genomics, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 3
 - name: Computational Health Center, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 4
 - name: Helmholtz Pioneer Campus, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 5
 - name: School of Computation, Information and Technology, Technical University of Munich, Munich, Germany
   index: 6 
 - name: Helmholtz AI, Helmholtz Zentrum München - German Research Center for Environmental Health, 85764 Neuherberg, Germany
   index: 7 
   
date: 30 August 2023
bibliography: paper.bib
---
# Summary

Many organizations offer High Performance Computing (HPC) environments
as a service, hosted on-premises or in the cloud. Compute jobs are
commonly managed via Slurm [@slurm], but an intuitive, easy-to-use
and interactive visualization has been lacking. To fill this gap, we
developed a Slurm Cluster Admin Statistics (SCAS) dashboard. SCAS
provides a means to analyze and visualize data of compute jobs and
includes a feature to generate presentations for cluster users. It thus
allows HPC stakeholders to easily analyze and identify bottlenecks of
Slurm-based compute clusters in a timely fashion and provides
decision-making support for managing cluster resources.

# Statement of need

Slurm [@slurm] is an open-source cluster management and job
scheduling system for Linux-based compute clusters and is widely used
for High Performance Computing (HPC). It offers command line tools to
export and analyze cluster use and various applications have been
developed to monitor the current state of the cluster (e.g. live
dashboards using Grafana [@grafanadb]). A feature rich tool for the
analysis of cluster performance is Open XDMoD [@xdmod] that supports
various schedulers and metrics. Open XDMoD uses 3^rd^ party software
libraries that are not free for commercial use. Open OnDemand
[@Hudak2018] allows users to access a HPC cluster using a web portal,
it provides various apps to facilitate HPC usage and can integrate the
Open XDMoD for usage statistics. Both, Open XDMoD and Open OnDemand
require continuous support and extensive configurations and therefore,
intuitive, responsive, easy-to-install and easy-to-use applications that
enable HPC administrators and managers to analyze and visualize cluster
usage in detail and over time are highly complementary. This information
is crucial to identify bottlenecks in compute clusters and make informed
strategic decisions regarding their future development.

To address this, we developed the Slurm Cluster Admin Statistics (SCAS)
dashboard, a scalable and flexible dashboard application to analyze
completed compute jobs on a Slurm-based cluster. The dashboard offers
various statistics, visualizations, and insights to HPC stakeholders and
cluster users. Additionally, we engineered the software to have a
low-memory footprint and to be fast and responsive to user queries. The
software stack is provided in an easy-to-use and easy-to-deploy manner
using docker containers and a docker-compose implementation.

# Description

## SCAS Dashboard overview

The SCAS dashboard architecture consists of a nginx web server as a
router (reverse proxy), a frontend based on R-Shiny [@shiny; @R;
@shinydashboard], a backend based on Python using the Django REST
framework to provide an API, and a PostgreSQL database as backend (see
\autoref{fig:fig1}). The dashboard is intended for the HPC stakeholders
and therefore includes secure user authentication. The frontend is a
user-friendly interface for filtering and visualizing the Slurm data.
The backend provides an admin interface via Python Django Admin and a
web API that is used by both the frontend and a script for uploading new
data. Additionally, the backend creates a daily index of the data,
enabling the software to maintain a low memory footprint while being
fast and responsive. Furthermore, a presentation can be generated
automatically and viewed by various stakeholders, including the cluster
users, via a web browser.

![Architecture of the SCAS dashboard. The dashboard and the
presentation are accessed by the user through a web browser. New data
can be uploaded to the SCAS dashboard by executing a script that
regularly fetches the latest data from a job submission node. On the
server side, the architecture is organized into separate components
(shown in dashed box): nginx (reverse proxy), SCAS-frontend,
SCAS-backend and PostgresSQL database. A docker-compose implementation
of the services is provided. \label{fig:fig1}](figures/Figure1.png){
width=100% }

## SCAS dashboard workflow

Completed compute jobs and available node configurations are submitted
to the SCAS-backend API with a script that utilizes the Slurm's *sacct*
tool. This script can be run as a daily or weekly *cron* job on a job
submission node. The backend then generates the daily statistics that
are stored in the database. This preprocessed indexed data enables the
app to have a low memory footprint and high responsiveness, as no
calculations are required when the data is fetched from the API. Upon
filtering a date range in the frontend, a request is sent to the backend
which retrieves the data for the selected days and aggregates the
statistics to generate the visualizations.

## Frontend -- dashboard user interface

\autoref{fig:fig2} displays some example views of the user interface.
The date range, the cluster, and the partitions that should be analyzed
can be selected from the menu (\hyperref[fig:fig2]{Figure 2a}). Data
tables and visualizations are then updated accordingly and displayed to
the user.

For the selected date range, the visualizations include:

-   Number of jobs, CPU and GPU hours per month
    (\hyperref[fig:fig2]{Figure 2b,c})

-   Memory and cores requested by users, displayed as contingency graphs

-   Average job pending and runtimes per month and per day
    (\hyperref[fig:fig2]{Figure 2d,e,f})

-   Distribution of CPU hours used vs. the percentage of users

-   Total cluster utilization per day and per month, individual node
    utilization per month, summaries of utilization per CPU/GPU or
    memory type of the nodes per month (\hyperref[fig:fig2]{Figure
    2g})

The data can also be downloaded for use in spreadsheet applications.

## Frontend -- automated presentation

For presenting key figures to the cluster users, a feature is available
to generate a browser-based presentation in carousel mode. The
presentation is auto-updated and customization settings are available
via the admin interface.

## SCAS dashboard - example use case

To exemplify an analysis with the SCAS dashboard, we assumed that users
reported longer pending times for GPU resources in recent months. We
have simulated this case by increasing the number of GPU jobs (and their
pending times) for GPU servers, with 16 GPUs, over a time frame of 1
year. As shown in \hyperref[fig:fig2]{Figure 2b,c}, the increase in
the number of GPU jobs and CPU hours for the GPU partition is visible
and confirms the assumption. By inspecting the pending times per day
(\hyperref[fig:fig2]{Figure 2d}) there is a general, unbiased
increase of the pending times visible for the last few months. From
\hyperref[fig:fig2]{Figure 2e} we can then see an increase of the
pending times for the GPU partition for the previous 6 months.
\hyperref[fig:fig2]{Figure 2f} shows that the increase of the pending
times is only seen for servers with >10 GPUs, and the utilization of
the nodes with 16 GPUs has increased while those with 2 and 4 GPUs were
stable (\hyperref[fig:fig2]{Figure 2g}). This analysis can be used to
draw concrete conclusions. In this case to either inform the users that
resources are available if up to 4 GPUs are requested, or to make the
decision to invest in new GPU servers to achieve shorter pending times
and higher throughput.

![ **a**. User interface of the SCAS Dashboard featuring navigation
and the selection menu. The central panel displays statistics and
graphics. **b**. Line plot showing the jobs run per month.
**c**. Line plot showing the GPU hours per month. **d**. Heatmap
plot showing the average daily pending times of the jobs. **e**.
Line plot with the average jobs pending times per month. The positive
error bars indicate the standard deviation. **f**. Line plot with
the average jobs pending times per month separated by GPU categories.
The positive error bars indicate the standard deviation. **g**. Line
plot showing the utilization of nodes with different numbers of GPUs.
\label{fig:fig2}](figures/Figure2.png){ width=100% }

# Conclusion and Availability

The SCAS dashboard enables rapid and responsive analysis of Slurm-based
cluster usage. This allows stakeholders: I) to identify current
bottlenecks of CPU and GPU utilization, II) to make informed decisions
to adapt SLURM parameters in the short term and III) to support
strategic decisions, all based on user needs. The SCAS dashboard, code,
and the documentation are hosted on a publicly available GitHub
repository (<https://github.com/Bioinformatics-Munich/scas_dashboard>).
The repository also contains a docker-compose file for rapid deployment
and testing of the software, as well as a program to generate test data
for the dashboard.

# Acknowledgements

We acknowledge the Institute of Computational Biology (Prof. Dr. Dr.
Fabian Theis) at Helmholtz Munich for supporting the development of the
software. We thank Dr. Bastian Rieck, Helmholtz Munich, for valuable
contributions and comments to the manuscript.

# References
