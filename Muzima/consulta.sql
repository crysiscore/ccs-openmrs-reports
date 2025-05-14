		left join
		(
			select patient_id,max(data_consulta) data_consulta,max(data_proxima_consulta) data_proxima_consulta
			from
			(

				Select 	ultimavisita.patient_id,ultimavisita.encounter_datetime data_consulta ,o.value_datetime data_proxima_consulta
				from
					(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	encounter e
								inner join patient p on p.patient_id=e.patient_id
						where 	e.voided=0 and p.voided=0 and e.encounter_type=6 and e.location_id=(select value_string from muzima_setting where property = 'Encounter.DefaultLocationId') and e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
						group by p.patient_id
					) ultimavisita
					inner join encounter e on e.patient_id=ultimavisita.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
				where 	o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and
						e.encounter_type=6 and e.location_id=(select value_string from muzima_setting where property = 'Encounter.DefaultLocationId')

				UNION

				Select 	ultimavisita.patient_id,ultimavisita.encounter_datetime data_consulta ,o.value_datetime data_proxima_consulta
				from
					(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	encounter e
								inner join patient p on p.patient_id=e.patient_id
						where 	e.voided=0 and p.voided=0 and e.encounter_type=35 and e.location_id=(select value_string from muzima_setting where property = 'Encounter.DefaultLocationId') and e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
						group by p.patient_id
					) ultimavisita
					inner join encounter e on e.patient_id=ultimavisita.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
				where 	o.concept_id=6310 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and
						e.encounter_type=35 and e.location_id=(select value_string from muzima_setting where property = 'Encounter.DefaultLocationId')


			) consultaRecepcao
			group by patient_id
		--	having max(data_proxima_consulta) between date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval 13 DAY) and date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval 19 DAY)
		) consulta on inicio_real.patient_id=consulta.patient_id