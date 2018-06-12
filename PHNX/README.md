# PHNX Job Launcher

**About**
----
Program-agnostic slurm job launcher.
Launches supertasks within PHNX folder.

**Program requirements**
----
In order to be runnable via PHNX, the program calls should be packed together with all the data required for run into a single folder called `PAYLOAD`.  All program calls should reference the data using absolute paths leading to `PAYLOAD`.

Every `PAYLOAD` should contain  :
* `program_calls.txt`  - list of program calls to run, each line contains one call
* `dependencies.txt`  - list of program dependencies to install
* `running_config.txt`  - list of slurm running parameters :
	* `USER`  - slurm user (ishanu)
	* `MAX_PARALLEL_JOBS`  - maximum amount of simultaneous job runs allowed
	* `INTERVAL` - interval between PHNX iterations, in seconds
	* `PARTITION`  - cluster's partition to run on
	* `RUNTIME`  - max runtime allowed before timeout
	* `QOS`  - quality-of-service value
	* `MEM`  - amount of memory to allocate
	* `NODES` - number of nodes to use
	* `TPC`  - number of threads to use

**To run:**
----
In PHNX folder, run:
`./initializer.sh [SUPERTASK_NAME] [PAYLOAD_PATH]`
also see `SAMPLE_PAYLOAD` for an example;

**Script descriptions**
----

* **initializer.sh**
Initialize the supertask folder, convert all program calls into slurm .sbc scripts (enriched with slurm running configs, dependencies);
Run `iterator.sh`;

* **iterator.sh**
Until all jobs are complete or have erred, run `supertask_run.sh` with specified interval;
*  **supertask_run.sh**
Update information on completed, erred running and toso tasks;
Launch a specified number of tasks using `run_tasks.sh` if there are todo tasks and vacant spot is available;
*  **run_tasks.sh**
Using `sbatch` command, launch a specified number of jobs on the cluster;

