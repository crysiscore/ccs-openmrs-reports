/*
Name CCS LISTA DE MONITORIA DE PACIENTES INSCRITOS NA DISPENSA ANUAL -DA
Description-
                 -      no âmbito do projecto de implementação da DA em Gaza, precisaremos de algumas listas para apoio as equipas para monitoria dos pacientes neste modelo de dispensa.
Created by:    Agnaldo  Samuel
Change Date: 06/01/2026
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
            tipo_dispensa_depois_da.tipodispensa as tipo_dispensa_depois_da,
            tipo_dispensa_antes_da.tipodispensa as tipo_dispensa_antes_da,
             DATE_FORMAT(tipo_dispensa_depois_da.data_ult_tipo_dis,'%d/%m/%Y')  as data_tipo_dispensa_depois_da,
             cv_antes_da.valor_ultima_carga   AS carga_viral_antes_da,
            DATE_FORMAT(cv_antes_da.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v_antes_da ,
            DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v_depois_da ,
             cv.valor_ultima_carga  as carga_viral_numeric_depois_da,
            DATE_FORMAT(in_3hp_tpi.data_inicio_tpt,'%d/%m/%Y') AS data_inicio_tpt,
            DATE_FORMAT(ult_ped_cv.data_pedido_cv,'%d/%m/%Y') AS data_pedido_apos_inscricao,
            DATE_FORMAT(gravida_real.data_gravida,'%d/%m/%Y') AS data_gravida,
 			DATE_FORMAT(lactante_real.date_enrolled,'%d/%m/%Y') AS data_lactante,
 			DATE_FORMAT(end_tpt.data_end_tpt,'%d/%m/%Y') AS data_fim_tpt ,
 			if( marcado_tb.tratamento_tb IS NULL, NULL, CONCAT( marcado_tb.tratamento_tb, ' - ',   DATE_FORMAT(marcado_tb.data_marcado_tb,'%d/%m/%Y' ))) AS trat_tb,
 			DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
            DATE_FORMAT(ultimoFila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
 		    DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
            if( DATEDIFF(:endDate,ult_seguimento.value_datetime)<=28, 'ACTIVO EM TARV',
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

  /**  ****************	Ultimo Pedido de CV ba ficha clinica apos inscricao **************************** **/
       LEFT JOIN (
SELECT
    i.patient_id,
    i.data_modelo,
    pcv.data_pedido_cv
FROM
(
    /* INICIO_DA: data de inscrição no modelo (data_modelo) no período */
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
    /* Último pedido de CV APÓS inscrição (data_modelo) */
    SELECT
        i2.patient_id,
        MAX(e2.encounter_datetime) AS data_pedido_cv
    FROM
    (
        /* repetir INICIO_DA aqui (MySQL 5.6 não tem CTE) */
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
       AND e2.encounter_datetime > i2.data_modelo   /* APÓS inscrição */
    INNER JOIN obs pedido
        ON pedido.encounter_id = e2.encounter_id
       AND pedido.voided = 0
       AND pedido.concept_id = 23722
       AND pedido.value_coded = 856
    GROUP BY i2.patient_id
) pcv
ON pcv.patient_id = i.patient_id



           ) ult_ped_cv ON ult_ped_cv.patient_id =  inscrito_da.patient_id
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
    /* TIPO DISPENSA: último tipo de dispensa ANTES do data_modelo (por paciente) */
    SELECT
        m.patient_id,
        m.data_ult_tipo_dis,
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
        /* pega a maior data do tipo de dispensa que seja < data_modelo */
        SELECT
            i2.patient_id,
            MAX(e2.encounter_datetime) AS data_ult_tipo_dis
        FROM
        (
            /* repetir INICIO_DA aqui (MySQL 5.6 não tem CTE) */
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
        INNER JOIN obs o2
            ON o2.encounter_id = e2.encounter_id
           AND o2.voided = 0
           AND o2.concept_id = 23739
           AND o2.location_id = :location
        GROUP BY i2.patient_id
    ) m
    INNER JOIN encounter e
        ON e.patient_id = m.patient_id
       AND e.encounter_datetime = m.data_ult_tipo_dis
       AND e.voided = 0
       AND e.encounter_type IN (6, 9)
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id = 23739
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
    /* TIPO DISPENSA: último tipo de dispensa ANTES do data_modelo (por paciente) */
    SELECT
        m.patient_id,
        m.data_ult_tipo_dis,
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
        /* pega a maior data do tipo de dispensa que seja < data_modelo */
        SELECT
            i2.patient_id,
            MAX(e2.encounter_datetime) AS data_ult_tipo_dis
        FROM
        (
            /* repetir INICIO_DA aqui (MySQL 5.6 não tem CTE) */
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
        INNER JOIN obs o2
            ON o2.encounter_id = e2.encounter_id
           AND o2.voided = 0
           AND o2.concept_id = 23739
           AND o2.location_id = :location
        GROUP BY i2.patient_id
    ) m
    INNER JOIN encounter e
        ON e.patient_id = m.patient_id
       AND e.encounter_datetime = m.data_ult_tipo_dis
       AND e.voided = 0
       AND e.encounter_type IN (6, 9)
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id = 23739
) td
ON td.patient_id = i.patient_id
		) tipo_dispensa_depois_da ON tipo_dispensa_depois_da.patient_id=inscrito_da.patient_id

          /**********************  Inicio de TPI  ********************************************************************/
		    LEFT JOIN
              (select inicio_tpt.patient_id, min(inicio_tpt.data_inicio_tpi) data_inicio_tpt

                       from (
                                /*	Inicio  3HP na Ficha Clinica, Seguimento e Resumo	     */
                                select p.patient_id, min(estadoProfilaxia.obs_datetime) data_inicio_tpi
                                from patient p
                                inner join encounter e on p.patient_id = e.patient_id
                                inner join obs profilaxia3HP on profilaxia3HP.encounter_id = e.encounter_id
                                inner join obs estadoProfilaxia on estadoProfilaxia.encounter_id = e.encounter_id
                                  where p.voided = 0
                                  and e.voided = 0
                                  and profilaxia3HP.voided = 0
                                  and estadoProfilaxia.voided = 0
                                  and profilaxia3HP.concept_id = 23985
                                  and profilaxia3HP.value_coded = 23954
                                  and estadoProfilaxia.concept_id = 165308
                                  and estadoProfilaxia.value_coded = 1256
                                  and e.encounter_type in (6, 9, 53)
                                  and e.location_id = :location
                                  and estadoProfilaxia.obs_datetime <=  :endDate and :endDate
                                group by p.patient_id
                                union
                                /* Inicio Usando Outras prescrições DT-3HP na Ficha Clinica  */
                                select p.patient_id, min(outrasPrescricoesDT3HP.obs_datetime) data_inicio_tpi
                                from patient p
                                         inner join encounter e on p.patient_id = e.patient_id
                                         inner join obs outrasPrescricoesDT3HP
                                                    on outrasPrescricoesDT3HP.encounter_id = e.encounter_id
                                where p.voided = 0
                                  and e.voided = 0
                                  and outrasPrescricoesDT3HP.voided = 0
                                  and outrasPrescricoesDT3HP.obs_datetime <=  :endDate
                                  and outrasPrescricoesDT3HP.concept_id = 1719
                                  and outrasPrescricoesDT3HP.value_coded = 165307
                                  and e.encounter_type in (6)
                                  and e.location_id = :location
                                group by p.patient_id
                                union
                                  /*
                                  Patients who have Regime de TPT with the values “3HP or 3HP +
                                  Piridoxina” and “Seguimento de tratamento TPT” = (‘Inicio’ or ‘Re-Inicio’)
                                  marked on Ficha de Levantamento de TPT (FILT)  during the previous
                                  reporting period (3HP Start Date)
                                  */
                                 select p.patient_id, min(seguimentoTPT.obs_datetime) data_inicio_tpi
                                            from patient p
                                                     inner join encounter e on p.patient_id = e.patient_id
                                                     inner join obs regime3HP on regime3HP.encounter_id = e.encounter_id
                                                     inner join obs seguimentoTPT on seguimentoTPT.encounter_id = e.encounter_id
                                            where e.voided = 0
                                              and p.voided = 0
                                              and seguimentoTPT.obs_datetime <=  :endDate
                                              and regime3HP.voided = 0
                                              and regime3HP.concept_id = 23985
                                              and regime3HP.value_coded in (23954, 23984)
                                              and e.encounter_type = 60
                                              and e.location_id = :location
                                              and seguimentoTPT.voided = 0
                                              and seguimentoTPT.concept_id = 23987
                                              and seguimentoTPT.value_coded in (1256, 1705)
                                            group by p.patient_id

                                            union

                                                                                /*
                                                    Patients who have  (Profilaxia
                                                    TPT with the value “Isoniazida (INH)” and Estado da Profilaxia with the
                                                    value “Inicio (I)”) marked on Ficha Clínica , Ficha Seguimento and Ficha Resumo
                                             */

                                            select p.patient_id, min(obsInicioINH.obs_datetime) data_inicio_tpi
                                            from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs o on o.encounter_id = e.encounter_id
                                                inner join obs obsInicioINH on obsInicioINH.encounter_id = e.encounter_id
                                            where e.voided=0 and p.voided=0 and o.voided=0 and e.encounter_type in (6,9,53)and o.concept_id=23985 and o.value_coded=656
                                                and obsInicioINH.concept_id=165308 and obsInicioINH.value_coded=1256 and obsInicioINH.voided=0
                                                and obsInicioINH.obs_datetime <=  :endDate and  e.location_id=:location
                                                group by p.patient_id


                                            union

                                            /*
                                             *   Patients who have Regime de TPT with the values (“Isoniazida” or
                                                    “Isoniazida + Piridoxina”) and “Seguimento de tratamento TPT” = (‘Inicio’ or
                                                    ‘Re-Inicio’) marked on Ficha de Levantamento de TPT (FILT) during the
                                                    previous reporting period (INH Start Date)
                                             * */
                                            select p.patient_id,min(seguimentoTPT.obs_datetime) data_inicio_tpi
                                            from	patient p
                                                inner join encounter e on p.patient_id=e.patient_id
                                                inner join obs o on o.encounter_id=e.encounter_id
                                                inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
                                            where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime <=  :endDate
                                                and seguimentoTPT.voided =0 and seguimentoTPT.concept_id = 23987 and seguimentoTPT.value_coded in (1256,1705)
                                                and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
                                                group by p.patient_id


                   ) inicio_tpt
                       group by inicio_tpt.patient_id)  in_3hp_tpi  ON in_3hp_tpi.patient_id=inscrito_da.patient_id

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
    /* CV: última carga viral DEPOIS do início DA (por paciente) */
    SELECT
        m.patient_id,
        m.data_ultima_carga,
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
        /* pega a maior data de CV que seja > data_modelo */
        SELECT
            i2.patient_id,
            MAX(e2.encounter_datetime) AS data_ultima_carga
        FROM
        (
            /* repetir INICIO_DA aqui (MySQL 5.6 não tem CTE) */
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
        INNER JOIN encounter e2
            ON e2.patient_id = i2.patient_id
           AND e2.voided = 0
           AND e2.location_id = :location
           AND e2.encounter_type IN (6, 9, 13, 51, 53)
           AND e2.encounter_datetime >  i2.data_modelo
        INNER JOIN obs o2
            ON o2.encounter_id = e2.encounter_id
           AND o2.voided = 0
           AND o2.concept_id IN (856, 1305)
        GROUP BY i2.patient_id
    ) m
    INNER JOIN encounter e
        ON e.patient_id = m.patient_id
       AND e.encounter_datetime = m.data_ultima_carga
       AND e.voided = 0
       AND e.location_id = :location
       AND e.encounter_type IN (6, 9, 13, 51, 53)
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id IN (856, 1305)
    LEFT JOIN form fr
        ON fr.form_id = e.form_id
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
    /* CV: última carga viral ANTES do início DA (por paciente) */
    SELECT
        m.patient_id,
        m.data_ultima_carga,
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
        /* pega a maior data de CV que seja < data_modelo */
        SELECT
            i2.patient_id,
            MAX(e2.encounter_datetime) AS data_ultima_carga
        FROM
        (
            /* repetir INICIO_DA aqui (MySQL 5.6 não tem CTE) */
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
        INNER JOIN encounter e2
            ON e2.patient_id = i2.patient_id
           AND e2.voided = 0
           AND e2.location_id = :location
           AND e2.encounter_type IN (6, 9, 13, 51, 53)
           AND e2.encounter_datetime < i2.data_modelo
        INNER JOIN obs o2
            ON o2.encounter_id = e2.encounter_id
           AND o2.voided = 0
           AND o2.concept_id IN (856, 1305)
        GROUP BY i2.patient_id
    ) m
    INNER JOIN encounter e
        ON e.patient_id = m.patient_id
       AND e.encounter_datetime = m.data_ultima_carga
       AND e.voided = 0
       AND e.location_id = :location
       AND e.encounter_type IN (6, 9, 13, 51, 53)
    INNER JOIN obs o
        ON o.encounter_id = e.encounter_id
       AND o.voided = 0
       AND o.concept_id IN (856, 1305)
    LEFT JOIN form fr
        ON fr.form_id = e.form_id
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
select fim_tpt.patient_id,max(fim_tpt.data_fim_tpt) data_end_tpt  -- Completaram TPT no FILT ou FC
	from
	(
		select 	p.patient_id,max(e.encounter_datetime) data_fim_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1267 and e.encounter_type in (6,9,53,60) and  e.location_id=:location
		group by p.patient_id )  fim_tpt group by patient_id
	) end_tpt ON end_tpt.patient_id=inscrito_da.patient_id -- AND data_consulta=data_pick_up



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
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
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
                        inner join obs o on o.encounter_id =e.encounter_id
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