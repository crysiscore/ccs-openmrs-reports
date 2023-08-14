USE openmrs;
SET @startDate :='2022-12-21';
SET @endDate :='2023-05-12';
SET @location =208;




    /* Start *******************************        Falencia CV           ***************************/


        SELECT e.patient_id,  vl_data_penult.data_penul_cv , o.value_numeric valor_penul_carga,   last_vl.data_ultima_carga as data_ult_vl, last_vl.valor_ultima_carga as valor_ult_vl
        FROM
        encounter e
        INNER JOIN obs o ON e.encounter_id=o.encounter_id
        INNER JOIN
            (
	SELECT 	e.patient_id,MAX(encounter_datetime) AS data_penul_cv  --
		FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
        INNER  JOIN  (  SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10  copias/ml'
                WHEN 23906 THEN  'Menor que 20  copias/ml'
                WHEN 23907 THEN  'Menor que 40  copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                ELSE ''
                END  AS carga_viral_qualitativa,
                o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                LEFT JOIN form fr ON fr.form_id = e.form_id
                WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= @location   AND e.encounter_type IN (6,9,13,51) AND
				 o.voided=0 AND 	o.concept_id IN( 856)  /* AND  e.encounter_datetime <= @endDate */
                GROUP BY e.patient_id ) last_vl on e.patient_id = last_vl.patient_id
	            WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856)
                AND e.encounter_datetime < last_vl.data_ultima_carga
				GROUP BY patient_id

    ) vl_data_penult ON vl_data_penult.patient_id =  e.patient_id
    LEFT JOIN  (  SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10  copias/ml'
                WHEN 23906 THEN  'Menor que 20  copias/ml'
                WHEN 23907 THEN  'Menor que 40  copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                ELSE ''
                END  AS carga_viral_qualitativa,
                o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                LEFT JOIN form fr ON fr.form_id = e.form_id
                WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= @location   AND e.encounter_type IN (6,9,13,51) AND
				 o.voided=0 AND 	o.concept_id IN( 856)  /* AND  e.encounter_datetime <= @endDate */
                GROUP BY e.patient_id ) last_vl on e.patient_id = last_vl.patient_id

   WHERE e.encounter_type IN (6,9,13,51) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856)
                AND e.encounter_datetime =vl_data_penult.data_penul_cv
				GROUP BY patient_id ;

        -- ---------------------------------------------------------------------------------------

     SELECT e.patient_id,  penul_cv.encounter_datetime AS data_penul_cv , o.value_numeric valor_penul_carga -- ,   last_vl.data_ultima_carga as data_ult_vl, last_vl.valor_ultima_carga as valor_ult_vl
        FROM
        encounter e
        INNER JOIN obs o ON e.encounter_id=o.encounter_id
        INNER JOIN
 (SELECT visita2.patient_id,
               (SELECT visita.encounter_datetime
                FROM (SELECT e.patient_id, encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)) visita
                WHERE visita.patient_id = visita2.patient_id
                ORDER BY encounter_datetime DESC
                LIMIT 1,1) AS encounter_datetime
        FROM (SELECT e.patient_id, encounter_datetime
              FROM encounter e
                       INNER JOIN obs o ON e.encounter_id = o.encounter_id
              WHERE e.encounter_type IN (6, 9, 13, 51)
                AND e.voided = 0
                AND o.voided = 0
                AND o.concept_id IN (856)) visita2
        GROUP BY visita2.patient_id)  penul_cv ON penul_cv.patient_id =  e.patient_id


        WHERE e.encounter_type IN (6,9,13,51) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856)
                AND e.encounter_datetime =penul_cv.encounter_datetime
				GROUP BY patient_id ;


  -- -----------------------------------------------------------------


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