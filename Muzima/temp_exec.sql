SELECT *
FROM (SELECT patient_id, data_inicio
      FROM (SELECT patient_id, min(data_inicio) data_inicio
            FROM (
                     /*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/

                     SELECT p.patient_id, min(e.encounter_datetime) data_inicio
                     FROM patient p
                              INNER JOIN encounter e on p.patient_id = e.patient_id
                              INNER JOIN obs o on o.encounter_id = e.encounter_id
                     WHERE e.voided = 0
                       and o.voided = 0
                       and p.voided = 0
                       and e.encounter_type in (18, 6, 9)
                       and o.concept_id = 1255
                       and o.value_coded = 1256
                       and e.encounter_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                       and e.location_id =
                           (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                     group by p.patient_id

                     union

                     /*Patients on ART who have art start date ART Start date*/
                     SELECT p.patient_id, min(value_datetime) data_inicio
                     FROM patient p
                              INNER JOIN encounter e on p.patient_id = e.patient_id
                              INNER JOIN obs o on e.encounter_id = o.encounter_id
                     WHERE p.voided = 0
                       and e.voided = 0
                       and o.voided = 0
                       and e.encounter_type in (18, 6, 9, 53)
                       and o.concept_id = 1190
                       and o.value_datetime is not null
                       and o.value_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                       and e.location_id =
                           (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                     group by p.patient_id

                     union

                     /*Patients enrolled in ART Program OpenMRS Program*/
                     SELECT pg.patient_id, min(date_enrolled) data_inicio
                     FROM patient p
                              INNER JOIN patient_program pg on p.patient_id = pg.patient_id
                     WHERE pg.voided = 0
                       and p.voided = 0
                       and program_id = 2
                       and date_enrolled <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                       and location_id =
                           (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                     group by pg.patient_id

                     union


                     /*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
                     SELECT e.patient_id, MIN(e.encounter_datetime) AS data_inicio
                     FROM patient p
                              INNER JOIN encounter e on p.patient_id = e.patient_id
                     WHERE p.voided = 0
                       and e.encounter_type = 18
                       AND e.voided = 0
                       and e.encounter_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                       and e.location_id =
                           (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                     GROUP BY p.patient_id

                     union

                     /*Patients with first drugs pick up date set Recepcao Levantou ARV*/
                     SELECT p.patient_id, min(value_datetime) data_inicio
                     FROM patient p
                              INNER JOIN encounter e on p.patient_id = e.patient_id
                              INNER JOIN obs o on e.encounter_id = o.encounter_id
                     WHERE p.voided = 0
                       and e.voided = 0
                       and o.voided = 0
                       and e.encounter_type = 52
                       and o.concept_id = 23866
                       and o.value_datetime is not null
                       and o.value_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                       and e.location_id =
                           (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                     group by p.patient_id) inicio
            group by patient_id) inicio1
      WHERE data_inicio <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))) inicio_real
    /**********      Lactantes Diagnosticadas  na CPP    ***************/
         INNER JOIN (
    /**********            LACTANTE            ***************/
   SELECT patient_id, MIN(data_parto) data_parto, datediff(date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), data_parto)  diff
   FROM ( SELECT p.patient_id, e.encounter_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id
    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6332
      and value_coded = 1065
      and e.encounter_type = 6
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
    union
        /**********      LACTANTE   na FICHA RESUMO         ***************/
    SELECT p.patient_id, o.value_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id

    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and o.concept_id = 6332
      and o.value_coded = 1065
      and e.encounter_type = 53
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))

    union
    /**************  CRITÉRIO PARA INICIO DE TRATAMENTO ARV : LACTANTE ********************/
    SELECT p.patient_id, e.encounter_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id
    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6334
      and value_coded = 6332
      and e.encounter_type in (5, 6)
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
    union
    /************** INSCRICAO NO PROGRA PTV?ETV : LACTANTE ********************/
    SELECT pg.patient_id, ps.start_date data_parto
    FROM patient p
             INNER JOIN patient_program pg on p.patient_id = pg.patient_id
             INNER JOIN patient_state ps on pg.patient_program_id = ps.patient_program_id
    WHERE pg.voided = 0
      and ps.voided = 0
      and p.voided = 0
      and pg.program_id = 8
      and ps.state = 27
      and ps.start_date BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))) all_lactante group by  patient_id)
 lactante_real on lactante_real.patient_id = inicio_real.patient_id
    /************************************      Consulta    *************************************/
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
		) consulta on lactante_real.patient_id=consulta.patient_id
         INNER JOIN person p on p.person_id = inicio_real.patient_id
WHERE  timestampdiff(year, birthdate, date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))) >= 15 and
   ( diff between 21 and 28 or
      diff between 45 and 52 or
       diff between 76 and 83 or
     diff between 263 and 270)

