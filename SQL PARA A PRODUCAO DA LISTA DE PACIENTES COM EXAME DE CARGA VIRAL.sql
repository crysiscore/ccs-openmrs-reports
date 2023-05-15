select 	cargaViral.*,
		pid.identifier,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) nome,
		p.gender,
		round(datediff(:endDate,p.birthdate)/365) idade_actual
from 
(	Select 	p.patient_id,o.obs_datetime,o.date_created,o.value_numeric
	from 	patient p 
			inner join encounter e on e.patient_id=p.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
	where 	p.voided=0 and e.voided=0 and e.encounter_type=13 and o.voided=0 and 
			e.location_id=:location and o.obs_datetime between :startDate and :endDate and o.concept_id=856
)cargaViral
inner join person p on p.person_id=cargaViral.patient_id
left join 
(	select pid1.*
	from patient_identifier pid1
	inner join 
		(
			select patient_id,min(patient_identifier_id) id 
			from patient_identifier
			where voided=0
			group by patient_id
		) pid2
	where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
) pid on pid.patient_id=cargaViral.patient_id
left join 
(	select pn1.*
	from person_name pn1
	inner join 
		(
			select person_id,min(person_name_id) id 
			from person_name
			where voided=0
			group by person_id
		) pn2
	where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
) pn on pn.person_id=cargaViral.patient_id
order by cargaViral.patient_id,cargaViral.obs_datetime