/*
Name: CCS LISTA DE MONITORIA DE PACIENTES INSCRITOS NA DISPENSA ANUAL -DA


Description-
      - No âmbito do projecto de implementação da DA em Gaza, precisaremos de algumas listas para apoio as equipas
        para monitoria dos pacientes neste modelo de dispensa.
Created by:    Agnaldo  Samuel
Change Date: 06/01/2026

Revisao:   Agnaldo  Samuel
Change Date: 18/05/2026
- Revisao do TPT (inicio e fim)

Revisao:   Codex / Agnaldo Samuel
Change Date: 13/07/2026
- Incluido encounter 53 (Ficha Resumo) na leitura do inicio e fim de TPT
- Para encounter 53, a data clinica do TPT passa a usar obs_datetime do conceito 165308
- Os blocos de TPT passam a buscar historico ate :endDate, sem restringir por :startDate
- Mantida a selecao de um unico inicio mais antigo e um unico fim mais recente por paciente

Change Date: 07/06/2026
- Inclusao da Ficha Resumo na Busca do TPT

*/

SELECT *
FROM
( SELECT
            inscrito_da.patient_id,
			pid.identifier AS NID,
			p.gender  as sexo,
			ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
 			DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio_tarv,
            DATE_FORMAT(inscrito_da.data_inscricao_da,'%d/%m/%Y') AS data_inscricao_da,
             inscrito_da.estado AS estado_inscricao_da,
            tipo_dispensa_antes_da.tipodispensa as tipo_dispensa_antes_da,
             DATE_FORMAT(tipo_dispensa_antes_da.data_ult_tipo_dis,'%d/%m/%Y')  as data_tipo_dispensa_antes_da,
            tipo_dispensa_depois_da.tipodispensa as tipo_dispensa_depois_da,
            DATE_FORMAT(tipo_dispensa_depois_da.data_ult_tipo_dis,'%d/%m/%Y')  as data_tipo_dispensa_depois_da,
            DATE_FORMAT(ult_ped_cv_antes_da.data_pedido_cv,'%d/%m/%Y') AS data_pedido_antes_inscricao,
            DATE_FORMAT(ult_ped_cv.data_pedido_cv,'%d/%m/%Y') AS data_pedido_apos_inscricao,
             cv_antes_da.valor_ultima_carga   AS carga_viral_antes_da,
            DATE_FORMAT(cv_antes_da.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v_antes_da ,
             cv.valor_ultima_carga  as carga_viral_numeric_depois_da,
            DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v_depois_da ,
            DATE_FORMAT(in_3hp_tpi.data_inicio_tpt,'%d/%m/%Y') AS data_inicio_tpt,
 			DATE_FORMAT(end_tpt.data_end_tpt,'%d/%m/%Y') AS data_fim_tpt ,
 			if( marcado_tb.tratamento_tb IS NULL, NULL, CONCAT( marcado_tb.tratamento_tb, ' - ',   DATE_FORMAT(marcado_tb.data_marcado_tb,'%d/%m/%Y' ))) AS trat_tb,
            DATE_FORMAT(gravida_real.data_gravida,'%d/%m/%Y') AS data_gravida,
 			DATE_FORMAT(lactante_real.date_enrolled,'%d/%m/%Y') AS data_lactante,
 			DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
            DATE_FORMAT(ultimoFila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
 		    DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
            if( DATEDIFF(:endDate,ultimoFila.value_datetime)<=28, 'ACTIVO EM TARV',
                if(saida_real.patient_id IS NOT NULL, saida_real.estado, 'ABANDONO NAO NOTIFICADO')
                )  AS estado_paciente ,
             profissao.profissao,
            pad3.county_district AS 'Distrito',
 			pad3.address2 AS 'Padministrativo',
 			pad3.address6 AS 'Localidade',
 			pad3.address5 AS 'Bairro',
 			pad3.address1 AS 'PontoReferencia'

	FROM (

select * from

(
    /********************************************************   Inscrito  na Ficha FC  e APSS **************************************************************/
select   mdc_fc_estado.patient_id, mdc_fc_estado.data_modelo as data_inscricao_da,
             IF (mdc_fc_estado.status is not null,  mdc_fc_estado.status, IF(  (missing_estados.value_text = 'DA-Inicio' or missing_estados.comments = 'DA-Inicio') ,  'DA-Inicio', NULL ) )  as estado ,
             IF( mdc_fc_estado.data_status is not null, mdc_fc_estado.data_status, IF(missing_estados.data_modelo is not null ,missing_estados.data_modelo , NULL ) ) as data_estado,
              mdc_fc_estado.obs_group_id
from (
select mdc.patient_id ,
       --  mdc.modelodf,
       mdc.data_modelo as data_modelo,
       st.status,
       st.data_status,
      --  st.value_coded,
       -- mdc.form_name,
       mdc.obs_group_id

from (

                select  mdc_grouped_inicio.patient_id, min(data_modelo) as data_modelo, mdc_grouped_inicio.obs_group_id

                FROM (SELECT e.patient_id,
                          /* CASE o.value_coded
                         WHEN  165314 THEN  'DISPENSA ANUAL DE ARV'
                         WHEN  23729 THEN   'FLUXO RÁPIDO (FR)'
                         WHEN  23888 THEN  'DISPENSA SEMESTRAL'
                         WHEN  23730 THEN 'DISPENSA TRIMESTRAL (DT)'
 	                     ELSE  '' END AS modelodf,
                         f.name as form_name, */
                             min(encounter_datetime) as data_modelo,
                             o.obs_group_id
                      FROM obs o
                               INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                      WHERE e.encounter_type IN (6, 9, 34, 35)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id        =  165174
                        and o.value_coded       = 165314
                        AND o.location_id = :location
                        and e.encounter_datetime between :startDate and :endDate
                      group by patient_id

                      union all

                      SELECT e.patient_id,
                             min(encounter_datetime) as data_modelo,
                             o.obs_group_id
                      FROM obs o
                               INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                               INNER JOIN form f on f.form_id = e.form_id
                      WHERE e.encounter_type IN (6, 9, 34, 35)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id = 165174
                        and o.value_coded = 23732
                        and (o.value_text = 'DA-Inicio' or o.comments = 'DA-Inicio')
                        AND o.location_id = :location
                        and e.encounter_datetime between :startDate and :endDate
                      group by patient_id)  mdc_grouped_inicio group by mdc_grouped_inicio.patient_id
        )  mdc

                inner join

(
                SELECT 	e.patient_id ,
				CASE o.value_coded
                WHEN 1256 THEN 'CASO NOVO'
                WHEN 1257 THEN 'MANTER'
                WHEN 1267 THEN 'COMPLETO'
                ELSE o.value_coded end AS status,
                min(encounter_datetime) as data_status,
                 o.obs_group_id as obs_group_id

			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9,34,35) AND e.voided=0 AND o.voided=0 AND o.concept_id in (165322) and o.value_coded in (1256,1257)
			 AND o.location_id=:location
            group by patient_id , status, o.obs_group_id

     )   st  on st.obs_group_id = mdc.obs_group_id and st.patient_id=mdc.patient_id and st.data_status =mdc.data_modelo
    )  mdc_fc_estado

Left Join  (
                      SELECT e.patient_id,
                             o.value_text,
                             o.comments,
                             e.encounter_datetime as data_modelo,
                             o.obs_group_id
                      FROM obs o
                               INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                               INNER JOIN form f on f.form_id = e.form_id
                      WHERE e.encounter_type IN (6, 9, 34, 35)
                        AND e.voided = 0
                        AND o.voided = 0
                        AND o.concept_id = 165174
                        and o.value_coded = 23732
                        and (o.value_text = 'DA-Inicio' or o.comments = 'DA-Inicio')
                        AND o.location_id = :location
                        and e.encounter_datetime between :startDate and :endDate
                 ) missing_estados on  missing_estados.patient_id=mdc_fc_estado.patient_id and missing_estados.data_modelo=mdc_fc_estado.data_modelo

)   t  ) inscrito_da
		INNER JOIN person p ON p.person_id=inscrito_da.patient_id

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
			) pad3 ON pad3.person_id=inscrito_da.patient_id
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
			) pn ON pn.person_id=inscrito_da.patient_id
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
			) pid ON pid.patient_id=inscrito_da.patient_id


