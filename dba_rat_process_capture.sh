###################################################################################
# dba_rat_process_capture.sh
#
# Parameters:     instance for Replay
#                 REPLAY NAME
#                 Directory location of Capture to Prepare
#
# Example: /u01/app/oracle/scripts/dba_rat_process_capture.sh aries1 /zfssa/oracle_export/capture/mycapture
#`
# Description:
# Process will take instance name for instance that will do replay then take
# the replay name append datetime then location of the capture to be repared for replay
# the process will make a copy of the capture to a replay location for processing 
# create a replay directory for the replay then process the capture
#
# Requirements: Access to the directory location of the capture
#               Access to location to create directory for Replay
#               
####################################################################################
#
# Set the environment for the oracle account
. /home/oracle/.bash_profile

# Check if the environment variables were passed
if (( $# < 2 ));then
  echo "Wrong number of arguments, $*, passed to dba_rat_process_capture.sh, must pass instance name, directory location of Capture."
  exit 8
fi

#
# assign ORACLE_SID to passed SID
export ORACLE_SID=$1

# Location of the capture
export capture_dir=$2

# Get locations
export SCRIPTLOC=`dirname $0`
export SCRIPTDIR=`basename $0`
export GOBACK=`pwd`

# assign a date we can use as part of the logfile
export DTELOG=`/bin/date +%m%d%C%y%H%M`
export DTE=`/bin/date +%m%d%C%y`

# set date format for rman log files
export NLS_DATE_FORMAT="dd-mon-yyyy hh24:mi:ss"

# Get the Upper hostname so we can use in in our logfile path
export HOST_LOWER=`hostname -s | awk '{print tolower($0)}'`

# Set Upper case of passed SID so we can be sure of
# proper backup directory in case SID is passed as lowercase
export INST_UPPER=`echo $ORACLE_SID | awk '{print toupper($0)}'`

# Set lower case of passed SID so we can be sure of
# proper backup file names in case SID is passed as uppercase
export INST_LOWER=`echo $ORACLE_SID | awk '{print tolower($0)}'`

# Set the logfile directory
export LOGPATH=${SCRIPTLOC}/logs
export LOGFILE=${INST_LOWER}_dba_rat_process_capture_${DTELOG}.log
export LOG=$LOGPATH/$LOGFILE

# Lets set the ORACLE_HOME Based on the oratab setting
# for the instance passed
export ORACLE_HOME=`/usr/local/bin/dbhome $ORACLE_SID`

# Set the rest of the Oracle Environment
# based on our ORACLE_HOME
export LIBPATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
#export ORA_NLS10=$ORACLE_HOME/nls/data

# Set our PATH with the ORACLE_HOME so that we have a good
# clean environment to work with
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:.:/bin:/usr/bin:/etc:/usr/local/bin:/usr/sbin:/usr/ucb:$HOME/bin:/usr/bin/X11:/sbin

export replay_name=`echo "${ORACLE_SID}_R_${DTE}" | awk '{print toupper($0)}'`
export directory_name=${replay_name}
export directory_location=/zfssa/oracle_export/replay/${directory_name}

echo "Starting the Real Application Testing Capture Processing......."
echo "--"
echo "Process Capture from ${capture_dir}" >> ${LOG}
echo "Process Capture from ${capture_dir}" 
echo "Using Replay Directory Name ${directory_name}" >> ${LOG}
echo "Using Replay Directory Name ${directory_name}"
echo "Using Replay Directory Location ${directory_location}" >> ${LOG}
echo "Using Replay Directory Location ${directory_location}"

# Make the directory for the replay to keep them separated
mkdir ${directory_location}

echo "Making a Copy Of Capture to Replay Location ${directory_location}"
echo "Making a Copy Of Capture to Replay Location ${directory_location}" >> ${LOG}
# Copy the Capture to the replay location so we keep our caputure pure and untouched as a precaution
cp -r ${capture_dir}/* ${directory_location}

# Give World everything
echo "Making directory for Replay have world permissions"
echo "Making directory for Replay have world permissions" >> ${LOG}
chmod -R 777 ${directory_location}

echo "Processing Captured Workload copied to replay location ${directory_location}"
echo "Processing Captured Workload copied to replay location ${directory_location}" >> ${LOG}
######################################
# Process Capture In Replay Location
######################################
sqlplus -s / as sysdba << EOF >> ${LOG}
set serveroutput on size 1000000
set linesize 100
set timing on
set echo on

-----------------------------------------------------------------------------------------------------------
-- Create Directory
-----------------------------------------------------------------------------------------------------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE DIRECTORY ${directory_name} as ' || '''' || '${directory_location}' || '''' || ' ;') ;
set timing on
set feedback on

CREATE OR REPLACE DIRECTORY ${directory_name} as '${directory_location}' ;

set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('grant read, write on directory ${directory_name} to PUBLIC ;') ;
set timing on
set feedback on
grant read, write on directory ${directory_name} to PUBLIC ;

-----------------------------------------------------------------------------------------------------------
-- Turn on SQL Trace if needed to track down issue
-----------------------------------------------------------------------------------------------------------
-- Set Tracing on
--alter session set TRACEFILE_IDENTIFIER = 'RAT' ;
--alter session set max_dump_file_size=unlimited ;
--alter session set statistics_level=ALL ;
--alter session set events '10046 trace name context forever, level 12' ;

-----------------------------------------------------------------------------------------------------------
-- process captured workload
-----------------------------------------------------------------------------------------------------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('exec dbms_workload_replay.process_capture (' || '''' || '${directory_name}' || '''' || ',4) ;') ;
set timing on
set feedback on
exec dbms_workload_replay.process_capture ('${directory_name}',4) ;

-- show status of replay post processing
select id, name, status from dba_workload_replays ;

-----------------------------------------------------------------------------------------------------------
-- initialize replay
-----------------------------------------------------------------------------------------------------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('exec dbms_workload_replay.initialize_replay (' || '''' || '${replay_name}' || '''' || ',' || '''' || '${directory_name}' || '''' || ') ;') ;
set timing on
set feedback on
exec dbms_workload_replay.initialize_replay ('${replay_name}','${directory_name}') ;

-----------------------------------------------------------------------------------------------------------
-- If SQL Tracing was turned on Turn the tracing off
-----------------------------------------------------------------------------------------------------------
--ALTER SESSION SET EVENTS '10046 trace name context off';

-----------------------------------------------------------------------------------------------------------
-- Filter SQL statements from Replay
-----------------------------------------------------------------------------------------------------------
-- Filter any select SQL Statements
set feedback off
set timing off
exec dbms_output.put_line('Filtering out SQL Statements from Replay') ;
set timing on
set feedback on
-- skip on delete from work queue table
exec dbms_workload_replay.set_sql_mapping( sql_id => '2fav7ma47v9fq', operation => 'SKIP') ;
exec dbms_workload_replay.set_sql_mapping( sql_id => 'gvrbcf6agtz99', operation => 'SKIP') ; 
exec dbms_workload_replay.set_sql_mapping( sql_id => 'fsfbn0zbumrb8', operation => 'SKIP') ;

-- RCM SQL Ids to exclude
-- Query Tracking Id: [ed29cff8-5a54-43d8-8ab6-11424ab090c0] UPDATE COVERAGE SET RM270_ELIGIBILITY_HEADER_ID 
exec dbms_workload_replay.set_sql_mapping( sql_id => '7uhx7mm3hqwd8', operation => 'SKIP') ;

-- Query Tracking Id: [f045092a-13c9-4d44-bf6f-73ba32dc90da] UPDATE COVERAGE_PATIENT SET ACCOUNT_NUMBER 
exec dbms_workload_replay.set_sql_mapping( sql_id => '8r1rh08w2vthb', operation => 'SKIP') ;

-- Query Tracking Id: [f045092a-13c9-4d44-bf6f-73ba32dc90da] UPDATE COVERAGE_PATIENT SET ACCOUNT_NUMBER 
exec dbms_workload_replay.set_sql_mapping( sql_id => '1ptpb8dfaww4t', operation => 'SKIP') ;

-- Query Tracking Id: [10cf2280-0346-45d2-b692-fcc1e0f71471] MERGE INTO COVERAGE_SERVICE_TYPE 
exec dbms_workload_replay.set_sql_mapping( sql_id => '5b0baw68aw9p7', operation => 'SKIP') ;

-- Query Tracking Id: [15b3e0a8-83e0-4868-b8f3-0c3b31680a5c] INSERT INTO COVERAGE_PATIENT 
exec dbms_workload_replay.set_sql_mapping( sql_id => '7p7jx9mu232u8', operation => 'SKIP') ;
commit;

-----------------------------------------------------------------------------------------------------------
-- Remap Connections (Optional)
-----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- By default, all instances of replay_connection will be equal to NULL. When replay_connection is 
-- NULL (default), replay sessions will connect to the default host as determined by the replay 
-- client's runtime environment. Consequently, if no capture time connect strings are remapped, 
-- then all the replay sessions will simply connect to the default host to replay the workload.
----------------------------------------------------------------------------------------------------
-- Put any remap needed here before prepare of workload is done.
@${SCRIPTLOC}/dba_rat_replay_remap_connections.sql

-----------------------------------------------------------------------------------------------------------
-- prepare replay
-----------------------------------------------------------------------------------------------------------
-- scale_up_multiplier - x times each part of replay is executed concurrently
-- query_only - Only execute the read queries of the workload.
------------
-- SCN
------------
--set feedback off
--set timing off
--exec DBMS_OUTPUT.PUT_LINE('exec dbms_workload_replay.prepare_replay(synchronization=>' || '''' || 'SCN' || '''' || ',capture_sts=>FALSE' || ');') ;
--set timing on
--set feedback on
-- Capture STS must be FALSE for RAC
--exec dbms_workload_replay.prepare_replay(synchronization=>'SCN',capture_sts=>FALSE);
--exec dbms_workload_replay.prepare_replay(synchronization=>'SCN',capture_sts=>FALSE, query_only=TRUE);

------------
-- Time
------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('exec dbms_workload_replay.prepare_replay(synchronization=>' || '''' || 'TIME' || '''' || ',capture_sts=>FALSE' || ');') ;
set timing on
set feedback on
-- Capture STS must be FALSE for RAC
--exec dbms_workload_replay.prepare_replay(synchronization=>'TIME',capture_sts=>FALSE);
exec dbms_workload_replay.prepare_replay(synchronization=>FALSE,capture_sts=>FALSE, query_only=>TRUE);

-- Use for RAT Tests without any Sync, go fast eliminating timing in between calls
--set feedback off
--set timing off
--exec DBMS_OUTPUT.PUT_LINE('exec dbms_workload_replay.prepare_replay(synchronization=>FALSE) ;') ;
--set timing on
--set feedback on
--exec dbms_workload_replay.prepare_replay(synchronization=>FALSE) ;
--exec dbms_workload_replay.prepare_replay(synchronization=>FALSE, query_only=>TRUE) ;

select id, name, status from dba_workload_replays ;

-----------------------------------------------------------------------------------------------------------
-- set timing per oracle for replay
-----------------------------------------------------------------------------------------------------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('exec DBMS_WORKLOAD_REPLAY.SET_REPLAY_TIMEOUT (enabled => TRUE,min_delay => 10,max_delay => 11,delay_factor => 2);') ;
set timing on
set feedback on
exec DBMS_WORKLOAD_REPLAY.SET_REPLAY_TIMEOUT (enabled => TRUE,min_delay => 10,max_delay => 11,delay_factor => 2);

-----------------------------------------------------------------------------------------------------------
-- Advance Snapshots so replay and capture can not overlap
-----------------------------------------------------------------------------------------------------------
set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;') ;
set timing on
set feedback on
EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

set feedback off
set timing off
exec DBMS_OUTPUT.PUT_LINE('EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;') ;
set timing on
set feedback on
EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

----------------------------------------------------------------------------------------------------------
-- Import capture AWR into replay database
-----------------------------------------------------------------------------------------------------------
--select capture_id into v_capture_id from dba_workload_replays where status = 'PREPARE' ;
--select dbms_workload_capture.import_awr(v_capture_id,'AVDBA') from dual;
exit 
EOF

###########################
# Calibrate the workload
###########################
echo "Calibrating the workload Check logfile for calibrate details......."
echo "Calibrating the workload Check logfile for calibrate details......." >> ${LOG}
wrc mode=calibrate replaydir=${directory_location} >> ${LOG}

echo "Listing Hosts for Replay for RAC."
echo "Listing Hosts for Replay for RAC." >> ${LOG}
wrc mode=list_hosts replaydir=${directory_location} >> ${LOG}

echo "Process of Capture and prepare for Replay Completed"
echo "Process of Capture and prepare for Replay Completed" >> ${LOG}
echo "Processed Capture from ${capture_dir}" >> ${LOG}
echo "Processed Capture from ${capture_dir}" 
echo "Using Replay Directory Name ${directory_name}" >> ${LOG}
echo "Using Replay Directory Name ${directory_name}"
echo "Using Replay Directory Location ${directory_location}" >> ${LOG}
echo "Using Replay Directory Location ${directory_location}"
echo "Logfile of processing -> ${LOG}"
echo "Logfile of processing -> ${LOG}" >> ${LOG}

echo "--"
echo "--"
echo "At this point you are ready to execute the replay, spawn number of replay client across instances if RAC"
echo "At each instance in RAC substitute the instance name with the proper instance name between clients"
echo "wrc username/password@${ORACLE_SID} replaydir=${directory_location}"
echo "Then when all wrc clients are started at the number required execute Replay"
echo "Start Replay   -> exec DBMS_WORKLOAD_REPLAY.START_REPLAY ();"
echo "Monitor Replay -> select id, name, prepare_time, start_time, status from dba_workload_replays;" 
echo "Cancel Replay  -> exec DBMS_WORKLOAD_REPLAY.CANCEL_REPLAY ();" 
echo "Delete Replay  -> exec DBMS_WORKLOAD_REPLAY.DELETE_REPLAY_INFO(<replay#>') ; " 
echo "--" >> ${LOG}
echo "--" >> ${LOG}
echo "At this point you are ready to execute the replay, spawn number of replay client across instances if RAC" >> ${LOG}
echo "At each instance in RAC substitute the instance name with the proper instance name between clients" >> ${LOG}
echo "wrc username/password@${ORACLE_SID} replaydir=${directory_location}" >> ${LOG}
echo "Then when all wrc clients are started at the number required execute Replay" >> ${LOG}
echo "Start Replay   -> exec DBMS_WORKLOAD_REPLAY.START_REPLAY ();" >> ${LOG}
echo "Monitor Replay -> select id, name, prepare_time, start_time, status from dba_workload_replays;" >> ${LOG}
echo "Cancel Replay  -> exec DBMS_WORKLOAD_REPLAY.CANCEL_REPLAY ();" >> ${LOG}
echo "Delete Replay  -> exec DBMS_WORKLOAD_REPLAY.DELETE_REPLAY_INFO(<replay#>) ; " >> ${LOG}

exit 0
# select id, name, prepare_time, start_time, status from dba_workload_replays;
# exec DBMS_WORKLOAD_REPLAY.CANCEL_REPLAY ();
# DBMS_WORKLOAD_REPLAY.DELETE_REPLAY_INFO ();
