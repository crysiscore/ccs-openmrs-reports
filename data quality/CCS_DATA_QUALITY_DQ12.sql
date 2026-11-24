/*
NAME: CCS DATA QUALITY RQD12 - PACIENTES COM CONSULTAS SEM FILA NEM LEVANTAMENTO DE TARV
Created by: Codex / Agnaldo Samuel
Change Date: 24/11/2026
Description:
- Lista por unidade sanitária dos pacientes com pelo menos uma consulta de seguimento nos dois anos até endDate, inclusive.
- Exclui a FILA (tipo 18) e a Recepção (tipo 52) com data de levantamento preenchida (conceito 23866) pela data da respectiva ficha.
- Apresenta a última consulta de cada paciente, incluindo o seguimento histórico de adultos e pediatria, sem filtro de estado em TARV.

Revisao:   Codex / Agnaldo Samuel
Change Date: 24/11/2026
- Acrescenta a data de início de TARV usando a primeira evidência válida até endDate na unidade seleccionada: início de regime (1255/1256), data de início (1190) ou inscrição no programa TARV (2).
- Apresenta a data como campo informativo, incluindo evidências anteriores à janela de consultas de dois anos.
- Teste no MySQL 5.6, CS Xipamanine, endDate de 24/11/2026: os mesmos 78 pacientes, com 48 datas de início confirmadas por consulta de referência e 30 sem data.

Revisao:   Codex / Agnaldo Samuel
Change Date: 24/11/2026
- Alinha a data de início de TARV com o DAH. Inclui a primeira FILA (tipo 18) e a data de levantamento registada no Master Card (tipo 52, conceito 23866) no cálculo da primeira evidência válida na unidade até endDate.
- Usa a data da ficha de Recepção para a elegibilidade do RDQ12 e a data de levantamento preenchida para o cálculo da data de início.
- Validado em MySQL 5.6 no CS Xipamanine. Para 24/11/2026, as datas coincidiram com as cinco fontes do DAH para os 78 pacientes (48 com data). As datas e as listas também se mantiveram face à versão anterior para 31/12/2024 e 31/12/2025.

Revisao:   Agnaldo Samuel
Change Date: 24/11/2026
- Acrescenta a próxima consulta da última ficha clínica (1410), o último tipo de dispensa (23739) e o último sector da Ficha Resumo (165/23783), sem alterar os critérios de elegibilidade.
- Teste no MySQL 5.6, CS Xipamanine, endDate de 24/11/2026: 78 pacientes e colunas anteriores idênticas. Os novos campos coincidiram com os registos de origem: 53 datas de próxima consulta, 52 tipos de dispensa e 26 sectores.
*/
SELECT
    consulta.patient_id,
    DATE_FORMAT(consulta.data_seguimento, '%d/%m/%Y') AS data_seguimento,
    CONCAT_WS(' ', NULLIF(pn.given_name, ''), NULLIF(pn.middle_name, ''), NULLIF(pn.family_name, '')) AS nome,
    DATE_FORMAT(pe.birthdate, '%d/%m/%Y') AS birthdate,
    TIMESTAMPDIFF(YEAR, pe.birthdate, DATE(:endDate)) AS idade_actual,
    pe.gender,
    pid.identifier AS nid,
    /* O dia seguinte a endDate substitui datas ausentes para calcular o mínimo;
       se todas as fontes estiverem vazias, NULLIF devolve NULL. */
    CASE WHEN pe.voided = 0 THEN DATE_FORMAT(NULLIF(LEAST(
        COALESCE((
            SELECT MIN(CASE WHEN inicio.concept_id = 1255 THEN historico.encounter_datetime
                            ELSE inicio.value_datetime END)
            FROM encounter historico
            INNER JOIN obs inicio ON inicio.encounter_id = historico.encounter_id AND inicio.voided = 0
            WHERE historico.patient_id = consulta.patient_id
              AND historico.voided = 0
              AND historico.location_id = :location
              AND (
                  (historico.encounter_type IN (6, 9, 18)
                   AND inicio.concept_id = 1255 AND inicio.value_coded = 1256
                   AND historico.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY))
                  OR
                  (historico.encounter_type IN (6, 9, 18, 53)
                   AND inicio.concept_id = 1190
                   AND inicio.value_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY))
                  OR
                  (historico.encounter_type = 52
                   AND inicio.concept_id = 23866
                   AND inicio.value_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY))
              )
        ), DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)),
        COALESCE((
            SELECT MIN(programa.date_enrolled)
            FROM patient_program programa
            WHERE programa.patient_id = consulta.patient_id
              AND programa.voided = 0
              AND programa.program_id = 2
              AND programa.location_id = :location
              AND programa.date_enrolled < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
        ), DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)),
        COALESCE((
            SELECT MIN(farmacia.encounter_datetime)
            FROM encounter farmacia
            WHERE farmacia.patient_id = consulta.patient_id
              AND farmacia.voided = 0
              AND farmacia.encounter_type = 18
              AND farmacia.location_id = :location
              AND farmacia.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
        ), DATE_ADD(DATE(:endDate), INTERVAL 1 DAY))
    ), DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)), '%d/%m/%Y') END AS data_inicio,
    DATE_FORMAT((
        SELECT proxima.value_datetime
        FROM obs proxima
        WHERE proxima.encounter_id = (
            SELECT MAX(e.encounter_id)
            FROM encounter e
            WHERE e.patient_id = consulta.patient_id
              AND e.encounter_datetime = consulta.data_seguimento
              AND e.encounter_type IN (6, 9)
              AND e.location_id = :location
              AND e.voided = 0
        )
          AND proxima.concept_id = 1410
          AND proxima.voided = 0
          AND proxima.value_datetime IS NOT NULL
        ORDER BY proxima.obs_id DESC
        LIMIT 1
    ), '%d/%m/%Y') AS data_proxima_consulta,
    CASE (
        SELECT dispensa.value_coded
        FROM encounter e
        INNER JOIN obs dispensa ON dispensa.encounter_id = e.encounter_id
        WHERE e.patient_id = consulta.patient_id
          AND e.encounter_type IN (6, 9, 53)
          AND e.location_id = :location
          AND e.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
          AND e.voided = 0
          AND dispensa.concept_id = 23739
          AND dispensa.voided = 0
          AND dispensa.value_coded IS NOT NULL
        ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, dispensa.obs_id DESC
        LIMIT 1
    )
        WHEN 1098 THEN 'DISPENSA MENSAL'
        WHEN 165340 THEN 'DISPENSA BIMESTRAL'
        WHEN 23720 THEN 'DISPENSA TRIMESTRAL'
        WHEN 23888 THEN 'DISPENSA SEMESTRAL'
        WHEN 165314 THEN 'DISPENSA ANUAL'
    END AS tipo_dispensa,
    CASE (
        SELECT sector_obs.value_coded
        FROM encounter e
        INNER JOIN obs sector_obs ON sector_obs.encounter_id = e.encounter_id
        WHERE e.patient_id = consulta.patient_id
          AND e.form_id = 165
          AND e.location_id = :location
          AND e.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
          AND e.voided = 0
          AND sector_obs.concept_id = 23783
          AND sector_obs.voided = 0
          AND sector_obs.value_coded IS NOT NULL
        ORDER BY e.encounter_datetime DESC, e.encounter_id DESC, sector_obs.obs_id DESC
        LIMIT 1
    )
        WHEN 1414 THEN 'TB'
        WHEN 1987 THEN 'SAAJ'
        WHEN 1985 THEN 'CPN/G'
        WHEN 1872 THEN 'CCR/L'
        WHEN 21275 THEN 'Clínica'
    END AS sector
