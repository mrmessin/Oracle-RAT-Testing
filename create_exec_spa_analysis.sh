#--------------------------------------------------------------------------------------------------
#-- Script: create_execute_spa_analysis.sh
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
  echo "Wrong number of arguments, $*, passed to create_execute_spa_analysis.sh, must pass database instance name."
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
   export schema=dba_spa
fi

if [ -z "${tablename}" ]; then
   echo "User did not pass table name default to dba_spa_table"
   export tablename=dba_spa_table
fi

if [ -z "${stsname}" ]; then
   echo "User did not pass sql tuning set name default to dba_spa_sts"
   export stsname=dba_spa_sts
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
export LOGFILE=${INST_LOWER}_create_execute_spa_analysis_${DTE}.log
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

echo "--"
echo "--" >> ${LOG}

# Start the SPA STS Capture
sqlplus -s / as sysdba << EOF >> ${LOG}
set timing on
set echo on
DECLARE
   cur1 DBMS_SQLTUNE.SQLSET_CURSOR;
   cur2 DBMS_SQLTUNE.SQLSET_CURSOR;
   h1                  NUMBER ;   
   v_schema_name       VARCHAR2(30) := '${schema}' ;
   v_tablespace_name   VARCHAR2(30) := 'USERS' ;
   v_table_name        VARCHAR2(15) := '${tablename}' ;
   v_sts_name          VARCHAR2(15) := '${stsname}' ;
   v_logfile           VARCHAR2(100) ;
   v_dumpfile          VARCHAR2(100) ;
   v_export_name       VARCHAR2(100) ;
   v_condition         VARCHAR2(100) ;
BEGIN
    v_logfile := v_schema_name || '_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') || '.dmp.log' ;
    v_dumpfile := v_schema_name || '_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') || '.dmp' ;
    v_export_name := 'STS_' || v_sts_name || '_' || to_char(SYSDATE,'yyyymmdd') ;
    v_condition := 'parsing_schema_name <> ' || '''' || 'SYS' || '''' || ' AND (sql_text like ' || '''' || 'SELECT%' || '''' || ' or sql_text like ' || '''' || 'select%' || '''' || ') ' ;

    -- Create the sql set
   DBMS_OUTPUT.PUT_LINE ('Creating SPA Analysis Task') ;
   DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => v_sts_name, sqlset_owner=> v_schema_name);

dbms.sqlpa.create_analysis_task(sqlset_name => 'my_sts',
task_name => 'my_spa_task',
description => 'test index changes');

dbms_sqlpa.execute_analysis_task(task_name => 'my_spa_task',
execution_type => 'test execute',
execution_name => 'before_change');



/*
   -- open cursor of our sql to load into the tuning set	
   OPEN cur1 FOR
     SELECT VALUE(P)
     FROM table(DBMS_SQLTUNE.SELECT_CURSOR_CACHE(v_condition, NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) P;

   DBMS_OUTPUT.PUT_LINE ('Loading Buffer Cache Data into SQL Tuning Set') ;
   DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => v_sts_name, populate_cursor => cur1, sqlset_owner=> v_schema_name);
  
   CLOSE cur1 ;
*/
  
   OPEN cur2 FOR
    SELECT VALUE(P)
      FROM 
       table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(17865,17902,v_condition,NULL, NULL,NULL,NULL,1,NULL,'ALL')) P;
/*
       table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(30108,30112,v_condition,NULL, NULL,NULL,NULL,1,NULL,'ALL')) P;
*/

   DBMS_OUTPUT.PUT_LINE ('Loading AWR Data into SQL Tuning Set.') ;
   DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => v_sts_name,
                            populate_cursor => cur2,
                            load_option => 'MERGE',
                            update_option => 'ACCUMULATE',
		                 sqlset_owner=>v_schema_name) ;

   CLOSE cur2 ;   

END ;
/ 

---------------------------------------------------------------------------
-- Query our sql tuning sets
---------------------------------------------------------------------------
select name, created, statement_count from dba_sqlset ;

EOF

spool off
