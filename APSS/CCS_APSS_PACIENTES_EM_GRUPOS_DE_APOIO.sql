
SELECT *
FROM
( SELECT
            inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT( IFNULL(pn.given_name,''),' ', IFNULL(pn.middle_name,''),' ', IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
            DATE_FORMAT(gr_apoio_ult_inicio.data_grupo_apoio,'%d/%m/%Y') as grupoapoio_ult_inicio_apss,
            DATE_FORMAT(gr_apoio_ult_inicio_fc.data_grupo_apoio,'%d/%m/%Y') as grupoapoio_ult_inicio_fc,
            grupoapoio.grupoapoio,
            grupoapoio.estado_grupo_apoio,
            IF(DATEDIFF(:endDate,visita.value_datetime)<=28,'ACTIVO EM TARV','ABANDONO NAO NOTIFICADO') estado,
			DATE_FORMAT(seguimento.encounter_datetime,'%d/%m/%Y') AS data_ult_consulta,
            DATE_FORMAT(seguimento.value_datetime,'%d/%m/%Y') AS consulta_proximo_marcado,
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

		(
	    SELECT e.patient_id,
        CASE o.concept_id
            WHEN     165324 THEN 'ADOLESCENTE E JOVEM MENTOR'
			WHEN 23757 THEN 'ADOLESCENTES REVELADAS/OS (AR)'
			WHEN 23753 THEN 'CRIANCAS REVELADAS'
            WHEN 23755 THEN 'PAIS E CUIDADORES (PC)'
            WHEN 24031 THEN 'Mãe Mentora'
            WHEN 23759 THEN 'MAE PARA MAE (MPM)'
            WHEN 165325 THEN 'HOMEM CAMPEAO'
            WHEN 23772 THEN 'OUTRO GRUPO DE APOIO'
			ELSE '' END AS grupoapoio ,
			 last_grupo_apoio.encounter_datetime data_grupo_apoio,
	        case o.value_coded
            WHEN 1256 THEN 'INICIA'
            WHEN 1257 THEN 'CONTINUA'
	        WHEN 1267 THEN 'COMPLETO'
            ELSE '' END AS estado_grupo_apoio
			FROM

			(	SELECT  p.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                          INNER JOIN patient p ON p.patient_id=e.patient_id
                          INNER JOIN obs o ON o.encounter_id =e.encounter_id
				             AND 	e.voided=0  AND o.voided=0  AND p.voided=0  AND o.concept_id in (165324,23757,23753,23755,24031,23759,165325,23772 )
                            AND e.encounter_type IN (34,35)  AND e.location_id=:location and  encounter_datetime between :startDate and :endDate
				GROUP BY e.patient_id
			) last_grupo_apoio
			INNER JOIN encounter e ON e.patient_id=last_grupo_apoio.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id in (165324,23757,23753,23755,24031,23759,165325,23772 ) AND o.voided=0 and e.voided=0
			  AND e.encounter_datetime=last_grupo_apoio.encounter_datetime
			and e.encounter_type  IN (34,35) AND e.location_id=:location
              GROUP BY patient_id


		) grupoapoio

		    INNER JOIN person p ON p.person_id=grupoapoio.patient_id

	left join
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
	) inicio_real on inicio_real.patient_id = grupoapoio.patient_id

        LEFT JOIN
        (	SELECT ultimavisita.patient_id,ultimavisita.value_datetime,ultimavisita.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type
					FROM 	encounter e
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 and o.voided =0  AND e.encounter_type =18 AND  o.concept_id in (5096 ,1410)
						and	e.location_id=:location AND e.encounter_datetime <=:endDate  and o.value_datetime is  not null
					GROUP BY p.patient_id
				) ultimavisita

		) visita ON visita.patient_id=grupoapoio.patient_id

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
			) pad3 ON pad3.person_id=grupoapoio.patient_id
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
			) pn ON pn.person_id=grupoapoio.patient_id
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
			) pid ON pid.patient_id=grupoapoio.patient_id


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
		) fila ON fila.patient_id=grupoapoio.patient_id


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
		) seguimento ON seguimento.patient_id=grupoapoio.patient_id

	/* ******************************* ultima carga viral **************************** */
		LEFT JOIN (
SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
               	when 165331 then CONCAT('<',o.comments)
                ELSE ''
                END  AS carga_viral_qualitativa,
				ult_cv.data_cv_qualitativa data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS Origem_Resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv_qualitativa
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv_qualitativa
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) AND  e.encounter_datetime <= :endDate
                GROUP BY e.patient_id

		) ultima_cv ON ultima_cv.patient_id=grupoapoio.patient_id

