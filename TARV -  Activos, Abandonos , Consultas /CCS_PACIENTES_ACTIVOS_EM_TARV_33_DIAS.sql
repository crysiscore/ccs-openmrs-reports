/*

Name CCS ACTUALMENTE EM TARV 33 DIAS
Description-
              - Pacientes actualmente em tarv, com data do proximo seguimento nao superior a data corremte em 28 dias

Created By: Colaco C.
Created Date: NA

Change by: Agnaldo  Samuel
Change Date: 06/06/2021
Change Reason: Bug fix
    -- Peso e altura incorrecta ( Anibal J.)
    -- Excluir ficha resumo e APPSS na determinacao da ultima visita
    -- Revelacao de diagnostico da ficha clinica ( Mauricio T.)

Change Date: 18/11/2021
Change by: Agnaldo  Samuel
Change Reason: Bug fix
-- Correcao do erro da maior data da proxima consulta entre a consulta clinica e o fila

Change Date: 13/05/2022
Change by: Agnaldo  Samuel
Change Reason: Change request
-- Adicao da variavel profilaxia ctz ( Mauricio T.)

Change Date: 13/05/2022
Change by: Agnaldo  Samuel
Change Reason: Change request
-- remover condicao endDate <= null nas CV (Marcia Jasse)

Change Date: 28/07/2022
Change by: Agnaldo  Samuel
Change Reason: Bug fix
-- data gravida busca data de rastreio (Marcia Jasse)

Change Date: 08/08/2022
Change Reason: Bug fix
              -  Correcao no criterio de exclusao ( Pacientes transferidos da FC e cartao de visita).
			  -  Revisao da sub-consulta que verifica a saida no programa TARV-Tratamento (Visao geral OpenMRS)

Change Date: 26/01/2021
Change Reason: Change request
              -  Correcao no criterio de exclusao ( Pacientes transferidos da FC e cartao de visita).
			  -  Revisao da sub-consulta que verifica a saida no programa TARV-Tratamento (Visao geral OpenMRS)
              -
Change Date: 26/02/2023
Change Reason: Change request
              -  Fonte de Regime T.  passa a ser FC
              - Remocao do campo no NID

Change Date: 12/05/2023
Change Reason: Change request
              -  Criterios do CDC
              -  Inclusao de pacientes transferidos com levantamento actualizado

Change Date: 12/12/2023
Change Reason: Change request
              -  Rastreio de ITS
*/


