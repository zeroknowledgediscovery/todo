# PHNX Job Launcher

**About**
----
Program-agnostic slurm job launcher.
Launches supertasks within PHNX folder.

**Program requirements**
----
In order to be runnable via PHNX, the program calls should be packed together with all the data and executables required for run into a single folder called `PAYLOAD`.

Every `PAYLOAD` should contain  :
* `bin` - folder containing all the executables to be executed during the supertask
* `program_calls.txt`  - list of program calls to run, each line contains one call
* `dependencies.txt`  - list of program dependencies to install
* `running_config.txt`  - list of Midway running parameters :
	* `USER`  - your midway username
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
Copy the PHNX folder to the directory from which you intend to run the tasks.

Get PAYLOAD folder ready (also see `SAMPLE_PAYLOAD` and `TERROR_PAYLOAD` for an examples)

In PHNX folder, run:
`./phnx.sh [SUPERTASK_NAME] [FULL_PAYLOAD_PATH]`

The standard and error outputs are saved at `PHNX/SUPERTASK_NAME/phnx.out` and `PHNX/SUPERTASK_NAME/phnx.out`

The program results are saved at `PAYLOAD` folder.

**To resume:**
----
In PHNX folder, run:
`./phnx.sh [SUPERTASK_NAME] [FULL_PAYLOAD_PATH]`


**TERROR example:**
----
Load `TERROR_PAYLOAD` on your instance;

Load `PHNX` folder on your instance, cd to it;

Run `./phnx.sh TERROR [full_path_to_payload_folder]`

**Script descriptions**
----

* **phnx.sh**
Initialize the supertask folder, convert all program calls into slurm .sbc scripts (enriched with slurm running configs, dependencies);
Run `iterator.sh`;

* **iterator.sh**
Until all jobs are complete or have erred, run `supertask_run.sh` with specified interval;
*  **supertask_run.sh**
Update information on completed, erred running and toso tasks;
Launch a specified number of tasks using `run_tasks.sh` if there are todo tasks and vacant spot is available;
*  **run_tasks.sh**
Using `sbatch` command, launch a specified number of jobs on the cluster;

