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

/* ====== TESTE (remove para todos) ====== */
WHERE i.patient_id = 1246;