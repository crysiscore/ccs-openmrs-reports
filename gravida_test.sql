 SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                WHEN 165331 THEN 'MENOR QUE'
                WHEN 23814 THEN 'CARGA VIRAL INDETECTAVEL'
                ELSE concat('OUTRO - ',value_coded  )
                END  AS carga_viral_qualitativa,
                 o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) AND  e.patient_id=15883  -- and e.encounter_datetime < '2025-10-20'
                GROUP BY e.patient_id