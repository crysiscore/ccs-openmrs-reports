/*

Name:CCS - LISTA DE CRIANÇAS E ADOLESCENTES SEM REVELAÇÃO DIAGNÓSTICA TOTAL
Created by: Agnaldo Samuel <agnaldosamuel@ccsaude.org.mz>
creation date: 18/07/2027
Description-
  Notas:
  - A idade e calculada na data de corte (@endDate).
  - O paciente entra na lista se tiver pelo menos uma observacao valida do
    conceito 6340 nos formularios APSS (encounter_type 34 ou 35).
  - Para sector/encaminhamento, grupo de apoio e factores de risco sao
    considerados os registos das 2 consultas mais recentes que contenham a
    respectiva variavel, nos encounter_type 6, 9, 34 e 35. As restantes
    variaveis longitudinais devolvem o registo mais recente ate @endDate.
  - O conceito 1272 representa encaminhamento/referencia; ele nao possui SAAJ
    entre as respostas configuradas nesta base. Por isso, o indicador
    ja_esteve_no_saaj usa adicionalmente o modelo de atendimento
    165174 = 165319 (PARAGEM UNICA NO SAAJ), encontrado no template.
*/

SET @endDate := CURDATE();
SET @location := 208;

SELECT
    nid.nid                                                        AS nid,
    pn.nome                                                        AS nome,
    TIMESTAMPDIFF(YEAR, pe.birthdate, @endDate)                    AS idade_actual,
    DATE_FORMAT(consulta.data_ultima_consulta, '%d/%m/%Y')         AS data_ultima_consulta,
    DATE_FORMAT(consulta.data_proxima_consulta, '%d/%m/%Y')        AS data_proxima_consulta,
    DATE_FORMAT(levantamento.data_levantamento, '%d/%m/%Y')        AS data_levantamento,
    DATE_FORMAT(levantamento.data_proximo_levantamento, '%d/%m/%Y') AS data_proximo_levantamento,
    encaminhamento.descricao                                      AS sector,
    IF(saaj.patient_id IS NULL, 'NAO', 'SIM')                     AS saaj,
    grupo.grupo_apoio                                             AS grupo_apoio,
    grupo.estado_grupo                                            AS estado_grupo,
    telefone.contacto                                             AS Contacto,
    risco.factor_risco                                            AS factor_risco,
    revelacao.estado_revelacao                                    AS estado_revelacao,
    DATE_FORMAT(revelacao.data_revelacao, '%d/%m/%Y')              AS data_revelacao,
     telefone.contacto                                             AS Contacto,
      pe.gender                                                    As sexo
FROM patient p
INNER JOIN person pe
        ON pe.person_id = p.patient_id
       AND pe.voided = 0

/* Ultimo estado de revelacao registado no APSS. */
INNER JOIN (
    SELECT
        e.patient_id,
        STR_TO_DATE(
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DATE_FORMAT(e.encounter_datetime, '%Y-%m-%d %H:%i:%s')
                    ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                    SEPARATOR '||'
                ),
                '||', 1
            ),
            '%Y-%m-%d %H:%i:%s'
        ) AS data_revelacao,
        SUBSTRING_INDEX(
            GROUP_CONCAT(
                CASE o.value_coded
                    WHEN 6337 THEN 'REVELACAO TOTAL'
                    WHEN 6338 THEN 'REVELACAO PARCIAL'
                    WHEN 6339 THEN 'SEM REVELACAO'
                END
                ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                SEPARATOR '||'
            ),
            '||', 1
        ) AS estado_revelacao
    FROM encounter e
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 6340
           AND o.value_coded IN (6337, 6338, 6339)
    WHERE e.voided = 0
      AND e.encounter_type IN (34, 35)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) revelacao
        ON revelacao.patient_id = p.patient_id

