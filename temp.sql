/*
Name - CCS_LISTA_DE_AVALIACAO_PARA_RETENCAO_EM_MDS
Description
              - Avaliacao de retencao num modelo especifico

Created By - Agnaldo Samuel
Created Date-  23/11/2021


Modified By - Agnaldo Samuel
Modification  Date-  12/01/20212
Reason@
Inclusao da variavel estado de permanencia e  tipo de profilaxia TPT


USE openmrs;
SET startDate='2020-06-21';
SET endDate='2021-12-20';
SET location=208;
set modelo= 'FARMAC/Farmacia Privada';
*/
USE openmrs;
SET @startDate :='2020-06-21';
SET @endDate :='2023-12-20';
SET @location :=208;
set @modelo := 'Paragem unica no SAAJ';


SELECT *
FROM
(SELECT 	inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT( IFNULL(pn.given_name,''),' ', IFNULL(pn.middle_name,''),' ', IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
            ROUND(DATEDIFF(@endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
			DATE_FORMAT(modelodf.data_modelo ,'%d/%m/%Y') AS data_inscricao,
            modelodf.modelodf,
            DATE_FORMAT(modelodf_ultimo.data_modelo,'%d/%m/%Y') AS data_ult_actualizacao,
            DATE_FORMAT(ultima_profilaxia.data_ultima_profilaxia ,'%d/%m/%Y' ) AS data_ultima_profilaxia,
            ultima_profilaxia.profilaxia ,
            ultima_profilaxia.origem_prof,
            regime.ultimo_regime,
            IF(DATEDIFF(@endDate,visita.value_datetime)<=28,'ACTIVO EM TARV','ABANDONO NAO NOTIFICADO') estado,
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
								e.encounter_datetime<=@endDate AND e.location_id=@location
						GROUP BY p.patient_id

						UNION

						/*Patients on ART who have art start date@ ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND
								o.value_datetime<=@endDate AND e.location_id=@location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program@ OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=@endDate AND location_id=@location
						GROUP BY pg.patient_id

						UNION


						/*Patients with first drugs pick up date set in Pharmacy@ First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=@endDate AND e.location_id=@location
						  GROUP BY 	p.patient_id

			) inicio
		GROUP BY patient_id
	)inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		  /************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		INNER JOIN
		(	 SELECT mdl.patient_id,  mdl.modelodf, MIN(mdl.data_modelo) AS data_modelo  FROM (
              SELECT 	e.patient_id,
				CASE o.concept_id
					WHEN '23724'  THEN 'Grupos de Apoio para adesao comunitaria'
					WHEN '23725'  THEN 'Abordagem Familiar'
					WHEN '23726'  THEN 'Clubes de Adesao'
					WHEN '23727'  THEN 'Paragem unica'
                    WHEN '23729'  THEN  'Fluxo Rapido'
					WHEN '23730'  THEN  'Dispensa Trimestral de ARV'
					WHEN '23731'  THEN 'Dispensa Comunitaria'
					WHEN '23732'  THEN 'OUTRO MODELO'
                    WHEN '23888'  THEN 'Dispensa Semestral de ARV'
                    WHEN '165177' THEN 'FARMAC/Farmacia Privada'
				ELSE '' END AS modelodf,
				encounter_datetime AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND  o.location_id=@location and  o.concept_id in
            (select case @modelo
                       when 'Grupos de Apoio para adesao comunitaria'  then 23724
                       when 'Abordagem Familiar' then 23725
                       when 'Clubes de Adesao' then 23726
                       when 'Paragem unica' then 23727
                       when 'Fluxo Rapido' then 23729
                       when 'Dispensa Trimestral de ARV' then 23730
                       when 'Dispensa Comunitaria' then 23731
                       when 'Dispensa Semestral de ARV' then  23888
                       when 'FARMAC/Farmacia Privada' then 165177 end )


             UNION ALL


              SELECT 	e.patient_id,
				CASE o.value_coded
                    WHEN '23888' THEN 'Dispensa Semestral de ARV'
				ELSE '' END AS modelodf,
				encounter_datetime AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23739 AND o.value_coded= ( select case @modelo when 'Dispensa Semestral de ARV' then 23888 else 1111 end  )  AND o.location_id=@location
            GROUP BY patient_id

			UNION ALL

		SELECT first_mdf.patient_id,
        CASE o.value_coded
			WHEN 23730 THEN 'Dispensa Trimestral de ARV'
            WHEN 23888 THEN 'Dispensa Semestral de ARV'
            WHEN 165314 THEN 'Dispensa Anual de ARV'
            WHEN 165315 THEN 'Dispensa Descentralizada de ARV'
            WHEN 165178 THEN 'DCP - Dispensa Comunitaria atraves do Provedor'
            WHEN 165179 THEN 'DCA - Dispensa Comunitaria atraves do APE'
            WHEN 165265 THEN 'BM - Dispensa Comunitaria atraves de Brigadas Moveis'
            WHEN 165264 THEN 'CM - Dispensa Comunitaria atraves de CM'
            WHEN 23725 THEN 'Abordagem Familiar'
            WHEN 23729 THEN 'Fluxo Rapido'
            WHEN 23724 THEN 'GA - Grupos de Apoio para adesão comunitaria'
            WHEN 23726 THEN 'CA - Clubes de Adesão'
            WHEN 165316 THEN 'EH - Extensao de Horario'
            WHEN 165317 THEN 'TB - Paragem unica no sector da TB'
            WHEN 165318 THEN 'CT - Paragem unica nos serviços TARV'
            WHEN 165319 THEN 'SAAJ - Paragem unica no SAAJ'
            WHEN 165320 THEN 'Paragem unica na SMI'
            WHEN 165321 THEN 'DAH - Doença Avançada por HIV'
            WHEN 23727 THEN  ' Paragem Única (PU)'
            WHEN 165177 THEN  'FARMAC/Farmácia Privada'
            WHEN 23731  THEN  ' Dispensa Comunitária (DC)'
            WHEN 23732  THEN   'Outro Modelo'
			ELSE '' END AS modelodf ,
			 first_mdf.encounter_datetime data_modelo
			FROM

			(	SELECT  p.patient_id,MIN(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                          INNER JOIN patient p ON p.patient_id=e.patient_id
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0  AND o.voided=0  AND p.voided=0  AND o.concept_id=165174 AND e.encounter_type IN (6,9)  AND e.location_id=@location
				GROUP BY e.patient_id
			) first_mdf
			INNER JOIN encounter e ON e.patient_id=first_mdf.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=165174 AND o.voided=0 and e.voided=0  AND e.encounter_datetime=first_mdf.encounter_datetime AND
			e.encounter_type IN (6,9)  AND e.location_id=@location   and  o.value_coded in
            (select case @modelo
            WHEN  'Dispensa Trimestral de ARV'                THEN 23730
            WHEN  'Dispensa Semestral de ARV'                 THEN 23888
            WHEN  'Dispensa Anual de ARV'                     THEN 165314
            WHEN  'Dispensa Descentralizada de ARV'           THEN 165315
            WHEN  'Dispensa Comunitaria atraves do Provedor' THEN 165178
            WHEN  'Dispensa Comunitaria atraves do APE'      THEN 165179
            WHEN  'Dispensa Comunitaria atraves de Brigadas Moveis' THEN 165265
            WHEN  'Dispensa Comunitaria atraves de CM'         THEN 165264
            WHEN  'Abordagem Familiar'                         THEN 23725
            WHEN  'Fluxo Rapido'                               THEN 23729
            WHEN  'Grupos de Apoio para adesao comunitaria'    THEN 23724
            WHEN  'Clubes de Adesao'                           THEN 23726
            WHEN  'Extensao de Horario'                        THEN 165316
            WHEN  'Paragem unica no sector da TB'              THEN 165317
            WHEN  'Paragem unica nos servicos TARV' 	       THEN 165318
            WHEN  'Paragem unica no SAAJ'      		           THEN 165319
            WHEN  'Paragem unica na SMI' 				       THEN 165320
            WHEN  'Doenca Avancada por HIV' 			       THEN 165321
			WHEN  'Paragem unica'                               THEN 23727
            WHEN  'FARMAC/Farmacia Privada'                    THEN 165177
            WHEN   'Dispensa Comunitaria'                       THEN 23731
            WHEN   'Outro Modelo'                                THEN 23732
			end  )
			) mdl  where data_modelo IS NOT NULL
			       GROUP BY patient_id

		) modelodf ON modelodf.patient_id=inicio_real.patient_id AND modelodf.data_modelo between @startDate and @endDate

        LEFT JOIN
        (	SELECT ultimavisita.patient_id,ultimavisita.value_datetime,ultimavisita.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type
					FROM 	encounter e
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 and o.voided =0  AND e.encounter_type IN (6,9,18) AND  o.concept_id in (5096 ,1410)
						and	e.location_id=@location AND e.encounter_datetime <=@endDate  and o.value_datetime is  not null
					GROUP BY p.patient_id
				) ultimavisita

		) visita ON visita.patient_id=modelodf.patient_id

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
						o.concept_id=1087 AND e.location_id=@location
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
							e.location_id=@location
					GROUP BY e.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                WHERE  o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime AND
			  o.voided=0  AND e.voided =0 AND e.encounter_type =18  AND e.location_id=@location
		) fila ON fila.patient_id=modelodf.patient_id


	/*  ** ******************************************  ultima consulta  **** ************************************* */
		LEFT JOIN
		(		SELECT ultimoSeguimento.patient_id,ultimoSeguimento.encounter_datetime,o.value_datetime
	FROM

		(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
			FROM 	encounter e
			INNER JOIN patient p ON p.patient_id=e.patient_id
			WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=@location
			GROUP BY p.patient_id
		) ultimoSeguimento
		INNER JOIN encounter e ON e.patient_id=ultimoSeguimento.patient_id
		INNER JOIN obs o ON o.encounter_id=e.encounter_id
		WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimoSeguimento.encounter_datetime AND
		e.encounter_type IN (6,9)
		) seguimento ON seguimento.patient_id=modelodf.patient_id

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
				AND	e.voided=0  AND e.location_id= @location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) AND  e.encounter_datetime <= @endDate
                GROUP BY e.patient_id

		) ultima_cv ON ultima_cv.patient_id=modelodf.patient_id

	/* ******************************* ultima profilaxia **************************** */
		LEFT JOIN (

            SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 656   THEN  'Isoniazida'
                WHEN 23982 THEN  'Isoniazida + Piridoxina'
                WHEN 755   THEN  'Levofloxacina'
                WHEN 23983 THEN  'Levofloxacina + Piridoxina'
                WHEN 23954 THEN  ' 3HP (Rifapentina + Isoniazida)'
                WHEN 23984 THEN  '3HP + Piridoxina'
                ELSE ''
                END  AS profilaxia,
				ult_prof.data_prof data_ultima_profilaxia,
                fr.name AS origem_prof
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_prof
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,53,60) AND e.voided=0 AND o.voided=0 AND o.concept_id =23985
							GROUP BY patient_id
				) ult_prof
                ON e.patient_id=ult_prof.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                LEFT JOIN form fr ON fr.form_id = e.form_id
                WHERE e.encounter_datetime=ult_prof.data_prof
				AND	e.voided=0  AND e.location_id= @location   AND e.encounter_type IN  (6,9,53,60) AND
				o.voided=0 AND 	o.concept_id  =23985  AND  e.encounter_datetime <= @endDate
                GROUP BY e.patient_id

		) ultima_profilaxia ON ultima_profilaxia.patient_id=modelodf.patient_id
  /************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		left JOIN
		(
         SELECT mdl.patient_id,  mdl.modelodf, MAX(mdl.data_modelo) AS data_modelo  FROM (
              SELECT 	e.patient_id,
				CASE o.concept_id
					WHEN '23724'  THEN 'Grupos de Apoio para adesao comunitaria'
					WHEN '23725'  THEN 'Abordagem Familiar'
					WHEN '23726'  THEN 'Clubes de Adesao'
					WHEN '23727'  THEN 'PARAGEM UNICA'
                    WHEN '23729'  THEN  'Fluxo Rapido'
					WHEN '23730'  THEN  'Dispensa Trimestral de ARV'
					WHEN '23731'  THEN 'Dispensa Comunitaria'
					WHEN '23732'  THEN 'OUTRO MODELO'
                    WHEN '23888'  THEN 'Dispensa Semestral de ARV'
                    WHEN '165177' THEN 'FARMAC/Farmacia Privada'
				ELSE '' END AS modelodf,
				encounter_datetime AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND  o.location_id=@location and  o.concept_id in
            (select case @modelo
                       when 'Grupos de Apoio para adesao comunitaria'  then 23724
                       when 'Abordagem Familiar' then 23725
                       when 'Clubes de Adesao' then 23726
                       when 'PARAGEM UNICA' then 23727
                       when 'Fluxo Rapido' then 23729
                       when 'Dispensa Trimestral de ARV' then 23730
                       when 'Dispensa Comunitaria' then 23731
                       when 'Dispensa Semestral de ARV' then  23888
                       when 'Farmacia Privada' then 165177 end  )


             UNION ALL


              SELECT 	e.patient_id,
				CASE o.value_coded
                    WHEN '23888' THEN 'Dispensa Semestral de ARV'
				ELSE '' END AS modelodf,

				encounter_datetime AS data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23739 AND o.value_coded= ( select case @modelo when 'Dispensa Semestral de ARV' then 23888 else 1111 end  )  AND o.location_id=@location
            GROUP BY patient_id

			UNION ALL
	--
		SELECT first_mdf.patient_id,
        CASE o.value_coded
			WHEN 23730 THEN 'Dispensa Trimestral de ARV'
            WHEN 23888 THEN 'Dispensa Semestral de ARV'
            WHEN 165314 THEN 'Dispensa Anual de ARV'
            WHEN 165315 THEN 'Dispensa Descentralizada de ARV'
            WHEN 165178 THEN 'DCP - Dispensa Comunitaria atraves do Provedor'
            WHEN 165179 THEN 'DCA - Dispensa Comunitaria atraves do APE'
            WHEN 165265 THEN 'BM - Dispensa Comunitaria atraves de Brigadas Moveis'
            WHEN 165264 THEN 'CM - Dispensa Comunitaria atraves de CM'
            WHEN 23725 THEN 'Abordagem Familiar'
            WHEN 23729 THEN 'Fluxo Rapido'
            WHEN 23724 THEN 'GA - Grupos de Apoio para adesão comunitaria'
            WHEN 23726 THEN 'CA - Clubes de Adesão'
            WHEN 165316 THEN 'EH - Extensao de Horario'
            WHEN 165317 THEN 'TB - Paragem unica no sector da TB'
            WHEN 165318 THEN 'CT - Paragem unica nos serviços TARV'
            WHEN 165319 THEN 'SAAJ - Paragem unica no SAAJ'
            WHEN 165320 THEN 'Paragem unica na SMI'
            WHEN 165321 THEN 'DAH - Doença Avançada por HIV'
			ELSE 'OUTRO' END AS modelodf ,
			 first_mdf.encounter_datetime data_modelo
			FROM

			(	SELECT  p.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                          INNER JOIN patient p ON p.patient_id=e.patient_id
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0  AND o.voided=0  AND p.voided=0  AND o.concept_id=165174 AND e.encounter_type IN (6,9)  AND e.location_id=@location
				GROUP BY e.patient_id
			) first_mdf
			INNER JOIN encounter e ON e.patient_id=first_mdf.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=165174 AND o.voided=0 and e.voided=0  AND e.encounter_datetime=first_mdf.encounter_datetime AND
			e.encounter_type IN (6,9)  AND e.location_id=@location   and  o.value_coded in
            (select case @modelo
            WHEN  'Dispensa Trimestral de ARV'                THEN 23730
            WHEN  'Dispensa Semestral de ARV'                 THEN 23888
            WHEN  'Dispensa Anual de ARV'                     THEN 165314
            WHEN  'Dispensa Descentralizada de ARV'           THEN 165315
            WHEN  'Dispensa Comunitaria atraves do Provedor' THEN 165178
            WHEN  'Dispensa Comunitaria atraves do APE'      THEN 165179
            WHEN  'Dispensa Comunitaria atraves de Brigadas Moveis' THEN 165265
            WHEN  'Dispensa Comunitaria atraves de CM'         THEN 165264
            WHEN  'Abordagem Familiar'                         THEN 23725
            WHEN  'Fluxo Rapido'                               THEN 23729
            WHEN  'Grupos de Apoio para adesao comunitaria'    THEN 23724
            WHEN  'Clubes de Adesao'                           THEN 23726
            WHEN  'Extensao de Horario'                        THEN 165316
            WHEN  'Paragem unica no sector da TB'              THEN 165317
            WHEN  'Paragem unica nos servicos TARV' 	        THEN 165318
            WHEN  'Paragem unica no SAAJ'      		        THEN 165319
            WHEN  'Paragem unica na SMI' 				        THEN 165320
            WHEN  'Doenca Avancada por HIV' 			        THEN 165321 end  )
			 ) mdl  where  data_modelo is not null GROUP BY patient_id

		) modelodf_ultimo ON modelodf_ultimo.patient_id=inicio_real.patient_id AND modelodf.data_modelo <= @endDate



) activos
GROUP BY patient_id