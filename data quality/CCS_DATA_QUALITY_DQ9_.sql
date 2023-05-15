/*
NAME:  	Pacientes com pedidos de CV sem resultados
Created by: Agnaldo Samuel <agnaldosamuel@ccsaude.org.mz>
creation date: 20/02/2023
Description:
        - 	Pacientes com pedidos de CV sem resultados a mais de 2 semanas;
USE openmrs;
SET :startDate := '2022-03-21';
SET :endDate := '2023-02-20';
SET :location := 208;
*/


select ult_ped_cv.patient_id,
       pid.identifier AS NID,
       CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',

       p.gender,
	   DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
       ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
               DATE_FORMAT(ult_ped_cv.data_pedido_cv,'%d/%m/%Y') AS data_pedido_cv,
        DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_consulta,
        DATE_FORMAT(resultado_cv.data_ultima_carga,'%d/%m/%Y') AS data_ultima_carga

from ( /*	Ultimo Pedido de CV ba ficha clinica                            */
         select p.patient_id, max(e.encounter_datetime) data_pedido_cv
         from patient p
                  inner join encounter e on p.patient_id = e.patient_id
                  inner join obs pedido on pedido.encounter_id = e.encounter_id
         where p.voided = 0
           and e.voided = 0
           and pedido.voided = 0
           and pedido.concept_id = 23722
           and pedido.value_coded = 856
           and e.encounter_type in (6, 9)
           and e.location_id = :location
           and e.encounter_datetime between :startDate and :endDate
         group by p.patient_id) ult_ped_cv
         left join (
    /*	Ultimo resultado de CV              */
    select cv.*
    from (SELECT e.patient_id,
                 CASE o.value_coded
                     WHEN 1306 THEN 'Nivel baixo de detencao'
                     WHEN 23814 THEN 'Indectetavel'
                     WHEN 23905 THEN 'Menor que 10 copias/ml'
                     WHEN 23906 THEN 'Menor que 20 copias/ml'
                     WHEN 23907 THEN 'Menor que 40 copias/ml'
                     WHEN 23908 THEN 'Menor que 400 copias/ml'
                     WHEN 23904 THEN 'Menor que 839 copias/ml'
                     WHEN 165331 THEN concat(' < ', o.comments)
                     ELSE ''
                     END AS      carga_viral_qualitativa,
                 ult_cv.data_cv  data_ultima_carga,
                 o.value_numeric carga_viral_num,
                 fr.name AS      origem_resultado
          FROM encounter e
                   INNER JOIN (SELECT e.patient_id, MAX(encounter_datetime) AS data_cv
                               FROM encounter e
                                        INNER JOIN obs o ON e.encounter_id = o.encounter_id
                               WHERE e.encounter_type IN (6, 9, 13, 51)
                                 AND e.voided = 0
                                 AND o.voided = 0
                                 AND o.concept_id IN (856, 1305)
                               GROUP BY patient_id) ult_cv
                              ON e.patient_id = ult_cv.patient_id
                   INNER JOIN obs o ON o.encounter_id = e.encounter_id
                   LEFT JOIN form fr ON fr.form_id = e.form_id
          WHERE e.encounter_datetime = ult_cv.data_cv
            AND e.voided = 0
            AND e.location_id = :location
            AND e.encounter_type IN (6, 9, 13, 51)
            AND o.voided = 0
            AND o.concept_id IN (856, 1305) /*  AND  e.encounter_datetime  <=  :endDate  */
          GROUP BY e.patient_id) cv) resultado_cv on resultado_cv.patient_id = ult_ped_cv.patient_id
         LEFT JOIN (SELECT ultimavisita.patient_id, ultimavisita.encounter_datetime, o.value_datetime
                    FROM (SELECT e.patient_id, MAX(encounter_datetime) AS encounter_datetime
                          FROM encounter e
                          WHERE e.voided = 0
                            AND e.encounter_type IN (9, 6)
                          GROUP BY e.patient_id) ultimavisita
                             INNER JOIN encounter e ON e.patient_id = ultimavisita.patient_id
                             INNER JOIN obs o ON o.encounter_id = e.encounter_id
                    WHERE o.concept_id = 1410
                      AND o.voided = 0
                      AND e.voided = 0
                      AND e.encounter_datetime = ultimavisita.encounter_datetime
                      AND e.encounter_type IN (9, 6)
                      AND e.location_id = :location) ult_seguimento ON ult_seguimento.patient_id = ult_ped_cv.patient_id
         INNER JOIN person p ON p.person_id = ult_ped_cv.patient_id

         LEFT JOIN
     (SELECT pad1.*
      FROM person_address pad1
               INNER JOIN
           (SELECT person_id, MIN(person_address_id) id
            FROM person_address
            WHERE voided = 0
            GROUP BY person_id) pad2
      WHERE pad1.person_id = pad2.person_id
        AND pad1.person_address_id = pad2.id) pad3 ON pad3.person_id = ult_ped_cv.patient_id
         LEFT JOIN
     (SELECT pn1.*
      FROM person_name pn1
               INNER JOIN
           (SELECT person_id, MIN(person_name_id) id
            FROM person_name
            WHERE voided = 0
            GROUP BY person_id) pn2
      WHERE pn1.person_id = pn2.person_id
        AND pn1.person_name_id = pn2.id) pn ON pn.person_id = ult_ped_cv.patient_id
         LEFT JOIN
     (SELECT pid1.*
      FROM patient_identifier pid1
               INNER JOIN
           (SELECT patient_id, MIN(patient_identifier_id) id
            FROM patient_identifier
            WHERE voided = 0
            GROUP BY patient_id) pid2
      WHERE pid1.patient_id = pid2.patient_id
        AND pid1.patient_identifier_id = pid2.id) pid ON pid.patient_id = ult_ped_cv.patient_id