/* Nome preferido, ou o primeiro nome activo quando nao houver preferido. */
LEFT JOIN (
    SELECT
        person_id,
        COALESCE(
            MAX(CASE WHEN preferred = 1
                THEN TRIM(CONCAT_WS(' ', NULLIF(given_name, ''), NULLIF(middle_name, ''), NULLIF(family_name, '')))
            END),
            MIN(TRIM(CONCAT_WS(' ', NULLIF(given_name, ''), NULLIF(middle_name, ''), NULLIF(family_name, ''))))
        ) AS nome
    FROM person_name
    WHERE voided = 0
    GROUP BY person_id
) pn
        ON pn.person_id = p.patient_id

/* NID TARV: identifier_type 2. */
LEFT JOIN (
    SELECT
        patient_id,
        COALESCE(
            MAX(CASE WHEN preferred = 1 THEN identifier END),
            MIN(identifier)
        ) AS nid
    FROM patient_identifier
    WHERE voided = 0
      AND identifier_type = 2
    GROUP BY patient_id
) nid
        ON nid.patient_id = p.patient_id

/* Ultima consulta clinica que tenha data da proxima consulta (1410). */
LEFT JOIN (
    SELECT
        e.patient_id,
        STR_TO_DATE(
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DATE_FORMAT(e.encounter_datetime, '%Y-%m-%d %H:%i:%s')
                    ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                    SEPARATOR '||'
                ), '||', 1
            ), '%Y-%m-%d %H:%i:%s'
        ) AS data_ultima_consulta,
        STR_TO_DATE(
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DATE_FORMAT(o.value_datetime, '%Y-%m-%d')
                    ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                    SEPARATOR '||'
                ), '||', 1
            ), '%Y-%m-%d'
        ) AS data_proxima_consulta
    FROM encounter e
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 1410
           AND o.value_datetime IS NOT NULL
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) consulta
        ON consulta.patient_id = p.patient_id

/* Ultimo levantamento na farmacia/fila e respectiva data marcada (5096). */
LEFT JOIN (
    SELECT
        e.patient_id,
        STR_TO_DATE(
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DATE_FORMAT(e.encounter_datetime, '%Y-%m-%d %H:%i:%s')
                    ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                    SEPARATOR '||'
                ), '||', 1
            ), '%Y-%m-%d %H:%i:%s'
        ) AS data_levantamento,
        STR_TO_DATE(
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DATE_FORMAT(o.value_datetime, '%Y-%m-%d')
                    ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
                    SEPARATOR '||'
                ), '||', 1
            ), '%Y-%m-%d'
        ) AS data_proximo_levantamento
    FROM encounter e
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 5096
           AND o.value_datetime IS NOT NULL
    WHERE e.voided = 0
      AND e.encounter_type = 18
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) levantamento
        ON levantamento.patient_id = p.patient_id

/*
  Sector/encaminhamento/referencia (1272) nas 2 consultas mais recentes
  que contenham esta variavel, entre Ficha Clinica e APSS.
*/
LEFT JOIN (
    SELECT
        e.patient_id,
        GROUP_CONCAT(
            CONCAT(
                DATE_FORMAT(e.encounter_datetime, '%d/%m/%Y'),
                ': ',
                COALESCE(cn.nome, CONCAT('CONCEITO ', o.value_coded))
            )
            ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
            SEPARATOR ' | '
        ) AS descricao
    FROM (
        SELECT
            e1.patient_id,
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DISTINCT e1.encounter_id
                    ORDER BY e1.encounter_datetime DESC, e1.encounter_id DESC
                    SEPARATOR ','
                ),
                ',', 2
            ) AS encounter_ids
        FROM encounter e1
        INNER JOIN obs o1
                ON o1.encounter_id = e1.encounter_id
               AND o1.voided = 0
               AND o1.concept_id = 1272
               AND o1.value_coded IS NOT NULL
        WHERE e1.voided = 0
          AND e1.encounter_type IN (6, 9, 34, 35)
          AND e1.location_id = @location
          AND e1.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
        GROUP BY e1.patient_id
    ) ultimos
    INNER JOIN encounter e
            ON e.patient_id = ultimos.patient_id
           AND FIND_IN_SET(e.encounter_id, ultimos.encounter_ids) > 0
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 1272
           AND o.value_coded IS NOT NULL
    LEFT JOIN (
        SELECT
            concept_id,
            COALESCE(
                MAX(CASE WHEN locale = 'pt' AND concept_name_type = 'FULLY_SPECIFIED' THEN name END),
                MAX(CASE WHEN locale = 'en' AND concept_name_type = 'FULLY_SPECIFIED' THEN name END),
                MAX(name)
            ) AS nome
        FROM concept_name
        WHERE voided = 0
        GROUP BY concept_id
    ) cn
            ON cn.concept_id = o.value_coded
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9, 34, 35)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) encaminhamento
        ON encaminhamento.patient_id = p.patient_id

