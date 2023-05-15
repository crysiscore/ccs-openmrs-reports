/*
NAME:  Pacientes com regimes terapeuticos discordantes (Fila VS Ficha Mestra)
Created by: Agnaldo Samuel <agnaldosamuel@ccsaude.org.mz>
creation date: 16/08/2022
Description:
        -  Pacientes com regimes terapeuticos discordantes (Fila VS Ficha Mestra)

USE openmrs;
SET :startDate:='2022-03-21';
SET :endDate:='2022-08-08';
SET :location:=208;
*/


SELECT * 
FROM 
(SELECT 	
            inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
			DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
            tipo_dispensa.tipodispensa,
            DATE_FORMAT(ultimoFila.encounter_datetime,'%d/%m/%Y')   AS data_ult_levantamento,
			DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
            DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
			regime_fc.ultimo_regime AS regime_fc,
			DATE_FORMAT( regime_fc.data_regime ,'%d/%m/%Y')  AS  data_regime_dc,
			regime_fila.ultimo_regime as regime_fila,
			DATE_FORMAT( regime_fila.data_regime ,'%d/%m/%Y')  AS data_regime_fila
            /*pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'*/

			
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
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9,53) AND
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program: OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
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
		
		INNER JOIN		
		(	SELECT ultimavisita.patient_id,ultimavisita.value_datetime -- ,e.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime
					FROM 	encounter e 
					INNER JOIN obs o ON o.encounter_id=e.encounter_id 
					INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND o.voided =0  AND e.encounter_type IN (6,9,35) AND  o.concept_id IN (5096 ,1410,6310)
						AND	e.location_id=:location AND e.encounter_datetime <=:endDate  AND o.value_datetime IS  NOT NULL
					GROUP BY p.patient_id
				) ultimavisita
			/*NNER JOIN encounter e on e.patient_id=ultimavisita.patient_id
			inner join obs o on o.encounter_id = e.encounter_id
			where e.voided=0 AND o.voided =0  and ultimavisita.value_datetime = o.value_datetime AND e.encounter_type IN (6,9,35) AND  o.concept_id IN (5096 ,1410,6310)
              */
		) visita ON visita.patient_id=inicio_real.patient_id

		LEFT JOIN 
		(SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
				WHERE 	e.voided=0  AND e.encounter_type=18 AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=5096 AND o.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND 
			e.encounter_type=18 AND e.location_id=:location 
		) ultimoFila ON ultimoFila.patient_id=inicio_real.patient_id
        
		LEFT JOIN
		(
			SELECT 	pg.patient_id
			FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
			WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
		) programa ON programa.patient_id=inicio_real.patient_id

			/** **************************************** Tipo dispensa  concept_id = 23739 **************************************** **/
    LEFT JOIN 
		( SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 23888  THEN 'DISPENSA SEMESTRAL'
					WHEN 1098 THEN 'DISPENSA MENSAL'
					WHEN 23720 THEN 'DISPENSA TRIMESTRAL'
				ELSE '' END AS tipodispensa,
                e.encounter_datetime
                FROM encounter e INNER JOIN
                ( SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_tipo_dis
					FROM 	obs o
					INNER JOIN encounter e ON o.encounter_id=e.encounter_id
					WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23739 AND o.location_id=:location
					GROUP BY patient_id ) ult_dispensa
					ON e.patient_id =ult_dispensa.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53)
             AND ult_dispensa.data_ult_tipo_dis = e.encounter_datetime 
             AND o.voided=0 AND o.concept_id = 23739
             GROUP BY patient_id
		) tipo_dispensa ON tipo_dispensa.patient_id=inicio_real.patient_id


