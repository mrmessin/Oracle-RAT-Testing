###################################################################################
# dba_rat_capture.sh
#
# Parameters:     Instance Name
#                 duration of capture   (defaults to 900 seconds)
#
# Example: /u01/app/oracle/scripts/dba_rat_capture.sh ariesq1 3600
#
# Description: Process that will create the directories, execute a
#              Real Application Testing Capture
#              Generate Capture Report and extract AWR from Capture
#
# Requirements: Shared directory location for capture files
#               permissions to shared directory to create new
#               directory and write capture files from oracle database
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

# assign duration of catpture to passed value
export duration=$2

# Check if we got a value for duration if not default to 15 minutes (900 seconds)
# Value is in seconds
if [ -z "${duration}" ]; then
   echo "User did not pass duration setting to default 15 minutes (900 seconds)"
   export duration=900
fi

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
export LOGFILE=${INST_LOWER}_dba_rat_capture_${DTE}.log
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

# Set the RAT Capture Info
export capture_name=`echo "${ORACLE_SID}_CAP_${DTE}" | awk '{print toupper($0)}'`
export directory_name=CAPDIR_${capture_name}
export directory_location=${RAT_BASE}/capture/${directory_name}

echo "Process Using RAT Capture Name -> ${capture_name}"
echo "Process Using RAT Capture Name -> ${capture_name}" >> ${LOG}
echo "Process Using RAT Capture Directory Name -> ${directory_name}"
echo "Process Using RAT Capture Directory Name -> ${directory_name}" >> ${LOG}
echo "Process Using Directory Location -> ${directory_location}"
echo "Process Using Directory Location -> ${directory_location}" >> ${LOG}
echo "Doing Capture for ${duration} seconds"
echo "Doing Capture for ${duration} seconds" >> ${LOG}

echo "--"
echo "--" >> ${LOG}
echo "Making the directory Location -> ${directory_location}"
echo "Making the directory Location -> ${directory_location}" >> ${LOG}
# Make the directory for the capture to keep them separated
mkdir ${directory_location}

echo "--"
echo "--" >> ${LOG}
echo "Executing the Capture for ${duration} seconds."
echo "Executing the Capture for ${duration} seconds." >> ${LOG}
# Start the Capture
sqlplus -s / as sysdba << EOF >> ${LOG}
set timing on
set echo on
CREATE DIRECTORY ${directory_name} as '${directory_location}' ;
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user dbsnmp', 'USER', 'DBSNMP');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user sysman', 'USER', 'SYSMAN');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user sys', 'USER', 'SYS');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user system', 'USER', 'SYSTEM');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user avdba', 'USER', 'AVDBA');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user sysrac', 'USER', 'SYSRAC');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user infosec', 'USER', 'INFOSEC');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user infosec1', 'USER', 'INFOSEC1');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user infouser', 'USER', 'INFOUSER');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user rdba', 'USER', 'RDBA');
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user audsys', 'USER', 'AUDSYS') ;
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user sysdg', 'USER', 'SYSDG') ;
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user syskm', 'USER', 'SYSKM') ;
EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user wmsys', 'USER', 'WMSYS') ;
EXEC DBMS_WORKLOAD_CAPTURE.START_CAPTURE(name=>'${capture_name}', dir=>'${directory_name}', duration=>${duration}, default_action=>'INCLUDE');
exit;
EOF
#EXEC DBMS_WORKLOAD_CAPTURE.ADD_FILTER ('filter user gg', 'USER', 'GG');

echo "Capture Start Complete waiting for addition time for Capture to Close ${duration} seconds......"
echo "Capture Start Complete waiting for addition time for Capture to Close ${duration} seconds......" >> ${LOG}
# wait the duration of the capture
sleep ${duration}

# Now sleep an additional 3 minutes to allow capture to show complete.
sleep 180

echo "Capture Time Completed."
echo "Capture Time Completed." >> ${LOG}

