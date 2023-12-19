-- TPT_CASCADE_INICIO_3HP

  select patient_id
  from
  	(

	  	 /********** FC/RESUMO/ 3HP Regime TPT:3HP & Estado da profilaxia: Iniciar  *****************/
	  	select p.patient_id, min(estadoProfilaxia.obs_datetime) data_inicio_3HP
		from patient p
			inner join encounter e on p.patient_id = e.patient_id
			inner join obs profilaxia3HP on profilaxia3HP.encounter_id = e.encounter_id
			inner join obs estadoProfilaxia on estadoProfilaxia.encounter_id = e.encounter_id
		where p.voided = 0 and e.voided = 0  and profilaxia3HP.voided = 0 and estadoProfilaxia.voided = 0
			and  profilaxia3HP.concept_id = 23985  and profilaxia3HP.value_coded = 23954 and estadoProfilaxia.concept_id = 165308 and estadoProfilaxia.value_coded = 1256
			and e.encounter_type in (6,9,53) and e.location_id=:location and estadoProfilaxia.obs_datetime < :endDate
			group by p.patient_id,estadoProfilaxia.obs_datetime

	  	union

		select p.patient_id, min(e.encounter_datetime) data_inicio_3HP
		from	patient p
			inner join encounter e on p.patient_id=e.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
		where p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (6,9) and o.concept_id=1719 and o.value_coded=165307
			and e.encounter_datetime < :endDate and e.location_id= :location

		union

		select p.patient_id, min(e.encounter_datetime) data_inicio_3HP
  		from patient p
  			inner join encounter e on p.patient_id=e.patient_id
  			inner join obs o on o.encounter_id=e.encounter_id
  			inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
  		where e.voided=0 and p.voided=0 and e.encounter_datetime < :endDate
  			and o.voided=0 and o.concept_id=23985 and o.value_coded in (23954,23984) and e.encounter_type=60 and  e.location_id=:location
  			and seguimentoTPT.voided =0 and seguimentoTPT.concept_id =23987 and seguimentoTPT.value_coded in (1256,1705)
  		group by p.patient_id

          union

          select inicio.patient_id, inicio.data_inicio_3HP
  		from
  			(		  /********** FILT Regime TPT: 3HP + Piridoxina + estado profilaxia: Manter/Completo  *****************/
  			    select p.patient_id, e.encounter_datetime data_inicio_3HP
  				from	patient p
  					inner join encounter e on p.patient_id=e.patient_id
  					inner join obs o on o.encounter_id=e.encounter_id
  					inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
  				where p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=60  and o.concept_id=23985 and o.value_coded in (23954,23984)
  					and seguimentoTPT.voided =0 and seguimentoTPT.concept_id =23987 and seguimentoTPT.value_coded in (1257,1267)
  					and	e.encounter_datetime < :endDate and e.location_id= :location
  				union
  				/*****                 Manter ou Completo                         ******/
  				select p.patient_id, e.encounter_datetime data_inicio_3HP
  				from	patient p
  					inner join encounter e on p.patient_id=e.patient_id
  					inner join obs o on o.encounter_id=e.encounter_id
  					left join obs seguimentoTPT on ( e.encounter_id =seguimentoTPT.encounter_id
  						and seguimentoTPT.concept_id =23987
  						and seguimentoTPT.value_coded in (1256,1257,1705,1267)
  						and seguimentoTPT.voided =0 )
  				where p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=60  and o.concept_id=23985 and o.value_coded in (23954,23984)
  					and	e.encounter_datetime < :endDate and e.location_id =:location
  					and seguimentoTPT.concept_id is null
  			) inicio

          left join

  		(

  			  /********** FILT Regime TPT: 3HP + Piridoxina  *****************/
  			select p.patient_id, e.encounter_datetime data_inicio_3HP
  			from	patient p
  				inner join encounter e on p.patient_id=e.patient_id
  				inner join obs o on o.encounter_id=e.encounter_id
  			where p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=60  and o.concept_id=23985 and o.value_coded in (23954,23984)
  				and	e.encounter_datetime < :endDate and e.location_id= :location
               union

                /********** FC/RESUMO Regime TPT: 3HP  & Estado da profilaxia: Iniciar *****************/
               select p.patient_id, estadoProfilaxia.obs_datetime data_inicio_3HP
			from patient p
				inner join encounter e on p.patient_id = e.patient_id
				inner join obs profilaxia3HP on profilaxia3HP.encounter_id = e.encounter_id
				inner join obs estadoProfilaxia on estadoProfilaxia.encounter_id = e.encounter_id
			where p.voided = 0 and e.voided = 0  and profilaxia3HP.voided = 0 and estadoProfilaxia.voided = 0
				and  profilaxia3HP.concept_id = 23985  and profilaxia3HP.value_coded = 23954 and estadoProfilaxia.concept_id = 165308 and estadoProfilaxia.value_coded = 1256
				and e.encounter_type in (6,53) and e.location_id=:location and estadoProfilaxia.obs_datetime < :endDate
				group by p.patient_id,estadoProfilaxia.obs_datetime
               union
               /********* FC Tratamento Prescrito: DT-3HP *****************/
  			select p.patient_id, e.encounter_datetime data_inicio_3HP
  			from	patient p
  				inner join encounter e on p.patient_id=e.patient_id
  				inner join obs o on o.encounter_id=e.encounter_id
  			where p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type = 6 and o.concept_id=1719 and o.value_coded = 165307
  				and e.encounter_datetime < :endDate and e.location_id= :location

  		) inicio_anterior
  			on inicio_anterior.patient_id = inicio.patient_id
  			and inicio_anterior.data_inicio_3HP between (inicio.data_inicio_3HP - INTERVAL 4 MONTH) and (inicio.data_inicio_3HP - INTERVAL 1 day)
  		where inicio_anterior.patient_id is null

      ) inicio_3HP