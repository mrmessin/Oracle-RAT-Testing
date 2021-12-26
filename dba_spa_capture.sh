#--------------------------------------------------------------------------------------------------
#-- Script: dba_spa_capture.sh
#--
#-- Author: Michael Messina, Senior Managing Consultant
#-- Last Updated: 09/23/2020
#--
#-- Description: Process that will create a SQL Tuning Set to be used
#--              to assist with the measure of impact to SQL Statement for
#--              for environment changes such as OS, DB version and patches
#--              as well as prameter changes to the database
#--
#-- Parameters: 1 - Database Instance Name
#--             2 - Schema used for the proces (optional will default)
#--             3 - Table Name used for loading SQL Tuning set into table (optional will default)
#--             4 - SQL Tuning Set Name (optional will default)
#--------------------------------------------------------------------------------------------------
# set the environment for the oracle account
. /home/oracle/.bash_profile

# Check if the environment variables were passed
if (( $# < 1 ));then
  echo "Wrong number of arguments, $*, passed to dba_spa_capture.sh, must pass database instance name."
  exit 8
fi

#
# assign ORACLE_SID to passed SID
export ORACLE_SID=$1

# assign duration of catpture to passed value
export schema=$2
export tablename=$3
export stsname=$4

if [ -z "${schema}" ]; then
   echo "User did not pass schema default to dba_spa"
   export schema=avdba
fi

if [ -z "${tablename}" ]; then
   echo "User did not pass table name default to dba_spa_table"
   export tablename=dba_spa_table
fi

if [ -z "${stsname}" ]; then
   echo "User did not pass sql tuning set name default to dba_spa_sts"
   export stsname=dba_spa_sts
fi

export spataskname=`echo "${stsname}_task"`

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
export LOGFILE=${INST_LOWER}_dba_spa_capture_${DTE}.log
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

echo "Process Using Instance Name -> ${ORACLE_SID}"
echo "Process Using Instance Name -> ${ORACLE_SID}" >> ${LOG}
echo "Process Using SPA Schema Name -> ${schema}"
echo "Process Using SPA Schema Name -> ${schema}" >> ${LOG}
echo "Process Using SPA Table Name -> ${tablename}"
echo "Process Using SPA Table Name -> ${tablename}" >> ${LOG}
echo "Process Using SPA SQL Tuning Set Name -> ${stsname}"
echo "Process Using SPA SQL Tuning Set Name -> ${stsname}" >> ${LOG}
echo "Process Using SPA Task Name -> ${spataskname}"
echo "Process Using SPA Task Name -> ${spataskname}" >> ${LOG}

echo "--"
echo "--" >> ${LOG}

# Start the SPA STS Capture
sqlplus -s / as sysdba << EOF >> ${LOG}
set timing on
set echo on
set serveroutput on size 1000000
DECLARE
   cur1 DBMS_SQLTUNE.SQLSET_CURSOR;
   cur2 DBMS_SQLTUNE.SQLSET_CURSOR;
   h1                  NUMBER ;   
   v_schema_name       VARCHAR2(30) := '${schema}' ;
   v_tablespace_name   VARCHAR2(30) := 'USERS' ;
   v_table_name        VARCHAR2(64) := '${tablename}' ;
   v_sts_name          VARCHAR2(64) := '${stsname}' ;
   v_spa_task          VARCHAR2(64) := '${spataskname}' ;
   v_logfile           VARCHAR2(200) ;
   v_dumpfile          VARCHAR2(200) ;
   v_export_name       VARCHAR2(64) ;
   v_condition         VARCHAR2(200) ;
   v_min_snap          NUMBER ;
   v_max_snap          NUMBER ; 
   v_cnt               NUMBER ;
   v_sts_task_out      VARCHAR2(4000) ;

BEGIN
    v_logfile := v_schema_name || '_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') || '.dmp.log' ;
    v_dumpfile := v_schema_name || '_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') || '.dmp' ;
    v_export_name := 'STS_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') ;
    v_condition := 'parsing_schema_name NOT IN (' || '''' || 'SYS' || '''' || ',' || '''' || 'SYSTEM' || '''' || ',' || '''' || 'AVDBA' || '''' ||  ',' || '''' || 'RDBA' || '''' || ',' || '''' || 'DBSNMP' || '''' || ') AND UPPER(sql_text) like ' || '''' || 'SELECT%' || '''' ;

   -- get begin and end snap for last 24 hours
   select min(snap_id) into v_min_snap from dba_hist_snapshot where begin_interval_time >= SYSDATE-1 ;
   select max(snap_id) into v_max_snap from dba_hist_snapshot where begin_interval_time <= SYSDATE ;

   DBMS_OUTPUT.PUT_LINE('STS Name -> ' || v_sts_name) ;
   DBMS_OUTPUT.PUT_LINE('Task Name -> ' || v_spa_task) ;
   DBMS_OUTPUT.PUT_LINE('Using Begin Snap -> ' || TO_CHAR(v_min_snap)) ;
   DBMS_OUTPUT.PUT_LINE('Using End Snap -> ' || TO_CHAR(v_max_snap)) ;
   DBMS_OUTPUT.PUT_LINE('Using Condition -> ' || v_condition) ;

   -- Check if we have a SQL Tuning Set with our name and ownership
   SELECT COUNT(*) INTO v_cnt FROM DBA_SQLSET WHERE OWNER = UPPER(v_schema_name) and NAME = v_sts_name ;

   if v_cnt > 0 then
      -- If STS exists remove it first
      dbms_output.put_line('Dropping existing SQL Tuning Set') ;
      DBMS_SQLTUNE.DROP_SQLSET(sqlset_name => v_sts_name, sqlset_owner=> v_schema_name);
   end if ;

   -- check if we have a prior execute spa task of same name
   SELECT COUNT(*) INTO v_cnt FROM DBA_ADVISOR_TASKS where TASK_NAME = UPPER(v_spa_task) ;

   if v_cnt > 0 then
      dbms_output.put_line('Dropping existing Analysis Task') ;
      DBMS_SQLPA.DROP_ANALYSIS_TASK(v_spa_task) ;
   end if ;
 
   -- Create the sql set
   DBMS_OUTPUT.PUT_LINE ('Creating SQL Tuning Set') ;
   DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => v_sts_name, sqlset_owner=> v_schema_name);

   DBMS_OUTPUT.PUT_LINE ('Loading Buffer Cache Data into SQL Tuning Set') ;
   -- open cursor of our sql to load into the tuning set	
   OPEN cur1 FOR
     SELECT VALUE(P)
     FROM table(DBMS_SQLTUNE.SELECT_CURSOR_CACHE(v_condition, NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) P;
     
   DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => v_sts_name, populate_cursor => cur1, sqlset_owner=> v_schema_name);
  
   CLOSE cur1 ;
  
   DBMS_OUTPUT.PUT_LINE ('Loading AWR Data into SQL Tuning Set.') ;
   OPEN cur2 FOR
    SELECT VALUE(P)
      FROM 
       table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(v_min_snap,v_max_snap,v_condition,NULL, NULL,NULL,NULL,1,NULL,'ALL')) P;

   DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => v_sts_name,
                            populate_cursor => cur2,
                            load_option => 'MERGE',
                            update_option => 'ACCUMULATE',
		            sqlset_owner=>v_schema_name) ;

   CLOSE cur2 ;   

   DBMS_OUTPUT.PUT_LINE ('Creating Analysis Task for SQL Tuning Set.') ;
   -- Now that we have a SQL Tuning SET we need to create an analysis task for execution
   v_sts_task_out := dbms_sqlpa.create_analysis_task(sqlset_name=>v_sts_name,
                                                sqlset_owner=>v_schema_name,
                                                task_name=>v_spa_task,
                                                description=>'SPA STS Capture/execute before changes');

   DBMS_OUTPUT.PUT_LINE ('Creating Analysis Task Output -> ' || v_sts_task_out) ;
   
   DBMS_OUTPUT.PUT_LINE ('Setting Parameters for Analysis Task for SQL Tuning Set for Execution.') ;
   -- Compare plan lines when hash value does not come out the same
   DBMS_SQLPA.SET_ANALYSIS_TASK_PARAMETER(task_name => v_spa_task, 
                                          parameter => 'PLAN_LINES_COMPARISON', 
                                          value => 'AUTO');

   DBMS_OUTPUT.PUT_LINE ('Executing Analysis Task for SQL Tuning Set.') ;
   -- After creating the analysis task we need to execute the task for baseline tuning set that has SQL in it.  
   dbms_sqlpa.execute_analysis_task(task_name => v_spa_task,
                                 execution_type => 'test execute',
                                 execution_name => 'before_change');