#echo "Taking Post Capture Snapshot to Ensure we Have an End Snapshot........."
#echo "Taking Post Capture Snapshot to Ensure we Have an End Snapshot........." >> ${LOG}
#sqlplus -s / as sysdba << EOF >> ${LOG}
#set timing on
#set echo on
#EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;
#exit;
#EOF

echo "--"
echo "--" >> ${LOG}
echo "Generating Capture Report to file -> ${directory_location}/${capture_name}_CaptureReport.html"
echo "Generating Capture Report to file -> ${directory_location}/${capture_name}_CaptureReport.html" >> ${LOG}

# now that capture is complete generate a capture report
sqlplus -s / as sysdba << EOF
-- execute capture report
-- Capture Report
DECLARE
   cap_id NUMBER;
   cap_rpt CLOB;
   buffer VARCHAR2(32767);
   buffer_size CONSTANT BINARY_INTEGER := 32767;
   amount BINARY_INTEGER;
   offset NUMBER(38);
   file_handle UTL_FILE.FILE_TYPE;
   v_filename CONSTANT VARCHAR2(80) := '${capture_name}_CaptureReport.html';
   directory_name   VARCHAR2(128) ;

BEGIN
   SELECT id, DIRECTORY
   INTO cap_id,
        directory_name 
   FROM dba_workload_captures
   where name = '${capture_name}'
     and status = 'COMPLETED' ;

   cap_rpt := DBMS_WORKLOAD_CAPTURE.REPORT(capture_id => cap_id, format =>   DBMS_WORKLOAD_CAPTURE.TYPE_HTML);

   -- Write Report to file
   DBMS_OUTPUT.ENABLE(1000000);

   -- --------------------------------
   -- OPEN NEW XML FILE IN WRITE MODE
   -- --------------------------------
   file_handle := UTL_FILE.FOPEN(location => directory_name,
filename => v_filename,
open_mode => 'w',
max_linesize => buffer_size);
amount := buffer_size;
offset := 1;

   WHILE amount >= buffer_size
   LOOP
      DBMS_LOB.READ(lob_loc => cap_rpt, amount => amount, offset => offset,
buffer => buffer);

      offset := offset + amount;

      UTL_FILE.PUT(file => file_handle, buffer => buffer);
      UTL_FILE.FFLUSH(file => file_handle);
   END LOOP;

   UTL_FILE.FCLOSE(file => file_handle);
   
END;
/
exit ;
EOF

echo "--"
echo "--" >> ${LOG}
echo "Extracting AWR for Capture to file -> ${directory_location}/cap/wcr_ca.dmp"
echo "Log File for Extracting AWR for Capture to file -> ${directory_location}/cap/wcr_ca.log"
echo "Extracting AWR for Capture to file -> ${directory_location}/cap/wcr_ca.dmp" >> ${LOG}
echo "Log File for Extracting AWR for Capture to file -> ${directory_location}/cap/wcr_ca.log" >> ${LOG}

# Extract the AWR for the Capture   
sqlplus -s / as sysdba << EOF
set timing on
set echo on
DECLARE
   cap_id NUMBER;
   directory_name   VARCHAR2(128) ;

BEGIN
   SELECT id, DIRECTORY
   INTO cap_id,
        directory_name 
   FROM dba_workload_captures
   where name = '${capture_name}' 
     and status = 'COMPLETED' ;

   -- Extract the AWR for the Capture
   DBMS_WORKLOAD_CAPTURE.EXPORT_AWR (capture_id => cap_id);     
END ;
/
exit ;
EOF

echo "--"
echo "--" >> ${LOG}
echo "RAT Workload Capture Completed."
echo "RAT Workload Capture Completed." >> ${LOG}

exit 0
# DBMS_WORKLOAD_CAPTURE.EXPORT_AWR (capture_id => 2);
# retval : = DBMS_WORKLOAD_CAPTURE.IMPORT_AWR (capture_id => 2, staging_schema => 'schema', force_cleanup => TRUE)
# DBMS_WORKLOAD_CAPTURE.DELETE_CAPTURE_INFO (capture_id => 2);
