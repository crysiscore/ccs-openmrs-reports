
SET @rank := 0, @current_patient := '', @prev_datetime := NULL;
SELECT
    patient_id,
    data_rastreio,
    MAX(sistolica) as sistolica,
    MAX(diastolica) as diastolica,
    numero_visita
FROM (
    SELECT
        t.*,
        @rank := IF(@current_patient = t.patient_id AND @prev_datetime != t.data_rastreio, @rank + 1,
                    IF(@current_patient := t.patient_id, 1, 1)) as numero_visita,
        @prev_datetime := t.data_rastreio
    FROM (
        SELECT
            e.patient_id,
            e.encounter_datetime as data_rastreio,
            MAX(CASE WHEN o.concept_id = 5085 THEN o.value_numeric END) as sistolica,
            MAX(CASE WHEN o.concept_id = 5086 THEN o.value_numeric END) as diastolica
        FROM encounter e
        INNER JOIN obs o ON o.encounter_id = e.encounter_id
        WHERE e.voided = 0
        AND o.voided = 0
        AND o.concept_id IN (5085, 5086)
        AND e.encounter_type IN (6, 9)
        AND e.location_id = :location
        GROUP BY e.patient_id, e.encounter_datetime
        ORDER BY e.patient_id, e.encounter_datetime DESC
    ) t
) tmp
WHERE numero_visita <= 3
GROUP BY patient_id, data_rastreio, numero_visita
ORDER BY patient_id, data_rastreio DESC;