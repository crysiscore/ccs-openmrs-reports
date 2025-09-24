/*
Name - CCS LISTA DE PACIENTES COM RASTREIO DE DOENCA AVANCADA
Description -
		#   Critérios para elegiveis para rastreio de doença avançada:
		•	Inicios TARV (do período que se pretende extrair a lista),
		•	Reinicios (do período que se pretende extrair a lista),
		•	Grávidas
		•	Falências- 2 CVs consecutivas acima de 1000; Ficha LAB
		•	Ter iniciado TB ou estar em tratamento TB no periodo( Ficha clinica)
		*   Incluir como variável
		•	último Resultado do CD4 abaixo de 200;
		•	pacientes com teste de CrAG e TB_LAM;
		•	Data de Inicio TARV;


Created By - Agnaldo  Samuel
Created Date - 29/08/2021

Modified  By - Agnaldo  Samuel
Modification Date - 04/01/2022
Modification Reason:  Novos criterios de elegibilidade

Modified  By - Agnaldo  Samuel
Modification Date - 14/05/2025
Modification Reason:
        • Retirar o CD4 como critério mas mantendo como uma variável adicional somente;
        • Acrescentar uma coluna das mulheres grávidas inscritas (considerar somente a data de inscrição no programa) no periodo de reporte
        • Manter todos os restantes critérios referentes à CV.


*/


SELECT
    *