SELECT *
FROM
(SELECT
            inicio_real.patient_id,
			pid.identifier AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
			DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
            weight.peso AS peso,
            height.altura ,
            hemog.hemoglobina,
            if(cd4.value_numeric is not null , cd4.value_numeric , if(cd4_perc.value_numeric is not null, concat(cd4_perc.value_numeric, '%'), '' )
			 ) AS cd4,
			  if(cd4.encounter_datetime is not null , DATE_FORMAT(cd4.encounter_datetime,'%d/%m/%Y')  , if(cd4_perc.encounter_datetime is not null, DATE_FORMAT(cd4_perc.encounter_datetime,'%d/%m/%Y') , '' )
			 ) AS data_cd4,
             if( cv.valor_comment is not null, concat('Menor (<) que ',cv.valor_comment ), if(cv.carga_viral_qualitativa is not null,cv.carga_viral_qualitativa,cv.carga_viral_qualitativa)  ) as carga_viral_qualitativa,
            cv.valor_comment,
             profilaxia_ctz.estado AS profilaxia_ctz,
            DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v ,
            cv.valor_ultima_carga AS carga_viral_numeric,
            cv.origem_resultado AS origem_cv,
            keypop.populacaochave,
            linha_terapeutica.linhat AS linhaterapeutica,
            tipo_dispensa.tipodispensa,
			DATE_FORMAT(ult_mestr.value_datetime,'%d/%m/%Y')   data_ult_mestruacao,
			IF( ptv.date_enrolled IS NULL, 'Nao', 	DATE_FORMAT(ptv.date_enrolled,'%d/%m/%Y') ) AS inscrito_ptv_etv,
			DATE_FORMAT(ccu_rastreio.dataRegisto,'%d/%m/%Y') AS rastreio_ccu ,
			tb_lam.resul_tb_lam,
			DATE_FORMAT(tb_lam.data_result,'%d/%m/%Y') AS data_tb_lam,
            tb_crag.resul_tb_crag,
            DATE_FORMAT(tb_crag.data_result,'%d/%m/%Y')  AS data_tb_crag,
			escola.nivel_escolaridade,
			telef.value AS telefone,
            regime.ultimo_regime,
            its.its,
              DATE_FORMAT(its.encounter_datetime,'%d/%m/%Y')  AS data_rastreio_its,
			marcado_tb.tratamento_tb,
			DATE_FORMAT(  marcado_tb.data_marcado_tb , '%d/%m/%Y') AS data_marcado_tb,
            DATE_FORMAT(regime.data_regime,'%d/%m/%Y') AS data_regime,
            DATE_FORMAT(gravida_real.data_gravida,'%d/%m/%Y') AS data_gravida,
			DATE_FORMAT(lactante_real.date_enrolled,'%d/%m/%Y') AS data_lactante,
            DATE_FORMAT(ult_fila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
			DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
            -- DATE_FORMAT(3_ult_vis.encounter_datetime,'%d/%m/%Y') as data_visita_3,
            -- DATE_FORMAT(2_ult_vis.encounter_datetime,'%d/%m/%Y') as data_visita_2,
            DATE_FORMAT(ult_vis.encounter_datetime,'%d/%m/%Y') AS data_ult_visita,
            DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
            risco_adesao.factor_risco AS factor_risco_adesao,
			IF(programa.patient_id IS NULL,'NAO','SIM') inscrito_programa,
			IF(mastercard.patient_id IS NULL,'NAO','SIM') temmastercard,
			IF(mastercardFResumo.patient_id IS NULL,'NAO','SIM') temmastercardFR,
			IF(mastercardFClinica.patient_id IS NULL,'NAO','SIM') temmastercardFC,
			IF(mastercardFAPSS.patient_id IS NULL,'NAO','SIM') temmastercardFA,
            DATE_FORMAT(mastercardFAPSS.dataRegisto,'%d/%m/%Y') AS  data_ult_vis_apss,
            DATE_FORMAT(mastercardFAPSS.value_datetime,'%d/%m/%Y')  AS  data_prox_apss,
			DATE_FORMAT( ult_levant_master_card.data_ult_lev_master_card,'%d/%m/%Y')  AS data_ult_lev_master_card ,
            DATE_FORMAT(ult_ped_cv.data_pedido_cv,'%d/%m/%Y') AS data_pedido_cv,
            conset.consentimento,
            revelacao.estado AS estado_revelacao,
			IF(gaaac.member_id IS NULL,'NÃO','SIM') emgaac,
            pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'


	FROM (select patient_id, data_inicio
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
		INNER JOIN person p ON p.person_id=inicio_real.patient_id

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
                         WHERE 	encounter_type in (6,9) AND e.voided=0 AND o.voided=0 and o.concept_id=1087 and
                                o.value_coded is not null
                         GROUP BY e.patient_id
                         ) ult_seg
				ON e.patient_id=ult_seg.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE  ult_seg.encounter_datetime = e.encounter_datetime AND
                        encounter_type in (6,9) AND e.voided=0 AND o.voided=0 AND
						o.concept_id=1087 AND e.location_id=:location

			) regime ON regime.patient_id=inicio_real.patient_id


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

		LEFT JOIN
		(
			SELECT 	pg.patient_id
			FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
			WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
		) programa ON programa.patient_id=inicio_real.patient_id
		LEFT JOIN
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter
			WHERE 	encounter_type = 52 AND voided=0
			GROUP BY patient_id
		) mastercard ON mastercard.patient_id = inicio_real.patient_id
        /** **********************   CCU Rastreio  ********************************** **/
	     LEFT JOIN
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter
			WHERE 	encounter_type = 28 AND form_id = 122 AND voided = 0
			GROUP BY patient_id
		) ccu_rastreio ON ccu_rastreio.patient_id = inicio_real.patient_id

		LEFT JOIN
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter
			WHERE 	encounter_type = 53 AND form_id = 165 AND voided=0
			GROUP BY patient_id
		) mastercardFResumo ON mastercardFResumo.patient_id = inicio_real.patient_id

		LEFT JOIN
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter
			WHERE 	encounter_type IN (6,9) AND form_id = 163 AND voided=0
			GROUP BY patient_id
		) mastercardFClinica ON mastercardFClinica.patient_id = inicio_real.patient_id

		LEFT JOIN
		(
             SELECT e.patient_id, ult_apss.dataRegisto,o.value_datetime
			  FROM    encounter e  INNER JOIN
              (
				SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
						FROM 	encounter
						WHERE 	encounter_type IN (34,35) AND form_id = 164 AND voided=0
						GROUP BY patient_id
               ) ult_apss
			ON e.patient_id = ult_apss.patient_id
            INNER JOIN obs o ON o.encounter_id =e.encounter_id
            WHERE e.encounter_type IN (34,35)
             AND ult_apss.dataRegisto = e.encounter_datetime
             AND o.voided=0 AND o.concept_id = 6310
             GROUP BY patient_id
		) mastercardFAPSS ON mastercardFAPSS.patient_id = inicio_real.patient_id
     /************************* TB LAM  **********************************************/
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
        e.encounter_type IN (6 , 9, 13)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23951
            AND e.encounter_datetime <= :endDate
    GROUP BY patient_id) ult_linhat
    INNER JOIN encounter e ON e.patient_id = ult_linhat.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 53)
            AND ult_linhat.data_ult_linhat = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23951
    GROUP BY patient_id) tb_lam ON tb_lam.patient_id = inicio_real.patient_id
  /**  ****************	Ultimo Pedido de CV ba ficha clinica **************************** **/
       LEFT JOIN (
         select p.patient_id, max(e.encounter_datetime) data_pedido_cv
         from patient p
                  inner join encounter e on p.patient_id = e.patient_id
                  inner join obs pedido on pedido.encounter_id = e.encounter_id
         where p.voided = 0
           and e.voided = 0
           and pedido.voided = 0
           and pedido.concept_id = 23722
           and pedido.value_coded = 856
           and e.encounter_type in (6, 9)
           and e.location_id=:location
         group by p.patient_id) ult_ped_cv ON ult_ped_cv.patient_id =  inicio_real.patient_id
    /************************* Crag **********************************************/
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
        e.patient_id, MAX(encounter_datetime) AS data_crag
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 13)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
            AND e.encounter_datetime <=:endDate
    GROUP BY patient_id) ult_crag
    INNER JOIN encounter e ON e.patient_id = ult_crag.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 53)
            AND ult_crag.data_crag = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
    GROUP BY patient_id) tb_crag ON tb_crag.patient_id = inicio_real.patient_id
    /************************** keypop concept_id = 23703 ****************************/
               LEFT JOIN
		(SELECT ultimavisita_keypop.patient_id,ultimavisita_keypop.encounter_datetime data_keypop,
        CASE o.value_coded
					WHEN '1377'  THEN 'HSH'
					WHEN '20454' THEN 'PID'
					WHEN '20426' THEN 'REC'
					WHEN '1901'  THEN 'MTS'
					WHEN '23885' THEN 'Outro'
				ELSE '' END AS populacaochave
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime, e.encounter_type
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0  AND o.voided=0   AND o.concept_id=23703 AND e.encounter_type IN (6,9,34,35)  AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_keypop
			INNER JOIN encounter e ON e.patient_id=ultimavisita_keypop.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=23703 AND o.voided=0 AND e.encounter_datetime=ultimavisita_keypop.encounter_datetime AND
			e.encounter_type IN (6,9,34,35)  AND e.location_id=:location
			GROUP BY e.patient_id
		) keypop ON keypop.patient_id=inicio_real.patient_id

		LEFT JOIN
		(
			SELECT DISTINCT member_id FROM gaac_member WHERE voided=0
		) gaaac ON gaaac.member_id=inicio_real.patient_id

        /************  Peso  *********************/
        LEFT JOIN
		(SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_numeric peso
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0 AND o.voided=0   AND o.concept_id=5089 AND e.encounter_type IN (6,9) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=5089 AND o.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND
			e.encounter_type IN (6,9) AND e.location_id=:location
		) weight ON weight.patient_id=inicio_real.patient_id
               /************  Altura  *********************/
		 LEFT JOIN
		(SELECT ultimavisita_peso.patient_id,ultimavisita_peso.encounter_datetime,o.value_numeric AS altura
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0   AND o.concept_id=5090 AND e.encounter_type IN (6,9) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_peso
			INNER JOIN encounter e ON e.patient_id=ultimavisita_peso.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=5090 AND o.voided=0 AND e.encounter_datetime=ultimavisita_peso.encounter_datetime AND
			e.encounter_type IN (6,9) AND e.location_id=:location
		) height ON height.patient_id=inicio_real.patient_id

                       /************  Hemoglobina  *********************/
		LEFT JOIN
		(SELECT ultimavisita_hemoglobina.patient_id,ultimavisita_hemoglobina.encounter_datetime,o.value_numeric hemoglobina
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
	                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0   AND o.concept_id=1692 AND e.encounter_type IN (6,9) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_hemoglobina
			INNER JOIN encounter e ON e.patient_id=ultimavisita_hemoglobina.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=1692 AND o.voided=0 AND e.encounter_datetime=ultimavisita_hemoglobina.encounter_datetime AND
			e.encounter_type IN (6,9) AND e.location_id=:location
		) hemog ON hemog.patient_id=inicio_real.patient_id

   /*****************************   gravida nos ultimos 12 mesmes   *************************************************/
   LEFT JOIN
	(	SELECT patient_id, data_gravida
		FROM
			( SELECT p.patient_id,MAX(obs_datetime) data_gravida
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON e.encounter_id=o.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND concept_id = 1982 AND value_coded = 1065
					AND e.encounter_type =6 AND o.obs_datetime BETWEEN DATE_SUB(:endDate, INTERVAL 12 MONTH) AND  :endDate  AND
					e.location_id=:location
			GROUP BY p.patient_id
			) gravida
			/*** union

			select pp.patient_id,pp.date_enrolled as data_gravida
			from 	patient_program pp
			where 	pp.program_id in (3,4,8) and pp.voided=0 and  pp.date_completed is null and
					pp.date_enrolled between  date_sub(:endDate, interval 9 MONTH) and  :endDate  and pp.location_id=:location
			) gravida


		group by patient_id   ***/
	) gravida_real ON gravida_real.patient_id=inicio_real.patient_id

	  /************************* LACTANTES *********************************************/
     LEFT JOIN  (	SELECT patient_id,  date_enrolled
		FROM
			(SELECT p.patient_id,MAX(obs_datetime) date_enrolled
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON e.encounter_id=o.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND concept_id = 6332 AND value_coded = 1065
					AND e.encounter_type =6 AND o.obs_datetime BETWEEN DATE_SUB(:endDate, INTERVAL 18 MONTH) AND :endDate  AND
					e.location_id=:location
			GROUP BY p.patient_id

			) lactante

	) lactante_real ON lactante_real.patient_id=inicio_real.patient_id

			/** **************************************** Tipo dispensa  concept_id = 23739 **************************************** **/
    LEFT JOIN
		( SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 23888  THEN 'DISPENSA SEMESTRAL'
					WHEN 1098 THEN 'DISPENSA MENSAL'
					WHEN 23720 THEN 'DISPENSA TRIMESTRAL'
				ELSE '' END AS tipodispensa,
                e.encounter_datetime
                FROM encounter e INNER JOIN
                ( SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_tipo_dis
					FROM 	obs o
					INNER JOIN encounter e ON o.encounter_id=e.encounter_id
					WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23739 AND o.location_id=:location
					GROUP BY patient_id ) ult_dispensa
					ON e.patient_id =ult_dispensa.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53)
             AND ult_dispensa.data_ult_tipo_dis = e.encounter_datetime
             AND o.voided=0 AND o.concept_id = 23739
             GROUP BY patient_id
		) tipo_dispensa ON tipo_dispensa.patient_id=inicio_real.patient_id

        /** ************************** LinhaTerapeutica concept_id = 21151  * ********************************************** **/
        LEFT JOIN
		(
SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 21148  THEN 'SEGUNDA LINHA'
					WHEN 21149  THEN 'TERCEIRA LINHA'
					WHEN 21150  THEN 'PRIMEIRA LINHA'
				ELSE '' END AS linhat,
                encounter_datetime AS data_ult_linha
				FROM 	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ult_linhat
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151
							GROUP BY patient_id
				) ult_linhat
			INNER JOIN encounter e ON e.patient_id=ult_linhat.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53) AND ult_linhat.data_ult_linhat =e.encounter_datetime AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151
            GROUP BY patient_id
		) linha_terapeutica ON linha_terapeutica.patient_id=inicio_real.patient_id

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
	    /* ************ ******************************  Ultima mestruacao    ******************** ******************************/
		LEFT JOIN
		(SELECT ultimavisita_mentruacao.patient_id,ultimavisita_mentruacao.encounter_datetime,o.value_datetime
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=1465 AND e.encounter_type IN (6,9) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_mentruacao
			INNER JOIN encounter e ON e.patient_id=ultimavisita_mentruacao.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=1465 AND o.voided=0 AND e.encounter_datetime=ultimavisita_mentruacao.encounter_datetime AND
			e.encounter_type IN (6,9) AND e.location_id=:location
		) ult_mestr ON ult_mestr.patient_id=inicio_real.patient_id


          /***********************   Factores de risco de adesao *****************************************************/
          LEFT JOIN (SELECT
						e.patient_id,
						o.value_coded,
						CASE  o.value_coded
						WHEN 6436  THEN   'Estigma/Preocupado com a privacidade'
						WHEN 23769 THEN  'ASPECTOS CULTURAIS OU TRADICIONAIS (P)'
						WHEN 23768 THEN  'PERDEU / ESQUECEU / PARTILHOU COMPRIMIDOS (L)'
						WHEN 6303  THEN   'VIOLENCIA BASEADA NO GENERO'
						WHEN 23767 THEN 'SENTE-SE MELHOR (E)'
						WHEN 18698 THEN  'FALTA DE ALIMENTO'
						WHEN 207   THEN 'DEPRESSÃO'
						WHEN 820   THEN 'PROBLEMAS DE TRANSPORTE'
						WHEN 1936  THEN 'UTENTE SETENTE-SE DOENTE'
						WHEN 1956  THEN 'NÃO ACREDITO NO REULTADO'
						WHEN 2015  THEN 'EFEITOS SECUNDARIOS ARV'
						WHEN 2153  THEN  'FALTA DE APOIO'
						WHEN 2155  THEN 'NÃO REVELOU SEU DIAGNOSTICO'
						WHEN 6186  THEN 'NAO ACREDITA NO TRATAMENTO'
						WHEN 23766 THEN 'SÃO MUITOS COMPRIMIDOS (D)'
						WHEN 2017  THEN 'OUTRO MOTIVO DE FALTA'
						WHEN 1603  THEN  'ABUSO DE ALCOOL'
						END AS factor_risco,
                        ult_risco_adesao.data_ult_risco_adesao
						FROM encounter e INNER JOIN
										(   SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_risco_adesao
											FROM 	obs o
											INNER JOIN encounter e ON o.encounter_id=e.encounter_id
											WHERE 	e.encounter_type IN (6,9,18,35) AND e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=:location
											GROUP BY patient_id ) ult_risco_adesao
						ON ult_risco_adesao.patient_id=e.patient_id
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE e.encounter_datetime = ult_risco_adesao.data_ult_risco_adesao AND
						e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=:location
						AND e.encounter_type IN (6,9,18,35)
						GROUP BY patient_id ) risco_adesao ON risco_adesao.patient_id =  inicio_real.patient_id AND DATEDIFF(:endDate,risco_adesao.data_ult_risco_adesao)/30 <= 3

		 /*******************************   Patients enrolled in PTV/ETV Program: OpenMRS Program ************************************/
        LEFT JOIN (

						/*Patients enrolled in PTV/ETV Program: OpenMRS Program*/
						SELECT 	pg.patient_id,date_enrolled
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=8 AND  date_enrolled  BETWEEN DATE_SUB(:endDate , INTERVAL 9 MONTH ) AND :endDate
						GROUP BY pg.patient_id
        ) ptv ON ptv.patient_id= inicio_real.patient_id

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
              o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
							GROUP BY patient_id
				) ult_cv
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  inicio_real.patient_id

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

		) ult_fila ON ult_fila.patient_id = inicio_real.patient_id

  /*  ************************************   penultimo  levantamento ***** *******************************
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
    LIMIT 1,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id

		) 2_ult_fila ON 2_ult_fila.patient_id = inicio_real.patient_id

  /* ********* ********************************   3 ultimo  levantamento ******* *****************************
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
    LIMIT 2,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id

		) 3_ult_fila ON 3_ult_fila.patient_id = inicio_real.patient_id
****************************************************************************************************************** */
	/*  ** ******************************************  ultima visita  **** ************************************* */
		LEFT JOIN (


SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id
		) ult_vis ON ult_vis.patient_id = inicio_real.patient_id

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
            ) ult_seguimento ON ult_seguimento.patient_id = inicio_real.patient_id
	/*  * *******************************************  penultima visita  *** **************************************
		LEFT JOIN (


SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id
		) 2_ult_vis ON 2_ult_vis.patient_id = inicio_real.patient_id

	/*   ********************************************  3 ultima  visita  *** ***************************************
		LEFT JOIN (


SELECT visita2.patient_id ,
(	SELECT	 visita.encounter_datetime
					FROM
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 2,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e
							INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9)
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id
		) 3_ult_vis ON 3_ult_vis.patient_id = inicio_real.patient_id
       */
	/* * **************************** Escolaridade **** ********************************************** */
		LEFT JOIN
		(SELECT ultimavisita_escolaridade.patient_id,
		CASE o.value_coded
                WHEN 1445  THEN  'NENHUMA EDUCAÇÃO FORMAL'
                WHEN 1446 THEN  'PRIMARIO'
               WHEN 1447 THEN  'SECONDÁRIO, NIVEL BASICO'
              WHEN 1448 THEN  ' UNIVERSITARIO'
               WHEN 6124 THEN  'TÉCNICO BÁSICO'
                WHEN 1444 THEN  'TÉCNICO MÉDIO'
               ELSE 'OUTRO'
           END  AS nivel_escolaridade,
		   ultimavisita_escolaridade.encounter_datetime AS data_ult_esc
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=1443 AND e.encounter_type =53 AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_escolaridade
			INNER JOIN encounter e ON e.patient_id=ultimavisita_escolaridade.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=1443 AND o.voided=0 AND e.encounter_datetime=ultimavisita_escolaridade.encounter_datetime AND
			e.encounter_type =53 AND e.location_id=:location
		) escola ON escola.patient_id=inicio_real.patient_id
        /** **************************** ITS concept_id=174 ********************************************** */