END ;
/ 

---------------------------------------------------------------------------
-- Query our sql tuning sets
---------------------------------------------------------------------------
select name, created, statement_count from dba_sqlset where owner = '${schema}' and name = '${stsname}' ;
EOF

echo "SQL Tuning Set Capture is completed and Ready to make change."
echo "SQL Tuning Set Capture is completed and Ready to make change." >> ${LOG}
echo "Post Change Execute the Tasks Again and Get Analysis Report"
echo "Post Change Execute the Tasks Again and Get Analysis Report" >> ${LOG}
echo "--"
echo "--" >> ${LOG}
echo "EXEC DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(task_name => '${spataskname}', execution_type => 'test execute', execution_name => 'after_change');"
echo "EXEC DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(task_name => '${spataskname}', execution_type => 'test execute', execution_name => 'after_change');" >> ${LOG}
echo "--"
echo "--" >> ${LOG}
echo "EXEC DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(task_name => '${spataskname}', execution_type => 'compare performance', execution_params => dbms_advisor.arglist('execution_name1', 'before_change', 'execution_name2', 'after_change'));"
echo "EXEC DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(task_name => '${spataskname}', execution_type => 'compare performance', execution_params => dbms_advisor.arglist('execution_name1', 'before_change', 'execution_name2', 'after_change'));" >> ${LOG}
echo "--"
echo "--" >> ${LOG}
echo "SET LONG 1000000"
echo "SET LONG 1000000" >> ${LOG}
echo "SET PAGESIZE 0"
echo "SET PAGESIZE 0" >> ${LOG}
echo "SET LINESIZE 200"
echo "SET LINESIZE 200" >> ${LOG}
echo "SET LONGCHUNKSIZE 200"
echo "SET LONGCHUNKSIZE 200" >> ${LOG}
echo "SET TRIMSPOOL ON"
echo "SET TRIMSPOOL ON" >> ${LOG}
echo "SPOOL /u01/app/oracle/scripts/logs/${spataskname}_analysis_report_${DTE}.log"
echo "SPOOL /u01/app/oracle/scripts/logs/${spataskname}_analysis_report_${DTE}.log" >> ${LOG}
echo "SELECT DBMS_SQLPA.REPORT_ANALYSIS_TASK ('${spataskname}','HTML','ALL','ALL') FROM dual;"
echo "SELECT DBMS_SQLPA.REPORT_ANALYSIS_TASK ('${spataskname}','HTML','ALL','ALL') FROM dual;" >> ${LOG}
echo "SPOOL OFF"
echo "SPOOL OFF" >> ${LOG}

exit 0
