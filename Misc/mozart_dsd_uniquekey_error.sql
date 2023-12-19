SELECT o1.uuid as dsd_uuid, o1.encounter_id, o1.value_coded as dsd_id, o2.value_coded as dsd_state_id, o1.date_created, e.uuid as encounter_uuid, 
e.encounter_type, e.form_id as source_id, o1.person_id as patient_id, p.patient_uuid, e.encounter_datetime as encounter_date 
FROM openmrs.obs o1
JOIN openmrs.obs o2 on o1.obs_group_id = o2.obs_group_id
AND o1.encounter_id = o2.encounter_id AND o1.concept_id = 165174 AND o2.concept_id = 165322 AND !o1.voided and  !o2.voided 
JOIN mozart2.patient p ON o1.person_id = p.patient_id 
JOIN openmrs.encounter e on o1.encounter_id = e.encounter_id AND e.encounter_type IN (6,35) AND e.encounter_datetime <= '2023-03-20'

f7eecb37-5e2d-4700-beef-8e072f844e22

select * from encounter where uuid ='ab6134b0-4280-47c7-a906-645c3b64a221';
select * from obs where uuid = 'f7eecb37-5e2d-4700-beef-8e072f844e22';
select * from obs o1 where encounter_id = 1938659 and !o1.voided and o1.concept_id = 165174;
select * from obs o1 where encounter_id = 1653178 and !o1.voided and o1.concept_id = 165322;


select * from obs o1 where encounter_id = 1499501  and o1.concept_id = 165174;

select * from obs o1 where encounter_id = 1499501  and o1.concept_id in ( 165174 , 165322 ) and !voided;



select   *   from obs where !voided and obs_group_id IN (10358188 , 10358191 );


-- Chamanculo
update obs set voided =1, voided_by =1
where obs_id in (13030571,13030573);

-- Josemacamo
update obs set voided =1, voided_by =1
where obs_id in (17251538);
-- altomae
update obs set voided =1, voided_by =1
where obs_id in (13874739);
-- albasine
update obs set voided =1, voided_by =1
where obs_id in (10358196,10358197,10358194, 10358196,10358197,10358192);
