# Generate and upload of test data  
Install the packages listed in requirements.txt with `pip install -r requirements.txt`.  
Optional: generate test jobs for -n days from today with `./SlurmDashboard_generate_test_data.py`  
Upload test data, run on the host, this will try to upload to the localhost, see --help for further info:  
`./SlurmDashboard_send_data.py --clusterid slurm1 --nodesfile ./nodes.template --jobsfile ./jobs.out --skipsslverification`  
Note: If the default test data is used, this data was generated from 2022-07 to 2023-08  
