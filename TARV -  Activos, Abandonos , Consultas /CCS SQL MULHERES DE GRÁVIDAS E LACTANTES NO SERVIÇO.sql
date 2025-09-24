select
    	pid.identifier NID,
    	concat(ifnull(pn.given_name,''),' ',ifnull( pn.middle_name,''),' ',ifnull(pn.family_name,'')) as NomeCompleto,
		round(datediff(current_date,pe.birthdate)/365) idade_actual,
		pe.gender ,
		--  using the data_parto e data_gravida classify if the woman is pregnant or is breasfeeding
        if(gravidaLactante.decisao = 2, 'GRAVIDA', 'LACTANTE') as gravida_lactante,
        gravidaLactante.*,
        if(admissao_programa.date_enrolled is null,'NAO','SIM') programa_ptv,
		DATE_FORMAT(admissao_programa.date_enrolled,'%d/%m/%Y') AS data_inscricao_ptv,
		DATE_FORMAT(admissao_programa.date_completed,'%d/%m/%Y') AS data_completed,
		DATE_FORMAT(ult_seguimento.encounter_datetime,'%d/%m/%Y') AS ult_consulta,
        DATE_FORMAT(proxima_consulta.value_datetime,'%d/%m/%Y') AS  prox_marcado,
        IF(activos_28.patient_id is not null, 'ACTIVO NO PROGRAMA', 'FALTOSO') as activos_28,
		/* cv.carga_viral_qualitativa,
        DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_cv ,
        cv.valor_ultima_carga AS carga_viral_numeric,
        cv.origem_resultado AS origem_cv, */
        saida.estado_tarv_trat,
       DATE_FORMAT( saida.data_ult_estado,'%d/%m/%Y') AS data_ult_estado,
        saida.fonte,
        g_apoio.grupo_apoio,
        g_apoio.estado,
        g_apoio.data_ult_seguimento


