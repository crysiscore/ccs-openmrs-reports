SELECT e.uuid as encounter_uuid, o.concept_id, o.value_coded, o.value_text
FROM openmrs.obs o JOIN mozart2.patient p ON o.person_id = p.patient_id
    JOIN openmrs.encounter e on o.encounter_id = e.encounter_id AND e.encounter_type IN (6,35) AND e.encounter_datetime <= '2023-03-20'
                                    AND !o.voided AND o.concept_id IN (23703,23710)
where e.uuid = 'c54232b0-08e0-4825-812f-545691553ae6';


select o.*
from obs o where encounter_id in (
select encounter_id
from openmrs.obs  o
where  o.concept_id IN (23703,23710) and voided = 0
group by  encounter_id
having count(encounter_id) >1 )  and o.concept_id IN (23703,23710) and voided = 0;

-- Zimpeto
update obs set voided =1, voided_by =1  where obs_id in (6319051,7297220,9450292,10583420);
show processlist ;

-- alto mae
update obs set voided =1, voided_by =1  where obs_id in (9226642, 9227113, 9226467,9226962,9225924,
                                                         9226675,9226421, 9226217,9226836,9226510,
                                                        9179950,13148651,13006004,14290702);

select * from obs where uuid='aa79f3ba-a0bf-477a-b8eb-5e33549fc7a5';








