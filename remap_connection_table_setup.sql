-- table to drive our mapping
create table avdba.connection_remap_replay
(
db				varchar2(30),
connection_service_capture      varchar2(4000),
connection_tns_replay           varchar2(4000)
)
tablespace USERS_HC ;
--tablespace USERS ;

create index avdba.connection_remap_replay_idx1 on avdba.connection_remap_replay(db) ;

-- aries
insert into avdba.connection_remap_replay values ('ARIES','aries2_aries','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries2_track','ag3aries6') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_aud','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_bat','ag3aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_etl','ag3aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_bat','ag3aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_gg_rt','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rpt','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','aries_rt','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','axi','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','idm','ag3aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect','ag3aries2') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm.prd','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','mconnect_rcm','ag3aries1') ;
insert into avdba.connection_remap_replay values ('ARIES','track','ag3aries6') ;
insert into avdba.connection_remap_replay values ('ARIES','default','ag3aries6') ;

-- rcm
insert into avdba.connection_remap_replay values ('PRDRMED','rcm.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcm_readonly','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmclaim','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore.prd','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmcore','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmedi','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmelig','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmetl','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis.prd','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmiis','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmremit','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmrpt','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco.prd','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtibco','ag3rcmprd4') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans.prd','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','rcmtrans','ag3rcmprd3') ;
insert into avdba.connection_remap_replay values ('PRDRMED','default','ag3rcmprd3') ;
commit ;