left join (

SELECT 	e.patient_id,
				CASE o.value_coded
				  when	12611 then 'Transtorno inflamatório do escroto'
                  when  6747  then   'Granuloma inguinal'
                  when  223   then   'SIFILIS'
                  when  864   then   'ULCERAS GENETAIS'
                  when  902   then   'DOENCA INFLAMATORIA PELVICA'
                  when  5993  then   'LEUCORREIAS'
                  when  5993  then   'CORRIMENTO'
                  when  5995  then   'CORRIMENTO URETRAL'
                  when  5995  then   'Secreção uretra'
				ELSE '' END AS its,
                e.encounter_datetime
                FROM encounter e INNER JOIN
                ( SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_tipo_dis
					FROM 	obs o
					INNER JOIN encounter e ON o.encounter_id=e.encounter_id
					WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 174 AND o.location_id=:location
					GROUP BY patient_id ) ult_its
					ON e.patient_id =ult_its.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9)
             AND ult_its.data_ult_tipo_dis = e.encounter_datetime
             AND o.voided=0 AND o.concept_id = 174 AND o.location_id=:location
             GROUP BY patient_id
) its on its.patient_id = inicio_real.patient_id
                /** ************************** Profilaxia CTZ  6121 ********************************************** **/

        LEFT JOIN
		(
                SELECT e.patient_id,
                ficha_seguimento.data_ult_seguimento,
				CASE o.value_coded
				WHEN 1256 THEN 'NOVO'
				WHEN 1257 THEN 'CONTINUA'
				WHEN 1267 THEN 'TERMINA'
                WHEN 1065 THEN 'SIM'
                WHEN 1066 THEN 'NAO'
			    ELSE '' END AS estado
				FROM (
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ult_seguimento
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 6121 AND e.form_id=163
                            AND e.location_id=:location
							GROUP BY patient_id
				      )  ficha_seguimento

			INNER JOIN encounter e ON e.patient_id=ficha_seguimento.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND ficha_seguimento.data_ult_seguimento =e.encounter_datetime AND e.voided=0 AND o.voided=0 AND o.concept_id = 6121
                     AND e.location_id=:location
            GROUP BY patient_id
		) profilaxia_ctz ON profilaxia_ctz.patient_id=inicio_real.patient_id