where resultado_cv.data_ultima_carga < ult_ped_cv.data_pedido_cv
  and ult_ped_cv.data_pedido_cv <= date_sub(:endDate, interval 2 WEEK)
  and ult_ped_cv.patient_id NOT IN
      (
          -- Pacientes que sairam do programa TARV-TRATAMENTO ( Panel do Paciente)
          SELECT pg.patient_id
          FROM patient p
                   INNER JOIN patient_program pg ON p.patient_id = pg.patient_id
                   INNER JOIN patient_state ps ON pg.patient_program_id = ps.patient_program_id
                   INNER JOIN (SELECT pg.patient_id, MAX(ps.start_date) AS data_ult_estado
                               FROM patient p
                                        INNER JOIN patient_program pg ON p.patient_id = pg.patient_id
                                        INNER JOIN patient_state ps ON pg.patient_program_id = ps.patient_program_id
                               WHERE pg.voided = 0
                                 AND ps.voided = 0
                                 AND p.voided = 0
                                 AND pg.program_id = 2
                                 AND location_id = :location
                               GROUP BY pg.patient_id) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND
                                                                        ultimo_estado.data_ult_estado = ps.start_date

          WHERE pg.voided = 0
            AND ps.voided = 0
            AND p.voided = 0
            AND pg.program_id = 2
            AND ps.state IN (7, 8, 9, 10)
            AND location_id = :location
            AND ps.start_date <= :endDate
          GROUP BY pg.patient_id
          UNION ALL
          -- Pacientes que sairam do programa TARV-TRATAMENTO ( Ficha Mestra/Home Card Visit)
          SELECT patient_id
          FROM (SELECT homevisit.patient_id,
                       homevisit.encounter_datetime,
                       CASE o.value_coded
                           WHEN 2005 THEN 'Esqueceu a Data'
                           WHEN 2006 THEN 'Esta doente'
                           WHEN 2007 THEN 'Problema de transporte'
                           WHEN 2010 THEN 'Mau atendimento na US'
                           WHEN 23915 THEN 'Medo do provedor de saude na US'
                           WHEN 23946 THEN 'Ausencia do provedor na US'
                           WHEN 2015 THEN 'Efeitos Secundarios'
                           WHEN 2013 THEN 'Tratamento Tradicional'
                           WHEN 1706 THEN 'Transferido para outra US'
                           WHEN 23863 THEN 'AUTO Transferencia'
                           WHEN 2017 THEN 'OUTRO'
                           END AS motivo_saida
                FROM (SELECT e.patient_id, MAX(encounter_datetime) AS encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON o.encounter_id = e.encounter_id
                      WHERE e.voided = 0
                        AND o.voided = 0
                        AND e.encounter_type = 21
                        AND e.location_id = :location
                        AND e.encounter_datetime <= :endDate
                      GROUP BY e.patient_id) homevisit
                         INNER JOIN encounter e ON e.patient_id = homevisit.patient_id
                         INNER JOIN obs o ON o.encounter_id = e.encounter_id
                         INNER JOIN patient p on p.patient_id = e.patient_id
                WHERE o.concept_id = 2016
                  AND o.value_coded IN (1706, 23863)
                  AND o.voided = 0
                  AND p.voided = 0
                  AND e.voided = 0
                  AND e.encounter_datetime = homevisit.encounter_datetime
                  AND e.encounter_type = 21
                  AND e.location_id = :location


                UNION ALL
                SELECT master_card.patient_id,
                       master_card.encounter_datetime,
                       CASE o.value_coded
                           WHEN 1706 THEN 'Transferido para outra US'
                           WHEN 1366 THEN 'Obito'
                           END AS motivo_saida
                FROM (SELECT e.patient_id, MAX(encounter_datetime) AS encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON o.encounter_id = e.encounter_id
                      WHERE e.voided = 0
                        AND o.voided = 0
                        AND e.encounter_type IN (6, 9)
                        AND e.location_id = :location
                        AND e.encounter_datetime <= :endDate
                      GROUP BY e.patient_id) master_card
                         INNER JOIN encounter e ON e.patient_id = master_card.patient_id
                         INNER JOIN obs o ON o.encounter_id = e.encounter_id
                         INNER JOIN patient p on p.patient_id = e.patient_id
                WHERE o.concept_id = 6273
                  AND o.value_coded in (1366, 1706)
                  AND o.voided = 0
                  AND p.voided = 0
                  AND e.voided = 0
                  AND e.encounter_datetime = master_card.encounter_datetime
                  AND e.encounter_type IN (6, 9)
                  AND e.location_id = :location
                GROUP BY e.patient_id) transfered_out)