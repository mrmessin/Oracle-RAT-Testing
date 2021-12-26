set pagesize 1000
set linesize 100
select id, name, prepare_time, start_time, status from dba_workload_replays;

set pagesize 1000
set linesize 100
select id, name, dbname, dbversion, status, start_time, end_time, duration_secs, num_clients, SYNCHRONIZATION, ERROR_CODE, ERROR_MESSAGE, rac_mode from dba_workload_replays ;