from(
select   distinct   gravida_real.patient_id,
                   DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
                   DATE_FORMAT(min(gravida_real.data_gravida) ,'%d/%m/%Y') AS  data_gravida ,
                   DATE_FORMAT(max(lactante_real.data_parto) ,'%d/%m/%Y')as  data_parto,
                   if(max(gravida_real.data_gravida) is null and max(lactante_real.data_parto) is null, null,
                   if(max(gravida_real.data_gravida) is null, 1,
                   if(max(lactante_real.data_parto) is null, 2,
                   if(max(lactante_real.data_parto) > min(gravida_real.data_gravida), 1, 2)))) decisao
from
    /******    Gravidez    ******************/

     (
       select max(data_gravida) data_gravida, patient_id
       from (
      /* Data da gravides */
      Select p.patient_id, e.encounter_datetime data_gravida
      from patient p
               inner join encounter e on p.patient_id = e.patient_id
               inner join obs o on e.encounter_id = o.encounter_id
      where p.voided = 0
        and e.voided = 0
        and o.voided = 0
        and concept_id = 1600
        and e.encounter_type in (5, 6)
        and e.encounter_datetime between :startDate and current_date
        and e.location_id = :location

      union

      /**** Inscricao no programa PTV/ETV ***/
      select pp.patient_id, pp.date_enrolled data_gravida
      from patient_program pp
      where pp.program_id = 8
        and pp.voided = 0
        and pp.date_enrolled between :startDate and current_date
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
        and e.encounter_datetime between :startDate and current_date
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
        and o.value_datetime between :startDate and current_date
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
        and data_colheita.value_datetime between :startDate and current_date
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
          and current_date
        and e.location_id = :location) pregnant
       group by patient_id
           )  gravida_real


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
								e.encounter_datetime between :startDate and current_date AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						-- Patients on ART who have art start date ART Start date
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND
								o.value_datetime between :startDate and current_date AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						-- Patients enrolled in ART Program: OpenMRS Program
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled between :startDate and current_date AND location_id=:location
						GROUP BY pg.patient_id

						UNION


						-- Patients with first drugs pick up date set in Pharmacy: First ART Start Date
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime between :startDate and current_date AND e.location_id=:location
						  GROUP BY 	p.patient_id




			) inicio
		GROUP BY patient_id
	)  inicio_real on gravida_real.patient_id = inicio_real.patient_id

       -- Informacao sobre o outcome da gravidez

         left join (
    select patient_id , max(data_parto) data_parto
    from (
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
      and o.value_datetime between :startDate and current_date
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
      and e.encounter_datetime between :startDate and current_date
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
      and e.encounter_datetime between :startDate and current_date
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
      and ps.start_date between :startDate and current_date
      and location_id = :location ) breastfeeding group by  patient_id ) lactante_real
                   on lactante_real.patient_id = inicio_real.patient_id

 where    ( gravida_real.data_gravida is not null and lactante_real.data_parto is  null ) or (gravida_real.data_gravida is not null and lactante_real.data_parto is not null)
           or (data_gravida is null and lactante_real.data_parto is not null)
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
    /* ******************************* Grupo de Apoio **************************** */
	Left join (
                SELECT e.patient_id,
                ficha_seguimento.data_ult_seguimento,
				CASE  o.value_coded
				    when 1256 then 'INICIA'
				    when 1257 then 'CONTINUA'
                    when 1267 then 'TERMINA'
                    ELSE '' END AS estado,
                CASE o.concept_id
                 when 23757 then  'ADOLESCENTES REVELADAS/OS AR'
                 when 23757 then  'ADOLESCENTES REVELADAS/OS AR'
				 when 165324 then 'ADOLESCENTE E JOVEM MENTOR'
                when 23753 then 'CRIANCAS REVELADAS CR'
                when 23755 then 'PAIS E CUIDADORES PC'
                when 24031 then 'Mãe Mentora'
                when 23759 then 'MAE PARA MAE MPM'
                when 165325 then 'HOMEM CAMPEAO'
                when 23772 then 'OUTRO GRUPO DE APOIO'
                ELSE '' END AS grupo_apoio
				FROM (
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ult_seguimento
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id  in ( 23757, 165324, 23753, 23755, 24031, 23759, 165325, 23772)
							  AND e.location_id=:location
							GROUP BY patient_id
				      )  ficha_seguimento

			INNER JOIN encounter e ON e.patient_id=ficha_seguimento.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,34,35) AND ficha_seguimento.data_ult_seguimento =e.encounter_datetime AND e.voided=0 AND
			       o.voided=0 AND o.concept_id in ( 23757, 165324, 23753, 23755, 24031, 23759, 165325, 23772)
                     AND e.location_id=:location
            GROUP BY patient_id ) g_apoio ON g_apoio.patient_id=gravidaLactante.patient_id
