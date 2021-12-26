-- Capture Report 
set server output on size 1000000
select id, name, STATUS, directory from dba_workload_captures ;
DECLARE 
   cap_id NUMBER; 
   cap_rpt CLOB; 
   buffer VARCHAR2(32767); 
   buffer_size CONSTANT BINARY_INTEGER := 32767; 
   amount BINARY_INTEGER; 
   offset NUMBER(38); 
   file_handle UTL_FILE.FILE_TYPE; 
   v_capture_name VARCHAR2(128) := '&CAPTURE_NAME' ;
   v_filename CONSTANT VARCHAR2(80) := v_capture_name || '_CaptureReport.html'; 
   v_directory_name  VARCHAR2(128) ;

BEGIN 
   SELECT id, directory 
   INTO cap_id, 
        v_directory_name
   FROM dba_workload_captures 
   where name = v_capture_name
     and status = 'COMPLETED' ;

   cap_rpt := DBMS_WORKLOAD_CAPTURE.REPORT(capture_id => cap_id, format => DBMS_WORKLOAD_CAPTURE.TYPE_HTML); 

   -- -------------------------------- 
   -- OPEN NEW XML FILE IN WRITE MODE 
   -- -------------------------------- 
   file_handle := UTL_FILE.FOPEN(location => v_directory_name, 
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