/* ************************************  ULTIMO FILA  ******************************************************/
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
		) ultimoFila ON ultimoFila.patient_id=inscrito_da.patient_id


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
    GROUP BY patient_id) tb_lam ON tb_lam.patient_id = inscrito_da.patient_id
   /**  ****************	PROFISSAO NA FICHA RESUMO**************************** **/
                    LEFT JOIN (
         select p.patient_id, max(e.encounter_datetime)  data_fr,
         o.value_text as profissao
         from patient p
                  inner join encounter e on p.patient_id = e.patient_id
                  inner join obs o on o.encounter_id = e.encounter_id
         where p.voided = 0
           and e.voided = 0
           and o.voided = 0
           and o.concept_id = 1459
           and e.encounter_type in (53)
           and e.location_id=:location
         group by p.patient_id) profissao ON profissao.patient_id =  inscrito_da.patient_id

  /**  ****************	Ultimo Pedido de CV antes e apos inscricao **************************** **/
       LEFT JOIN (
SELECT
    i.patient_id,
    pcv.data_pedido_cv
FROM
(
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id

        UNION ALL

        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* Último pedido de CV APÓS inscrição; desempata pela maior data e encounter_id. */
    SELECT
        i2.patient_id,
        e2.encounter_datetime AS data_pedido_cv
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id

            UNION ALL

            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e2
        ON e2.patient_id = i2.patient_id
       AND e2.voided = 0
       AND e2.location_id = :location
       AND e2.encounter_type IN (6, 9)
       AND e2.encounter_datetime > i2.data_modelo
    INNER JOIN obs pedido
        ON pedido.encounter_id = e2.encounter_id
       AND pedido.voided = 0
       AND pedido.concept_id = 23722
       AND pedido.value_coded = 856
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs pedido3
            ON pedido3.encounter_id = e3.encounter_id
           AND pedido3.voided = 0
           AND pedido3.concept_id = 23722
           AND pedido3.value_coded = 856
        WHERE e3.patient_id = e2.patient_id
          AND e3.voided = 0
          AND e3.location_id = e2.location_id
          AND e3.encounter_type IN (6, 9)
          AND e3.encounter_datetime > i2.data_modelo
          AND (
                e3.encounter_datetime > e2.encounter_datetime
                OR (
                    e3.encounter_datetime = e2.encounter_datetime
                    AND e3.encounter_id > e2.encounter_id
                )
              )
    )
) pcv
ON pcv.patient_id = i.patient_id
           ) ult_ped_cv ON ult_ped_cv.patient_id =  inscrito_da.patient_id
       LEFT JOIN (
SELECT
    i.patient_id,
    pcv.data_pedido_cv
FROM
(
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id

        UNION ALL

        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* Último pedido de CV ANTES da inscrição; desempata pela maior data e encounter_id. */
    SELECT
        i2.patient_id,
        e2.encounter_datetime AS data_pedido_cv
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id

            UNION ALL

            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e2
        ON e2.patient_id = i2.patient_id
       AND e2.voided = 0
       AND e2.location_id = :location
       AND e2.encounter_type IN (6, 9)
       AND e2.encounter_datetime < i2.data_modelo
    INNER JOIN obs pedido
        ON pedido.encounter_id = e2.encounter_id
       AND pedido.voided = 0
       AND pedido.concept_id = 23722
       AND pedido.value_coded = 856
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs pedido3
            ON pedido3.encounter_id = e3.encounter_id
           AND pedido3.voided = 0
           AND pedido3.concept_id = 23722
           AND pedido3.value_coded = 856
        WHERE e3.patient_id = e2.patient_id
          AND e3.voided = 0
          AND e3.location_id = e2.location_id
          AND e3.encounter_type IN (6, 9)
          AND e3.encounter_datetime < i2.data_modelo
          AND (
                e3.encounter_datetime > e2.encounter_datetime
                OR (
                    e3.encounter_datetime = e2.encounter_datetime
                    AND e3.encounter_id > e2.encounter_id
                )
              )
    )
) pcv
ON pcv.patient_id = i.patient_id
           ) ult_ped_cv_antes_da ON ult_ped_cv_antes_da.patient_id =  inscrito_da.patient_id
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
    GROUP BY patient_id) tb_crag ON tb_crag.patient_id = inscrito_da.patient_id
   /*****************************   gravida nos ultimos 12 meses   *************************************************/
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
	) gravida_real ON gravida_real.patient_id=inscrito_da.patient_id

  /*******************************              LACTANTES              *********************************************/
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

	) lactante_real ON lactante_real.patient_id=inscrito_da.patient_id

 		/************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		LEFT JOIN
		(

select modelos_estado.patient_id, modelos_estado.modelodf, modelos_estado.data_modelo, modelos_estado.status, modelos_estado.data_status,
         modelos_estado.value_coded
from (
select mdc.patient_id ,
       mdc.modelodf,
       mdc.data_modelo as data_modelo,
       st.status,
       st.data_status,
       st.value_coded,
       mdc.obs_group_id
from (
                SELECT 	e.patient_id ,
				CASE o.value_coded
 WHEN  165314 THEN 'DISPENSA ANUAL DE ARV'
 WHEN  165179 THEN 'DISPENSA COMUNITARIA;RIA VIA APE'
 WHEN  165265 THEN 'CLINICAS MVEIS (DCCM)'
 WHEN  165264 THEN 'BRIGADAS MVEIS (DCBM)'
 WHEN  23729 THEN 'FLUXO RÁPIDO (FR)'
 WHEN  165321 THEN 'DOENCA AVANCADA POR HIV'
 WHEN  23731 THEN 'DISPENSA COMUNITÁRIA (DC)'
 WHEN  23888 THEN 'DISPENSA SEMESTRAL'
 WHEN  23726 THEN 'CLUBES DE ADESÃO (CA)'
 WHEN  165340 THEN 'DISPENSA BIMESTRAL'
 WHEN  23732 THEN 'OUTRO MODELO'
 WHEN  165178 THEN 'DISPENSA COMUNITÁRIA VIA PROVEDOR'
 WHEN  165319 THEN 'PARAGEM UNICA NO SAAJ'
 WHEN  165318 THEN 'PARAGEM UNICA NOS SERVICOS DE TARV'
 WHEN  23730 THEN 'DISPENSA TRIMESTRAL (DT)'
 WHEN  165315 THEN 'DISPENSA DESCENTRALIZADA DE ARV'
 WHEN  165316 THEN 'EXTENSAO DE HORARIO'
 WHEN  23725 THEN 'ABORDAGEM FAMILIAR (AF)'
 WHEN  165177 THEN 'FARMAC/FARMÁCIA PRIVADA'
 WHEN  165317 THEN 'PARAGEM UNICA NO SECTOR DA TB'
 WHEN  23727 THEN 'PARAGEM ÚNICA (PU)'
 WHEN  23724 THEN 'Gaac (GA)'
 WHEN  165320 THEN 'PARAGEM UNICA NA SMI'

 	ELSE '' END AS modelodf,

				max(encounter_datetime) as data_modelo,
                                 o.obs_group_id
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id in (165174)
			 AND o.location_id=:location   and o.value_coded in (165179,165177,165178,23731,165264,165179,165315)
			            group by patient_id, modelodf, o.obs_group_id
        ) mdc

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

                     ) st  on st.obs_group_id = mdc.obs_group_id group by mdc.patient_id, mdc.modelodf, mdc.data_modelo) modelos_estado

		) modelodf ON modelodf.patient_id=inscrito_da.patient_id

	/** **************************************** Tipo dispensa antes da inscricao na DA concept_id = 23739 **************************************** **/
    LEFT JOIN
		(
		    SELECT
    i.patient_id,
    i.data_modelo,
    td.data_ult_tipo_dis,
    td.tipodispensa
FROM
(
    /* INICIO_DA: primeira data de inscrição no modelo (data_modelo) no período */
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id

        UNION ALL

        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* TIPO DISPENSA: último tipo de dispensa ANTES do data_modelo, com desempate por encounter_id. */
    SELECT
        i2.patient_id,
        e2.encounter_datetime AS data_ult_tipo_dis,
        CASE o.value_coded
            WHEN 23888  THEN 'DISPENSA SEMESTRAL'
            WHEN 1098   THEN 'DISPENSA MENSAL'
            WHEN 23720  THEN 'DISPENSA TRIMESTRAL'
            WHEN 165314 THEN 'DISPENSA ANUAL'
            WHEN 165340 THEN 'DISPENSA BIMESTRAL'
            ELSE ''
        END AS tipodispensa
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id

            UNION ALL

            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e2
        ON e2.patient_id = i2.patient_id
       AND e2.voided = 0
       AND e2.encounter_type IN (6, 9)
       AND e2.encounter_datetime < i2.data_modelo
    INNER JOIN obs o
        ON o.encounter_id = e2.encounter_id
       AND o.voided = 0
       AND o.concept_id = 23739
       AND o.location_id = :location
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs o3
            ON o3.encounter_id = e3.encounter_id
           AND o3.voided = 0
           AND o3.concept_id = 23739
           AND o3.location_id = :location
        WHERE e3.patient_id = e2.patient_id
          AND e3.voided = 0
          AND e3.encounter_type IN (6, 9)
          AND e3.encounter_datetime < i2.data_modelo
          AND (
                e3.encounter_datetime > e2.encounter_datetime
                OR (
                    e3.encounter_datetime = e2.encounter_datetime
                    AND e3.encounter_id > e2.encounter_id
                )
              )
    )
) td
ON td.patient_id = i.patient_id
		) tipo_dispensa_antes_da ON tipo_dispensa_antes_da.patient_id=inscrito_da.patient_id
