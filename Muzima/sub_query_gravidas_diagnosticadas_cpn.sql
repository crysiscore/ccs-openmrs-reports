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
         INNER JOIN
     (SELECT patient_id, max(data_consulta) data_consulta, max(data_proxima_consulta) data_proxima_consulta
      FROM (SELECT ultimavisita.patient_id,
                   ultimavisita.encounter_datetime data_consulta,
                   o.value_datetime                data_proxima_consulta
            FROM (SELECT p.patient_id, max(encounter_datetime) as encounter_datetime
                  FROM encounter e
                           INNER JOIN patient p on p.patient_id = e.patient_id
                  WHERE e.voided = 0
                    and p.voided = 0
                    and e.encounter_type = 6
                    and e.location_id =
                        (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                    and e.encounter_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                  group by p.patient_id) ultimavisita
                     INNER JOIN encounter e on e.patient_id = ultimavisita.patient_id
                     INNER JOIN obs o on o.encounter_id = e.encounter_id
            WHERE o.concept_id = 1410
              and o.voided = 0
              and e.encounter_datetime = ultimavisita.encounter_datetime
              and e.encounter_type = 6
              and e.location_id =
                  (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')

            UNION

            SELECT ultimavisita.patient_id,
                   ultimavisita.encounter_datetime data_consulta,
                   o.value_datetime                data_proxima_consulta
            FROM (SELECT p.patient_id, max(encounter_datetime) as encounter_datetime
                  FROM encounter e
                           INNER JOIN patient p on p.patient_id = e.patient_id
                  WHERE e.voided = 0
                    and p.voided = 0
                    and e.encounter_type = 35
                    and e.location_id =
                        (SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
                    and e.encounter_datetime <= date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                  group by p.patient_id) ultimavisita
                     INNER JOIN encounter e on e.patient_id = ultimavisita.patient_id
                     INNER JOIN obs o on o.encounter_id = e.encounter_id
            WHERE o.concept_id = 6310
              and o.voided = 0
              and e.encounter_datetime = ultimavisita.encounter_datetime
              and e.encounter_type = 35
              and e.location_id = (SELECT value_string
                                   FROM muzima_setting
                                   WHERE property = 'Encounter.DefaultLocationId')) consultaRecepcao
      group by patient_id

     ) consulta on inicio_real.patient_id = consulta.patient_id
         /**********      Gravidas Diagnosticadas CPN    ***************/
         INNER JOIN (SELECT patient_id, max(data_gravida) data_gravida
                     FROM (
                              /*********************** Data da gravidez **************************/
                              SELECT p.patient_id, e.encounter_datetime data_gravida
                              FROM patient p

                                       INNER JOIN encounter e on p.patient_id = e.patient_id
                                       INNER JOIN obs o on e.encounter_id = o.encounter_id

                              WHERE p.voided = 0
                                and e.voided = 0
                                and o.voided = 0
                                and concept_id = 1600
                                and e.encounter_type in (5, 6)
                                and e.encounter_datetime BETWEEN date_add(
                                      date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -9
                                      month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                                and e.location_id = (SELECT location_id
                                                     FROM location l
                                                     WHERE l.name = (SELECT property_value
                                                                     FROM global_property
                                                                     WHERE property = 'default_location'))
                              union
                              /**** Inscricao no programa PTV/ETV ***/
                              SELECT pp.patient_id, pp.date_enrolled data_gravida
                              FROM patient_program pp
                              WHERE pp.program_id = 8
                                and pp.voided = 0
                                and pp.date_enrolled BETWEEN date_add(
                                      date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -9
                                      month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                                and pp.location_id = (SELECT location_id
                                                      FROM location l
                                                      WHERE l.name = (SELECT property_value
                                                                      FROM global_property
                                                                      WHERE property = 'default_location'))

                              union
                              /*****   Gravida com inicio inicio tarv no periodo na: Ficha resumo **************/
                              SELECT p.patient_id, o.value_datetime data_gravida
                              FROM patient p
                                       INNER JOIN encounter e on p.patient_id = e.patient_id
                                       INNER JOIN obs o on e.encounter_id = o.encounter_id
                              --    INNER JOIN obs obsART on e.encounter_id = obsART.encounter_id
                              WHERE p.voided = 0
                                and e.voided = 0
                                and o.voided = 0
                                and o.concept_id = 1982
                                and o.value_coded = 1065
                                and e.encounter_type = 53
                                and o.value_datetime BETWEEN date_add(
                                      date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -9
                                      month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                                and e.location_id = (SELECT location_id
                                                     FROM location l
                                                     WHERE l.name = (SELECT property_value
                                                                     FROM global_property
                                                                     WHERE property = 'default_location'))

                              union
                              --  Marcada Gestante  na FC
                              SELECT p.patient_id, e.encounter_datetime data_gravida
                              FROM patient p
                                       INNER JOIN encounter e
                                                  on p.patient_id = e.patient_id
                                       INNER JOIN obs o on e.encounter_id = o.encounter_id
                              WHERE p.voided = 0
                                and e.voided = 0
                                and o.voided = 0
                                and concept_id = 1982
                                and value_coded = 1065
                                and e.encounter_type in (5, 6)
                                and e.encounter_datetime BETWEEN date_add(
                                      date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -9
                                      month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                                and current_date
                                and e.location_id = (SELECT location_id
                                                     FROM location l
                                                     WHERE l.name = (SELECT property_value
                                                                     FROM global_property
                                                                     WHERE property = 'default_location'))) all_gravida
                     group by patient_id) gravida_real on gravida_real.patient_id = inicio_real.patient_id

         INNER JOIN person p on p.person_id = inicio_real.patient_id
WHERE timestampdiff(year, birthdate, date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))) >= 15
  and inicio_real.data_inicio between date_add(date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -90
                                               DAY) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
  and (datediff(date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), inicio_real.data_inicio) between 15 and 22 or
       datediff(date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), inicio_real.data_inicio) between 45 and 52 or
       datediff(date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), inicio_real.data_inicio) between 75 and 82)
