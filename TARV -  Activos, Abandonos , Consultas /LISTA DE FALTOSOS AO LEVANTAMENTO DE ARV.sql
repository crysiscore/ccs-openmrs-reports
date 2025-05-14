select *
from
(select 	max_frida.patient_id

from
		(	Select 	p.patient_id,max(encounter_datetime) encounter_datetime
			from 	patient p
					inner join encounter e on e.patient_id=p.patient_id
			where 	p.voided=0 and e.voided=0 and e.encounter_type=18 and
					e.location_id=(select location_id from location l where l.name = (select property_value from global_property where property = 'default_location') ) and e.encounter_datetime<=current_date
			group by p.patient_id
		) max_frida
		inner join obs o on o.person_id=max_frida.patient_id
		inner join person p on p.person_id=max_frida.patient_id
		left join
		(	select pad1.*
			from person_address pad1
			inner join
			(
				select person_id,min(person_address_id) id
				from person_address
				where voided=0
				group by person_id
			) pad2
			where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
		) pad3 on pad3.person_id=max_frida.patient_id
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
		) pn on pn.person_id=max_frida.patient_id
		left join
		(   select pid1.*
			from patient_identifier pid1
			inner join
			(
				select patient_id,min(patient_identifier_id) id
				from patient_identifier
				where voided=0
				group by patient_id
			) pid2
			where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
		) pid on pid.patient_id=max_frida.patient_id
		left join person_attribute pat on pat.person_id=max_frida.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
where 	max_frida.encounter_datetime=o.obs_datetime and o.voided=0 and o.concept_id=5096 and o.location_id=(select location_id from location l where l.name = (select property_value from global_property where property = 'default_location') ) and
		max_frida.patient_id not in
		(
			select 	pg.patient_id
			from 	patient p
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and
					ps.start_date<=current_date and location_id= (
select location_id from location l where l.name = (select property_value from global_property where property = 'default_location'))
		)
		and datediff(current_date,o.value_datetime) between 7 and 60
) faltoso
group by patient_id



