
select  gravidaLactante.*,

        if(admissao_programa.date_enrolled is null,'NAO','SIM') programa_ptv,
		DATE_FORMAT(admissao_programa.date_enrolled,'%d/%m/%Y') AS date_inscricao_ptv,
		DATE_FORMAT(admissao_programa.date_completed,'%d/%m/%Y') AS date_completed,
		DATE_FORMAT(ult_seguimento.encounter_datetime,'%d/%m/%Y') AS ult_consulta,
        DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS  prox_marcado,
		pid.identifier NID,
		concat(ifnull(pn.given_name,''),' ',ifnull( pn.middle_name,''),' ',ifnull(pn.family_name,'')) as NomeCompleto,
		round(datediff(:endDate,pe.birthdate)/365) idade_actual,
		pe.gender ,
		DATE_FORMAT(cd4.encounter_datetime    ,'%d/%m/%Y') AS ult_cd4,
		cd4.value_numeric as cd4,
		cv.carga_viral_qualitativa,
        DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_cv ,
        cv.valor_ultima_carga AS carga_viral_numeric,
        cv.origem_resultado AS origem_cv


from(
select     gravida_real.patient_id,
                   DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
              DATE_FORMAT(min(gravida_real.data_gravida) ,'%d/%m/%Y') AS  data_gravida ,
             DATE_FORMAT(max(lactante_real.data_parto) ,'%d/%m/%Y')as  data_parto,
             if(max(gravida_real.data_gravida) is null and max(lactante_real.data_parto) is null, null,
                if(max(gravida_real.data_gravida) is null, 1,
                   if(max(lactante_real.data_parto) is null, 2,
                      if(max(lactante_real.data_parto) > max(gravida_real.data_gravida), 1, 2)))) decisao
from
    /******    Gravidez    ******************/

     ( Select p.patient_id, e.encounter_datetime data_gravida
      from patient p
               inner join encounter e on p.patient_id = e.patient_id
               inner join obs o on e.encounter_id = o.encounter_id
      where p.voided = 0
        and e.voided = 0
        and o.voided = 0
        and concept_id = 1600
        and e.encounter_type in (5, 6)
        and e.encounter_datetime between :startDate and :endDate
        and e.location_id = :location

      union

      /**** Inscricao no programa PTV/ETV ***/
      select pp.patient_id, pp.date_enrolled data_gravida
      from patient_program pp
      where pp.program_id = 8
        and pp.voided = 0
        and pp.date_enrolled between :startDate and :endDate
        and pp.location_id = :location


      union

      /* CRITÉRIO PARA INICIO DE TRATAMENTO ARV  6331 -  Option B+ call for the administration
      of triple combination antiretroviral therapy (ART) to all pregnant HIV-infected women  */

      Select p.patient_id, e.encounter_datetime data_gravida
      from patient p
               inner join encounter e on p.patient_id = e.patient_id
               inner join obs o on e.encounter_id = o.encounter_id
      where p.voided = 0
        and e.voided = 0
        and o.voided = 0
        and concept_id = 6334
        and value_coded = 6331
        and e.encounter_type in (5, 6)
        and e.encounter_datetime between :startDate and :endDate
        and e.location_id = :location


      union
      /*****   Gravida com inicio inicio tarv no periodo na: Ficha resumo **************/
      Select p.patient_id, o.value_datetime data_gravida
      from patient p
               inner join encounter e on p.patient_id = e.patient_id
               inner join obs o on e.encounter_id = o.encounter_id
            --    inner join obs obsART on e.encounter_id = obsART.encounter_id
      where p.voided = 0
        and e.voided = 0
        and o.voided = 0
        and o.concept_id = 1982
        and o.value_coded = 1065
        and e.encounter_type = 53
        and o.value_datetime between :startDate and :endDate
        and e.location_id = :location


          /*****   Gravida  na Ficha FSR **************/
      union
      select p.patient_id, data_colheita.value_datetime data_gravida
      from patient p
               inner join encounter e on p.patient_id = e.patient_id
               inner join obs esta_gravida on e.encounter_id = esta_gravida.encounter_id
               inner join obs data_colheita on data_colheita.encounter_id = e.encounter_id
      where p.voided = 0
        and e.voided = 0
        and esta_gravida.voided = 0
        and data_colheita.voided = 0
        and esta_gravida.concept_id = 1982
        and esta_gravida.value_coded = 1065
        and e.encounter_type = 51
        and data_colheita.concept_id = 23821
        and data_colheita.value_datetime between :startDate and :endDate
        and e.location_id = :location

      union
      --  Marcada Gestante  na FC
      Select p.patient_id, e.encounter_datetime data_gravida
      from patient p
               inner join encounter e
                          on p.patient_id = e.patient_id
               inner join obs o on e.encounter_id = o.encounter_id
      where p.voided = 0
        and e.voided = 0
        and o.voided = 0
        and concept_id = 1982
        and value_coded = 1065
        and e.encounter_type in (5, 6)
        and e.encounter_datetime between :startDate
          and :endDate
        and e.location_id = :location) gravida_real


         left join (	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(

				-- Patients on ART who initiated the ARV DRUGS ART Regimen Start Date

						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND
								e.encounter_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						-- Patients on ART who have art start date ART Start date
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
	) inicio_real on gravida_real.patient_id = inicio_real.patient_id

       -- Informacao sobre o outcome da gravidez

         left join (

        -- DATA DO PARTO     #5599: Dia em que a mulher da parto.
    Select p.patient_id, o.value_datetime data_parto
    from patient p
             inner join encounter e on p.patient_id = e.patient_id
             inner join obs o on e.encounter_id = o.encounter_id
    where p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 5599
      and e.encounter_type in (5, 6)
      and o.value_datetime between :startDate and :endDate
      and e.location_id = :location
    union
    /**********            LACTANTE            ***************/
    Select p.patient_id, e.encounter_datetime data_parto
    from patient p
             inner join encounter e on p.patient_id = e.patient_id
             inner join obs o on e.encounter_id = o.encounter_id
    where p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6332
      and value_coded = 1065
      and e.encounter_type = 6
      and e.encounter_datetime between :startDate and :endDate
      and e.location_id = :location
    union
        /**********      LACTANTE   na FICHA RESUMO         ***************/
    Select p.patient_id, o.value_datetime data_parto
    from patient p
             inner join encounter e on p.patient_id = e.patient_id
             inner join obs o on e.encounter_id = o.encounter_id

    where p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and o.concept_id = 6332
      and o.value_coded = 1065
      and e.encounter_type = 53
      and e.location_id = :location

    union
    Select p.patient_id, e.encounter_datetime data_parto
    from patient p
             inner join encounter e on p.patient_id = e.patient_id
             inner join obs o on e.encounter_id = o.encounter_id
    where p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6334
      and value_coded = 6332
      and e.encounter_type in (5, 6)
      and e.encounter_datetime between :startDate and :endDate
      and e.location_id = :location
    union
    select pg.patient_id, ps.start_date data_parto
    from patient p
             inner join patient_program pg on p.patient_id = pg.patient_id
             inner join patient_state ps on pg.patient_program_id = ps.patient_program_id
    where pg.voided = 0
      and ps.voided = 0
      and p.voided = 0
      and pg.program_id = 8
      and ps.state = 27
      and ps.start_date between :startDate and :endDate
      and location_id = :location) lactante_real
                   on lactante_real.patient_id = inicio_real.patient_id

 where    ( gravida_real.data_gravida is not null and lactante_real.data_parto is  null ) or (gravida_real.data_gravida is not null and lactante_real.data_parto is not null)

      group by inicio_real.patient_id
      ) gravidaLactante
         inner join person pe on pe.person_id = gravidaLactante.patient_id
        /*** CD4    ******/
        LEFT JOIN(
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN
		    (
            SELECT 	cd4_max.patient_id, MAX(cd4_max.encounter_datetime) AS encounter_datetime
            FROM ( SELECT e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND e.location_id=:location  AND
							o.voided=0 AND o.concept_id=1695 AND e.encounter_type IN (6,9,53)

					UNION ALL
					SELECT 	 e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND  e.location_id=:location  AND
							o.voided=0 AND o.concept_id=5497 AND e.encounter_type =13 ) cd4_max
			GROUP BY patient_id ) cd4_temp
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id IN (1695,5497) AND e.encounter_type IN (6,9,13,53)
			GROUP BY patient_id

		) cd4 ON cd4.patient_id =  gravidaLactante.patient_id
	left join
	(
		select pp.patient_id,pp.date_enrolled,pp.date_completed
		from 	patient_program pp
		where 	pp.program_id=8 and
				pp.date_enrolled between :startDate and :endDate and pp.location_id=:location
	) admissao_programa on admissao_programa.patient_id= gravidaLactante.patient_id
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
			) pad3 ON pad3.person_id=gravidaLactante.patient_id
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
			) pn ON pn.person_id=gravidaLactante.patient_id
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
			) pid ON pid.patient_id=gravidaLactante.patient_id
    /* ******************************** ultima carga viral *********** ******************************/
        LEFT JOIN(
          SELECT 	e.patient_id,
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
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  gravidaLactante.patient_id

       /*****************************   ultimo levantamento ************** **********************/
		LEFT JOIN
		(

	SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id

		) ult_fila ON ult_fila.patient_id = gravidaLactante.patient_id
LEFT JOIN (
	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e inner join patient p on p.patient_id=e.patient_id
				WHERE 	p.voided=0 and e.voided=0 AND e.encounter_type IN (9,6)
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND
			e.encounter_type IN (9,6) AND e.location_id=:location
			 GROUP BY e.patient_id
            ) ult_seguimento ON ult_seguimento.patient_id = gravidaLactante.patient_id
  where pe.voided = 0
  and pe.gender = 'F'