/*
    USE openmrs;
    SET :startDate:='2015-01-21';
    SET :endDate:='2022-08-08';
    SET :location:=208;

    SET @us:= (SELECT location.name
    FROM location INNER JOIN global_property
    ON location.name=global_property.property_value AND global_property.property='default_location') ;

*/

    SELECT :location as us ,activos_com_saidas.*
    FROM
    ( SELECT
                inicio_real.patient_id,
                CONCAT(pid.identifier,' ') AS NID,
                CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
                p.gender,
                DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
                ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
                DATE_FORMAT(ultimoFila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
                DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
                DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
                DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
                DATE_FORMAT(visita.value_datetime,'%d/%m/%Y') as prox_marcado_fila_or_fc  ,
                IF(ult_seguimento.value_datetime>ultimoFila.value_datetime,DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y'),DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   ) as ult_seguimento,
                IF(DATEDIFF(:endDate,visita.value_datetime)<=28,'ACTIVO EM TARV','ABAANDONO NAO NOTIFICADO') estado,
                DATE_FORMAT( ult_levant_master_card.data_ult_lev_master_card,'%d/%m/%Y')  AS data_ult_lev_master_card ,
                DATE_FORMAT(saida.data_ult_estado,'%d/%m/%Y')  AS data_ult_estado,
                saida.estado_tarv_trat,
                saida.fonte,
                pad3.county_district AS 'Distrito',
                pad3.address2 AS 'Padministrativo',
                pad3.address6 AS 'Localidade',
                pad3.address5 AS 'Bairro',
                pad3.address1 AS 'PontoReferencia'

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
        ) inicio_real

            INNER JOIN person p ON p.person_id=inicio_real.patient_id
  INNER JOIN
            (
	            SELECT ultimavisita.patient_id,ultimavisita.value_datetime
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

        /**  ******************************************  Levantamento de ARV Master Card  **** ************************************ **/
                LEFT JOIN (
        SELECT ult_lev_master_card.patient_id,o.value_datetime AS data_ult_lev_master_card
            FROM

                (	SELECT 	e.patient_id,MAX(o.value_datetime) AS value_datetime
                    FROM 	encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
                    WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type =52 AND o.concept_id=23866
                    GROUP BY patient_id
                ) ult_lev_master_card
                INNER JOIN encounter e ON e.patient_id=ult_lev_master_card.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id
                WHERE o.concept_id=23866 AND o.voided=0 AND e.voided=0 AND o.value_datetime=ult_lev_master_card.value_datetime AND
                e.encounter_type =52
               GROUP BY patient_id
                ) ult_levant_master_card ON ult_levant_master_card.patient_id = inicio_real.patient_id


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

            -- SAIDAS DO PROGRAMA EM TODAS FONTES
             INNER JOIN (

              Select patient_id , max(data_ult_estado) as data_ult_estado, estado_tarv_trat,  fonte FROM (
               -- Pacientes que sairam do programa TARV-TRATAMENTO ( Panel do Paciente)
              SELECT 	pg.patient_id, ultimo_estado.data_ult_estado,
                      CASE ps.state
                        WHEN  7  THEN  'TRANSFERIDO PARA'
                        WHEN  8  THEN  'SUSPENDER TRATAMENTO'
                        WHEN  9  THEN  'ABANDONO'
                      END  AS estado_tarv_trat ,
                     'Panel do paciente' as fonte

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
                        pg.program_id=2 AND ps.state IN (7,8,9) AND   location_id=:location  AND ps.start_date between date_sub(:endDate, INTERVAL 1 YEAR) AND
                    :endDate
                        GROUP BY pg.patient_id

                UNION ALL
                -- Pacientes que sairam do programa TARV-TRATAMENTO (Home Card Visit)
                 SELECT homevisit.patient_id,homevisit.encounter_datetime AS data_ult_estado ,
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
					 END AS estado_tarv_trat ,
                    'Home Card Visit' as fonte
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
             SELECT master_card.patient_id,master_card.encounter_datetime AS data_ult_estado ,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US'
					 WHEN 1366 THEN 'Obito'
					 END AS estado_tarv_trat,
                     'Ficha Clinica' as fonte
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
				    GROUP BY e.patient_id
				    ) all_saidas  group by  patient_id
        ) saida on saida.patient_id = inicio_real.patient_id
        WHERE
           DATEDIFF(:endDate,visita.value_datetime)<= 28  -- De 33 para 28 Solicitacao do Mauricio 27/07/2020
            AND ult_seguimento.encounter_datetime  > saida.data_ult_estado
          /* AND inicio_real.patient_id IN (

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
					WHERE o.concept_id  =6273  AND o.value_coded in (1366, 1706) AND o.voided=0 AND p.voided =0  AND e.voided=0 AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id ) transfered_out

            ) */

    ) activos_com_saidas

    GROUP BY patient_id

