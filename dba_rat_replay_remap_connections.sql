set serveroutput on size 1000000
-- Procedure to setup the remap for replay
DECLARE 
   v_dbname          VARCHAR2(100) ;
   v_replay_id       NUMBER ;
   v_capture_id      NUMBER ;
   v_connection_id   NUMBER ;
   v_connection_service_capture   VARCHAR2(4000) ;
   v_connection_tns_replay        VARCHAR2(4000) ;
   v_default_map                  VARCHAR2(4000) ;
   CURSOR cur_services IS
     select connection_service_capture, connection_tns_replay
     from avdba.connection_remap_replay  
     where db = v_dbname 
	 order by connection_service_capture ;
   CURSOR cur_replay_connections IS
     select conn_id
     from DBA_WORKLOAD_CONNECTION_MAP
     where replay_id = v_replay_id 
       and CAPTURE_CONN like '%' || v_connection_service_capture || '%' ;
   CURSOR cur_no_map_connections IS
     select conn_id
	 from DBA_WORKLOAD_CONNECTION_MAP
	 where REPLAY_CONN IS NULL ;
BEGIN
-- grab our database name
select name
into v_dbname
from v$database ;

dbms_output.put_line('Using Database -> ' || v_dbname) ;

-- identify the replay we have in initialized state if we do not have one then we should abort
select ID, CAPTURE_ID
into v_replay_id, v_capture_id
from dba_workload_replays 
where STATUS = 'INITIALIZED' ;

dbms_output.put_line('Using Capture ID -> ' || to_char(v_capture_id)) ;
dbms_output.put_line('Using Replay ID -> ' || to_char(v_replay_id)) ;

-- get default connection map for database
select connection_tns_replay
into v_default_map
from avdba.connection_remap_replay
where db = v_dbname
  and connection_service_capture = 'default' ;

dbms_output.put_line('Default Remap Connection -> ' || to_char(v_default_map)) ;

----------------------------------------------------------------------------
-- go through our list of services we know we have to remap for database 
----------------------------------------------------------------------------
open cur_services ;
LOOP
   FETCH cur_services into v_connection_service_capture, v_connection_tns_replay ;
   EXIT WHEN cur_services%NOTFOUND ;

   -- For each service go through the connections that map
   OPEN cur_replay_connections ;
   LOOP 
      FETCH cur_replay_connections INTO v_connection_id ;
      EXIT WHEN cur_replay_connections%NOTFOUND ;
	  
      DBMS_WORKLOAD_REPLAY.REMAP_CONNECTION (v_connection_id,v_connection_tns_replay) ;
   END LOOP ;
   
   CLOSE cur_replay_connections ;
END LOOP ;

CLOSE cur_services ;

-- Now we handle any connections that still do not have a mapped connection with a default
OPEN cur_no_map_connections ;
LOOP
   FETCH cur_no_map_connections into v_connection_id ;
   EXIT WHEN cur_no_map_connections%NOTFOUND ;
   
   DBMS_WORKLOAD_REPLAY.REMAP_CONNECTION (v_connection_id,v_default_map) ;
END LOOP ;

CLOSE cur_no_map_connections ;
END ;
/

-- then show the remaps made so it can be reviewed for issues
set linesize 100
set pagesize 1000
column replay_id format 999999
column capture_conn format a100
column replay_conn format a100
select replay_id, capture_conn, replay_conn from DBA_WORKLOAD_CONNECTION_MAP ;
