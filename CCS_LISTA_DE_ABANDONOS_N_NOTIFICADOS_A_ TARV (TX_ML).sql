/*
Name: CCS LISTA DE ABANDONOS NÃO NOTIFICADOS AO TARV (TX_ML)
Description:
              -  Usando os critérios do indicador TX_ML  (OpenMRS TX_ML Indicator Specification and Requirements_v2.7.4.dox )
              -  https://www.dropbox.com/s/t22b3ggfd071vfq/OpenMRS%20TX_ML%20Indicator%20Specification%20and%20Requirements_v2.7.4.docx?dl=0


Created By: Agnaldo Samuel
Created Date: 18-11-2020

Change by: Agnaldo  Samuel
Change Date: 14/06/2021 
Change Reason: Bug fix 
              - A Sub-consulta do ultimo_seguimento buscava  uma data incorrecta  
			  - 
Change Date: 08/08/2022 
Change Reason: Bug fix 
              -  Correcao no criterio de exclusao ( Pacientes transferidos da FC e cartao de visita).
			  -  Revisao da sub-consulta que verifica a saida no programa TARV-Tratamento (Visao geral OpenMRS)
              -
USE openmrs;
    SET :startDate:='2022-03-21';
    SET :endDate:='2022-06-20';
    SET :location:=208;

*/