/*******************************  Activos 28 dias ******************/
 left join   (select patient_id, data_inicio
          from (select inicio_fila_seg_prox.*,
                       -- GREATEST(COALESCE(data_fila, data_seguimento), COALESCE(data_seguimento, data_fila))    data_usar_c,
                           data_fila    data_usar_c,
                       /* GREATEST(COALESCE(data_proximo_lev, data_proximo_seguimento, data_recepcao_levantou30),
                                COALESCE(data_proximo_seguimento, data_proximo_lev, data_recepcao_levantou30),
                                COALESCE(data_recepcao_levantou30, data_proximo_seguimento, data_proximo_lev)) data_usar*/
             GREATEST(COALESCE(data_proximo_lev, data_recepcao_levantou30),
                                COALESCE( data_proximo_lev, data_recepcao_levantou30),
                                COALESCE(data_recepcao_levantou30, data_proximo_lev)) data_usar
                from (select inicio_fila_seg.*,
                             max(obs_fila.value_datetime)                      data_proximo_lev,
                             /*max(obs_seguimento.value_datetime)                data_proximo_seguimento, */
                             date_add(data_recepcao_levantou, interval 30 day) data_recepcao_levantou30
                      from (select inicio.*,
                                   saida.data_estado,
                                   max_fila.data_fila,
                                   /* max_consulta.data_seguimento, */
                                   max_recepcao.data_recepcao_levantou
                            from (select patient_id, min(data_inicio) data_inicio
                                  from (select p.patient_id, min(e.encounter_datetime) data_inicio
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                                 inner join obs o on o.encounter_id = e.encounter_id
                                        where e.voided = 0
                                          and o.voided = 0
                                          and p.voided = 0
                                          and pe.voided = 0
                                          and e.encounter_type in (18, 6, 9)
                                          and o.concept_id = 1255
                                          and o.value_coded = 1256
                                          and e.encounter_datetime <= current_date
                                          and e.location_id = :location
                                        group by p.patient_id
                                        union

                                        select p.patient_id, min(value_datetime) data_inicio
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                                 inner join obs o on e.encounter_id = o.encounter_id
                                        where p.voided = 0
                                          and pe.voided = 0
                                          and e.voided = 0
                                          and o.voided = 0
                                          and e.encounter_type in (18, 6, 9, 53)
                                          and o.concept_id = 1190
                                          and o.value_datetime is not null
                                          and o.value_datetime <= current_date
                                          and e.location_id = :location
                                        group by p.patient_id
                                        union

                                        select pg.patient_id, min(date_enrolled) data_inicio
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join patient_program pg on p.patient_id = pg.patient_id
                                        where pg.voided = 0
                                          and p.voided = 0
                                          and pe.voided = 0
                                          and program_id = 2
                                          and date_enrolled <= current_date
                                          and location_id = :location
                                        group by pg.patient_id
                                        union

                                        select e.patient_id, MIN(e.encounter_datetime) AS data_inicio
                                        FROM patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                        WHERE p.voided = 0
                                          and pe.voided = 0
                                          and e.encounter_type = 18
                                          AND e.voided = 0
                                          and e.encounter_datetime <= current_date
                                          and e.location_id = :location
                                        GROUP BY p.patient_id
                                        union

                                        select p.patient_id, min(value_datetime) data_inicio
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                                 inner join obs o on e.encounter_id = o.encounter_id
                                        where p.voided = 0
                                          and pe.voided = 0
                                          and e.voided = 0
                                          and o.voided = 0
                                          and e.encounter_type = 52
                                          and o.concept_id = 23866
                                          and o.value_datetime is not null
                                          and o.value_datetime <= current_date
                                          and e.location_id = :location
                                        group by p.patient_id) inicio_real
                                  group by patient_id) inicio
                                     left join
                                 (select patient_id, max(data_estado) data_estado
                                  from (select distinct max_estado.patient_id, max_estado.data_estado
                                        from (select pg.patient_id,
                                                     max(ps.start_date) data_estado
                                              from patient p
                                                       inner join person pe on pe.person_id = p.patient_id
                                                       inner join patient_program pg on p.patient_id = pg.patient_id
                                                       inner join patient_state ps on pg.patient_program_id = ps.patient_program_id
                                              where pg.voided = 0
                                                and ps.voided = 0
                                                and p.voided = 0
                                                and pe.voided = 0
                                                and pg.program_id = 2
                                                and ps.start_date <= current_date
                                                and pg.location_id = :location
                                              group by pg.patient_id) max_estado
                                                 inner join patient_program pp on pp.patient_id = max_estado.patient_id
                                                 inner join patient_state ps
                                                            on ps.patient_program_id = pp.patient_program_id and
                                                               ps.start_date = max_estado.data_estado
                                        where pp.program_id = 2
                                          and ps.state in (8, 10)
                                          and pp.voided = 0
                                          and ps.voided = 0
                                          and pp.location_id = :location
                                        union
                                        select p.patient_id,
                                               max(o.obs_datetime) data_estado
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                                 inner join obs o on e.encounter_id = o.encounter_id
                                        where e.voided = 0
                                          and o.voided = 0
                                          and p.voided = 0
                                          and pe.voided = 0
                                          and e.encounter_type in (53, 6)
                                          and o.concept_id in (6272, 6273)
                                          and o.value_coded in (1366, 1709)
                                          and o.obs_datetime <= current_date
                                          and e.location_id = :location
                                        group by p.patient_id
                                        union
                                        select person_id as patient_id, death_date as data_estado
                                        from person
                                        where dead = 1
                                          and voided = 0
                                          and death_date is not null
                                          and death_date <= current_date
                                        union
                                        select p.patient_id,
                                               max(obsObito.obs_datetime) data_estado
                                        from patient p
                                                 inner join person pe on pe.person_id = p.patient_id
                                                 inner join encounter e on p.patient_id = e.patient_id
                                                 inner join obs obsObito on e.encounter_id = obsObito.encounter_id
                                        where e.voided = 0
                                          and p.voided = 0
                                          and pe.voided = 0
                                          and obsObito.voided = 0
                                          and e.encounter_type in (21, 36, 37)
                                          and e.encounter_datetime <= current_date
                                          and e.location_id = :location
                                          and obsObito.concept_id in (2031, 23944, 23945)
                                          and obsObito.value_coded = 1366
                                        group by p.patient_id

                                        union

                                        select saidas_por_transferencia.patient_id, data_estado
                                        from (select saidas_por_transferencia.patient_id, max(data_estado) data_estado
                                              from (select distinct max_estado.patient_id, max_estado.data_estado
                                                    from (select pg.patient_id, max(ps.start_date) data_estado
                                                          from patient p
                                                                   inner join person pe on pe.person_id = p.patient_id
                                                                   inner join patient_program pg on p.patient_id = pg.patient_id
                                                                   inner join patient_state ps on pg.patient_program_id = ps.patient_program_id
                                                          where pg.voided = 0
                                                            and ps.voided = 0
                                                            and p.voided = 0
                                                            and pe.voided = 0
                                                            and pg.program_id = 2
                                                            and ps.start_date <= current_date
                                                            and pg.location_id = :location
                                                          group by pg.patient_id) max_estado
                                                             inner join patient_program pp on pp.patient_id = max_estado.patient_id
                                                             inner join patient_state ps on ps.patient_program_id =
                                                                                            pp.patient_program_id and
                                                                                            ps.start_date =
                                                                                            max_estado.data_estado
                                                    where pp.program_id = 2
                                                      and ps.state = 7
                                                      and pp.voided = 0
                                                      and ps.voided = 0
                                                      and pp.location_id = :location

                                                    union

                                                    select p.patient_id, max(o.obs_datetime) data_estado
                                                    from patient p
                                                             inner join person pe on pe.person_id = p.patient_id
                                                             inner join encounter e on p.patient_id = e.patient_id
                                                             inner join obs o on e.encounter_id = o.encounter_id
                                                    where e.voided = 0
                                                      and o.voided = 0
                                                      and p.voided = 0
                                                      and pe.voided = 0
                                                      and e.encounter_type in (53, 6)
                                                      and o.concept_id in (6272, 6273)
                                                      and o.value_coded = 1706
                                                      and o.obs_datetime <= current_date
                                                      and e.location_id = :location
                                                    group by p.patient_id

                                                    union

                                                    select ultimaBusca.patient_id, ultimaBusca.data_estado
                                                    from (select p.patient_id, max(e.encounter_datetime) data_estado
                                                          from patient p
                                                                   inner join person pe on pe.person_id = p.patient_id
                                                                   inner join encounter e on p.patient_id = e.patient_id
                                                                   inner join obs o on o.encounter_id = e.encounter_id
                                                          where e.voided = 0
                                                            and p.voided = 0
                                                            and pe.voided = 0
                                                            and e.encounter_datetime <= current_date
                                                            and e.encounter_type = 21
                                                            and e.location_id = :location
                                                          group by p.patient_id) ultimaBusca
                                                             inner join encounter e on e.patient_id = ultimaBusca.patient_id
                                                             inner join obs o on o.encounter_id = e.encounter_id
                                                    where e.encounter_type = 21
                                                      and o.voided = 0
                                                      and o.concept_id = 2016
                                                      and o.value_coded in (1706, 23863)
                                                      and ultimaBusca.data_estado = e.encounter_datetime
                                                      and e.location_id = :location) saidas_por_transferencia
                                              group by patient_id) saidas_por_transferencia
                                                 left join
                                             (select patient_id, max(data_ultimo_levantamento) data_ultimo_levantamento
                                              from (select ultimo_fila.patient_id,
                                                           date_add(obs_fila.value_datetime, interval 1 day) data_ultimo_levantamento
                                                    from (select p.patient_id, max(encounter_datetime) data_fila
                                                          from patient p
                                                                   inner join person pe on pe.person_id = p.patient_id
                                                                   inner join encounter e on e.patient_id = p.patient_id
                                                          where p.voided = 0
                                                            and pe.voided = 0
                                                            and e.voided = 0
                                                            and e.encounter_type = 18
                                                            and e.location_id = :location
                                                            and e.encounter_datetime <= current_date
                                                          group by p.patient_id) ultimo_fila
                                                             left join
                                                         obs obs_fila on obs_fila.person_id = ultimo_fila.patient_id
                                                             and obs_fila.voided = 0
                                                             and obs_fila.obs_datetime = ultimo_fila.data_fila
                                                             and obs_fila.concept_id = 5096
                                                             and obs_fila.location_id = :location

                                                    union

                                                    select p.patient_id,
                                                           date_add(max(value_datetime), interval 31 day) data_ultimo_levantamento
                                                    from patient p
                                                             inner join person pe on pe.person_id = p.patient_id
                                                             inner join encounter e on p.patient_id = e.patient_id
                                                             inner join obs o on e.encounter_id = o.encounter_id
                                                    where p.voided = 0
                                                      and pe.voided = 0
                                                      and e.voided = 0
                                                      and o.voided = 0
                                                      and e.encounter_type = 52
                                                      and o.concept_id = 23866
                                                      and o.value_datetime is not null
                                                      and e.location_id = :location
                                                      and o.value_datetime <= current_date
                                                    group by p.patient_id) ultimo_levantamento
                                              group by patient_id) ultimo_levantamento
                                             on saidas_por_transferencia.patient_id = ultimo_levantamento.patient_id
                                        where ultimo_levantamento.data_ultimo_levantamento <= current_date) allSaida
                                  group by patient_id) saida on inicio.patient_id = saida.patient_id
                                     left join
                                 (select p.patient_id, max(encounter_datetime) data_fila
                                  from patient p
                                           inner join person pe on pe.person_id = p.patient_id
                                           inner join encounter e on e.patient_id = p.patient_id
                                  where p.voided = 0
                                    and pe.voided = 0
                                    and e.voided = 0
                                    and e.encounter_type = 18
                                    and e.location_id = :location
                                    and e.encounter_datetime <= current_date
                                  group by p.patient_id) max_fila on inicio.patient_id = max_fila.patient_id
                                   /*  left join
                                 (select p.patient_id, max(encounter_datetime) data_seguimento
                                  from patient p
                                           inner join person pe on pe.person_id = p.patient_id
                                           inner join encounter e on e.patient_id = p.patient_id
                                  where p.voided = 0
                                    and pe.voided = 0
                                    and e.voided = 0
                                    and e.encounter_type in (6, 9)
                                    and e.location_id = :location
                                    and e.encounter_datetime <= current_date
                                  group by p.patient_id) max_consulta on inicio.patient_id = max_consulta.patient_id */
                                     left join
                                 (select p.patient_id, max(value_datetime) data_recepcao_levantou
                                  from patient p
                                           inner join person pe on pe.person_id = p.patient_id
                                           inner join encounter e on p.patient_id = e.patient_id
                                           inner join obs o on e.encounter_id = o.encounter_id
                                  where p.voided = 0
                                    and pe.voided = 0
                                    and e.voided = 0
                                    and o.voided = 0
                                    and e.encounter_type = 52
                                    and o.concept_id = 23866
                                    and o.value_datetime is not null
                                    and o.value_datetime <= current_date
                                    and e.location_id = :location
                                  group by p.patient_id) max_recepcao on inicio.patient_id = max_recepcao.patient_id
                            group by inicio.patient_id) inicio_fila_seg
                               left join
                           obs obs_fila on obs_fila.person_id = inicio_fila_seg.patient_id
                               and obs_fila.voided = 0
                               and obs_fila.obs_datetime = inicio_fila_seg.data_fila
                               and obs_fila.concept_id = 5096
                               and obs_fila.location_id = :location
                        /*   left join
                           obs obs_seguimento on obs_seguimento.person_id = inicio_fila_seg.patient_id
                               and obs_seguimento.voided = 0
                               and obs_seguimento.obs_datetime = inicio_fila_seg.data_seguimento
                               and obs_seguimento.concept_id = 1410
                               and obs_seguimento.location_id = :location */
                      group by inicio_fila_seg.patient_id) inicio_fila_seg_prox
                group by patient_id) coorte12meses_final
          where (data_estado is null or (data_estado is not null and data_usar_c > data_estado))
            and date_add(data_usar, interval 28 day) >= current_date
) activos_28 on activos_28.patient_id = gravidaLactante.patient_id

