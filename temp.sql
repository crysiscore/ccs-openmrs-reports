/*

USE openmrs;
SET startDate='2020-06-21';
SET endDate='2021-12-20';
SET location=208;
set modelo= 'FARMAC/Farmacia Privada';
*/


SELECT patient_id ,art_start_date as data_inicio
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
      GROUP BY patient_id) tx_new
WHERE art_start_date BETWEEN :startDate AND :endDate;