/* Historico de Paragem Unica no SAAJ, modelo de atendimento 165174=165319. */
LEFT JOIN (
    SELECT DISTINCT e.patient_id
    FROM encounter e
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 165174
           AND o.value_coded = 165319
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
) saaj
        ON saaj.patient_id = p.patient_id

/*
  Grupos de apoio registados nas 2 consultas mais recentes que contenham
  esta variavel, entre Ficha Clinica e APSS.
*/
LEFT JOIN (
    SELECT
        e.patient_id,
        GROUP_CONCAT(
            CONCAT(
                DATE_FORMAT(e.encounter_datetime, '%d/%m/%Y'),
                ': ',
                CASE o.concept_id
                    WHEN 165324 THEN 'ADOLESCENTE E JOVEM MENTOR'
                    WHEN 23757  THEN 'ADOLESCENTES REVELADAS/OS (AR)'
                    WHEN 23753  THEN 'CRIANCAS REVELADAS (CR)'
                    WHEN 23755  THEN 'PAIS E CUIDADORES (PC)'
                    WHEN 24031  THEN 'MAE MENTORA'
                    WHEN 23759  THEN 'MAE PARA MAE (MPM)'
                    WHEN 165325 THEN 'HOMEM CAMPEAO'
                    WHEN 23772  THEN 'OUTRO GRUPO DE APOIO'
                END
            )
            ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
            SEPARATOR ' | '
        ) AS grupo_apoio,
        GROUP_CONCAT(
            CONCAT(
                DATE_FORMAT(e.encounter_datetime, '%d/%m/%Y'),
                ': ',
                CASE o.value_coded
                    WHEN 1256 THEN 'INICIA'
                    WHEN 1257 THEN 'CONTINUA'
                    WHEN 1267 THEN 'TERMINA'
                    ELSE 'SEM ESTADO REGISTADO'
                END
            )
            ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
            SEPARATOR ' | '
        ) AS estado_grupo
    FROM (
        SELECT
            e1.patient_id,
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DISTINCT e1.encounter_id
                    ORDER BY e1.encounter_datetime DESC, e1.encounter_id DESC
                    SEPARATOR ','
                ),
                ',', 2
            ) AS encounter_ids
        FROM encounter e1
        INNER JOIN obs o1
                ON o1.encounter_id = e1.encounter_id
               AND o1.voided = 0
               AND o1.concept_id IN (165324, 23757, 23753, 23755, 24031, 23759, 165325, 23772)
        WHERE e1.voided = 0
          AND e1.encounter_type IN (6, 9, 34, 35)
          AND e1.location_id = @location
          AND e1.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
        GROUP BY e1.patient_id
    ) ultimos
    INNER JOIN encounter e
            ON e.patient_id = ultimos.patient_id
           AND FIND_IN_SET(e.encounter_id, ultimos.encounter_ids) > 0
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id IN (165324, 23757, 23753, 23755, 24031, 23759, 165325, 23772)
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9, 34, 35)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) grupo
        ON grupo.patient_id = p.patient_id

