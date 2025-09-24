/*
Name:CCS PACIENTES EM MDS
Description:
              - Pacientes actualmente em tarv, com data do proximo seguimento nao superior a data corremte em 28 dias inscritos em pelo menos 1 MDS

Created By: Agnaldo Samuel
Created Date: 28/03/2021

Change by: Agnaldo  Samuel
Change Date: 13/09/2021
Change Reason: Bug fix
-- Correcao no sub-consulta que busca o  ultimo seguimento
-- Adicao do novo modelo Farmacia Privada
-- filtro de pacientes em MDS num periodo

Change by: Agnaldo  Samuel
Change Date: 29/05/2025
Change Reason: Bug fix
-- Alteracao dos concept-ids de MDS no Ficha clinic

Change by: Agnaldo  Samuel
Change Date: 04/09/2025
Change Reason: Adicao de novos modelos
- DAH - Doenca Avancada por HIV
- DA - Dispensa Anual de ARV
*/



SELECT *
FROM
(SELECT distinct	inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
			modelodf.modelodf,
			DATE_FORMAT(modelodf.data_modelo, '%d/%m/%Y') as data_modelo,
			modelodf.status,
			modelodf.value_coded,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
			DATE_FORMAT(modelodf.data_modelo ,'%d/%m/%Y') as data_inscricao,
            linha_terapeutica.linhat as linhaterapeutica,
			telef.value AS telefone,
            regime.ultimo_regime,
			DATE_FORMAT(visita.encounter_datetime,'%d/%m/%Y') as data_ult_consulta,
            DATE_FORMAT(visita.value_datetime,'%d/%m/%Y') as consulta_proximo_marcado,
            DATE_FORMAT(fila.encounter_datetime,'%d/%m/%Y') as data_ult_levantamento,
            DATE_FORMAT(fila.value_datetime,'%d/%m/%Y') as fila_proximo_marcado,
			IF(DATEDIFF(:endDate,ultimavisita.value_datetime)<=28,'ACTIVO EM TARV','FALTOSO/ABANDONO') estado,
		    pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'


	FROM (select patient_id, data_inicio
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
                                    and e.encounter_datetime <= :endDate
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
                        /*   left join
                           obs obs_seguimento on obs_seguimento.person_id = inicio_fila_seg.patient_id
                               and obs_seguimento.voided = 0
                               and obs_seguimento.obs_datetime = inicio_fila_seg.data_seguimento
                               and obs_seguimento.concept_id = 1410
                               and obs_seguimento.location_id = :location */
                      group by inicio_fila_seg.patient_id) inicio_fila_seg_prox
                group by patient_id) coorte12meses_final

          where (data_estado is null or (data_estado is not null and data_usar_c > data_estado))
            and date_add(data_usar, interval 28 day) >= :endDate
) inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id


		    		/************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		INNER JOIN
		(

select modelos_estado.patient_id, modelos_estado.modelodf, modelos_estado.data_modelo, modelos_estado.status, modelos_estado.data_status,
       modelos_estado.value_coded
from (
select mds.patient_id ,
       mds.modelodf,
       mds.data_modelo as data_modelo,
       st.status,
       st.data_status,
       st.value_coded,
       mds.obs_group_id
from (
                SELECT 	e.patient_id ,
				CASE o.value_coded
 WHEN  165314 THEN 'DA - Dispensa Anual de ARV'
 WHEN  165179 THEN 'DCA - Dispensa Comunitária via APE'
 WHEN  165265 THEN 'CM - Dispensa Comunitária através de CM'
 WHEN  165264 THEN 'BM - Dispensa Comunitária através de Brigadas Móveis'
 WHEN  23729 THEN 'FR - FLUXO RÁPIDO (FR)'
 WHEN  165321 THEN 'DAH - DOENCA AVANCADA POR HIV'
 WHEN  23731 THEN 'DC - Dispensa Comunitária '
 WHEN  23888 THEN 'DS - Dispensa Semestral de ARV'
 WHEN  23726 THEN 'CA - Clubes de Adesão'
 WHEN  165340 THEN 'DB - Dispensa Bimestral'
 WHEN  165178 THEN 'DCP - Dispensa Comunitária através do Provedor'
 WHEN  165319 THEN 'SAAJ - PARAGEM UNICA NO SAAJ'
 WHEN  165318 THEN 'CT - PARAGEM UNICA NOS SERVIÇOS DE TARV'
 WHEN  23730 THEN 'DT - Dispensa Trimestral de ARV'
 WHEN  165315 THEN 'DD - Dispensa Descentralizada de ARV'
 WHEN  165316 THEN 'EH - Extensão de Horário'
 WHEN  23725 THEN 'AF - Abordagem Familiar'
 WHEN  165177 THEN 'FARMAC/Farmácia Privada'
 WHEN  165317 THEN 'TB - Paragem única no sector da TB'
 WHEN  23727 THEN 'PU - Paragem Única'
 WHEN  23724 THEN 'GAAC - Gaac'
 WHEN  165320 THEN 'SMI - PARAGEM UNICA NA SMI'
 WHEN 23724 THEN 'GA - Grupos de Apoio para adesão comunitária'
WHEN 23732  THEN   'Outro Modelo'

 	ELSE '' END AS modelodf,

				max(encounter_datetime) as data_modelo,
                                 o.obs_group_id
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id in (165174)
			 AND o.location_id=:location
			            group by patient_id, modelodf, o.obs_group_id
        ) mds

                left join

(
                SELECT 	e.patient_id ,
                         o.value_coded,
				CASE o.value_coded
                WHEN 1256 THEN 'CASO NOVO'
                WHEN 1257 THEN 'MANTER'
                WHEN 1267 THEN 'COMPLETO'
                ELSE o.value_coded end AS status,
                max(encounter_datetime) as data_status,
                 o.obs_group_id as obs_group_id

			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id in (165322)
			 AND o.location_id=:location
            group by patient_id , status, o.obs_group_id

                     ) st  on st.obs_group_id = mds.obs_group_id group by mds.patient_id, mds.modelodf, mds.data_modelo) modelos_estado

		) modelodf ON modelodf.patient_id=inicio_real.patient_id and data_modelo between  :startDate and :endDate and value_coded <> 1267

		       /**************************     ultima visita ****************************/
      	left  JOIN
		(
			SELECT lastvis.patient_id,lastvis.value_datetime,lastvis.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type
					FROM 	encounter e
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 and o.voided =0  AND e.encounter_type IN (6,9,18) AND  o.concept_id in (5096 ,1410)
						and	e.location_id=:location AND e.encounter_datetime <=:endDate  and o.value_datetime is  not null
					GROUP BY p.patient_id
				) lastvis
		) ultimavisita ON ultimavisita.patient_id=inicio_real.patient_id


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

		left join
			(
	select 	e.patient_id,
						case o.value_coded
						when 1703 then 'AZT+3TC+EFV'
						when 6100 then 'AZT+3TC+LPV/r'
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 6104 then 'ABC+3TC+EFV'
						when 23784 then 'TDF+3TC+DTG'
						when 23786 then 'ABC+3TC+DTG'
						when 6116 then 'AZT+3TC+ABC'
						when 6106 then 'ABC+3TC+LPV/r'
						when 6105 then 'ABC+3TC+NVP'
						when 6108 then 'TDF+3TC+LPV/r'
						when 23790 then 'TDF+3TC+LPV/r+RTV'
						when 23791 then 'TDF+3TC+ATV/r'
						when 23792 then 'ABC+3TC+ATV/r'
						when 23793 then 'AZT+3TC+ATV/r'
						when 23795 then 'ABC+3TC+ATV/r+RAL'
						when 23796 then 'TDF+3TC+ATV/r+RAL'
						when 23801 then 'AZT+3TC+RAL'
						when 23802 then 'AZT+3TC+DRV/r'
						when 23815 then 'AZT+3TC+DTG'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
						when 23797 then 'ABC+3TC+DRV/r+RAL'
						when 23798 then '3TC+RAL+DRV/r'
						when 23803 then 'AZT+3TC+RAL+DRV/r'
						when 6243 then 'TDF+3TC+NVP'
						when 6103 then 'D4T+3TC+LPV/r'
						when 792 then 'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 1311 then 'ABC+3TC+LPV/r'
						when 1312 then 'ABC+3TC+NVP'
						when 1313 then 'ABC+3TC+EFV'
						when 1314 then 'AZT+3TC+LPV/r'
						when 1315 then 'TDF+3TC+EFV'
						when 6330 then 'AZT+3TC+RAL+DRV/r'
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r'
						when 6326 then 'AZT+3TC+ABC+LPV/r'
						when 6327 then 'D4T+3TC+ABC+EFV'
						when 6328 then 'AZT+3TC+ABC+EFV'
						when 6109 then 'AZT+DDI+LPV/r'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
						when 21163 then 'AZT+3TC+LPV/r'
						when 23799 then 'TDF+3TC+DTG'
						when 23800 then 'ABC+3TC+DTG'
						else 'OUTRO' end as ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				from 	encounter e
                inner join
                         ( select e.patient_id,max(encounter_datetime) encounter_datetime
                         from encounter e
                         inner join obs o on e.encounter_id=o.encounter_id
                         where 	encounter_type in (6,9) and e.voided=0 and o.voided=0
                         group by e.patient_id
                         ) ultimolev
				on e.patient_id=ultimolev.patient_id
                inner join obs o on o.encounter_id=e.encounter_id
				where  ultimolev.encounter_datetime = e.encounter_datetime and
                        encounter_type in (6,9) and e.voided=0 and o.voided=0 and
						o.concept_id=1087 and e.location_id=:location
              group by patient_id

			) regime on regime.patient_id=inicio_real.patient_id

        /** ************************** LinhaTerapeutica concept_id = 21151  * ********************************************** **/
        LEFT JOIN
		(SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 21148  THEN 'SEGUNDA LINHA'
					WHEN 21149  THEN 'TERCEIRA LINHA'
					WHEN 21150  THEN 'PRIMEIRA LINHA'
				ELSE '' END AS linhat,
                max(encounter_datetime) as data_ult_linha
			FROM 	obs o
			INNER JOIN encounter e ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151
            group by patient_id
		) linha_terapeutica ON linha_terapeutica.patient_id=inicio_real.patient_id

	          /* ******************************** ultima levantamento *********** ******************************/
 		left JOIN
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
                where  o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime and
			  o.voided=0  AND e.voided =0 AND e.encounter_type =18  AND e.location_id=:location
		) fila ON fila.patient_id=inicio_real.patient_id


	/*  ** ******************************************  ultima seguimento  **** ************************************* */
		left JOIN
		(		Select ultimoSeguimento.patient_id,ultimoSeguimento.encounter_datetime,o.value_datetime
	from

		(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
			from 	encounter e
			inner join patient p on p.patient_id=e.patient_id
			where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=:location
			group by p.patient_id
		) ultimoSeguimento
		inner join encounter e on e.patient_id=ultimoSeguimento.patient_id
		inner join obs o on o.encounter_id=e.encounter_id
		where o.concept_id=1410 and o.voided=0 and e.voided=0 and e.encounter_datetime=ultimoSeguimento.encounter_datetime and
		e.encounter_type in (6,9)
		) visita ON visita.patient_id=inicio_real.patient_id

	/* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0
	) telef  ON telef.person_id = inicio_real.patient_id



) activos