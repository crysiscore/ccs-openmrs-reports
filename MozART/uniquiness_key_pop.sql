select person_id,encounter_id,concept_id,value_coded,count(*)
from obs
where concept_id=23703 and voided=0
group by person_id,encounter_id,value_coded
having count(*)>1

-- E para corrigir pode correr este SQL até trazer 0 update:

update obs,
(
select min(obs_id) obs_id
from obs
where concept_id=23703 and voided=0
group by person_id,encounter_id,value_coded
having count(*)>1
)obsUpdate
set obs.voided=1,voided_by=1,date_voided=now(),void_reason='Mozart2 duplicated'
where obs.obs_id=obsUpdate.obs_id;