SELECT *
FROM
(	SELECT 	inicio_real.patient_id,
				inicio_real.data_inicio,
				pad3.county_district AS 'Distrito' ,
				pad3.address2 AS 'PAdministrativo' ,
				pad3.address6 AS 'Localidade' ,
				pad3.address5 AS 'Bairro' ,
				pad3.address1 AS 'PontoReferencia' ,
				CONCAT(IFNULL(pn.given_name,''), ' ' , IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',					
				pid.identifier AS NID,
				p.gender,
                pat.value as telefone,
				ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
				DATE_FORMAT(saida.encounter_datetime,'%d/%m/%Y') as data_saida,
				IF(saida.estado IS NOT NULL,saida.estado,IF(DATEDIFF(:endDate ,ultimo_seguimento.value_datetime)>=28,'ABANDONO NAO NOTIFICADO',IF(DATEDIFF(:endDate ,ultimo_seguimento.value_datetime)<28,'FALTOSO',''))) AS tipo_saida,
				--  visita.encounter_datetime as ultimo_levantamento,
				-- visita.value_datetime as proximo_marcado,
                 DATE_FORMAT(ultimo_seguimento.encounter_datetime,'%d/%m/%Y') as  ultimo_seg,
                 DATE_FORMAT(ultimo_seguimento.value_datetime,'%d/%m/%Y') as  prox_marcad,
                 DATE_FORMAT(ultimo_seguimento_fora_periodo.encounter_datetime,'%d/%m/%Y') as  ult_seg_fora_periodo,
                -- ultimo_seguimento.source,
                -- 3. All patients with the most recent date between the (1) last scheduled drug pick up date (Fila)
				-- and the (2) last scheduled consultation date (Ficha Seguimento or Ficha Clinica) 
				-- and (3) 30 days after the last ART pickup date (Recepção – Levantou ARV), 
				-- adding 28 days and this date is less than the reporting end Date and greater or equal than start date minus 1 day.
                DATE_ADD( ultimo_seguimento.value_datetime , INTERVAL 28 DAY) AS limite_txml,
			transfered_out_ficha_clinica.motivo_saida transfered_out_master_card,
			DATE_FORMAT(transfered_out_ficha_clinica.encounter_datetime,'%d/%m/%Y') as  data_transfered_out,
			transfered_out_homevisit.motivo_saida AS motivo_saida_home_visit,
			DATE_FORMAT(transfered_out_homevisit.encounter_datetime,'%d/%m/%Y') as  data_motivo_saida,
			IF(programa.patient_id IS NULL,'NAO','SIM') inscrito_programa
		FROM	
			(SELECT patient_id,data_inicio
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
					  
					  /*	union
						
						Patients with first drugs pick up date set: Recepcao Levantou ARV
						Select 	p.patient_id,min(value_datetime) data_inicio
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id
								inner join obs o on e.encounter_id=o.encounter_id
						where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=52 and 
								o.concept_id=23866 and o.value_datetime is not null and 
								o.value_datetime<=:endDate and e.location_id=:location 
						group by p.patient_id   */
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio <=:endDate 
)inicio_real
			INNER JOIN person p ON p.person_id=inicio_real.patient_id
			INNER JOIN
			(SELECT patient_id
				FROM (
					SELECT 	p.patient_id 
					FROM 	patient p INNER JOIN encounter e ON e.patient_id=p.patient_id 
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (5,7) AND e.encounter_datetime<=:endDate AND e.location_id = :location 

					UNION

					SELECT 	pg.patient_id
					FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					WHERE 	pg.voided=0 AND p.voided=0 AND program_id IN (1,2) AND date_enrolled<=:endDate AND location_id=:location 
					
					UNION
					
					SELECT 	p.patient_id
					FROM 	patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
							INNER JOIN obs o ON e.encounter_id=o.encounter_id
					WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=53 AND 
							o.concept_id=23891 AND o.value_datetime IS NOT NULL AND 
							o.value_datetime<=:endDate AND e.location_id=:location 


					) inscricao_programa group by patient_id
					
				
				
			)inscricao ON inicio_real.patient_id=inscricao.patient_id			
                       
            left join person_attribute pat on pat.person_id=inicio_real.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
           -- Include all patients who do not have the next scheduled drug pick up date (Fila) and next scheduled consultation date
           -- Ficha de Seguimento or Ficha Clinica) in their last clinical contact occurred during the reporting period and do not have
           -- any ART Pickup date (Recepção – Levantou ARV) during the reporting period 
              /*
				select patient_id,max(encounter_datetime) encounter_datetime, case when  MAX(value_datetime IS NULL) = 0 THEN max(value_datetime) ELSE NULL END as value_datetime, source
				from
				(
					Select ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime, 'Fila' as 'source' 
					from

					(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	encounter e 
								inner join patient p on p.patient_id=e.patient_id 		
						where 	e.voided=0 and p.voided=0 and e.encounter_type=18 and e.location_id=:location and 
								e.encounter_datetime<=:endDate 
						group by p.patient_id
					) ultimavisita
					inner join encounter e on e.patient_id=ultimavisita.patient_id
					inner join obs o on o.encounter_id=e.encounter_id			
					where o.concept_id=5096 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
					e.encounter_type=18 and e.location_id=:location 
					
					union
					
					Select 	p.patient_id,max(value_datetime) encounter_datetime,date_add(max(value_datetime), interval 30 day) as value_datetime,  'Recpcao- Levantou ARV' as 'source' 
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=52 and 
							o.concept_id=23866 and o.value_datetime is not null and 
							o.value_datetime<=:endDate and e.location_id=:location 
					group by p.patient_id
                     
                    union 
                    
                    Select ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime, 'Master Card' as 'source' 
					from

					(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	encounter e 
								inner join patient p on p.patient_id=e.patient_id 		
						where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=:location and 
								e.encounter_datetime<=:endDate 
						group by p.patient_id
					) ultimavisita
					inner join encounter e on e.patient_id=ultimavisita.patient_id
					inner join obs o on o.encounter_id=e.encounter_id			
					where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
					e.encounter_type in (6,9) and e.location_id=:location 
					
				) lev where encounter_datetime between :startDate and :endDate and value_datetime is null
				group by patient_id		 
                
                */
             -- 3.	All patients with the most recent date between the (1) last scheduled drug pick up date (Fila) 
             -- and the (2) last scheduled consultation date (Ficha Seguimento or Ficha Clinica) 
             -- and (3) 30 days after the last ART pickup date (Recepção – Levantou ARV), adding 28 days and this date is less than the reporting end Date and greater 
             -- or equal than start date minus 1 day.
             /***************************   Ultimo seguimento no periodo de analise ******************************* */
             LEFT JOIN 
             (        
				SELECT patient_id,MAX(encounter_datetime) encounter_datetime, MAX(value_datetime) AS value_datetime
				FROM
				(
					SELECT ultimofila.patient_id,ultimofila.encounter_datetime,o.value_datetime  -- , 'Fila' as 'source' 
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=18 AND e.location_id=:location AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
					) ultimofila
					INNER JOIN encounter e ON e.patient_id=ultimofila.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id			
					WHERE o.concept_id=5096 AND o.voided=0 AND e.encounter_datetime=ultimofila.encounter_datetime AND 
					e.encounter_type=18 AND e.location_id=:location 
					GROUP By e.patient_id
                    
					UNION
					
					SELECT 	e.patient_id,MAX(encounter_datetime) encounter_datetime,DATE_ADD(MAX(value_datetime), INTERVAL 30 DAY) AS value_datetime -- ,  'Recepcao- Levantou ARV' as 'source' 
					FROM 	encounter e
							INNER JOIN obs o ON e.encounter_id=o.encounter_id
					WHERE  e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
							o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
							o.value_datetime<=:endDate AND e.location_id=:location     
					GROUP BY e.patient_id                 
                    UNION 
                    
                    SELECT ultimaconsulta.patient_id,ultimaconsulta.encounter_datetime,o.value_datetime -- , 'Master Card - Ficha Clinica' as 'source' 
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
					) ultimaconsulta
					INNER JOIN encounter e ON e.patient_id=ultimaconsulta.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id			
					WHERE o.concept_id=1410 AND o.voided=0 AND e.encounter_datetime=ultimaconsulta.encounter_datetime AND 
					e.encounter_type IN (6,9) AND e.location_id=:location 
				    GROUP By e.patient_id
                    
				) lev_consulta
				GROUP BY patient_id		
                
                ) ultimo_seguimento ON inicio_real.patient_id = ultimo_seguimento.patient_id 
                /*************************** ultimo seguimento fora do periodo  *********************************************/
                
                       LEFT JOIN 
             (        
				SELECT patient_id, MAX(encounter_datetime) encounter_datetime
				FROM
				(
					SELECT ultimofila.patient_id,ultimofila.encounter_datetime
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=18 AND e.location_id=:location 
						GROUP BY p.patient_id
					) ultimofila
								
                    
					UNION
					
					SELECT 	e.patient_id,MAX(encounter_datetime) encounter_datetime
					FROM 	encounter e 
                    INNER JOIN obs o ON e.encounter_id=o.encounter_id
					WHERE e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
							o.concept_id=23866 AND o.value_datetime IS NOT NULL AND e.location_id=:location     
					GROUP BY e.patient_id                 
                    UNION 
                    
                    SELECT ultimaconsulta.patient_id,ultimaconsulta.encounter_datetime
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location 

						GROUP BY p.patient_id
					) ultimaconsulta

                    
				) lev_consulta
				GROUP BY patient_id		
                
                ) ultimo_seguimento_fora_periodo ON inicio_real.patient_id = ultimo_seguimento_fora_periodo.patient_id 
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
			LEFT JOIN
			(		
				/* SELECT 	pg.patient_id,max(ps.start_date) encounter_datetime,
                						CASE ps.state
							WHEN 7 THEN 'TRANSFERIDO PARA'
							WHEN 8 THEN 'SUSPENSO'
							WHEN 9 THEN 'ABANDONO'
							WHEN 10 THEN 'OBITO'
						ELSE 'OUTRO' END AS estado
				FROM 	patient p 
						INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
				WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
						pg.program_id=2 AND ps.state IN (7,8,9,10)  AND location_id=:location AND ps.start_date<= :endDate 
			         group by pg.patient_id
			         */
			         -- --------------------------------------------------------
			    SELECT 	pg.patient_id,ultimo_estado.data_ult_estado AS encounter_datetime,
			            CASE ps.state
							WHEN 7 THEN 'TRANSFERIDO PARA'
							WHEN 8 THEN 'SUSPENSO'
							WHEN 9 THEN 'ABANDONO'
							WHEN 10 THEN 'OBITO'
						ELSE 'OUTRO' END AS estado
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
			) saida ON saida.patient_id=inicio_real.patient_id
	
			LEFT JOIN ( SELECT homevisit.patient_id,homevisit.encounter_datetime,
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
					WHERE o.concept_id =2016  AND o.value_coded IN (1706,23863) AND o.voided=0 AND e.voided=0  AND p.voided=0 AND e.encounter_datetime=homevisit.encounter_datetime AND
					e.encounter_type =21 AND e.location_id=:location
					GROUP BY e.patient_id
				
			) transfered_out_homevisit ON transfered_out_homevisit.patient_id=inicio_real.patient_id

			LEFT JOIN ( SELECT master_card.patient_id,master_card.encounter_datetime,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US' 
					 WHEN 1366 THEN 'Obito'
					 END AS motivo_saida
							FROM	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id 		
						WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND
								e.encounter_datetime<=:endDate 
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  IN (6273)  AND o.value_coded in (1366, 1706) AND o.voided=0 AND p.voided=0 AND e.voided=0 AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location 
				    GROUP BY e.patient_id

			) transfered_out_ficha_clinica ON transfered_out_ficha_clinica.patient_id=inicio_real.patient_id
			LEFT JOIN
			(
				SELECT 	pg.patient_id
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location 
			) programa ON programa.patient_id=inicio_real.patient_id
	
	)inicios

		-- The system will exclude the following patients: (OpenMRS TX_ML Indicator Specification and Requirements_v2.7.4 )
		-- ALL Patients who were transferred-OUT (defined BY criteria ON TX_ML_FR6) BY END of previous reporting period AND
		-- ALL Patient who are dead (defined BY criteria ON TX_ML_FR4) BY END of previous reporting period.
WHERE patient_id NOT IN  
	
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
           -- Pacientes que sairam do programa TARV-TRATAMENTO (Home Card Visit)
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


             UNION ALL
              -- Pacientes que sairam do programa TARV-TRATAMENTO ( Ficha Mestra)
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
					WHERE o.concept_id  =6273  AND o.value_coded in (1366, 1706) AND o.voided=0 AND p.voided =0  AND e.voided=0 AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id ) transfered_out

				
		)   AND
		-- (OpenMRS TX_ML Indicator Specification and Requirements_v2.7.4)
		-- 3. All patients with the most recent date between the (1) last scheduled drug pick up date (Fila)
		-- and the (2) last scheduled consultation date (Ficha Seguimento or Ficha Clinica) 
		-- and (3) 30 days after the last ART pickup date (Recepção – Levantou ARV), 
		-- adding 28 days and this date is less than the reporting end Date and greater or equal than start date minus 1 day.
        DATE(limite_txml)   between DATE_SUB(:startDate , INTERVAL 1 DAY)  AND   :endDate
      -- AND data_transfered_out IS NULL AND data_motivo_saida IS  NULL
       
			
GROUP BY patient_id