SELECT  elegiveis_preventiva.patient_id ,
         criterio,  gender,
        round(datediff(current_date,p.birthdate)/365) idade_actual,
         given_name,
         middle_name,
         family_name,
         identifier,
         gravida_real.data_gravida,
         lactante_real.data_parto,
         if(consentimento.patient_id is null, null, 'consentimento')
         FROM (	/* inicio_real.patient_id,
				DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
				pad3.county_district as 'Distrito',
				pad3.address2 as 'PAdministrativo',
				pad3.address6 as 'Localidade',
				pad3.address5 as 'Bairro',
				pad3.address1 as 'PontoReferencia',
				if(pat.value is null,' ',pat.value) as 'Contacto',
				concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
				concat(pid.identifier,' ') as NID,
				if(pad3.person_address_id is null,' ',concat(' ',ifnull(pad3.address2,''),' ',ifnull(pad3.address5,''),' ',ifnull(pad3.address3,''),' ',ifnull(pad3.address1,''),' ',ifnull(pad3.address4,''),' ',ifnull(pad3.address6,''))) as endereco,
				p.gender,
				round(datediff(current_date,p.birthdate)/365) idade_actual,
				-- DATE_FORMAT(date_add(primeiravisita.value_datetime, interval -3 day),'%d/%m/%Y') datachamada,
				if(consentimento.patient_id is null,'NAO','SIM') as consentido */

         /* 4.1 Procedimentos para implementação das chamadas e visitas preventivas
                Critérios de Elegibilidade:
                ✓ Toda mulher grávida, lactante e criança exposta (novos diagnosticados ao HIV ou já em TARV que nunca
                beneficiaram de seguimento preventivo);   */
		SELECT * FROM
			(
			    SELECT patient_id,data_inicio
			FROM
				(	SELECT patient_id,min(data_inicio) data_inicio
					FROM
						(
							/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/

							SELECT 	p.patient_id,min(e.encounter_datetime) data_inicio
							FROM 	patient p
									INNER JOIN encounter e on p.patient_id=e.patient_id
									INNER JOIN obs o on o.encounter_id=e.encounter_id
							WHERE 	e.voided=0 and o.voided=0 and p.voided=0 and
									e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and
									e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)) and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
							group by p.patient_id

							union

							/*Patients on ART who have art start date ART Start date*/
							SELECT 	p.patient_id,min(value_datetime) data_inicio
							FROM 	patient p
									INNER JOIN encounter e on p.patient_id=e.patient_id
									INNER JOIN obs o on e.encounter_id=o.encounter_id
							WHERE 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9,53) and
									o.concept_id=1190 and o.value_datetime is not null and
									o.value_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)) and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
							group by p.patient_id

							union

							/*Patients enrolled in ART Program OpenMRS Program*/
							SELECT 	pg.patient_id,min(date_enrolled) data_inicio
							FROM 	patient p INNER JOIN patient_program pg on p.patient_id=pg.patient_id
							WHERE 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)) and location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
							group by pg.patient_id

							union


							/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
							  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
							  FROM 		patient p
										INNER JOIN encounter e on p.patient_id=e.patient_id
							  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)) and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
							  GROUP BY 	p.patient_id

							union

							/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
							SELECT 	p.patient_id,min(value_datetime) data_inicio
							FROM 	patient p
									INNER JOIN encounter e on p.patient_id=e.patient_id
									INNER JOIN obs o on e.encounter_id=o.encounter_id
							WHERE 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=52 and
									o.concept_id=23866 and o.value_datetime is not null and
									o.value_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)) and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
							group by p.patient_id

						) inicio
					group by patient_id
				) inicio1
				WHERE data_inicio<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))

            ) inicio_real
		     INNER JOIN
		 (
			SELECT patient_id,max(data_consulta) data_consulta,max(data_proxima_consulta) data_proxima_consulta
			FROM
			(

				SELECT 	ultimavisita.patient_id,ultimavisita.encounter_datetime data_consulta ,o.value_datetime data_proxima_consulta
				FROM
					(	SELECT 	p.patient_id,max(encounter_datetime) as encounter_datetime
						FROM 	encounter e
								INNER JOIN patient p on p.patient_id=e.patient_id
						WHERE 	e.voided=0 and p.voided=0 and e.encounter_type=6 and
						       e.location_id=(SELECT value_string FROM muzima_setting  WHERE property = 'Encounter.DefaultLocationId')
						  and e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
						group by p.patient_id
					) ultimavisita
					INNER JOIN encounter e on e.patient_id=ultimavisita.patient_id
					INNER JOIN obs o on o.encounter_id=e.encounter_id
				WHERE 	o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and
						e.encounter_type=6 and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')

				UNION

				SELECT 	ultimavisita.patient_id,ultimavisita.encounter_datetime data_consulta ,o.value_datetime data_proxima_consulta
				FROM
					(	SELECT 	p.patient_id,max(encounter_datetime) as encounter_datetime
						FROM 	encounter e
								INNER JOIN patient p on p.patient_id=e.patient_id
						WHERE 	e.voided=0 and p.voided=0 and e.encounter_type=35 and
						        e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')
						  and   e.encounter_datetime<=date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
						group by p.patient_id
					) ultimavisita
					INNER JOIN encounter e on e.patient_id=ultimavisita.patient_id
					INNER JOIN obs o on o.encounter_id=e.encounter_id
				WHERE 	o.concept_id=6310 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and
						e.encounter_type=35 and e.location_id=(SELECT value_string FROM muzima_setting WHERE property = 'Encounter.DefaultLocationId')


			) consultaRecepcao
			group by patient_id
			-- having max(data_proxima_consulta) between date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval 13 DAY) and date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval 19 DAY)
		 ) consulta on inicio_real.patient_id=consulta.patient_id
		    /**********      Gravidas Diagnosticadas CPN    ***************/
           INNER JOIN  (SELECT patient_id, max(data_gravida) data_gravida
                  FROM (
                           /*********************** Data da gravidez **************************/
                           SELECT p.patient_id, e.encounter_datetime data_gravida
                           FROM patient p

                                    INNER JOIN encounter e on p.patient_id = e.patient_id
                                    INNER JOIN obs o on e.encounter_id = o.encounter_id

                           WHERE p.voided = 0
                             and e.voided = 0
                             and o.voided = 0
                             and concept_id = 1600
                             and e.encounter_type in (5, 6)
                             and e.encounter_datetime BETWEEN date_add(
                                   date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -3
                                   month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                             and e.location_id = (SELECT location_id
                                                  FROM location l
                                                  WHERE l.name = (SELECT property_value
                                                                  FROM global_property
                                                                  WHERE property = 'default_location'))
                           union
                           /**** Inscricao no programa PTV/ETV ***/
                           SELECT pp.patient_id, pp.date_enrolled data_gravida
                           FROM patient_program pp
                           WHERE pp.program_id = 8
                             and pp.voided = 0
                             and pp.date_enrolled BETWEEN date_add(
                                   date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -3
                                   month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                             and pp.location_id = (SELECT location_id
                                                   FROM location l
                                                   WHERE l.name = (SELECT property_value
                                                                   FROM global_property
                                                                   WHERE property = 'default_location'))

                           union
                           /*****   Gravida com inicio inicio tarv no periodo na: Ficha resumo **************/
                           SELECT p.patient_id, o.value_datetime data_gravida
                           FROM patient p
                                    INNER JOIN encounter e on p.patient_id = e.patient_id
                                    INNER JOIN obs o on e.encounter_id = o.encounter_id
                           --    INNER JOIN obs obsART on e.encounter_id = obsART.encounter_id
                           WHERE p.voided = 0
                             and e.voided = 0
                             and o.voided = 0
                             and o.concept_id = 1982
                             and o.value_coded = 1065
                             and e.encounter_type = 53
                             and o.value_datetime BETWEEN date_add(
                                   date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -3
                                   month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                             and e.location_id = (SELECT location_id
                                                  FROM location l
                                                  WHERE l.name = (SELECT property_value
                                                                  FROM global_property
                                                                  WHERE property = 'default_location'))

                           union
                           --  Marcada Gestante  na FC
                           SELECT p.patient_id, e.encounter_datetime data_gravida
                           FROM patient p
                                    INNER JOIN encounter e
                                               on p.patient_id = e.patient_id
                                    INNER JOIN obs o on e.encounter_id = o.encounter_id
                           WHERE p.voided = 0
                             and e.voided = 0
                             and o.voided = 0
                             and concept_id = 1982
                             and value_coded = 1065
                             and e.encounter_type in (5, 6)
                             and e.encounter_datetime BETWEEN  date_add(
                                   date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY)), interval -3
                                   month) and date(DATE_ADD(now(), INTERVAL (-WEEKDAY(now())) DAY))
                             and current_date
                             and e.location_id = (SELECT location_id
                                                  FROM location l
                                                  WHERE l.name = (SELECT property_value
                                                                  FROM global_property
                                                                  WHERE property = 'default_location'))) all_gravida
                  group by patient_id) gravida_real on gravida_real.patient_id = inicio_real.patient_id
			    
		INNER JOIN person p on p.person_id=inicio_real.patient_id
		WHERE timestampdiff(year,birthdate,date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)))>=15
		  and inicio_real.data_inicio between date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval -90 DAY) and date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
          and ( datediff(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), inicio_real.data_inicio ) between 15 and 22 or
                datediff(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), inicio_real.data_inicio ) between 45 and 52 or
                datediff(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), inicio_real.data_inicio ) between 75 and 82 )



           UNION

         /* 4.1 Procedimentos para implementação das chamadas e visitas preventivas
            Critérios de Elegibilidade
            ✓ Todas crianças, adolescentes, adultos seropositivos que apresentam factores de psicossociais que afectam
            a adesão;   */

            SELECT
						e.patient_id,
						'factores psicossociais' as criterio
						FROM encounter e INNER JOIN
										(   SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_risco_adesao
											FROM 	obs o
											INNER JOIN encounter e ON o.encounter_id=e.encounter_id
											WHERE 	e.encounter_type IN (6,9,18,35) AND e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=(
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
											GROUP BY patient_id ) ult_risco_adesao
						ON ult_risco_adesao.patient_id=e.patient_id
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE e.encounter_datetime = ult_risco_adesao.data_ult_risco_adesao AND
						e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=(
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
						AND e.encounter_type IN (6,9,18,35) and e.encounter_datetime  BETWEEN  date_sub(current_date, interval  30 day) and  date_sub(current_date, interval  23 day)
						GROUP BY patient_id

     ) elegiveis_preventiva

     INNER JOIN person p on p.person_id = elegiveis_preventiva.patient_id

      /**********      Gravidas Diagnosticadas CPN    ***************/
     INNER JOIN  (

       SELECT patient_id, max(data_gravida) data_gravida
       FROM (
       /*********************** Data da gravidez **************************/
        SELECT p.patient_id, e.encounter_datetime data_gravida
                FROM patient p

                         INNER JOIN encounter e on p.patient_id = e.patient_id
                         INNER JOIN obs o on e.encounter_id = o.encounter_id

                WHERE p.voided = 0
                  and e.voided = 0
                  and o.voided = 0
                  and concept_id = 1600
                  and e.encounter_type in (5, 6)
                  and e.encounter_datetime BETWEEN  date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval -3 month) and date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
                  and e.location_id = (SELECT location_id
                                       FROM location l
                                       WHERE l.name = (SELECT property_value
                                                       FROM global_property
                                                       WHERE property = 'default_location'))
        union
        /**** Inscricao no programa PTV/ETV ***/
        SELECT pp.patient_id, pp.date_enrolled data_gravida
                                                     FROM patient_program pp
                                                     WHERE pp.program_id = 8
                                                       and pp.voided = 0
                                                       and pp.date_enrolled BETWEEN date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval -3 month) and date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
                                                       and pp.location_id = (SELECT location_id
                                                                             FROM location l
                                                                             WHERE l.name = (SELECT property_value
                                                                                             FROM global_property
                                                                                             WHERE property = 'default_location'))

        union
        /*****   Gravida com inicio inicio tarv no periodo na: Ficha resumo **************/
        SELECT p.patient_id, o.value_datetime data_gravida
                                                     FROM patient p
                                                              INNER JOIN encounter e on p.patient_id = e.patient_id
                                                              INNER JOIN obs o on e.encounter_id = o.encounter_id
                                                     --    INNER JOIN obs obsART on e.encounter_id = obsART.encounter_id
                                                     WHERE p.voided = 0
                                                       and e.voided = 0
                                                       and o.voided = 0
                                                       and o.concept_id = 1982
                                                       and o.value_coded = 1065
                                                       and e.encounter_type = 53
                                                       and o.value_datetime BETWEEN date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval -3 month) and date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
                                                       and e.location_id = (SELECT location_id
                                                                            FROM location l
                                                                            WHERE l.name = (SELECT property_value
                                                                                            FROM global_property
                                                                                            WHERE property = 'default_location'))

        union
        --  Marcada Gestante  na FC
        SELECT p.patient_id, e.encounter_datetime data_gravida
        FROM patient p
                 INNER JOIN encounter e
                            on p.patient_id = e.patient_id
                 INNER JOIN obs o on e.encounter_id = o.encounter_id
        WHERE p.voided = 0
          and e.voided = 0
          and o.voided = 0
          and concept_id = 1982
          and value_coded = 1065
          and e.encounter_type in (5, 6)
          and e.encounter_datetime BETWEEN BETWEEN date_add(date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY)), interval -3 month) and date(DATE_ADD(now(), INTERVAL(-WEEKDAY(now())) DAY))
          and current_date
          and e.location_id = (SELECT location_id
                               FROM location l
                               WHERE l.name = (SELECT property_value
                                               FROM global_property
                                               WHERE property = 'default_location'))) all_gravida
       group by patient_id) gravida_real on gravida_real.patient_id = elegiveis_preventiva.patient_id

                    -- Informacao sobre o outcome da gravidez

         left join (
     SELECT patient_id,
            max(data_parto) data_parto
            FROM (
        -- DATA DO PARTO     #5599: Dia em que a mulher da parto.
    SELECT p.patient_id, o.value_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id
    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 5599
      and e.encounter_type in (5, 6)
      and o.value_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
    union
    /**********            LACTANTE            ***************/
    SELECT p.patient_id, e.encounter_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id
    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6332
      and value_coded = 1065
      and e.encounter_type = 6
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
    union
        /**********      LACTANTE   na FICHA RESUMO         ***************/
    SELECT p.patient_id, o.value_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id

    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and o.concept_id = 6332
      and o.value_coded = 1065
      and e.encounter_type = 53
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))

    union
    SELECT p.patient_id, e.encounter_datetime data_parto
    FROM patient p
             INNER JOIN encounter e on p.patient_id = e.patient_id
             INNER JOIN obs o on e.encounter_id = o.encounter_id
    WHERE p.voided = 0
      and e.voided = 0
      and o.voided = 0
      and concept_id = 6334
      and value_coded = 6332
      and e.encounter_type in (5, 6)
      and e.encounter_datetime BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and e.location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
    union
    SELECT pg.patient_id, ps.start_date data_parto
    FROM patient p
             INNER JOIN patient_program pg on p.patient_id = pg.patient_id
             INNER JOIN patient_state ps on pg.patient_program_id = ps.patient_program_id
    WHERE pg.voided = 0
      and ps.voided = 0
      and p.voided = 0
      and pg.program_id = 8
      and ps.state = 27
      and ps.start_date BETWEEN  date_sub(current_date, interval  18 month)  and  current_date
      and location_id = (
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))) all_lactante group by  patient_id) lactante_real
                   on lactante_real.patient_id = elegiveis_preventiva.patient_id

			left join
			(	SELECT pad1.*
				FROM person_address pad1
				INNER JOIN
				(
					SELECT person_id,min(person_address_id) id
					FROM person_address
					WHERE voided=0
					group by person_id
				) pad2
				WHERE pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
			) pad3 on pad3.person_id=elegiveis_preventiva.patient_id
			left join
			(	SELECT pn1.*
				FROM person_name pn1
				INNER JOIN
				(
					SELECT person_id,min(person_name_id) id
					FROM person_name
					WHERE voided=0
					group by person_id
				) pn2
				WHERE pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
			) pn on pn.person_id=elegiveis_preventiva.patient_id
			left join
			(       SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
					(
						SELECT patient_id,min(patient_identifier_id) id
						FROM patient_identifier
						WHERE voided=0
						group by patient_id
					) pid2
					WHERE pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
			) pid on pid.patient_id=elegiveis_preventiva.patient_id
			left join person_attribute pat on pat.person_id=elegiveis_preventiva.patient_id
							and pat.person_attribute_type_id=9
							and pat.value is not null
							and pat.value<>'' and pat.voided=0
			left join
			(
				SELECT 	pg.patient_id,ps.start_date encounter_datetime,location_id,
						case ps.state
							when 7 then 'TRANSFERIDO PARA'
							when 8 then 'SUSPENSO'
							when 9 then 'ABANDONO'
							when 10 then 'OBITO'
						else 'OUTRO' end as estado
				FROM 	patient p
						INNER JOIN patient_program pg on p.patient_id=pg.patient_id
						INNER JOIN patient_state ps on pg.patient_program_id=ps.patient_program_id
				WHERE 	pg.voided=0 and ps.voided=0 and p.voided=0 and
						pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and location_id=(
SELECT location_id FROM location l WHERE l.name = (SELECT property_value FROM global_property WHERE property = 'default_location'))
             group by pg.patient_id
			) saida on saida.patient_id=elegiveis_preventiva.patient_id

       /****************************** CONSENTIMENTO ***********************************/
			left join
			(
			 SELECT patient_id FROM (SELECT p.patient_id
                                     FROM encounter e
                                              INNER JOIN patient p on p.patient_id = e.patient_id
                                              INNER JOIN obs o on o.encounter_id = e.encounter_id
                                     WHERE o.concept_id = 1738
                                       and o.value_coded = 1065
                                       and o.voided = 0
                                       and e.voided = 0
                                       and p.voided = 0
                                       and e.encounter_type = 19
                                       and e.location_id = (SELECT location_id
                                                            FROM location l
                                                            WHERE l.name = (SELECT property_value
                                                                            FROM global_property
                                                                            WHERE property = 'default_location'))
                                     group by p.patient_id

                                     union
                                     -- CONCORDA EM SER CONTACTADO EM CASO DE NECESSIDADE PELA UNIDADE SANITÁRIA
                                     SELECT p.patient_id
                                     FROM encounter e
                                              INNER JOIN patient p on p.patient_id = e.patient_id
                                              INNER JOIN obs o on o.encounter_id = e.encounter_id
                                     WHERE o.concept_id = 6306
                                       and o.value_coded = 1065
                                       and o.voided = 0
                                       and e.voided = 0
                                       and p.voided = 0
                                       and e.encounter_type in (34, 35)
                                       and e.location_id = (SELECT location_id
                                                            FROM location l
                                                            WHERE l.name = (SELECT property_value
                                                                            FROM global_property
                                                                            WHERE property = 'default_location'))
                                     group by p.patient_id) all_consentimento group by patient_id
			) consentimento on consentimento.patient_id=elegiveis_preventiva.patient_id


