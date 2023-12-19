/*
Name - CCS PACIENTES  INSCRISTOS PELO MENOS 1 VEZ EM MDS
Description:
              - Pacientes  inscritos peolo menos 1 vez em pelo menos 1 MDS

Created By - Agnaldo Samuel
Created Date-  28/10/2021

*/

SELECT * 
FROM 
(SELECT 	inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT( IFNULL(pn.given_name,''),' ', IFNULL(pn.middle_name,''),' ', IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
			DATE_FORMAT(modelodf.data_modelo ,'%d/%m/%Y') AS data_inscricao,
            modelodf.modelodf,
            regime.ultimo_regime,
			DATE_FORMAT(visita.encounter_datetime,'%d/%m/%Y') AS data_ult_consulta,
            DATE_FORMAT(visita.value_datetime,'%d/%m/%Y') AS consulta_proximo_marcado,
            DATE_FORMAT(fila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
            DATE_FORMAT(fila.value_datetime,'%d/%m/%Y') AS fila_proximo_marcado,
	        DATE_FORMAT(ultima_cv.data_ultima_carga,'%d/%m/%Y') AS data_ultima_carga,
            ultima_cv.valor_ultima_carga cv_numerico,
            ultima_cv.carga_viral_qualitativa AS cv_qualitativa,
            ultima_cv.Origem_Resultado,
		    pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'

			
	FROM	
	(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(	
			
				/*Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date: ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program: OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy: First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate AND e.location_id=:location
						  GROUP BY 	p.patient_id	
				
			) inicio
		GROUP BY patient_id	
	)inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		  /************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		INNER JOIN 
		(
			SELECT mdl.patient_id,  mdl.modelodf, MIN(mdl.data_modelo) AS data_modelo  FROM (
              SELECT 	e.patient_id,
				CASE o.concept_id
					WHEN '23724'  THEN 'GAAC (GA)'
					WHEN '23725'  THEN 'ABORDAGEM FAMILIAR'
					WHEN '23726'  THEN 'CLUBES DE ADESAO (CA)'
					WHEN '23727'  THEN 'PARAGEM UNICA (PU)'  
                    WHEN '23729'  THEN  'FLUXO RAPIDO (FR)'
					WHEN '23730'  THEN  'DISPENSA TRIMESTRAL (DT)'
					WHEN '23731'  THEN 'DISPENSA COMUNITARIA (DC)'
					WHEN '23732'  THEN 'OUTRO MODELO'
                    WHEN '23888'  THEN 'DISPENSA SEMESTRAL'
                    WHEN 165177   THEN ' FARMAC/Farmácia Privada'
				ELSE '' END AS modelodf, 
                 o.value_coded,
				MIN(encounter_datetime) AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888,165177)  AND o.location_id=:location
            GROUP BY patient_id
          
          
             UNION ALL
             
             			
              SELECT 	e.patient_id,
				CASE o.value_coded
                    WHEN '23888' THEN 'DISPENSA SEMESTRAL'
				ELSE '' END AS modelodf, 
                 o.value_coded,
				MIN(encounter_datetime) AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23739 AND o.value_coded=23888  AND o.location_id=:location
            GROUP BY patient_id ) mdl  GROUP BY patient_id
          
		) modelodf ON modelodf.patient_id=inicio_real.patient_id AND modelodf.data_modelo IS NOT NULL AND modelodf.data_modelo <= :endDate
		
	               
		LEFT JOIN 
			(	SELECT pad1.*
				FROM person_address pad1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_address_id) id 
					FROM person_address
					WHERE voided=0
					GROUP BY person_id
				) pad2
				WHERE pad1.person_id=pad2.person_id AND pad1.person_address_id=pad2.id
			) pad3 ON pad3.person_id=modelodf.patient_id				
			LEFT JOIN 			
			(	SELECT pn1.*
				FROM person_name pn1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_name_id) id 
					FROM person_name
					WHERE voided=0
					GROUP BY person_id
				) pn2
				WHERE pn1.person_id=pn2.person_id AND pn1.person_name_id=pn2.id
			) pn ON pn.person_id=modelodf.patient_id			
			LEFT JOIN
			(       SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
					(
						SELECT patient_id,MIN(patient_identifier_id) id
						FROM patient_identifier
						WHERE voided=0
						GROUP BY patient_id
					) pid2
					WHERE pid1.patient_id=pid2.patient_id AND pid1.patient_identifier_id=pid2.id
			) pid ON pid.patient_id=modelodf.patient_id
		
		LEFT JOIN 
			(
	SELECT 	e.patient_id,
						CASE o.value_coded
						WHEN 1703 THEN 'AZT+3TC+EFV'
						WHEN 6100 THEN 'AZT+3TC+LPV/r'
						WHEN 1651 THEN 'AZT+3TC+NVP'
						WHEN 6324 THEN 'TDF+3TC+EFV'
						WHEN 6104 THEN 'ABC+3TC+EFV'
						WHEN 23784 THEN 'TDF+3TC+DTG'
						WHEN 23786 THEN 'ABC+3TC+DTG'
						WHEN 6116 THEN 'AZT+3TC+ABC'
						WHEN 6106 THEN 'ABC+3TC+LPV/r'
						WHEN 6105 THEN 'ABC+3TC+NVP'
						WHEN 6108 THEN 'TDF+3TC+LPV/r'
						WHEN 23790 THEN 'TDF+3TC+LPV/r+RTV'
						WHEN 23791 THEN 'TDF+3TC+ATV/r'
						WHEN 23792 THEN 'ABC+3TC+ATV/r'
						WHEN 23793 THEN 'AZT+3TC+ATV/r'
						WHEN 23795 THEN 'ABC+3TC+ATV/r+RAL'
						WHEN 23796 THEN 'TDF+3TC+ATV/r+RAL'
						WHEN 23801 THEN 'AZT+3TC+RAL'
						WHEN 23802 THEN 'AZT+3TC+DRV/r'
						WHEN 23815 THEN 'AZT+3TC+DTG'
						WHEN 6329 THEN 'TDF+3TC+RAL+DRV/r'
						WHEN 23797 THEN 'ABC+3TC+DRV/r+RAL'
						WHEN 23798 THEN '3TC+RAL+DRV/r'
						WHEN 23803 THEN 'AZT+3TC+RAL+DRV/r'						
						WHEN 6243 THEN 'TDF+3TC+NVP'
						WHEN 6103 THEN 'D4T+3TC+LPV/r'
						WHEN 792 THEN 'D4T+3TC+NVP'
						WHEN 1827 THEN 'D4T+3TC+EFV'
						WHEN 6102 THEN 'D4T+3TC+ABC'						
						WHEN 1311 THEN 'ABC+3TC+LPV/r'
						WHEN 1312 THEN 'ABC+3TC+NVP'
						WHEN 1313 THEN 'ABC+3TC+EFV'
						WHEN 1314 THEN 'AZT+3TC+LPV/r'
						WHEN 1315 THEN 'TDF+3TC+EFV'						
						WHEN 6330 THEN 'AZT+3TC+RAL+DRV/r'						
						WHEN 6102 THEN 'D4T+3TC+ABC'
						WHEN 6325 THEN 'D4T+3TC+ABC+LPV/r'
						WHEN 6326 THEN 'AZT+3TC+ABC+LPV/r'
						WHEN 6327 THEN 'D4T+3TC+ABC+EFV'
						WHEN 6328 THEN 'AZT+3TC+ABC+EFV'
						WHEN 6109 THEN 'AZT+DDI+LPV/r'
						WHEN 6329 THEN 'TDF+3TC+RAL+DRV/r'
						WHEN 21163 THEN 'AZT+3TC+LPV/r'						
						WHEN 23799 THEN 'TDF+3TC+DTG'
						WHEN 23800 THEN 'ABC+3TC+DTG'
						ELSE 'OUTRO' END AS ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				FROM 	encounter e
                INNER JOIN
                         ( SELECT e.patient_id,MAX(encounter_datetime) encounter_datetime 
                         FROM encounter e 
                         INNER JOIN obs o ON e.encounter_id=o.encounter_id
                         WHERE 	encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 
                         GROUP BY e.patient_id
                         ) ultimolev
				ON e.patient_id=ultimolev.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id 
				WHERE  ultimolev.encounter_datetime = e.encounter_datetime AND
                        encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND 
						o.concept_id=1087 AND e.location_id=:location
              GROUP BY patient_id

			) regime ON regime.patient_id=modelodf.patient_id
		            
            
	          /* ******************************** ultima levantamento *********** ******************************/
 		LEFT JOIN		
		(	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime
			FROM
				(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e 
							INNER JOIN obs o  ON e.encounter_id=o.encounter_id 		
					WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type =18 AND 
							e.location_id=:location 
					GROUP BY e.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                WHERE  o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime AND			
			  o.voided=0  AND e.voided =0 AND e.encounter_type =18  AND e.location_id=:location
		) fila ON fila.patient_id=modelodf.patient_id 
 

	/*  ** ******************************************  ultima consulta  **** ************************************* */ 
		LEFT JOIN		
		(		SELECT ultimoSeguimento.patient_id,ultimoSeguimento.encounter_datetime,o.value_datetime
	FROM

		(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
			FROM 	encounter e 
			INNER JOIN patient p ON p.patient_id=e.patient_id 		
			WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location 
			GROUP BY p.patient_id
		) ultimoSeguimento
		INNER JOIN encounter e ON e.patient_id=ultimoSeguimento.patient_id
		INNER JOIN obs o ON o.encounter_id=e.encounter_id			
		WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimoSeguimento.encounter_datetime AND 
		e.encounter_type IN (6,9) 
		) visita ON visita.patient_id=modelodf.patient_id 
	
	/* ******************************* ultima carga viral **************************** */
		LEFT JOIN (	    SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                ELSE ''
                END  AS carga_viral_qualitativa,
				ult_cv.data_cv_qualitativa data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS Origem_Resultado
                FROM  encounter e 
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv_qualitativa
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305) 
							GROUP BY patient_id
				) ult_cv 
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id 
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv_qualitativa	
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) AND  e.encounter_datetime <= :endDate 
                GROUP BY e.patient_id
			
		) ultima_cv ON ultima_cv.patient_id=modelodf.patient_id 


) activos
GROUP BY patient_id