USE openmrs;
SET :endDate := '2023-03-20';
set :startDate := '2022-21-21';
SET :location := 208;


select
            distinct
            inicio_real.patient_id,
			pid.identifier AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			inicio_real.gender,
			DATE_FORMAT(inicio_real.birthdate,'%d/%m/%Y') as birthdate ,
            ROUND(DATEDIFF (:endDate,inicio_real.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
            DATE_FORMAT(data_ult_rastreio,'%d/%m/%Y') as data_ult_rastreio_ccu,
            DATE_FORMAT(seguimento.ultimo_seguimento, '%d/%m/%Y') as ultimo_seguimento,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') as data_proxima_visita,
            DATE_FORMAT(levantamento.ultimo_levantamneto, '%d/%m/%Y') as data_ultimo_levantamento,
            DATE_FORMAT(proximo_levantamento.value_datetime,'%d/%m/%Y') as data_proximo_levantamento,
            pad3.county_district AS 'Distrito',
			-- pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia',
            telef.value as telefone

      FROM
(

  SELECT criterio_1.patient_id, criterio_1.data_inicio, p.gender, p.birthdate,  ult_vis_ccu.encounter_datetime as data_ult_rastreio

   FROM ( SELECT *
        FROM (SELECT patient_id, MIN(data_inicio) data_inicio
              FROM (

                       /*Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date*/

                       SELECT p.patient_id, MIN(e.encounter_datetime) data_inicio
                       FROM patient p
                                INNER JOIN encounter e ON p.patient_id = e.patient_id
                                INNER JOIN obs o ON o.encounter_id = e.encounter_id
                       WHERE e.voided = 0
                         AND o.voided = 0
                         AND p.voided = 0
                         AND e.encounter_type IN (18, 6, 9)
                         AND o.concept_id = 1255
                         AND o.value_coded = 1256
                         AND e.encounter_datetime <= :endDate
                         AND e.location_id = :location
                       GROUP BY p.patient_id

                       UNION

                       /*Patients on ART who have art start date: ART Start date*/
                       SELECT p.patient_id, MIN(value_datetime) data_inicio
                       FROM patient p
                                INNER JOIN encounter e ON p.patient_id = e.patient_id
                                INNER JOIN obs o ON e.encounter_id = o.encounter_id
                       WHERE p.voided = 0
                         AND e.voided = 0
                         AND o.voided = 0
                         AND e.encounter_type IN (18, 6, 9, 53)
                         AND o.concept_id = 1190
                         AND o.value_datetime IS NOT NULL
                         AND o.value_datetime <= :endDate
                         AND e.location_id = :location
                       GROUP BY p.patient_id

                       UNION

                       /*Patients enrolled in ART Program: OpenMRS Program*/
                       SELECT pg.patient_id, MIN(date_enrolled) data_inicio
                       FROM patient p
                                INNER JOIN patient_program pg ON p.patient_id = pg.patient_id
                       WHERE pg.voided = 0
                         AND p.voided = 0
                         AND program_id = 2
                         AND date_enrolled <= :endDate
                         AND location_id = :location
                       GROUP BY pg.patient_id

                       UNION


                       /*Patients with first drugs pick up date set in Pharmacy: First ART Start Date*/
                       SELECT e.patient_id, MIN(e.encounter_datetime) AS data_inicio
                       FROM patient p
                                INNER JOIN encounter e ON p.patient_id = e.patient_id
                       WHERE p.voided = 0
                         AND e.encounter_type = 18
                         AND e.voided = 0
                         AND e.encounter_datetime <= :endDate
                         AND e.location_id = :location
                       GROUP BY p.patient_id) inicio
              GROUP BY patient_id) inicio2 )  criterio_1

        INNER JOIN person p ON p.person_id = criterio_1.patient_id
        INNER JOIN (SELECT lastvis.patient_id, lastvis.encounter_datetime
                    FROM (SELECT p.patient_id, max(encounter_datetime) as encounter_datetime
                          FROM encounter e
                                   inner join patient p on p.patient_id = e.patient_id
                          WHERE e.voided = 0
                            and p.voided = 0
                            and e.encounter_type = 28
                            and e.location_id = :location
                            and e.encounter_datetime <= :endDate
                          group by p.patient_id) lastvis )  ult_vis_ccu ON ult_vis_ccu.patient_id=criterio_1.patient_id
        --  Mulheres com idade superior a 15 anos rastreadas a mais d ano
        WHERE  p.gender = 'F' and  DATEDIFF(:endDate,p.birthdate)/365 > 15  and  DATEDIFF(:endDate,ult_vis_ccu.encounter_datetime) >= 365

	) inicio_real


    INNER JOIN
		(	SELECT ultimavisita.patient_id,ultimavisita.value_datetime,ultimavisita.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type
					FROM 	encounter e
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND o.voided =0  AND e.encounter_type IN (6,9,18) AND  o.concept_id IN (5096 ,1410)
						AND	e.location_id=:location AND e.encounter_datetime <=:endDate  AND o.value_datetime IS  NOT NULL
					GROUP BY p.patient_id
				) ultimavisita

		) visita ON visita.patient_id=inicio_real.patient_id
		
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


left join 
(	select  p.patient_id,max(encounter_datetime) ultimo_seguimento
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
	where 	e.voided=0 and p.voided=0 and e.encounter_datetime  and
			e.encounter_type in (6,9) and e.location_id=:location
	group by p.patient_id
) seguimento on inicio_real.patient_id=seguimento.patient_id 


left join (
	Select ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type in (9,6) 
				group by p.patient_id
			) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
			e.encounter_type in (9,6) and e.location_id=:location 
            ) ult_seguimento on ult_seguimento.patient_id = inicio_real.patient_id


left join (
	select  p.patient_id,max(encounter_datetime) ultimo_levantamneto
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
	where 	e.voided=0 and p.voided=0 and e.voided=0 and
			e.encounter_type=18 and e.location_id=:location
	group by p.patient_id
)levantamento on levantamento.patient_id = inicio_real.patient_id



left join (
Select ultimo_levantamento.patient_id,ultimo_levantamento.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type=18 
				group by p.patient_id
			) ultimo_levantamento
			inner join encounter e on e.patient_id=ultimo_levantamento.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=5096 and o.voided=0 and e.voided=0 and e.encounter_datetime=ultimo_levantamento.encounter_datetime and 
			e.encounter_type=18 and e.location_id=:location 
            ) proximo_levantamento on proximo_levantamento.patient_id = inicio_real.patient_id

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
           -- Pacientes que sairam do programa TARV-TRATAMENTO ( Ficha Mestra/Home Card Visit)
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

		) AND DATEDIFF(:endDate,visita.value_datetime)<= 28 -- De 33 para 28 Solicitacao do Mauricio 27/07/2020