/* ******************************* Revelacao do diagnostico **************************** */
	 LEFT JOIN
		(SELECT ultimavisita_revelacao.patient_id,ultimavisita_revelacao.encounter_datetime,
        CASE o.value_coded
        WHEN 6338 THEN 'REVELADO PARCIALMENTE'
        WHEN 6337 THEN 'REVELADO'
        WHEN 6339 THEN 'NÃO REVELADO' END AS estado
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime, e.encounter_type
				FROM 	encounter e
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=6340  AND e.encounter_type IN (34,35) AND e.location_id=:location
				GROUP BY e.patient_id
			) ultimavisita_revelacao
			INNER JOIN encounter e ON e.patient_id=ultimavisita_revelacao.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=6340 AND o.voided=0 AND e.encounter_datetime=ultimavisita_revelacao.encounter_datetime AND
			e.encounter_type IN (34,35) AND e.location_id=:location
		) revelacao ON revelacao.patient_id=inicio_real.patient_id


        /************************** TRATAMENTO DE TUBERCULOSE NA FICHA CLINICA  ****************************/
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
			e.encounter_type in (6,9) and o.value_coded in (1256,1257) and e.location_id=:location
		) marcado_tb on marcado_tb.patient_id =   inicio_real.patient_id


/* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0
	) telef  ON telef.person_id = inicio_real.patient_id

/* ********************************* Consentimento **********************************/

   LEFT JOIN (
		SELECT ultapss.patient_id,ultapss.encounter_datetime,CASE o.value_coded WHEN 1065 THEN 'Sim' WHEN 1066 THEN 'Nao' END AS consentimento
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN patient p ON p.patient_id=e.patient_id
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=35 AND e.location_id=:location
                        AND 	e.encounter_datetime<=:endDate
						GROUP BY p.patient_id ) ultapss
                      	INNER JOIN encounter e ON e.patient_id=ultapss.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE o.concept_id=6306 AND o.voided=0 AND e.encounter_datetime=ultapss.encounter_datetime AND
					e.encounter_type =35 AND e.location_id=:location
                    ) conset ON conset.patient_id = inicio_real.patient_id

) activos
GROUP BY patient_id