FROM (
    SELECT e.patient_id, MAX(e.encounter_datetime) AS data_seguimento
    FROM encounter e
    INNER JOIN patient p ON p.patient_id = e.patient_id AND p.voided = 0
    WHERE e.voided = 0
      AND e.encounter_type IN (6, 9)
      AND e.location_id = :location
      AND e.encounter_datetime >= DATE_SUB(DATE(:endDate), INTERVAL 2 YEAR)
      AND e.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
    GROUP BY e.patient_id
) consulta
LEFT JOIN person pe ON pe.person_id = consulta.patient_id
LEFT JOIN person_name pn ON pn.person_name_id = (
    SELECT nome.person_name_id
    FROM person_name nome
    WHERE nome.person_id = consulta.patient_id AND nome.voided = 0
    ORDER BY nome.preferred DESC, nome.person_name_id
    LIMIT 1
)
LEFT JOIN patient_identifier pid ON pid.patient_identifier_id = (
    SELECT nid.patient_identifier_id
    FROM patient_identifier nid
    WHERE nid.patient_id = consulta.patient_id AND nid.voided = 0
      AND nid.identifier_type = 2
    ORDER BY nid.preferred DESC, nid.patient_identifier_id
    LIMIT 1
)
WHERE NOT EXISTS (
    SELECT 1
    FROM encounter fila
    WHERE fila.patient_id = consulta.patient_id
      AND fila.voided = 0
      AND fila.encounter_type = 18
      AND fila.location_id = :location
      AND fila.encounter_datetime >= DATE_SUB(DATE(:endDate), INTERVAL 2 YEAR)
      AND fila.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
)
AND NOT EXISTS (
    SELECT 1
    FROM encounter recepcao
    INNER JOIN obs levantamento ON levantamento.encounter_id = recepcao.encounter_id
      AND levantamento.voided = 0
      AND levantamento.concept_id = 23866
      AND levantamento.value_datetime IS NOT NULL
    WHERE recepcao.patient_id = consulta.patient_id
      AND recepcao.voided = 0
      AND recepcao.encounter_type = 52
      AND recepcao.location_id = :location
      AND recepcao.encounter_datetime >= DATE_SUB(DATE(:endDate), INTERVAL 2 YEAR)
      AND recepcao.encounter_datetime < DATE_ADD(DATE(:endDate), INTERVAL 1 DAY)
)
ORDER BY consulta.data_seguimento DESC, consulta.patient_id;
