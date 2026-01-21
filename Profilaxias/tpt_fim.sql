INNER JOIN
	(
select fim_tpt.patient_id,max(fim_tpt.data_fim_tpt) data_tx_new_tpt  -- Completaram TPT no FILT ou FC
	from
	(
		select 	p.patient_id,max(e.encounter_datetime) data_fim_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1267 and e.encounter_type in (6,9,53,60) and  e.location_id=:location
		group by p.patient_id )  fim_tpt group by patient_id
	) tx_new_tpt ON tx_new_tpt.patient_id=tx_curr.patient_id -- AND data_consulta=data_pick_up


select  *  from macia.location