/********************************  Saidas  / Transferencias ***************************************************/
-- SAIDAS DO PROGRAMA EM TODAS FONTES
             left  JOIN (

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
                        pg.program_id=2 AND ps.state IN (7,8,9) AND   location_id=:location /* AND ps.start_date between date_sub(:endDate, INTERVAL 1 YEAR) AND
                    :endDate */
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
								e.encounter_datetime<=current_date
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
								e.encounter_datetime<=current_date
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  =6273  AND o.value_coded in (1366, 1706) AND o.voided=0 AND p.voided =0  AND e.voided=0 AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id
				    ) all_saidas  group by  patient_id
        ) saida on saida.patient_id = gravidaLactante.patient_id
	left join
	(
		select pp.patient_id,pp.date_enrolled,pp.date_completed
		from 	patient_program pp
		where 	pp.program_id=8 and
				pp.date_enrolled between :startDate and current_date and pp.location_id=:location
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
     /*   LEFT JOIN (
          SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
				when 165331 then 'Menor que'
			    ELSE o.value_coded
                END  AS carga_viral_qualitativa,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305) and o.voided=0
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,51,13,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305)
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  gravidaLactante.patient_id
   */
       /*****************************   ultimo levantamento ************** **********************/
		LEFT JOIN
		(

	SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=current_date
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=current_date
				) visita2
GROUP BY visita2.patient_id

		) ult_fila ON ult_fila.patient_id = gravidaLactante.patient_id
LEFT JOIN (
	SELECT *
		FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e inner join patient p on p.patient_id=e.patient_id
				WHERE 	p.voided=0 and e.voided=0 AND e.encounter_type IN (9,6) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita

            ) ult_seguimento ON ult_seguimento.patient_id = gravidaLactante.patient_id
LEFT JOIN (
	SELECT next_schedule_date.*
		FROM

			(	SELECT 	e.patient_id,MAX(o.value_datetime) AS value_datetime
				FROM 	encounter e inner join patient p on p.patient_id=e.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	p.voided=0 and e.voided=0 AND e.encounter_type IN (9,6) and o.concept_id=1410   AND e.location_id=:location
				GROUP BY e.patient_id
			) next_schedule_date
            ) proxima_consulta ON proxima_consulta.patient_id = gravidaLactante.patient_id
  where pe.voided = 0
  and pe.gender = 'F'