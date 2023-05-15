/*

Name: CCS DATA QUALITY REPORT RDQ1
Created by: Agnaldo Samuel <agnaldosamuel@ccsaude.org.mz>
creation date: 16/08/2022
Description-
              - Pacientes actualmente em tarv, cPacientes que iniciaram TB a mais de 6 meses sem desfecho
USE openmrs;
SET @startDate:='2022-03-21';
SET :endDate:='2022-08-08';
SET :location:=208;
*/


SELECT *
FROM
(SELECT
     inicio_real.patient_id,
     CONCAT(pid.identifier,' ')                                                                                                AS NID,
     CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,''))                              AS 'NomeCompleto',
     p.gender,
     DATE_FORMAT(p.birthdate,'%d/%m/%Y')                                                                                       AS birthdate ,
     ROUND(DATEDIFF(:endDate,p.birthdate)/365)                                                                                    idade_actual,
     DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y')                                                                           AS data_inicio,
     marcado_tb_fc.tratamento_tb                                                                                               AS estado_tb_fc,
     DATE_FORMAT(  marcado_tb_fc.data_marcado_tb , '%d/%m/%Y')                                                                 AS data_inicio_tb_fc,
     DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')                                                                         AS proximo_marcado,
     DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y')                                                                AS data_ult_visita_2,
     DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y')                                                                     AS data_proxima_visita,
     IF(DATEDIFF(:endDate,visita.value_datetime)<=28,'ACTIVO EM TARV','ABANDONO NAO NOTIFICADO')                                  estado,
     inicio_tb_panel_paciente.nome_programa,
     if(inicio_tb_panel_paciente.program_state='ACTIVO PRE-TARV','ACTIVO NO PROGRAMA',inicio_tb_panel_paciente.program_state ) AS program_state,
     DATE_FORMAT(inicio_tb_panel_paciente.start_date,'%d/%m/%Y') as start_date ,
     inicio_tb_panel_paciente.duracao_prog

        FROM
        (	SELECT patient_id,MIN(data_inicio) data_inicio
            FROM
                (

                    /*Patients on ART who initiated the ARV DRUGS@ ART Regimen Start Date*/

                            SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
                            FROM 	patient p
                                    INNER JOIN encounter e ON p.patient_id=e.patient_id
                                    INNER JOIN obs o ON o.encounter_id=e.encounter_id
                            WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND
                                    e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND
                                    e.encounter_datetime<=:endDate AND e.location_id=:location
                            GROUP BY p.patient_id

                            UNION

                            /*Patients on ART who have art start date@ ART Start date*/
                            SELECT 	p.patient_id,MIN(value_datetime) data_inicio
                            FROM 	patient p
                                    INNER JOIN encounter e ON p.patient_id=e.patient_id
                                    INNER JOIN obs o ON e.encounter_id=o.encounter_id
                            WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND
                                    o.concept_id=1190 AND o.value_datetime IS NOT NULL AND
                                    o.value_datetime<=:endDate AND e.location_id=:location
                            GROUP BY p.patient_id

                            UNION

                            /*Patients enrolled in ART Program@ OpenMRS Program*/
                            SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
                            FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
                            WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
                            GROUP BY pg.patient_id

                            UNION


                            /*Patients with first drugs pick up date set in Pharmacy@ First ART Start Date*/
                              SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
                              FROM 		patient p
                                        INNER JOIN encounter e ON p.patient_id=e.patient_id
                              WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate AND e.location_id=:location
                              GROUP BY 	p.patient_id




                ) inicio
            GROUP BY patient_id
        )inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		LEFT JOIN
	   (SELECT pad1.*
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
		(
		   SELECT pid1.*
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

 	   -- PATIENT PROGRAM ENROLLMENT : TUBERCULOSES
        INNER JOIN (
			SELECT 	pg.patient_id ,pg.program_id , pgr.name as nome_programa ,/*pg. patient_program_id,*/ ps.start_date,
			        /*ps.state,pws.concept_id, pws.initial, pws.terminal,*/ c.name as program_state,
			        TIMESTAMPDIFF(MONTH,ps.start_date, :endDate) as duracao_prog
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=5 AND    location_id=:location
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
                     LEFT JOIN program_workflow_state pws on ps.state = pws.program_workflow_state_id
			    LEFT JOIN
                    (SELECT  c.concept_id,cn.name FROM concept c
                    INNER JOIN concept_name cn ON c.concept_id=cn.concept_id
                    WHERE locale ='pt' group by c.concept_id

                    ) c on c.concept_id = pws.concept_id
			       LEFT JOIN  program pgr on pgr.program_id = pg.program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=5  AND pws.concept_id IN (6269,1369) AND location_id= :location
					-- GROUP BY pg.patient_id


        )  inicio_tb_panel_paciente  on inicio_tb_panel_paciente.patient_id = inicio_real.patient_id

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

        /************************** ULTIMO INICIO TRATAMENTO DE TUBERCULOSE NA FICHA CLINICA  ****************************/
        left join
		( Select ultimavisita_tb.patient_id, ultimavisita_tb.encounter_datetime data_marcado_tb,
        CASE o.value_coded
					WHEN '1256'  THEN 'INICIO'
					WHEN '1257' THEN 'CONTINUA'
				    WHEN '1267' THEN 'COMPLETO'
				ELSE 'OUTRO' END AS tratamento_tb
			from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e
                        inner join obs o on o.encounter_id =e.encounter_id
				       and 	e.voided=0  and o.voided=0   and o.concept_id=1268 and e.encounter_type IN (6,9)  and e.location_id=:location
				group by e.patient_id
			) ultimavisita_tb
			inner join encounter e on e.patient_id=ultimavisita_tb.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
          where o.concept_id=1268 and o.voided=0 and e.encounter_datetime=ultimavisita_tb.encounter_datetime and
			e.encounter_type in (6,9)and o.value_coded in (1256,1257,1267)and e.location_id=:location
		) marcado_tb_fc on marcado_tb_fc.patient_id =   inicio_real.patient_id

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
         AND duracao_prog > 6
) activos
GROUP BY patient_id