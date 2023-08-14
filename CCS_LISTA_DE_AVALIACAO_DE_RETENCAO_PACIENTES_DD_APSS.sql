#SET @row_number = 0, @prev_patient_id = -1;
select *
from (select inicio_real.patient_id,
             DATE_FORMAT(inicio_tarv.data_inicio, '%d/%m/%Y')       as data_inicio_tarv,
             concat(ifnull(pn.given_name, ''), ' ', ifnull(pn.middle_name, ''), ' ',
             ifnull(pn.family_name, ''))                     as 'NomeCompleto',
             concat(pid.identifier, ' ')                            as NID,
             if(pad3.person_address_id is null, ' ',
             concat(' ', ifnull(pad3.address2, ''), ' ', ifnull(pad3.address5, ''), ' ', ifnull(pad3.address3, ''),
                    ' ', ifnull(pad3.address1, ''), ' ', ifnull(pad3.address4, ''), ' ',
                    ifnull(pad3.address6, '')))                  as endereco,
             p.gender,
             round(datediff(:endDate, p.birthdate) / 365)              idade_actual,
             DATE_FORMAT(inicio_real.data_apss, '%d/%m/%Y') as 'data_apss'

      FROM (Select fp_levantamentos.*
            /************************ MDC: FARMAC / Farmácia Privada  165177  **************************/
            from (Select dd.*, levantamentos.data_apss
                  from (SELECT e.patient_id,
                               CASE o.value_coded
                                   WHEN '165315' THEN 'DISPENSA DESCENTRALIZADA DE ARV'
                                   ELSE '' END         AS tipo_model,
                               MIN(encounter_datetime) AS data_fp
                        FROM obs o
                                 INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                        WHERE e.encounter_type IN (6, 9)
                          AND e.voided = 0
                          AND o.voided = 0
                          AND o.concept_id = 165174
                          AND o.value_coded = 165315
                          and e.location_id = :location
                        GROUP BY patient_id) dd
                           left join (SELECT patient_id, encounter_datetime as data_apss
                                      FROM (SELECT patient_id,
                                                   encounter_datetime,
                                                   @row_number := IF(@prev_patient_id = patient_id, @row_number + 1, 1) AS row_number,
                                                 @prev_patient_id := patient_id
                                            FROM encounter
                                            where encounter_type = 35 and voided = 0 AND encounter_datetime <= :endDate
                                            ORDER BY patient_id, encounter_datetime DESC) ranked
                                      WHERE row_number <= 6) levantamentos
                                     on levantamentos.patient_id = dd.patient_id) fp_levantamentos
            order by patient_id, data_apss desc) inicio_real


               left join person p on p.person_id = inicio_real.patient_id
               left join
           (select pad1.*
            from person_address pad1
                     inner join
                 (select person_id, min(person_address_id) id
                  from person_address
                  where voided = 0
                  group by person_id) pad2
            where pad1.person_id = pad2.person_id
              and pad1.person_address_id = pad2.id) pad3 on pad3.person_id = inicio_real.patient_id
               left join
           (select pn1.*
            from person_name pn1
                     inner join
                 (select person_id, min(person_name_id) id
                  from person_name
                  where voided = 0
                  group by person_id) pn2
            where pn1.person_id = pn2.person_id
              and pn1.person_name_id = pn2.id) pn on pn.person_id = inicio_real.patient_id
               left join
           (select pid1.*
            from patient_identifier pid1
                     inner join
                 (select patient_id, min(patient_identifier_id) id
                  from patient_identifier
                  where voided = 0
                  group by patient_id) pid2
            where pid1.patient_id = pid2.patient_id
              and pid1.patient_identifier_id = pid2.id) pid on pid.patient_id = inicio_real.patient_id
               left join person_attribute pat on pat.person_id = inicio_real.patient_id
          and pat.person_attribute_type_id = 9
          and pat.value is not null
          and pat.value <> '' and pat.voided = 0
               left join
           (select pg.patient_id,
                   ps.start_date           encounter_datetime,
                   location_id,
                   case ps.state
                       when 7 then 'TRANSFERIDO PARA'
                       when 8 then 'SUSPENSO'
                       when 9 then 'ABANDONO'
                       when 10 then 'OBITO'
                       else 'OUTRO' end as estado
            from patient p
                     inner join patient_program pg on p.patient_id = pg.patient_id
                     inner join patient_state ps on pg.patient_program_id = ps.patient_program_id
            where pg.voided = 0
              and ps.voided = 0
              and p.voided = 0
              and pg.program_id = 2
              and ps.state in (7, 8, 9, 10)
              and ps.end_date is null
              and location_id = :location) saida on saida.patient_id = inicio_real.patient_id

               left join (SELECT patient_id, art_start_date as data_inicio
                          FROM (SELECT patient_id, MIN(art_start_date) art_start_date
                                FROM (SELECT p.patient_id, MIN(e.encounter_datetime) art_start_date
                                      FROM patient p
                                               INNER JOIN encounter e ON p.patient_id = e.patient_id
                                               INNER JOIN obs o ON o.encounter_id = e.encounter_id
                                      WHERE e.voided = 0
                                        AND o.voided = 0
                                        AND p.voided = 0
                                        AND e.encounter_type in (18, 6, 9)
                                        AND o.concept_id = 1255
                                        AND o.value_coded = 1256
                                        AND e.encounter_datetime <= :endDate
                                        AND e.location_id = :location
                                      GROUP BY p.patient_id
                                      UNION
                                      SELECT p.patient_id, MIN(value_datetime) art_start_date
                                      FROM patient p
                                               INNER JOIN encounter e ON p.patient_id = e.patient_id
                                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                                      WHERE p.voided = 0
                                        AND e.voided = 0
                                        AND o.voided = 0
                                        AND e.encounter_type IN (18, 6, 9, 53)
                                        AND o.concept_id = 1190
                                        AND o.value_datetime is NOT NULL
                                        AND o.value_datetime <= :endDate
                                        AND e.location_id = :location
                                      GROUP BY p.patient_id
                                      UNION
                                      SELECT pg.patient_id, MIN(date_enrolled) art_start_date
                                      FROM patient p
                                               INNER JOIN patient_program pg ON p.patient_id = pg.patient_id
                                      WHERE pg.voided = 0
                                        AND p.voided = 0
                                        AND program_id = 2
                                        AND date_enrolled <= :endDate
                                        AND location_id = :location
                                      GROUP BY pg.patient_id
                                      UNION
                                      SELECT e.patient_id, MIN(e.encounter_datetime) AS art_start_date
                                      FROM patient p
                                               INNER JOIN encounter e ON p.patient_id = e.patient_id
                                      WHERE p.voided = 0
                                        AND e.encounter_type = 18
                                        AND e.voided = 0
                                        AND e.encounter_datetime <= :endDate
                                        AND e.location_id = :location
                                      GROUP BY p.patient_id
                                      UNION
                                      SELECT p.patient_id, MIN(value_datetime) art_start_date
                                      FROM patient p
                                               INNER JOIN encounter e ON p.patient_id = e.patient_id
                                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                                      WHERE p.voided = 0
                                        AND e.voided = 0
                                        AND o.voided = 0
                                        AND e.encounter_type = 52
                                        AND o.concept_id = 23866
                                        AND o.value_datetime is NOT NULL
                                        AND o.value_datetime <= :endDate
                                        AND e.location_id = :location
                                      GROUP BY p.patient_id) art_start
                                GROUP BY patient_id) tx_new) inicio_tarv
                         on inicio_tarv.patient_id = inicio_real.patient_id) levantamentos_dd