/* Contacto do paciente (person_attribute_type_id 9). */
LEFT JOIN (
    SELECT person_id, MAX(NULLIF(TRIM(value), '')) AS contacto
    FROM person_attribute
    WHERE voided = 0
      AND person_attribute_type_id = 9
    GROUP BY person_id
) telefone
        ON telefone.person_id = p.patient_id

/*
  Factores de risco registados nas 2 consultas mais recentes que contenham
  esta variavel, sem limitar o historico a 3 meses.
*/
LEFT JOIN (
    SELECT
        e.patient_id,
        GROUP_CONCAT(
            CONCAT(
                DATE_FORMAT(e.encounter_datetime, '%d/%m/%Y'),
                ': ',
                CASE o.value_coded
                    WHEN 6436  THEN 'ESTIGMA/PREOCUPADO COM A PRIVACIDADE'
                    WHEN 23769 THEN 'ASPECTOS CULTURAIS OU TRADICIONAIS'
                    WHEN 23768 THEN 'PERDEU/ESQUECEU/PARTILHOU COMPRIMIDOS'
                    WHEN 6303  THEN 'VIOLENCIA BASEADA NO GENERO'
                    WHEN 23767 THEN 'SENTE-SE MELHOR'
                    WHEN 18698 THEN 'FALTA DE ALIMENTO'
                    WHEN 207   THEN 'DEPRESSAO'
                    WHEN 820   THEN 'PROBLEMAS DE TRANSPORTE'
                    WHEN 1936  THEN 'UTENTE SENTE-SE DOENTE'
                    WHEN 1956  THEN 'NAO ACREDITA NO RESULTADO'
                    WHEN 2015  THEN 'EFEITOS SECUNDARIOS DE ARV'
                    WHEN 2153  THEN 'FALTA DE APOIO'
                    WHEN 2155  THEN 'NAO REVELOU O SEU DIAGNOSTICO'
                    WHEN 6186  THEN 'NAO ACREDITA NO TRATAMENTO'
                    WHEN 23766 THEN 'SAO MUITOS COMPRIMIDOS'
                    WHEN 2017  THEN 'OUTRO MOTIVO DE FALTA'
                    WHEN 1603  THEN 'ABUSO DE ALCOOL'
                    WHEN 2010  THEN 'INSATISFACAO COM O SERVICO NO HDD'
                    ELSE CONCAT('CONCEITO ', o.value_coded)
                END
            )
            ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, o.obs_id DESC
            SEPARATOR ' | '
        ) AS factor_risco
    FROM (
        SELECT
            e1.patient_id,
            SUBSTRING_INDEX(
                GROUP_CONCAT(
                    DISTINCT e1.encounter_id
                    ORDER BY e1.encounter_datetime DESC, e1.encounter_id DESC
                    SEPARATOR ','
                ),
                ',', 2
            ) AS encounter_ids
        FROM encounter e1
        INNER JOIN obs o1
                ON o1.encounter_id = e1.encounter_id
               AND o1.voided = 0
               AND o1.concept_id = 6193
               AND o1.value_coded IS NOT NULL
        WHERE e1.voided = 0
          AND e1.encounter_type IN (6, 9, 34, 35)
          AND e1.location_id = @location
          AND e1.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
        GROUP BY e1.patient_id
    ) ultimos
    INNER JOIN encounter e
            ON e.patient_id = ultimos.patient_id
           AND FIND_IN_SET(e.encounter_id, ultimos.encounter_ids) > 0
    INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
           AND o.voided = 0
           AND o.concept_id = 6193
           AND o.value_coded IS NOT NULL
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9, 34, 35)
      AND e.location_id = @location
      AND e.encounter_datetime < DATE_ADD(@endDate, INTERVAL 1 DAY)
    GROUP BY e.patient_id
) risco
        ON risco.patient_id = p.patient_id

WHERE p.voided = 0
  AND pe.birthdate IS NOT NULL
  AND pe.birthdate <= @endDate
  AND TIMESTAMPDIFF(YEAR, pe.birthdate, @endDate) BETWEEN 8 AND 14
ORDER BY pn.nome, nid.nid;
