-- table to drive our mapping
drop table avdba.connection_remap_replay ;
create table avdba.connection_remap_replay
(
db				varchar2(30),
connection_service_capture      varchar2(4000),
connection_tns_replay           varchar2(4000)
)
tablespace USERS_DATA ;
--tablespace USERS ;

create index avdba.connection_remap_replay_idx1 on avdba.connection_remap_replay(db) ;

-- aries
insert into avdba.connection_remap_replay values ('ARIES','aries2_aries','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries2_track','ag4aries3') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_aud','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_bat','ag4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_etl','ag4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_bat','ag4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_rt','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rpt','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rt','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','axi','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','idm','ag4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect','ag4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm.prd','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm','ag4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','track','ag4aries3') ;
insert into avdba.connection_remap_replay values ('ARIES','default','ag4aries3') ;

-- rcm
insert into avdba.connection_remap_replay values ('PRDRMED','rcm.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm_readonly','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore.prd','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis.prd','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco.prd','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco','ag4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans.prd','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans','ag4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','default','ag4rcmprd1') ;
commit ;
