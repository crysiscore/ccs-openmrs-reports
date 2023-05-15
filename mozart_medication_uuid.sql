SELECT o.obs_id,
       o.obs_datetime,
       o.uuid               as medication_uuid,
       o.obs_group_id,
       o.concept_id,
       o.value_coded,
       o.value_datetime,
       o.encounter_id,
       e.uuid               as encounter_uuid,
       o.person_id          as patient_id,
       p.patient_uuid,
       e.encounter_type,
       e.encounter_datetime as encounter_date
FROM openmrs.obs o
         JOIN mozart2.patient p ON o.person_id = p.patient_id
         JOIN openmrs.encounter e on o.encounter_id = e.encounter_id AND e.encounter_type IN (6, 9, 18, 52, 53)
WHERE !o.voided and o.uuid='9b9073af-60ec-4eb5-81e1-694cf78334cd'
  AND CASE
          WHEN e.encounter_type = 52 THEN o.concept_id = 23866
          WHEN e.encounter_type = 53 THEN o.concept_id IN (1088, 21187, 21188, 21190, 23893)
          ELSE o.concept_id IN (1087, 1088, 21187, 21188, 21190, 23893) END
  AND CASE WHEN o.concept_id = 23866 THEN o.value_datetime <= '2023-03-20' ELSE o.obs_datetime <= '2023-03-20' END
ORDER BY o.obs_id ;

select distinct e.encounter_id, o.person_id
FROM encounter e
INNER JOIN obs o
    on e.encounter_id = o.encounter_id
    and e.patient_id <> o.person_id  where o.concept_id=165256;


select o.*  from    obs o
 inner join encounter e on o.encounter_id = e.encounter_id
where e.encounter_type=18  and o.concept_id=165256  and o.person_id  in (
select person_id from       (
select o.person_id, o.encounter_id, o.concept_id from obs o inner join encounter e on o.encounter_id = e.encounter_id
where e.encounter_type=18  and o.concept_id=165256

group by o.encounter_id, o.concept_id
having count(*) >1 ) temp ) order by encounter_id


-- incassane
update obs o set o.voided_by=1, o.voided=1
where obs_id =581429;
update obs o set o.voided_by=1, o.voided=1
where obs_id =581421;
update obs o set o.voided_by=1, o.voided=1
where obs_id =581411;


select obs_id, obs_datetime, value_coded from obs where  concept_id=1088 and person_id = 36369

group by obs_datetime;

select * from obs where uuid='9b9073af-60ec-4eb5-81e1-694cf78334cd';
select * from encounter where uuid='7e701e63-4efe-4059-9d63-eb521f0b1fb1';
select * from obs where concept_id=1088 and encounter_id=820679;

select person_id, o.encounter_id, obs_datetime, value_coded
from obs o   JOIN openmrs.encounter e on o.encounter_id = e.encounter_id AND e.encounter_type IN (6, 9, 18, 52, 53)
         where concept_id=1088
group by person_id, obs_datetime,concept_id ;

select * from encounter where encounter_id =820679;
select * from obs where encounter_id =820679;

