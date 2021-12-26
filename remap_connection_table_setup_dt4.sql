-- table to drive our mapping
drop table avdba.connection_remap_replay ;
create table avdba.connection_remap_replay
(
db				varchar2(30),
connection_service_capture      varchar2(4000),
connection_tns_replay           varchar2(4000)
)
--tablespace USERS_DATA ;
tablespace USERS_HC ;

create index avdba.connection_remap_replay_idx1 on avdba.connection_remap_replay(db) ;

-- aries
insert into avdba.connection_remap_replay values ('ARIES','aries2_aries','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries2_track','dt4aries3') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_aud','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_bat','dt4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_etl','dt4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_bat','dt4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_rt','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rpt','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rt','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','axi','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','idm','dt4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect','dt4aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm.prd','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm','dt4aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','track','dt4aries3') ;
insert into avdba.connection_remap_replay values ('ARIES','default','dt4aries3') ;

-- rcm
insert into avdba.connection_remap_replay values ('PRDRMED','rcm.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm_readonly','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore.prd','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis.prd','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco.prd','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco','dt4rcmprd2') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans.prd','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans','dt4rcmprd1') ;
insert into avdba.connection_remap_replay values ('PRDRMED','default','dt4rcmprd1') ;
commit ;
