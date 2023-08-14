select person_id,encounter_id,concept_id,value_coded,count(*)
from obs
where concept_id=165174 and voided=0
group by person_id,encounter_id,value_coded
having count(*)>1;

-- 2.
select person_id,encounter_id,concept_id,value_coded,obs_group_id,count(*)
from obs
where concept_id=165322 and voided=0
group by person_id,encounter_id,obs_group_id,value_coded
having count(*)>1;


-- Para corrigir deve correr os SQL abaixo até trazer 0 update:

-- (1)
update obs,
(
select min(obs_id) obs_id
from obs
where concept_id=165174 and voided=0
group by person_id,encounter_id,value_coded
having count(*)>1
) obsUpdate
set obs.voided=1,voided_by=1,date_voided=now(),void_reason='Mozart2 duplicated'
where obs.obs_id=obsUpdate.obs_id;

-- (2)
update obs,
(
select min(obs_id) obs_id
from obs
where concept_id=165322 and voided=0
group by person_id,encounter_id,obs_group_id,value_coded
having count(*)>1
) obsUpdate
set obs.voided=1,voided_by=1,date_voided=now(),void_reason='Mozart2 duplicated'
where obs.obs_id=obsUpdate.obs_id;
