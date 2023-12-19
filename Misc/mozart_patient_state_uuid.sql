SELECT p.patient_uuid, pg.program_id, pg.date_enrolled, pg.date_completed, l.uuid,  pg.uuid, pg.program_id, pws.concept_id, ps.start_date, ps.date_created, ps.uuid
FROM mozart2.patient p
    INNER JOIN openmrs.patient_program pg ON p.patient_id = pg.patient_id AND !pg.voided
LEFT JOIN openmrs.location l ON l.location_id=pg.location_id
    LEFT JOIN openmrs.patient_state ps on ps.patient_program_id=pg.patient_program_id AND !ps.voided AND (ps.start_date is NULL or ps.start_date <= '2023-03-20')
    LEFT JOIN openmrs.program_workflow_state pws on pws.program_workflow_state_id=ps.state
where  pg.uuid = 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';

select * from openmrs.patient_program where uuid = 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';
select * from openmrs.patient_state where uuid = 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';
select * from openmrs.program_workflow_state pws where uuid= 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';
update patient_state st set st.voided =1 where patient_state_id =15203;

select * from openmrs.patient_program where uuid = '6D36BEA3-68AF-4538-8703-5001F8CD753A';
select * from openmrs.patient_state where patient_program_id = 12015;
update patient_state st set st.voided =1 where patient_state_id =13002;

drop database mozart2;

select * from openmrs.patient where patient_id = 10807;
select * from mozart2.patient_state where state_uuid = 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';
select * from mozart2.patient where patient_uuid = 'DF46FDCE-E86F-408C-A4F5-F2AAEA4FB547';





select * from openmrs.patient_program where uuid = '302A6C87-2AD2-4605-8B86-CE1C2DE0BA0A';
select * from openmrs.patient_state where patient_program_id = 13287;
update patient_state st set st.voided =1 where patient_state_id =14274;


select ps.patient_program_id
    from patient_state ps   INNER JOIN openmrs.patient_program pg  on ps.patient_program_id=pg.patient_program_id AND !ps.voided and pg.program_id=1
    where ps.voided_by =1 and ps.voided=0 and ps.state in (2,6)
 group by ps.patient_program_id
having count(ps.patient_program_id) >1;

select * from openmrs.patient_state where patient_program_id = 11674;
select * from openmrs.patient_program where patient_program_id = 11588;