/** **************************************** Tipo dispensa depois da inscricao na DA concept_id = 23739 **************************************** **/
    LEFT JOIN
		( 		    SELECT
    i.patient_id,
    i.data_modelo,
    td.data_ult_tipo_dis,
    td.tipodispensa
FROM
(
    /* INICIO_DA: primeira data de inscrição no modelo (data_modelo) no período */
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id

        UNION ALL

        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* TIPO DISPENSA: último tipo de dispensa APOS o data_modelo, com desempate por encounter_id. */
    SELECT
        i2.patient_id,
        e2.encounter_datetime AS data_ult_tipo_dis,
        CASE o.value_coded
            WHEN 23888  THEN 'DISPENSA SEMESTRAL'
            WHEN 1098   THEN 'DISPENSA MENSAL'
            WHEN 23720  THEN 'DISPENSA TRIMESTRAL'
            WHEN 165314 THEN 'DISPENSA ANUAL'
            WHEN 165340 THEN 'DISPENSA BIMESTRAL'
            ELSE ''
        END AS tipodispensa
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id

            UNION ALL

            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e2
        ON e2.patient_id = i2.patient_id
       AND e2.voided = 0
       AND e2.encounter_type IN (6, 9)
       AND e2.encounter_datetime >= i2.data_modelo
    INNER JOIN obs o
        ON o.encounter_id = e2.encounter_id
       AND o.voided = 0
       AND o.concept_id = 23739
       AND o.location_id = :location
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs o3
            ON o3.encounter_id = e3.encounter_id
           AND o3.voided = 0
           AND o3.concept_id = 23739
           AND o3.location_id = :location
        WHERE e3.patient_id = e2.patient_id
          AND e3.voided = 0
          AND e3.encounter_type IN (6, 9)
          AND e3.encounter_datetime >= i2.data_modelo
          AND (
                e3.encounter_datetime > e2.encounter_datetime
                OR (
                    e3.encounter_datetime = e2.encounter_datetime
                    AND e3.encounter_id > e2.encounter_id
                )
              )
    )
) td
ON td.patient_id = i.patient_id
		) tipo_dispensa_depois_da ON tipo_dispensa_depois_da.patient_id=inscrito_da.patient_id

          /**********************  Inicio de TPT  ********************************************************************/
		    LEFT JOIN
              (
                  /* Historico de inicio de TPT ate :endDate.
                     Inclui encounter 53 (Ficha Resumo); neste caso usa obs_datetime
                     do 165308 como data clinica do evento, porque encounter_datetime
                     representa apenas a data de registo/resumo. */
                  SELECT
                      e.patient_id,
                      CASE
                          WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                          ELSE e.encounter_datetime
                      END AS data_inicio_tpt
                  FROM patient p
                  INNER JOIN encounter e
                      ON e.patient_id = p.patient_id
                  INNER JOIN obs regime
                      ON regime.encounter_id = e.encounter_id
                     AND regime.voided = 0
                     AND regime.concept_id = 23985
                     AND regime.value_coded IN (656, 23982, 165306, 23983, 23954, 23984, 165305)
                  INNER JOIN obs estado_tpt
                      ON estado_tpt.encounter_id = e.encounter_id
                     AND estado_tpt.voided = 0
                     AND estado_tpt.value_coded = 1256
                     AND (
                            (e.encounter_type IN (6, 9 ,53) AND estado_tpt.concept_id = 165308)
                            OR (e.encounter_type = 60 AND estado_tpt.concept_id = 23987)
                         )
                  WHERE p.voided = 0
                    AND e.voided = 0
                    AND e.encounter_type IN (6, 9, 53, 60)
                    AND e.location_id = :location
                    /* Nao limita por :startDate para permitir mostrar TPT historico
                       de pacientes inscritos na DA dentro do periodo do relatorio. */
                    AND (
                          CASE
                              WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                              ELSE e.encounter_datetime
                          END
                        ) < DATE_ADD(:endDate, INTERVAL 1 DAY)
                    AND NOT EXISTS (
                        /* Mantem apenas o primeiro inicio historico do paciente
                           considerando a data clinica do TPT. */
                        SELECT 1
                        FROM encounter e2
                        INNER JOIN obs regime2
                            ON regime2.encounter_id = e2.encounter_id
                           AND regime2.voided = 0
                           AND regime2.concept_id = 23985
                           AND regime2.value_coded IN (656, 23982, 165306, 23983, 23954, 23984, 165305)
                        INNER JOIN obs estado_tpt2
                            ON estado_tpt2.encounter_id = e2.encounter_id
                           AND estado_tpt2.voided = 0
                           AND estado_tpt2.value_coded = 1256
                           AND (
                                  (e2.encounter_type IN (6, 9 ,53) AND estado_tpt2.concept_id = 165308)
                                  OR (e2.encounter_type = 60 AND estado_tpt2.concept_id = 23987)
                               )
                        WHERE e2.voided = 0
                          AND e2.patient_id = e.patient_id
                          AND e2.encounter_type IN (6, 9, 53, 60)
                          AND e2.location_id = e.location_id
                          AND (
                                CASE
                                    WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                                    ELSE e2.encounter_datetime
                                END
                              ) < DATE_ADD(:endDate, INTERVAL 1 DAY)
                          AND (
                                (
                                    CASE
                                        WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                                        ELSE e2.encounter_datetime
                                    END
                                ) < (
                                    CASE
                                        WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                                        ELSE e.encounter_datetime
                                    END
                                )
                                OR (
                                    (
                                        CASE
                                            WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                                            ELSE e2.encounter_datetime
                                        END
                                    ) = (
                                        CASE
                                            WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                                            ELSE e.encounter_datetime
                                        END
                                    )
                                    AND e2.encounter_id < e.encounter_id
                                )
                              )
                    )
                    AND NOT EXISTS (
                        SELECT 1
                        FROM obs regime_duplicado
                        WHERE regime_duplicado.encounter_id = regime.encounter_id
                          AND regime_duplicado.voided = 0
                          AND regime_duplicado.concept_id = 23985
                          AND regime_duplicado.value_coded IN (656, 23982, 165306, 23983, 23954, 23984, 165305)
                          AND regime_duplicado.obs_id < regime.obs_id
                    )
                    AND NOT EXISTS (
                        SELECT 1
                        FROM obs estado_tpt_duplicado
                        WHERE estado_tpt_duplicado.encounter_id = estado_tpt.encounter_id
                          AND estado_tpt_duplicado.voided = 0
                          AND estado_tpt_duplicado.value_coded = 1256
                          AND estado_tpt_duplicado.concept_id = estado_tpt.concept_id
                          AND estado_tpt_duplicado.obs_id < estado_tpt.obs_id
                    )
              )  in_3hp_tpi  ON in_3hp_tpi.patient_id=inscrito_da.patient_id

          /* ******************************** ultima carga viral  apos inscricao na DA*********** ******************************/
        LEFT JOIN(
       SELECT
    i.patient_id,
    i.data_modelo,
    cv.data_ultima_carga,
    cv.valor_ultima_carga,
    cv.origem_resultado
FROM
(
    /* INICIO_DA: primeira data de inscrição na Dispensa Anual (DA) no período */
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        INNER JOIN form f ON f.form_id = e.form_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
        UNION ALL
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        INNER JOIN form f ON f.form_id = e.form_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* CV: última carga viral DEPOIS do início DA, com desempate por encounter_id e obs_id. */
    SELECT
        i2.patient_id,
        e.encounter_datetime AS data_ultima_carga,
        IF(o.value_numeric IS NOT NULL, o.value_numeric,
           CASE
             WHEN o.value_coded IS NULL THEN ''
             WHEN o.value_coded = 1306  THEN 'Nivel baixo de detencao'
             WHEN o.value_coded = 23905 THEN 'Menor que 10 copias/ml'
             WHEN o.value_coded = 23906 THEN 'Menor que 20 copias/ml'
             WHEN o.value_coded = 23907 THEN 'Menor que 40 copias/ml'
             WHEN o.value_coded = 23908 THEN 'Menor que 400 copias/ml'
             WHEN o.value_coded = 23904 THEN 'Menor que 839 copias/ml'
             WHEN o.value_coded = 165331 THEN CONCAT('MENOR QUE ', COALESCE(o.comments,''), ' Copias/ml')
             WHEN o.value_coded = 23814 THEN 'CARGA VIRAL INDETECTAVEL'
             ELSE CONCAT('OUTRO - ', COALESCE(o.value_coded,''))
           END
        ) AS valor_ultima_carga,
        fr.name AS origem_resultado
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            INNER JOIN form f ON f.form_id = e.form_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
            UNION ALL
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            INNER JOIN form f ON f.form_id = e.form_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e
        ON e.patient_id = i2.patient_id
       AND e.voided = 0
       AND e.location_id = :location
       AND e.encounter_type IN (6, 9, 13, 51, 53)
       AND e.encounter_datetime > i2.data_modelo
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id IN (856, 1305)
    LEFT JOIN form fr
        ON fr.form_id = e.form_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs o3
            ON o3.encounter_id = e3.encounter_id
           AND o3.voided = 0
           AND o3.concept_id IN (856, 1305)
        WHERE e3.patient_id = e.patient_id
          AND e3.voided = 0
          AND e3.location_id = e.location_id
          AND e3.encounter_type IN (6, 9, 13, 51, 53)
          AND e3.encounter_datetime > i2.data_modelo
          AND (
                e3.encounter_datetime > e.encounter_datetime
                OR (
                    e3.encounter_datetime = e.encounter_datetime
                    AND e3.encounter_id > e.encounter_id
                )
              )
    )
      AND NOT EXISTS (
        SELECT 1
        FROM obs o_dup
        WHERE o_dup.encounter_id = o.encounter_id
          AND o_dup.voided = 0
          AND o_dup.concept_id IN (856, 1305)
          AND o_dup.obs_id < o.obs_id
    )
) cv
ON cv.patient_id = i.patient_id

		) cv ON cv.patient_id =  inscrito_da.patient_id

          /* ******************************** ultima carga viral  antes da inscricao*********** ******************************/
        LEFT JOIN(
SELECT
    i.patient_id,
    i.data_modelo,
    cv.data_ultima_carga,
    cv.valor_ultima_carga,
    cv.origem_resultado
FROM
(
    /* INICIO_DA: primeira data de inscrição na Dispensa Anual (DA) no período */
    SELECT
        mdc_grouped_inicio.patient_id,
        MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
    FROM
    (
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        INNER JOIN form f ON f.form_id = e.form_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 165314
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
        UNION ALL
        SELECT
            e.patient_id,
            MIN(e.encounter_datetime) AS data_modelo
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id
        INNER JOIN form f ON f.form_id = e.form_id
        WHERE e.encounter_type IN (6, 9, 34, 35)
          AND e.voided = 0
          AND o.voided = 0
          AND o.concept_id = 165174
          AND o.value_coded = 23732
          AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
          AND o.location_id = :location
          AND e.encounter_datetime BETWEEN :startDate AND :endDate
        GROUP BY e.patient_id
    ) mdc_grouped_inicio
    GROUP BY mdc_grouped_inicio.patient_id
) i
LEFT JOIN
(
    /* CV: última carga viral ANTES do início DA, com desempate por encounter_id e obs_id. */
    SELECT
        i2.patient_id,
        e.encounter_datetime AS data_ultima_carga,
        IF(o.value_numeric IS NOT NULL, o.value_numeric,
           CASE
             WHEN o.value_coded IS NULL THEN ''
             WHEN o.value_coded = 1306  THEN 'Nivel baixo de detencao'
             WHEN o.value_coded = 23905 THEN 'Menor que 10 copias/ml'
             WHEN o.value_coded = 23906 THEN 'Menor que 20 copias/ml'
             WHEN o.value_coded = 23907 THEN 'Menor que 40 copias/ml'
             WHEN o.value_coded = 23908 THEN 'Menor que 400 copias/ml'
             WHEN o.value_coded = 23904 THEN 'Menor que 839 copias/ml'
             WHEN o.value_coded = 165331 THEN CONCAT('MENOR QUE ', COALESCE(o.comments,''), ' Copias/ml')
             WHEN o.value_coded = 23814 THEN 'CARGA VIRAL INDETECTAVEL'
             ELSE CONCAT('OUTRO - ', COALESCE(o.value_coded,''))
           END
        ) AS valor_ultima_carga,
        fr.name AS origem_resultado
    FROM
    (
        SELECT
            mdc_grouped_inicio.patient_id,
            MIN(mdc_grouped_inicio.data_modelo) AS data_modelo
        FROM
        (
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            INNER JOIN form f ON f.form_id = e.form_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 165314
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
            UNION ALL
            SELECT
                e.patient_id,
                MIN(e.encounter_datetime) AS data_modelo
            FROM obs o
            INNER JOIN encounter e ON e.encounter_id = o.encounter_id
            INNER JOIN form f ON f.form_id = e.form_id
            WHERE e.encounter_type IN (6, 9, 34, 35)
              AND e.voided = 0
              AND o.voided = 0
              AND o.concept_id = 165174
              AND o.value_coded = 23732
              AND (o.value_text = 'DA-Inicio' OR o.comments = 'DA-Inicio')
              AND o.location_id = :location
              AND e.encounter_datetime BETWEEN :startDate AND :endDate
            GROUP BY e.patient_id
        ) mdc_grouped_inicio
        GROUP BY mdc_grouped_inicio.patient_id
    ) i2
    INNER JOIN encounter e
        ON e.patient_id = i2.patient_id
       AND e.voided = 0
       AND e.location_id = :location
       AND e.encounter_type IN (6, 9, 13, 51, 53)
       AND e.encounter_datetime < i2.data_modelo
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id IN (856, 1305)
    LEFT JOIN form fr
        ON fr.form_id = e.form_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM encounter e3
        INNER JOIN obs o3
            ON o3.encounter_id = e3.encounter_id
           AND o3.voided = 0
           AND o3.concept_id IN (856, 1305)
        WHERE e3.patient_id = e.patient_id
          AND e3.voided = 0
          AND e3.location_id = e.location_id
          AND e3.encounter_type IN (6, 9, 13, 51, 53)
          AND e3.encounter_datetime < i2.data_modelo
          AND (
                e3.encounter_datetime > e.encounter_datetime
                OR (
                    e3.encounter_datetime = e.encounter_datetime
                    AND e3.encounter_id > e.encounter_id
                )
              )
    )
      AND NOT EXISTS (
        SELECT 1
        FROM obs o_dup
        WHERE o_dup.encounter_id = o.encounter_id
          AND o_dup.voided = 0
          AND o_dup.concept_id IN (856, 1305)
          AND o_dup.obs_id < o.obs_id
    )
) cv
ON cv.patient_id = i.patient_id

		) cv_antes_da ON cv_antes_da.patient_id =  inscrito_da.patient_id
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
		) ult_vis ON ult_vis.patient_id = inscrito_da.patient_id

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
            ) ult_seguimento ON ult_seguimento.patient_id = inscrito_da.patient_id

	/* * **************************** -- Completaram TPT no FILT ou FC  **** ********************************************** */
