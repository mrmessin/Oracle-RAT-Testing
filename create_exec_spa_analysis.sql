spool create_execute_spa_analysis.log
set echo on
set timing on

/*
DBMS_SQLPA.CREATE_ANALYSIS_TASK(
  sqlset_name       IN VARCHAR2,
  basic_filter      IN VARCHAR2 :=  NULL,
  con_name          IN VARCHAR2     DEFAULT,
  order_by          IN VARCHAR2 :=  NULL,
  top_sql           IN VARCHAR2 :=  NULL,
  task_name         IN VARCHAR2 :=  NULL,
  description       IN VARCHAR2 :=  NULL
  sqlset_owner      IN VARCHAR2 :=  NULL)
RETURN VARCHAR2;
*/

exec dbms_sqlpa.create_analysis_task(sqlset_name  => 'dba_spa_sts', -
                                     basic_filter => NULL, -
                                     con_name     => NULL, -
                                     order_by     => NULL, -
                                     top_sql      => NULL, -
                                     task_name    => 'my_spa_task_20211012', -
                                     description  => 'test index changes', -
                                     sqlset_owner => 'AVDBA' -
                                    );


/*
DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(
   task_name         IN VARCHAR2,
   execution_type    IN VARCHAR2               := 'test execute',
   execution_name    IN VARCHAR2               := NULL,
   execution_params  IN dbms_advisor.argList   := NULL,
   execution_desc    IN VARCHAR2               := NULL)
 RETURN VARCHAR2;
*/

exec dbms_sqlpa.execute_analysis_task(task_name => 'my_spa_task_20211012', -
                                      execution_type => 'test execute', -
                                      execution_name => 'before_change' -
                                     );

spool off
