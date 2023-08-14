
SELECT
    *  FROM (
SELECT      f_nome.patient_id,
DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
 ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
           CONCAT(pid.identifier,' ') AS NID,
           CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
		   p.gender,
           confidente.nome as nome_confidente, f_nome.nome_confidente as nome_familiar , 	DATE_FORMAT(f_nome.encounter_datetime,'%d/%m/%Y') AS data_registo ,   f_parentesco.parentesco ,   f_idade.idade,
		   f_teste_hiv.teste_hiv  ,  f_cuidados_hiv.cuidados_hiv ,  f_ccr.ccr ,f_nid.nid as nid_familiar ,
		   DATE_FORMAT(ult_seguimento.encounter_datetime, '%d/%m/%Y') AS data_ult_consulta,
           DATE_FORMAT(ult_seguimento.value_datetime, '%d/%m/%Y') AS data_proxima_visita,
           ult_seguimento.value_datetime AS proxima_visita,
           DATE_FORMAT(fila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
           DATE_FORMAT(fila.value_datetime,'%d/%m/%Y') AS fila_proximo_marcado ,
           DATE_FORMAT(ficha_rastreio_familiar.data_ficha_rastreio_familiar,'%d/%m/%Y') as data_ficha_rastreio_familiar,
           telef.value AS telefone
            
            
           FROM

          (select patient_id, data_inicio
             FROM (select inicio_fila_seg_prox.*,
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
                                        where p.voided  = 0
                                          and pe.voided = 0
                                          and e.voided  = 0
                                          and o.voided  = 0
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
                                                and p.voided  = 0
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
            and date_add(data_usar, interval 28 day) >= CURDATE()
   ) inicio_real

  INNER JOIN
(  select
        e.patient_id,
        o.value_text AS nome_confidente,
         encounter_datetime,
        o.obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23778
            AND e.encounter_datetime <= :endDate  AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23778 
            AND e.location_id=:location
      ) f_nome on f_nome.patient_id=inicio_real.patient_id

    INNER JOIN person p ON p.person_id=inicio_real.patient_id

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
			) pn ON pn.person_id=f_nome.patient_id			
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
			) pid ON pid.patient_id=f_nome.patient_id
		
    /***************************    FAMILIAR  PARENTESCO ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
       when 23706 then 	'TRABALHADOR'
		when 5622 then 	'OUTRO, NAO CODIFICADO'
		when 23705	then 'PRIMO'
		when 23707	then 'FILHO'
		when 23708	then 'NETO'
		when 970	then 'MAE'
        when 971	then 'PAI'
        when 972	then 'IRMAO'
        when 973 then 'AVO'
        when 975 then 'TIA'
        when 1921	then 'PARCEIRO'
        when 1930 then 'AMIGO OU COLIGA'
        when 1930	then 'AMIGO OU COLEGA'
        when 2034	then 'VIZINHO'
        when 2036 then	'CHEFE DE  BAIRRO'
        when 2036	then 'SECRETARIO DO BAIRRO'
        when 1067	then 'Desconhecido'
        else '' end as parentesco,
        encounter_datetime,
        o.obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.encounter_datetime <=:endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.location_id=:location
  ) f_parentesco ON  f_parentesco.patient_id = f_nome.patient_id  and f_parentesco.encounter_datetime = f_nome.encounter_datetime   and  f_nome.obs_group_id =  f_parentesco.obs_group_id
  
      /***************************  FAMILIAR   IDADE   ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
        value_numeric as idade,
        encounter_datetime,
       o.obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23777
            AND e.encounter_datetime <=:endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23777
            AND e.location_id=:location
   ) f_idade ON  f_idade.patient_id = f_nome.patient_id  and f_idade.encounter_datetime = f_nome.encounter_datetime  and  f_nome.obs_group_id =  f_idade.obs_group_id
    
    
      /***************************    FAMILIAR  Teste HIV ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
       when 1067	then 'Desconhecido'
         when 664 then 'NEGATIVO'
        when 703	then 'POSITIVO'
        else '' end as teste_hiv,
        encounter_datetime,
        obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23779
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23779
            AND e.location_id=:location
   ) f_teste_hiv ON  f_teste_hiv.patient_id = f_nome.patient_id  and f_teste_hiv.encounter_datetime = f_nome.encounter_datetime   and  f_nome.obs_group_id =  f_teste_hiv.obs_group_id
    
    
    
      /***************************    FAMILIAR  Cuidados HIV ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
        when 1065 then 'Sim'
        when 1066 then 'Nao'
        else '' end as cuidados_hiv,
        encounter_datetime,
       o.obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23780
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23780
            AND e.location_id=:location
    ) f_cuidados_hiv ON  f_cuidados_hiv.patient_id = f_nome.patient_id  and f_cuidados_hiv.encounter_datetime = f_nome.encounter_datetime  and   f_nome.obs_group_id =  f_cuidados_hiv.obs_group_id
    
    
      /***************************    FAMILIAR  CCR  ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
        when 1065 then 'Sim'
        when 1066 then 'Nao'
        when 23892 then 'Alta'
        else '' end as ccr,
        obs_group_id,
        encounter_datetime

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1885
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1885
            AND e.location_id=:location
 ) f_ccr ON  f_ccr.patient_id = f_nome.patient_id   and f_ccr.encounter_datetime = f_nome.encounter_datetime and   f_nome.obs_group_id =  f_ccr.obs_group_id
    
    
       /***************************  FAMILIAR   nid   ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
        o.value_text as nid,
        encounter_datetime,
        obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23781
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23781
            AND e.location_id=:location
    ) f_nid ON  f_nid.patient_id = f_nome.patient_id  and f_nid.encounter_datetime = f_nome.encounter_datetime  and   f_nome.obs_group_id =  f_nid.obs_group_id
    
    
    
     /***************************    Confidente  Parceiro ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
            CASE o.value_coded
                WHEN 1921 THEN 'PARCEIRO'
				ELSE ''
            END AS grau_parentesco,
            e.encounter_datetime
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.location_id=:location
    GROUP BY patient_id) parceiro  ON parceiro.patient_id = f_nome.patient_id  and parceiro.encounter_datetime = f_nome.encounter_datetime 
    
       /***************************    Confidente  Nome ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       o.value_text AS nome,
       encounter_datetime
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1740
            AND e.encounter_datetime <= :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1740
            AND e.location_id=:location
    GROUP BY patient_id) confidente  ON confidente.patient_id = f_nome.patient_id  and confidente.encounter_datetime = f_nome.encounter_datetime 
    
    
     /***************************    ultima consulta ****************************************/
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
            AND e.location_id = :location) ult_seguimento ON ult_seguimento.patient_id = f_nome.patient_id
            
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
		) fila ON fila.patient_id=f_nome.patient_id 
 

 /******************************** Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value  
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9 
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0 
	) telef  ON telef.person_id = f_nome.patient_id

   	LEFT JOIN
    (
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ficha_rastreio_familiar
							FROM encounter e
							
							 WHERE e.form_id = 146 AND e.voided=0
                            AND e.location_id=:location
							GROUP BY patient_id

			      )  ficha_rastreio_familiar ON ficha_rastreio_familiar.patient_id = f_nome.patient_id


group by  f_nome.patient_id,  f_nome.nome_confidente
    ) pat_index
 where   data_ficha_rastreio_familiar is null and   proxima_visita between  curdate() and :endDate

