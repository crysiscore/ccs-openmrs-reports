
SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT e.patient_id, encounter_datetime
                      FROM encounter e
                      INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime , (	SELECT	 visita.value_numeric
					FROM
                    ( SELECT e.patient_id, encounter_datetime,o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS ult_cv , (	SELECT	 visita.value_numeric
					FROM
                    ( SELECT e.patient_id, encounter_datetime,o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS penul_cv ,(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT e.patient_id, encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS data_penul_cv
FROM 	   ( SELECT e.patient_id, encounter_datetime, o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
				) visita2
GROUP BY visita2.patient_id