FROM
    (SELECT
        inicio_real.patient_id,
            CONCAT(pid.identifier, ' ') AS NID,
            CONCAT(IFNULL(pn.given_name, ''), ' ', IFNULL(pn.middle_name, ''), ' ', IFNULL(pn.family_name, '')) AS 'NomeCompleto',
            p.gender,
            DATE_FORMAT(p.birthdate, '%d/%m/%Y') AS birthdate,
            ROUND(DATEDIFF(:endDate, p.birthdate) / 365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio, '%d/%m/%Y') AS data_inicio,
            DATE_FORMAT(gravida.data_gravida, '%d/%m/%Y') AS data_gravida,
             DATE_FORMAT(inscricao_ptv.data_gravida, '%d/%m/%Y') AS data_inscricao_ptv,
            DATE_FORMAT(  marcado_tb.data_marcado_tb , '%d/%m/%Y') AS data_marcado_tb,
            DATE_FORMAT(falencia_cv.encounter_datetime, '%d/%m/%Y') AS data_ult_cv,
            falencia_cv.ult_cv,
               DATE_FORMAT(falencia_cv.data_penul_cv, '%d/%m/%Y') AS data_penult_cv,
            falencia_cv.penul_cv as penult_cv,
            tb_lam.resul_tb_lam,
            DATE_FORMAT(tb_lam.data_result,'%d/%m/%Y') AS data_tb_lam,
            tb_crag.resul_tb_crag,
            DATE_FORMAT(tb_crag.data_result,'%d/%m/%Y')  AS data_crag,
            if(cd4.value_numeric is not null , cd4.value_numeric , if(cd4_perc.value_numeric is not null, concat(cd4_perc.value_numeric, '%'), '' )
			 ) AS cd4,
			  if(cd4.encounter_datetime is not null , DATE_FORMAT(cd4.encounter_datetime,'%d/%m/%Y')  , if(cd4_perc.encounter_datetime is not null, DATE_FORMAT(cd4_perc.encounter_datetime,'%d/%m/%Y') , '' )
			 ) AS data_cd4,
            permanencia.estado_permanencia,
			DATE_FORMAT(permanencia.data_consulta, '%d/%m/%Y') AS data_reinicio,
            telef.value AS telefone,
            DATE_FORMAT(ult_seguimento.encounter_datetime, '%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime, '%d/%m/%Y') AS data_proxima_visita,
            pad3.county_district AS 'Distrito',
            pad3.address2 AS 'Padministrativo',
            pad3.address6 AS 'Localidade',
            pad3.address5 AS 'Bairro',
            pad3.address1 AS 'PontoReferencia'
    FROM
    /* Start  ************************************* Inicio real ************************************/
       (select patient_id, data_inicio
          from (select inicio_fila_seg_prox.*,
                       GREATEST(COALESCE(data_fila, data_seguimento), COALESCE(data_seguimento, data_fila))    data_usar_c,
                       GREATEST(COALESCE(data_proximo_lev, data_proximo_seguimento, data_recepcao_levantou30),
                                COALESCE(data_proximo_seguimento, data_proximo_lev, data_recepcao_levantou30),
                                COALESCE(data_recepcao_levantou30, data_proximo_seguimento, data_proximo_lev)) data_usar
                from (select inicio_fila_seg.*,
                             max(obs_fila.value_datetime)                      data_proximo_lev,
                             max(obs_seguimento.value_datetime)                data_proximo_seguimento,
                             date_add(data_recepcao_levantou, interval 30 day) data_recepcao_levantou30
                      from (select inicio.*,
                                   saida.data_estado,
                                   max_fila.data_fila,
                                   max_consulta.data_seguimento,
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
                                          and e.encounter_datetime <= :endDate
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
                                          and o.value_datetime <= :endDate
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
                                          and date_enrolled <= :endDate
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
                                          and e.encounter_datetime <= :endDate
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
                                          and o.value_datetime <= :endDate
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
                                                and ps.start_date <= :endDate
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
                                          and o.obs_datetime <= :endDate
                                          and e.location_id = :location
                                        group by p.patient_id
                                        union
                                        select person_id as patient_id, death_date as data_estado
                                        from person
                                        where dead = 1
                                          and voided = 0
                                          and death_date is not null
                                          and death_date <= :endDate
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
                                          and e.encounter_datetime <= :endDate
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
                                                            and ps.start_date <= :endDate
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
                                                      and o.obs_datetime <= :endDate
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
                                                            and e.encounter_datetime <= :endDate
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
                                                            and e.encounter_datetime <= :endDate
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
                                                      and o.value_datetime <= :endDate
                                                    group by p.patient_id) ultimo_levantamento
                                              group by patient_id) ultimo_levantamento
                                             on saidas_por_transferencia.patient_id = ultimo_levantamento.patient_id
                                        where ultimo_levantamento.data_ultimo_levantamento <= :endDate) allSaida
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
                                    and e.encounter_datetime <= :endDate
                                  group by p.patient_id) max_fila on inicio.patient_id = max_fila.patient_id
                                     left join
                                 (select p.patient_id, max(encounter_datetime) data_seguimento
                                  from patient p
                                           inner join person pe on pe.person_id = p.patient_id
                                           inner join encounter e on e.patient_id = p.patient_id
                                  where p.voided = 0
                                    and pe.voided = 0
                                    and e.voided = 0
                                    and e.encounter_type in (6, 9)
                                    and e.location_id = :location
                                    and e.encounter_datetime <= :endDate
                                  group by p.patient_id) max_consulta on inicio.patient_id = max_consulta.patient_id
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
                                    and o.value_datetime <= :endDate
                                    and e.location_id = :location
                                  group by p.patient_id) max_recepcao on inicio.patient_id = max_recepcao.patient_id
                            group by inicio.patient_id) inicio_fila_seg
                               left join
                           obs obs_fila on obs_fila.person_id = inicio_fila_seg.patient_id
                               and obs_fila.voided = 0
                               and obs_fila.obs_datetime = inicio_fila_seg.data_fila
                               and obs_fila.concept_id = 5096
                               and obs_fila.location_id = :location
                               left join
                           obs obs_seguimento on obs_seguimento.person_id = inicio_fila_seg.patient_id
                               and obs_seguimento.voided = 0
                               and obs_seguimento.obs_datetime = inicio_fila_seg.data_seguimento
                               and obs_seguimento.concept_id = 1410
                               and obs_seguimento.location_id = :location
                      group by inicio_fila_seg.patient_id) inicio_fila_seg_prox
                group by patient_id) coorte12meses_final
          where (data_estado is null or (data_estado is not null and data_usar_c > data_estado))
            and date_add(data_usar, interval 28 day) >= :endDate
)inicio_real
    /* END  **************************************  Inicio real ************************************/
        INNER JOIN person p ON p.person_id = inicio_real.patient_id

    /*  Start  ********************************** person attributees ********************************/
    LEFT JOIN (SELECT
        pad1.*
    FROM
        person_address pad1
    INNER JOIN (SELECT
        person_id, MIN(person_address_id) id
    FROM
        person_address
    WHERE
        voided = 0
    GROUP BY person_id) pad2
    WHERE
        pad1.person_id = pad2.person_id
            AND pad1.person_address_id = pad2.id) pad3 ON pad3.person_id = inicio_real.patient_id
    LEFT JOIN (SELECT
        pn1.*
    FROM
        person_name pn1
    INNER JOIN (SELECT
        person_id, MIN(person_name_id) id
    FROM
        person_name
    WHERE
        voided = 0
    GROUP BY person_id) pn2
    WHERE
        pn1.person_id = pn2.person_id
            AND pn1.person_name_id = pn2.id) pn ON pn.person_id = inicio_real.patient_id
    LEFT JOIN (SELECT
        pid1.*
    FROM
        patient_identifier pid1
    INNER JOIN (SELECT
        patient_id, MIN(patient_identifier_id) id
    FROM
        patient_identifier
    WHERE
        voided = 0
    GROUP BY patient_id) pid2
    WHERE
        pid1.patient_id = pid2.patient_id
            AND pid1.patient_identifier_id = pid2.id) pid ON pid.patient_id = inicio_real.patient_id
    /*  End  ********************************** person attributees **********************************/
    /* Start ******************************************* Inscricao PTV  ***********************************/
    LEFT JOIN (SELECT
        patient_id, MAX(data_gravida) AS data_gravida
    FROM
        (/* SELECT -- Criterio removido por solicitacao. Mauricio 06.05.2025
        p.patient_id, MAX(obs_datetime) data_gravida
    FROM
        patient p
    INNER JOIN encounter e ON p.patient_id = e.patient_id
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        p.voided = 0 AND e.voided = 0
            AND o.voided = 0
            AND concept_id = 1982
            AND value_coded = 1065
            AND e.encounter_type = 6
            AND o.obs_datetime BETWEEN :startDate AND :endDate
            AND e.location_id = :location
    GROUP BY p.patient_id UNION */ SELECT
        pp.patient_id, pp.date_enrolled AS data_gravida
    FROM
        patient_program pp
    WHERE
        pp.program_id = 8 AND pp.voided = 0
            AND pp.date_completed IS NULL
            AND pp.date_enrolled BETWEEN :startDate AND :endDate
            AND pp.location_id = :location) gravida
    GROUP BY patient_id) inscricao_ptv ON inscricao_ptv.patient_id = inicio_real.patient_id

            /* Start ******************************************* Gravida  ***********************************/
    LEFT JOIN ( SELECT
        p.patient_id, MAX(obs_datetime) data_gravida
    FROM
        patient p
    INNER JOIN encounter e ON p.patient_id = e.patient_id
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        p.voided = 0 AND e.voided = 0
            AND o.voided = 0
            and e.voided=0
            AND concept_id = 1982
            AND value_coded = 1065
            AND e.encounter_type = 6
            AND o.obs_datetime BETWEEN :startDate AND :endDate
            AND e.location_id = :location
    GROUP BY p.patient_id
   ) gravida ON gravida.patient_id = inicio_real.patient_id
    /* End ******************************************* Gravida  *************************************/
    /* Start ************************ TRATAMENTO DE TUBERCULOSE NA FICHA CLINICA  *******************/
    LEFT JOIN
		( Select ultimavisita_tb.patient_id, ultimavisita_tb.encounter_datetime data_marcado_tb,
        CASE o.value_coded
					WHEN '1256'  THEN 'INICIO'
					WHEN '1257' THEN 'CONTINUA'

				ELSE '' END AS tratamento_tb
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
			e.encounter_type in (6,9) and o.value_coded in (1256,1257) and e.location_id=:location
			       and  e.encounter_datetime BETWEEN :startDate AND :endDate
		) marcado_tb on marcado_tb.patient_id =   inicio_real.patient_id
    /* End *********************** TRATAMENTO DE TUBERCULOSE NA FICHA CLINICA  **********************/
    /* Start *******************************        Falencia CV           ***************************/
    LEFT JOIN (
SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT e.patient_id, encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime , (	SELECT	 visita.value_numeric
					FROM
                    ( SELECT e.patient_id, encounter_datetime,o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS ult_cv , (	SELECT	 visita.value_numeric
					FROM
                    ( SELECT e.patient_id, encounter_datetime,o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS penul_cv ,(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT e.patient_id, encounter_datetime
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS data_penul_cv
FROM 	   ( SELECT e.patient_id, encounter_datetime, o.value_numeric
                      FROM encounter e
                               INNER JOIN obs o ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 13, 51)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id IN (856)
				) visita2
GROUP BY visita2.patient_id
having  ult_cv <> penul_cv and ult_cv > 0
       ) falencia_cv ON falencia_cv.patient_id = inicio_real.patient_id
     /****************** ****************************  CD4  Absoluto  *****************************************************/
        LEFT JOIN(
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN
		    (
            SELECT 	cd4_max.patient_id, MAX(cd4_max.encounter_datetime) AS encounter_datetime
            FROM ( SELECT e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND e.location_id=:location  AND
							o.voided=0 AND o.concept_id=1695 AND e.encounter_type IN (6,9,13,53)
				) cd4_max
			GROUP BY patient_id ) cd4_temp
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id = 1695 AND e.encounter_type IN (6,9,13,53)
			GROUP BY patient_id

		) cd4 ON cd4.patient_id =  inicio_real.patient_id
		/****************** ****************************  CD4  Percentual  *****************************************************/
        LEFT JOIN(
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN
		    (
            SELECT 	cd4_max.patient_id, MAX(cd4_max.encounter_datetime) AS encounter_datetime
            FROM (
					SELECT 	 e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND  e.location_id=:location  AND
							o.voided=0 AND o.concept_id=730 AND e.encounter_type in (6,9,13,53)  )cd4_max
			GROUP BY patient_id ) cd4_temp
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id =730  AND e.encounter_type in (6,9,13,53)
			GROUP BY patient_id

		) cd4_perc ON cd4_perc.patient_id =  inicio_real.patient_id
    /* Start ************************************* TB LAM  ******************************************/
    LEFT JOIN (SELECT
        e.patient_id,
            CASE o.value_coded
                WHEN 664 THEN 'NEGATIVO'
                WHEN 703 THEN 'POSITIVO'
                ELSE ''
            END AS resul_tb_lam,
            encounter_datetime AS data_result
    FROM
        (SELECT
        e.patient_id, MAX(encounter_datetime) AS data_ult_linhat
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 13 ,51)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23951
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
    GROUP BY patient_id) ult_linhat
    INNER JOIN encounter e ON e.patient_id = ult_linhat.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 53 ,51)
            AND ult_linhat.data_ult_linhat = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23951
    GROUP BY patient_id) tb_lam ON tb_lam.patient_id = inicio_real.patient_id
    /* Start *********************************** CRAG  **********************************************/
    LEFT JOIN (SELECT
        e.patient_id,
            CASE o.value_coded
                WHEN 664 THEN 'NEGATIVO'
                WHEN 703 THEN 'POSITIVO'
                ELSE ''
            END AS resul_tb_crag,
            encounter_datetime AS data_result
    FROM
        (SELECT
        e.patient_id, MAX(encounter_datetime) AS data_ult_linhat
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 13,51)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
    GROUP BY patient_id) ult_linhat
    INNER JOIN encounter e ON e.patient_id = ult_linhat.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 53,51)
            AND ult_linhat.data_ult_linhat = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
    GROUP BY patient_id) tb_crag ON tb_crag.patient_id = inicio_real.patient_id

    /* End   *********************************** Permanencaio ARV  **********************************************/
    LEFT JOIN (SELECT
        e.patient_id,
        IF(o.value_coded = 1705, 'REINICIO', '') AS estado_permanencia,
            encounter_datetime                   AS data_consulta
    FROM
        (SELECT
        e.patient_id, MAX(encounter_datetime) AS data_ult_linhat
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type IN (6 , 9)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 6273
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
    GROUP BY patient_id) ult_linhat
    INNER JOIN encounter e ON e.patient_id = ult_linhat.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9)
            AND ult_linhat.data_ult_linhat = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 6273
    GROUP BY patient_id) permanencia ON permanencia.patient_id = inicio_real.patient_id
    LEFT JOIN (SELECT
        ultimavisita.patient_id,
            ultimavisita.encounter_datetime,
            o.value_datetime,
            e.location_id,
            e.encounter_id
    FROM
        (SELECT
        e.patient_id, MAX(encounter_datetime) AS encounter_datetime
    FROM
        encounter e
    WHERE
        e.voided = 0
            AND e.encounter_type IN (9 , 6)
    GROUP BY e.patient_id) ultimavisita
    INNER JOIN encounter e ON e.patient_id = ultimavisita.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        o.concept_id = 1410 AND o.voided = 0
            AND e.voided = 0
            AND e.encounter_datetime = ultimavisita.encounter_datetime
            AND e.encounter_type IN (9 , 6)
            AND e.location_id = :location) ult_seguimento ON ult_seguimento.patient_id = inicio_real.patient_id
    LEFT JOIN (SELECT
        p.person_id, p.value
    FROM
        person_attribute p
    WHERE
        p.person_attribute_type_id = 9
            AND ! p.value
            AND p.value <> ''
            AND p.voided = 0) telef ON telef.person_id = inicio_real.patient_id


    WHERE
        data_inicio BETWEEN :startDate AND :endDate
            OR ( gravida.data_gravida IS NOT NULL  and gravida.data_gravida  BETWEEN :startDate AND :endDate )
            OR (ult_cv > 1000 AND penul_cv > 1000)
            OR permanencia.estado_permanencia = 'REINICIO'
            or data_marcado_tb is NOT NULL) activos

GROUP BY patient_id