LEFT JOIN
	(
        /* Historico de fim de TPT ate :endDate.
           Inclui encounter 53 (Ficha Resumo); para 53 usa obs_datetime do 165308
           como data clinica do evento. */
        SELECT
            e.patient_id,
            CASE
                WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                ELSE e.encounter_datetime
            END AS data_end_tpt
        FROM patient p
        INNER JOIN encounter e
            ON e.patient_id = p.patient_id
        INNER JOIN obs estado_tpt
            ON estado_tpt.encounter_id = e.encounter_id
           AND estado_tpt.voided = 0
           AND estado_tpt.value_coded = 1267
           AND (
                (e.encounter_type IN (6, 9, 53) AND estado_tpt.concept_id = 165308)
                OR (e.encounter_type = 60 AND estado_tpt.concept_id = 23987)
           )
        WHERE p.voided = 0
          AND e.voided = 0
          AND e.location_id = :location
          AND e.encounter_type IN (6, 9, 53, 60)
          /* Nao limita por :startDate para permitir mostrar fim TPT historico
             de pacientes inscritos na DA dentro do periodo do relatorio. */
          AND (
                CASE
                    WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                    ELSE e.encounter_datetime
                END
              ) < DATE_ADD(:endDate, INTERVAL 1 DAY)
          AND EXISTS (
                SELECT 1
                FROM encounter e_inicio
                INNER JOIN obs regime_inicio
                    ON regime_inicio.encounter_id = e_inicio.encounter_id
                   AND regime_inicio.voided = 0
                   AND regime_inicio.concept_id = 23985
                   AND regime_inicio.value_coded IN (656, 23982, 165306, 23983, 23954, 23984, 165305)
                INNER JOIN obs estado_inicio
                    ON estado_inicio.encounter_id = e_inicio.encounter_id
                   AND estado_inicio.voided = 0
                   AND estado_inicio.value_coded = 1256
                   AND (
                        (e_inicio.encounter_type IN (6, 9, 53) AND estado_inicio.concept_id = 165308)
                        OR (e_inicio.encounter_type = 60 AND estado_inicio.concept_id = 23987)
                   )
                WHERE e_inicio.voided = 0
                  AND e_inicio.patient_id = e.patient_id
                  AND e_inicio.location_id = e.location_id
                  AND e_inicio.encounter_type IN (6, 9, 53, 60)
                  AND (
                        CASE
                            WHEN e_inicio.encounter_type = 53 AND estado_inicio.concept_id = 165308 THEN estado_inicio.obs_datetime
                            ELSE e_inicio.encounter_datetime
                        END
                      ) <= (
                        CASE
                            WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                            ELSE e.encounter_datetime
                        END
                      )
          )
          AND NOT EXISTS (
                /* Mantem apenas o ultimo fim historico do paciente
                   considerando a data clinica do TPT. */
                SELECT 1
                FROM encounter e2
                INNER JOIN obs estado_tpt2
                    ON estado_tpt2.encounter_id = e2.encounter_id
                   AND estado_tpt2.voided = 0
                   AND estado_tpt2.value_coded = 1267
                   AND (
                        (e2.encounter_type IN (6, 9, 53) AND estado_tpt2.concept_id = 165308)
                        OR (e2.encounter_type = 60 AND estado_tpt2.concept_id = 23987)
                   )
                WHERE e2.voided = 0
                  AND e2.patient_id = e.patient_id
                  AND e2.location_id = e.location_id
                  AND e2.encounter_type IN (6, 9, 53, 60)
                  AND (
                        CASE
                            WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                            ELSE e2.encounter_datetime
                        END
                      ) < DATE_ADD(:endDate, INTERVAL 1 DAY)
                  AND (
                        (
                            CASE
                                WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                                ELSE e2.encounter_datetime
                            END
                        ) > (
                            CASE
                                WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                                ELSE e.encounter_datetime
                            END
                        )
                        OR (
                            (
                                CASE
                                    WHEN e2.encounter_type = 53 AND estado_tpt2.concept_id = 165308 THEN estado_tpt2.obs_datetime
                                    ELSE e2.encounter_datetime
                                END
                            ) = (
                                CASE
                                    WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                                    ELSE e.encounter_datetime
                                END
                            )
                            AND e2.encounter_id > e.encounter_id
                        )
                  )
          )
          AND NOT EXISTS (
                SELECT 1
                FROM obs estado_tpt_dup
                WHERE estado_tpt_dup.encounter_id = estado_tpt.encounter_id
                  AND estado_tpt_dup.voided = 0
                  AND estado_tpt_dup.value_coded = 1267
                  AND estado_tpt_dup.concept_id = estado_tpt.concept_id
                  AND estado_tpt_dup.obs_id < estado_tpt.obs_id
          )
	) end_tpt ON end_tpt.patient_id=inscrito_da.patient_id



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
		) marcado_tb on marcado_tb.patient_id =   inscrito_da.patient_id


