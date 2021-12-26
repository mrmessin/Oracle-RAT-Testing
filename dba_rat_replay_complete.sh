###################################################################################
# dba_rat_replay_complete.sh
#
# Parameters:     Instance Name
#
# Example: /u01/app/oracle/scripts/dba_rat_replay_complete.sh ariesq1 
#
# Description: Process that will generate report and extract AWR from
#              Last completed Real Application Testing Replay
#
# Requirements: Shared directory location for Replay files
#               Completed Replay 
#`
#####################################################################
#
# Set the environment for the oracle account
. /home/oracle/.bash_profile

# Check if the environment variables were passed
if (( $# < 1 ));then
  echo "Wrong number of arguments, $*, passed to dba_rat_capture.sh, must pass database name."
  exit 8
fi

#
# assign ORACLE_SID to passed SID
export ORACLE_SID=$1

# Get locations
export SCRIPTLOC=`dirname $0`
export SCRIPTDIR=`basename $0`

# assign a date we can use as part of the logfile
export DTE=`/bin/date +%m%d%C%y%H%M`

# set date format for rman log files
export NLS_DATE_FORMAT="dd-mon-yy hh24:mi:ss"

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
export LOGFILE=${INST_LOWER}_dba_rat_replay_complete_${DTE}.log
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

# Set the RAT BASE Directory where Capture and Replay directories exist
export RAT_BASE=/zfssa/oracle_export

echo "Executing Replay Report for Most Recent Completed Replay...."
echo "Executing Replay Report for Most Recent Completed Replay...." >> ${LOG}
sqlplus -s / as sysdba << EOF >> ${LOG}
set serveroutput on size 1000000
set linesize 200
--
-- Replay Report
DECLARE
  cap_id         NUMBER;
  rep_id         NUMBER;
  rep_rpt        CLOB;
  buffer            VARCHAR2(32767);
  buffer_size       CONSTANT BINARY_INTEGER := 32767;
  amount            BINARY_INTEGER;
  offset            NUMBER(38);

  file_handle       UTL_FILE.FILE_TYPE;
  directory_name    VARCHAR2(256) ;
  v_replay_name     VARCHAR2(128) ;
  v_filename        VARCHAR2(128) ;
  v_directory_location  VARCHAR2(256) ;

BEGIN
   select max(id) 
   into rep_id
   from dba_workload_replays
   where status = 'COMPLETED' ;

   select name, directory, dir_path
   into v_replay_name, directory_name, v_directory_location
   from dba_workload_replays
   where id = rep_id ;

   -- Set the filename for the replay report 
   v_filename := v_replay_name || '_ReplayReport.html';
 
   rep_rpt := DBMS_WORKLOAD_REPLAY.REPORT(replay_id => rep_id,
                                          format => DBMS_WORKLOAD_REPLAY.TYPE_HTML);


   DBMS_OUTPUT.PUT_LINE ('RAT Replay Report -> ' || v_directory_location || '/' || v_filename) ;

   -- Write Report to file 
   DBMS_OUTPUT.ENABLE(100000);

   -- --------------------------------
   -- OPEN NEW XML FILE IN WRITE MODE
   -- --------------------------------
   file_handle := UTL_FILE.FOPEN(
       location     => directory_name,
       filename     => v_filename,
       open_mode    => 'w',
       max_linesize => buffer_size);

   amount := buffer_size;
   offset := 1;

    WHILE amount >= buffer_size
    LOOP

        DBMS_LOB.READ(
            lob_loc    => rep_rpt,
            amount     => amount,
            offset     => offset,
            buffer     => buffer);

        offset := offset + amount;

        UTL_FILE.PUT(
            file      => file_handle,
            buffer    => buffer);

        UTL_FILE.FFLUSH(file => file_handle);

    END LOOP;

    UTL_FILE.FCLOSE(file => file_handle);

END;
/
EOF

echo "Executing extract of AWR for Most Recent Completed Replay...."
echo "Executing extract of AWR for Most Recent Completed Replay...." >> ${LOG}
# Extract the AWR for the Replay
sqlplus -s / as sysdba << EOF >> ${LOG}
set severoutput on size 1000000
set linesize 200
DECLARE
  cap_id         NUMBER;
  rep_id         NUMBER;
  v_directory_location  VARCHAR2(256) ;
  v_replay_dir_number   VARCHAR2(256) ;

BEGIN
   select max(id) 
   into rep_id
   from dba_workload_replays
   where status = 'COMPLETED' ;

   select dir_path, REPLAY_DIR_NUMBER
   into v_directory_location, v_replay_dir_number
   from dba_workload_replays
   where id = rep_id ;

   DBMS_OUTPUT.PUT_LINE('Exporting AWR Data to -> ' || v_directory_location || '/rep' || '/wcr_ra_' || v_replay_dir_number || '.dmp') ;
   DBMS_OUTPUT.PUT_LINE('Logfile for AWR Export is -> ' || v_directory_location || '/rep' || '/wcr_ra_' || v_replay_dir_number || '.log') ;
   DBMS_WORKLOAD_REPLAY.EXPORT_AWR (replay_id => rep_id);
END ;
/
EOF

exit 0