left join 		(
	    SELECT e.patient_id,
        CASE o.concept_id
              WHEN     165324 THEN 'ADOLESCENTE E JOVEM MENTOR'
			WHEN 23757 THEN 'ADOLESCENTES REVELADAS/OS (AR)'
			WHEN 23753 THEN 'CRIANCAS REVELADAS'
            WHEN 23755 THEN 'PAIS E CUIDADORES (PC)'
            WHEN 24031 THEN 'Mãe Mentora'
            WHEN 23759 THEN 'MAE PARA MAE (MPM)'
            WHEN 165325 THEN 'HOMEM CAMPEAO'
            WHEN 23772 THEN 'OUTRO GRUPO DE APOIO'
			ELSE '' END AS grupoapoio ,
			  ultimo_inicio.encounter_datetime data_grupo_apoio,
	        case o.value_coded
            WHEN 1256 THEN 'INICIA'
            ELSE '' END AS estado_grupo_apoio
			FROM

			(	SELECT  p.patient_id, MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                          INNER JOIN patient p ON p.patient_id=e.patient_id
                          INNER JOIN obs o ON o.encounter_id =e.encounter_id
				             AND 	e.voided=0  AND o.voided=0  AND p.voided=0  AND o.concept_id in(165324,23757,23753,23755,24031,23759,165325,23772 )
                                                  and o.value_coded=1256
                            AND e.encounter_type IN (34,35)  AND e.location_id=:location and  encounter_datetime between :startDate and :endDate
				GROUP BY e.patient_id
			) ultimo_inicio
			INNER JOIN encounter e ON e.patient_id=ultimo_inicio.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id in (165324,23757,23753,23755,24031,23759,165325,23772 )  AND o.voided=0 and e.voided=0
			  AND e.encounter_datetime=ultimo_inicio.encounter_datetime
			and e.encounter_type  IN (34,35) AND e.location_id=:location
              GROUP BY patient_id


		) gr_apoio_ult_inicio on gr_apoio_ult_inicio.patient_id = grupoapoio.patient_id


left join 		(
	    SELECT e.patient_id,
        CASE o.concept_id
             WHEN     165324 THEN 'ADOLESCENTE E JOVEM MENTOR'
			WHEN 23757 THEN 'ADOLESCENTES REVELADAS/OS (AR)'
			WHEN 23753 THEN 'CRIANCAS REVELADAS'
            WHEN 23755 THEN 'PAIS E CUIDADORES (PC)'
            WHEN 24031 THEN 'Mãe Mentora'
            WHEN 23759 THEN 'MAE PARA MAE (MPM)'
            WHEN 165325 THEN 'HOMEM CAMPEAO'
            WHEN 23772 THEN 'OUTRO GRUPO DE APOIO'
			ELSE '' END AS grupoapoio ,
			  ultimo_inicio.encounter_datetime data_grupo_apoio,
	        case o.value_coded
            WHEN 1256 THEN 'INICIA'
            ELSE '' END AS estado_grupo_apoio
			FROM

			(	SELECT  p.patient_id, MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                          INNER JOIN patient p ON p.patient_id=e.patient_id
                          INNER JOIN obs o ON o.encounter_id =e.encounter_id
				             AND 	e.voided=0  AND o.voided=0  AND p.voided=0  AND o.concept_id in (165324,23757,23753,23755,24031,23759,165325,23772 )
                                                  and o.value_coded=1256
                            AND e.encounter_type IN (6,9)  AND e.location_id=:location and  encounter_datetime between :startDate and :endDate
				GROUP BY e.patient_id
			) ultimo_inicio
			INNER JOIN encounter e ON e.patient_id=ultimo_inicio.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id in (165324,23757,23753,23755,24031,23759,165325,23772 ) AND o.voided=0 and e.voided=0
			  AND e.encounter_datetime=ultimo_inicio.encounter_datetime
			and e.encounter_type  IN (6,9) AND e.location_id=:location
              GROUP BY patient_id


		) gr_apoio_ult_inicio_fc on gr_apoio_ult_inicio_fc.patient_id = grupoapoio.patient_id

) activos
GROUP BY patient_id