LEFT JOIN (
	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
				WHERE 	e.voided=0 AND e.encounter_type IN (9,6) 
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND 
			e.encounter_type IN (9,6) AND e.location_id=:location 
            ) ult_seguimento ON ult_seguimento.patient_id = inicio_real.patient_id

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
						WHEN 5424 THEN 'OUTRO MEDICAMENTO ANTI-RETROVIRAL'
						ELSE 'OUTRO' END AS ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				FROM 	encounter e
                INNER JOIN
                         ( SELECT e.patient_id,MAX(encounter_datetime) encounter_datetime
                         FROM encounter e
                         INNER JOIN obs o ON e.encounter_id=o.encounter_id
                         WHERE 	encounter_type =18 AND o.concept_id=1088  AND e.voided=0 AND o.voided=0
                         GROUP BY e.patient_id
                         ) ultimofila
				ON e.patient_id=ultimofila.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE  ultimofila.encounter_datetime = e.encounter_datetime AND
                        encounter_type =18 AND e.voided=0 AND o.voided=0 AND
						o.concept_id=1088 AND e.location_id=:location

			) regime_fila ON regime_fila.patient_id=inicio_real.patient_id
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
						WHEN 6107 THEN 'TDF+AZT+3TC+LPV/r'
						WHEN 6105 THEN 'ABC+3TC+NVP'
						WHEN 6108 THEN 'TDF+3TC+LPV/r'
						WHEN 23787 THEN 'ABC+AZT+LPV/r'
						WHEN 23788 THEN 'TDF+ABC+3TC+LPV/r'
						WHEN 23789 THEN 'TDF+AZT+LPV/r'
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
						WHEN 6234 THEN 'ABC+TDF+LPV/r'
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
						WHEN 165262 THEN 'ABC+3TC+RAL'
						WHEN  165330 THEN 'ATV/r+TDF+3TC+DTG'
						WHEN 5424 THEN 'OUTRO MEDICAMENTO ANTI-RETROVIRAL'
						ELSE 'OUTRO' END AS ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				FROM 	encounter e
                INNER JOIN
                         ( SELECT e.patient_id,MAX(encounter_datetime) encounter_datetime
                         FROM encounter e
                         INNER JOIN obs o ON e.encounter_id=o.encounter_id
                         WHERE 	encounter_type in (6,9)  AND o.concept_id=1087 and e.voided=0 AND o.voided=0
                         GROUP BY e.patient_id
                         ) ultimofila
				ON e.patient_id=ultimofila.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE  ultimofila.encounter_datetime = e.encounter_datetime AND
                        encounter_type in (6,9) AND e.voided=0 AND o.voided=0 AND
						o.concept_id=1087 AND e.location_id=:location

			) regime_fc ON regime_fc.patient_id=inicio_real.patient_id

	WHERE inicio_real.patient_id NOT IN
		(
			-- Pacientes que sairam do programa TARV-TRATAMENTO ( Panel do Paciente)
			SELECT 	pg.patient_id		
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
									pg.program_id=2 AND    location_id=:location		
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
                                       
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,9,10) AND   location_id= :location AND ps.start_date <=:endDate
					GROUP BY pg.patient_id
		    UNION ALL
           -- Pacientes que sairam do programa TARV-TRATAMENTO ( Home Card Visit)
           SELECT  patient_id FROM (
            SELECT homevisit.patient_id,homevisit.encounter_datetime,
					 CASE o.value_coded
					 WHEN 2005  THEN   'Esqueceu a Data'
					 WHEN 2006  THEN   'Esta doente'
					 WHEN 2007  THEN   'Problema de transporte'
					 WHEN 2010  THEN   'Mau atendimento na US'
					 WHEN 23915 THEN   'Medo do provedor de saude na US'
					 WHEN 23946 THEN   'Ausencia do provedor na US'
					 WHEN 2015  THEN   'Efeitos Secundarios'
					 WHEN 2013  THEN   'Tratamento Tradicional'
					 WHEN 1706  THEN   'Transferido para outra US'
					 WHEN 23863 THEN   'AUTO Transferencia'
					 WHEN 2017  THEN   'OUTRO'
					 END AS motivo_saida
					 FROM 	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type=21  AND e.location_id=:location AND
								e.encounter_datetime<=:endDate
						GROUP BY e.patient_id
					) homevisit
					INNER JOIN encounter e ON e.patient_id=homevisit.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id =2016  AND o.value_coded IN (1706,23863) AND o.voided=0 AND p.voided =0 AND e.voided=0 AND e.encounter_datetime=homevisit.encounter_datetime AND
					e.encounter_type =21 AND e.location_id=:location

                 -- Pacientes que sairam do programa TARV-TRATAMENTO ( Ficha Mestra)
             UNION ALL
             SELECT master_card.patient_id,master_card.encounter_datetime,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US'
					 WHEN 1366 THEN 'Obito'
					 END AS motivo_saida
					 FROM	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE  e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND
								e.encounter_datetime<=:endDate
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  =6273  AND o.value_coded in (1366, 1706) AND o.voided=0 AND p.voided =0  AND e.voided=0
					AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id ) transfered_out

		) AND DATEDIFF(:endDate,visita.value_datetime)<= 28 -- De 33 para 28 Solicitacao do Mauricio 27/07/2020

) activos where regime_fila <> regime_fc
GROUP BY patient_id