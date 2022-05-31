select 
            inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
			DATE_FORMAT(p.birthdate,'%d/%m/%Y') as birthdate ,
            ROUND(DATEDIFF (:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
            sector_eligibilidade.sector as sector_elegibilidade,
            sector_inicio_prep.sector as sector_inicio_prep,
            situacao_prep.situacao_prep,
            DATE_FORMAT(situacao_prep.data_situacao,'%d/%m/%Y') as data_situacao,
            DATE_FORMAT(ult_seguimento_prep.encounter_datetime ,'%d/%m/%Y') as data_ult_seguimento,
            proveniencia.proveniencia ,
            interrupcao_prep.motivo_interrupcao,    
            key_pop.pop_chave,
            estado_gravidez.estado,
            pad3.county_district AS 'Distrito',
			-- pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia',
            telef.value as contacto

			
	FROM	
	(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(	
			
						/* Patients on ART who have PREP start date in PREP: PROFLAXIA PRE-EXPOSICAO - INCIAL */
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND /*e.encounter_type IN (80,81) AND */
								o.concept_id=165211 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in PREP OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=25 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id

						
				
				
			) inicio 
		GROUP BY patient_id	
	)inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		
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
			) pad3 ON pad3.person_id=inicio_real.patient_id				
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
			) pn ON pn.person_id=inicio_real.patient_id			
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
			) pid ON pid.patient_id=inicio_real.patient_id
            
            /* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value  
		FROM person_attribute p
     WHERE  p.person_attribute_type_id  =9 
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0 
	) telef  ON telef.person_id = inicio_real.patient_id

		 /** ************************** Situacao do PREP concept_id = 165296  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
				WHEN	1256  THEN 	'CASO NOVO'
                WHEN    1257     THEN 'CONTINUA'
				WHEN	1705	THEN 'REINICIAR'
				ELSE '' END AS situacao_prep,
                o.obs_datetime  as data_situacao
				FROM 	(
							SELECT 	e.patient_id,min(encounter_datetime) as data_ficha_inicial
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 165296 
							group by patient_id
				) ficha_inicial
			INNER JOIN encounter e on e.patient_id=ficha_inicial.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (80,81) AND ficha_inicial.data_ficha_inicial =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 165296 
            AND e.location_id=:location
			group by patient_id
		) situacao_prep ON situacao_prep.patient_id=inicio_real.patient_id
      
       /** ************************** Sector de captação da Elegibilidade a PrEP: Concept_id  = 23783  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
				WHEN 1597 THEN 'UATS'
                WHEN 1978 THEN 'CPN'
                WHEN 1987 THEN 'GATV/SAAJ'
                WHEN 165206 THEN 'DOENCAS CRONICAS'
                WHEN 23873 THEN 'TRIAGEM - ADULTOS'
                WHEN 5483 THEN 'CPF'
				WHEN 1872 THEN 'CCR'
				WHEN 6245 THEN 'ATSC'
				WHEN 23913 THEN 'OUTRO SERVICO'
                ELSE '' END AS sector
				FROM (
							SELECT 	e.patient_id,min(encounter_datetime) as data_ficha_inicial
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23783 
							group by patient_id
				)  ficha_inicial_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_inicial_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (80,81) AND ficha_inicial_prep.data_ficha_inicial =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 23783 
            AND e.location_id=:location
			group by patient_id
		) sector_eligibilidade ON sector_eligibilidade.patient_id=inicio_real.patient_id
      
         /** **************************Sector em que o(a) Utente irá iniciar a PreP: Concept_id  = 165291  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1987 THEN 'GATV/SAAJ'
                WHEN 165206 THEN 'DOENCAS CRONICAS'
                WHEN 23873 THEN 'TRIAGEM - ADULTOS'
                WHEN 5483 THEN 'CPF'
				WHEN 1872 THEN 'CCR'
				WHEN 23913 THEN 'OUTRO SERVICO'
                ELSE '' END AS sector
				FROM (
							SELECT 	e.patient_id,min(encounter_datetime) as data_ficha_inicial
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 165291 
							group by patient_id
				)  ficha_inicial_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_inicial_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (80,81) AND ficha_inicial_prep.data_ficha_inicial =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 165291 
            AND e.location_id=:location
			group by patient_id
		) sector_inicio_prep ON sector_inicio_prep.patient_id=inicio_real.patient_id

  /** ************************** Ultimo seguimento PREP  * ********************************************** **/
     
      left join (
	   Select ultimavisita.patient_id,ultimavisita.encounter_datetime
		from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
				where 	e.voided=0 and e.encounter_type = 81 
				AND e.location_id=:location group by e.patient_id
			) ultimavisita where  ultimavisita.encounter_datetime between :startDate and :endDate
			
            ) ult_seguimento_prep on ult_seguimento_prep.patient_id = inicio_real.patient_id

 /** ************************** Proveniencia do utente  1594 * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
				WHEN 1369	THEN 'TRANSFERIDO DE'
                WHEN 1922	THEN 'COMUNIDADE'
                WHEN 21154	THEN 'NESTA UNIDADE SANITARIA'             
                ELSE '' END AS proveniencia
				FROM (
							SELECT 	e.patient_id,min(encounter_datetime) as data_ficha_inicial
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 1594 
							group by patient_id
				)  ficha_inicial_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_inicial_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (80,81) AND ficha_inicial_prep.data_ficha_inicial =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 1594 
            AND e.location_id=:location
			group by patient_id
		) proveniencia ON proveniencia.patient_id=inicio_real.patient_id
      
    /** ************************** PrEP Interrompida  165225  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
				WHEN 1169 THEN 'HIV POSITIVO'
				WHEN 2015 THEN 'EFEITOS SECUNDARIOS ARV'
				WHEN 5622 THEN 'OUTRO, NAO CODIFICADO'
				WHEN 165226 THEN 'SEM MAIS RISCOS SUBSTANCIAIS'
				WHEN 165227 THEN 'PREFERENCIA DO UTENTE'

                ELSE '' END AS motivo_interrupcao
				FROM (
							SELECT 	e.patient_id,max(encounter_datetime) as data_ult_seguimento
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type  in (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 165225
 
							group by patient_id
				)  ficha_seguimento_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_seguimento_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type  in (80,81) AND ficha_seguimento_prep.data_ult_seguimento =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 165225
                       and  e.encounter_datetime between :startDate and :endDate AND e.location_id=:location
            group by patient_id
		) interrupcao_prep ON interrupcao_prep.patient_id=inicio_real.patient_id   

 /** ************************** POPULACAO CHAVE  23703  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT 	e.patient_id,
				CASE o.value_coded
				WHEN 165205 THEN 'TG'
				WHEN 20426 THEN 'REC'
				WHEN 20454 THEN 'PID'
				WHEN 1377 THEN 'HSH'
				WHEN 1901 THEN 'TRABALHADOR DE SEXO'
                ELSE '' END AS pop_chave
				FROM (
							SELECT 	e.patient_id,max(encounter_datetime) as data_ult_seguimento
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type in (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23703
 
							group by patient_id
				)  ficha_seguimento_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_seguimento_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type  in (80,81) AND ficha_seguimento_prep.data_ult_seguimento =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 23703
                     and  e.encounter_datetime between :startDate and :endDate AND e.location_id=:location
            group by patient_id
		) key_pop ON key_pop.patient_id=inicio_real.patient_id
        
 /** ************************** e mulher, indique o estado de Gravidez /Lactação? (assinalar) 165223  * ********************************************** **/
        LEFT JOIN 
		(
              SELECT e.patient_id,
				CASE o.value_coded
				WHEN 1066 THEN 'NAO'
				WHEN 6332 THEN 'LACTAÇÃO'
				WHEN 1982 THEN 'ESTA GRAVIDA'
			    ELSE '' END AS estado
				FROM (
							SELECT 	e.patient_id,max(encounter_datetime) as data_ult_seguimento
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type in (80,81) AND e.voided=0 AND o.voided=0 AND o.concept_id = 165223
 
							group by patient_id
				      )  ficha_seguimento_prep
                
			INNER JOIN encounter e on e.patient_id=ficha_seguimento_prep.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type in (80,81) AND ficha_seguimento_prep.data_ult_seguimento =e.encounter_datetime and e.voided=0 AND o.voided=0 AND o.concept_id = 165223
                     and  e.encounter_datetime between :startDate and :endDate AND e.location_id=:location
            group by patient_id
		) estado_gravidez ON estado_gravidez.patient_id=inicio_real.patient_id
      