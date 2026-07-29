SET @endDate := CURDATE();
SET @location := 212;


SELECT e.patient_id,
       DATE_FORMAT(e.encounter_datetime, '%Y-%m-%d')
               AS data_revelacao,
       CASE o.value_coded
           WHEN 6337 THEN 'REVELACAO TOTAL'
           WHEN 6338 THEN 'REVELACAO PARCIAL'
           WHEN 6339 THEN 'SEM REVELACAO'
           END AS estado_revelacao,
           TIMESTAMPDIFF(YEAR, pe.birthdate, @endDate) AS idade
FROM encounter e

         INNER JOIN
     (select e.patient_id, max(e.encounter_datetime) ult_revelacao

      from encounter e
               inner join obs o
                          ON o.encounter_id = e.encounter_id
      WHERE e.voided = 0
        AND o.voided = 0
        AND o.concept_id = 6340
        AND o.value_coded IN (6337, 6338, 6339)
        AND e.encounter_type IN (34, 35)
        AND e.location_id = @location
        AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
      GROUP BY e.patient_id) rev

     on rev.patient_id = e.patient_id
         and rev.ult_revelacao = e.encounter_datetime
         inner join obs o on o.encounter_id = e.encounter_id
INNER JOIN person pe
        ON pe.person_id =rev.patient_id
       AND pe.voided = 0
WHERE e.voided = 0
  AND o.voided = 0
  AND o.concept_id = 6340
  AND o.value_coded IN (6337, 6338, 6339)
  AND e.encounter_type IN (34, 35)
  AND e.location_id = @location
   AND TIMESTAMPDIFF(YEAR, pe.birthdate, @endDate) BETWEEN 8 AND 14
GROUP BY e.patient_id


/*

left join  patient p
        ON p.patient_id = revelacao.patient_id
       AND p.voided = 0
left JOIN person pe
        ON pe.person_id =revelacao.patient_id
       AND pe.voided = 0

WHERE p.voided = 0
  AND pe.birthdate IS NOT NULL
  AND pe.birthdate <= @endDate
  AND TIMESTAMPDIFF(YEAR, pe.birthdate, @endDate) BETWEEN 8 AND 14
*/