/* ***************************************       Telefone    ******************************************************************* */
	LEFT JOIN (
		SELECT  p.person_id, p.value
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0
	) telef  ON telef.person_id = inscrito_da.patient_id


	/* ******************************* Saida Do Tratamento Tarv **************************** */
        LEFT JOIN
      (	select 	pg.patient_id,ps.start_date encounter_datetime,
					case ps.state
					when 7 then 'TRANSFERIDO PARA'
					when 8 then 'SUSPENDEU TRATAMENTO'
					when 9 then 'ABANDONO'
					when 10 then 'OBITO'
					else 'OUTRO' end as estado
			from 	patient p
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and ps.start_date between :startDate and :endDate and
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and location_id=:location
                  union all
                   Select ultimavisita_perm_tarv.patient_id, ultimavisita_perm_tarv.encounter_datetime ,
                     CASE o.value_coded
					WHEN '1707'  THEN 'ABANDONO'
					WHEN '1709' THEN 'SUSPENDEU TRATAMENTO'
					WHEN '1706' THEN 'TRANSFERIDO PARA'
					WHEN '1366'  THEN 'OBITO'
				ELSE 'OUTRO' END AS estado
			from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime, e.encounter_type
				from 	encounter e
                        inner join obs o on o.encounter_id =e.encounter_id and e.encounter_datetime between :startDate and :endDate
				       and 	e.voided=0  and o.voided=0   and o.concept_id=6273 and e.encounter_type IN (6,9)  and e.location_id=:location
				group by e.patient_id
			) ultimavisita_perm_tarv
			inner join encounter e on e.patient_id=ultimavisita_perm_tarv.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
			where o.concept_id=6273 and o.voided=0 and e.encounter_datetime=ultimavisita_perm_tarv.encounter_datetime and
			e.encounter_type in (6,9)  and e.location_id=:location
			group by e.patient_id
		) saida_real on saida_real.patient_id =   inscrito_da.patient_id
/* **************************************** Data de Inicio real na TARV  ******************************************************/
LEFT JOIN
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
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9,53) AND
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program: OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id



			) inicio
		GROUP BY patient_id
	) inicio_real ON inicio_real.patient_id=inscrito_da.patient_id
) activos group by  activos.patient_id
