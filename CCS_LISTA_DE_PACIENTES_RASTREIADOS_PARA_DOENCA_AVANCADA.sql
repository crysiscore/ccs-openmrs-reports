/*
Name - CCS LISTA DE PACIENTES COM RASTREIO DE DOENCA AVACADA 
Description - 
		# Critérios para elegiveis para rastreio de doença avançada:
		•	Inicios TARV (do período que se pretende extrair a lista), 
		•	Reinicios (do período que se pretende extrair a lista), 
		•	Grávidas 
		•	Falências: 2 CVs consecutivas acima de 1000;
		Incluir como variável:
		•	último Resultado do CD4 abaixo de 200;
		•	pacientes com teste de CrAG e TB_LAM;
		•	Data de Inicio TARV;
	

Created By - Agnaldo  Samuel
Created Date - 29/08/2021

Modified  By - Agnaldo  Samuel
Modification Date - 04/01/2020
Modification Reason: Novos criterios de elegibilidade

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
               DATE_FORMAT(gravida_real.data_gravida, '%d/%m/%Y') AS data_gravida,
               DATE_FORMAT(falencia_cv.data_ult_cv, '%d/%m/%Y') AS data_ult_cv,
            falencia_cv.ult_cv,
               DATE_FORMAT(falencia_cv.data_penult_cv, '%d/%m/%Y') AS data_penult_cv,
            falencia_cv.penult_cv,
            tb_lam.resul_tb_lam,
            tb_crag.resul_tb_crag,
            cd4.value_numeric AS cd4,
            permanencia.estado_permanencia,
			DATE_FORMAT(permanencia.data_consulta, '%d/%m/%Y') AS data_consulta,
            telef.value AS telefone,
            DATE_FORMAT(ult_seguimento.encounter_datetime, '%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime, '%d/%m/%Y') AS data_proxima_visita,
            IF(DATEDIFF(:endDate, visita.value_datetime) <= 28, 'ACTIVO EM TARV', 'ABANDONO NAO NOTIFICADO') estado,
            pad3.county_district AS 'Distrito',
            pad3.address2 AS 'Padministrativo',
            pad3.address6 AS 'Localidade',
            pad3.address5 AS 'Bairro',
            pad3.address1 AS 'PontoReferencia'
    FROM
        (SELECT 
        patient_id, MIN(data_inicio) data_inicio
    FROM
        (SELECT 
        p.patient_id, MIN(e.encounter_datetime) data_inicio
    FROM
        patient p
    INNER JOIN encounter e ON p.patient_id = e.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.voided = 0 AND o.voided = 0
            AND p.voided = 0
            AND e.encounter_type IN (18 , 6, 9)
            AND o.concept_id = 1255
            AND o.value_coded = 1256
            AND e.encounter_datetime <= :endDate
            AND e.location_id = :location
    GROUP BY p.patient_id UNION SELECT 
        p.patient_id, MIN(value_datetime) data_inicio
    FROM
        patient p
    INNER JOIN encounter e ON p.patient_id = e.patient_id
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        p.voided = 0 AND e.voided = 0
            AND o.voided = 0
            AND e.encounter_type IN (18 , 6, 9, 53)
            AND o.concept_id = 1190
            AND o.value_datetime IS NOT NULL
            AND o.value_datetime <= :endDate
            AND e.location_id = :location
    GROUP BY p.patient_id UNION SELECT 
        pg.patient_id, MIN(date_enrolled) data_inicio
    FROM
        patient p
    INNER JOIN patient_program pg ON p.patient_id = pg.patient_id
    WHERE
        pg.voided = 0 AND p.voided = 0
            AND program_id = 2
            AND date_enrolled <= :endDate
            AND location_id = :location
    GROUP BY pg.patient_id UNION SELECT 
        e.patient_id, MIN(e.encounter_datetime) AS data_inicio
    FROM
        patient p
    INNER JOIN encounter e ON p.patient_id = e.patient_id
    WHERE
        p.voided = 0 AND e.encounter_type = 18
            AND e.voided = 0
            AND e.encounter_datetime <= :endDate
            AND e.location_id = :location
    GROUP BY p.patient_id) inicio
    GROUP BY patient_id) inicio_real
    INNER JOIN person p ON p.person_id = inicio_real.patient_id
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
    LEFT JOIN (SELECT 
        patient_id, MAX(data_gravida) AS data_gravida
    FROM
        (SELECT 
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
    GROUP BY p.patient_id UNION SELECT 
        pp.patient_id, pp.date_enrolled AS data_gravida
    FROM
        patient_program pp
    WHERE
        pp.program_id = 8 AND pp.voided = 0
            AND pp.date_completed IS NULL
            AND pp.date_enrolled BETWEEN :startDate AND :endDate
            AND pp.location_id = :location) gravida
    GROUP BY patient_id) gravida_real ON gravida_real.patient_id = inicio_real.patient_id
    LEFT JOIN (SELECT 
        e.patient_id,
            lv.data_ult_cv,
            lv.value_numeric AS ult_cv,
            lv.data_penult_cv,
            o.value_numeric AS penult_cv
    FROM
        encounter e
    LEFT JOIN (SELECT 
        e.patient_id,
            MAX(e.encounter_datetime) AS data_penult_cv,
            last_viral_load.data_ult_cv,
            last_viral_load.value_numeric
    FROM
        encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    LEFT JOIN (SELECT 
        e.patient_id,
            e.encounter_datetime AS data_ult_cv,
            o.value_numeric
    FROM
        encounter e
    INNER JOIN (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_cv
    FROM
        encounter e
    WHERE
        e.encounter_type IN (6 , 9, 13, 53)
            AND e.voided = 0
    GROUP BY patient_id) ult_cv ON ult_cv.patient_id = e.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 13, 53)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 856
            AND e.encounter_datetime = ult_cv.data_cv
            AND e.location_id = :location
    GROUP BY patient_id) last_viral_load ON last_viral_load.patient_id = e.patient_id
    WHERE
        e.encounter_type IN (6 , 9, 13, 53)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 856
            AND e.encounter_datetime < last_viral_load.data_ult_cv
            AND e.location_id = :location
    GROUP BY e.patient_id) lv ON lv.patient_id = e.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 13, 53)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 856
            AND e.encounter_datetime = lv.data_penult_cv
            AND e.location_id = :location
    GROUP BY patient_id) falencia_cv ON falencia_cv.patient_id = inicio_real.patient_id
    INNER JOIN (SELECT 
        lastvis.patient_id,
            lastvis.value_datetime,
            lastvis.encounter_type
    FROM
        (SELECT 
        p.patient_id,
            MAX(o.value_datetime) AS value_datetime,
            e.encounter_type
    FROM
        encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    INNER JOIN patient p ON p.patient_id = e.patient_id
    WHERE
        e.voided = 0 AND p.voided = 0
            AND o.voided = 0
            AND e.encounter_type IN (6 , 9, 18)
            AND o.concept_id IN (5096 , 1410)
            AND e.location_id = :location
            AND e.encounter_datetime <= :endDate
            AND o.value_datetime IS NOT NULL
    GROUP BY p.patient_id) lastvis) visita ON visita.patient_id = inicio_real.patient_id
        AND DATEDIFF(:endDate, visita.value_datetime) <= 28
    LEFT JOIN (SELECT 
        e.patient_id, o.value_numeric, e.encounter_datetime
    FROM
        encounter e
    INNER JOIN (SELECT 
        cd4_max.patient_id,
            MAX(cd4_max.encounter_datetime) AS encounter_datetime
    FROM
        (SELECT 
        e.patient_id, o.value_numeric, encounter_datetime
    FROM
        encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.voided = 0
            AND e.location_id = :location
            AND o.voided = 0
            AND o.concept_id = 1695
            AND e.encounter_type IN (6 , 9, 53) UNION ALL SELECT 
        e.patient_id, o.value_numeric, encounter_datetime
    FROM
        encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.voided = 0
            AND e.location_id = :location
            AND o.voided = 0
            AND o.concept_id = 5497
            AND e.encounter_type = 13) cd4_max
    GROUP BY patient_id) cd4_temp ON e.patient_id = cd4_temp.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_datetime = cd4_temp.encounter_datetime
            AND e.voided = 0
            AND e.location_id = :location
            AND o.voided = 0
            AND o.concept_id IN (1695 , 5497)
            AND e.encounter_type IN (6 , 9, 13, 53)
    GROUP BY patient_id) cd4 ON cd4.patient_id = inicio_real.patient_id
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
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
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
        e.encounter_type IN (6 , 9, 13)
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
    GROUP BY patient_id) ult_linhat
    INNER JOIN encounter e ON e.patient_id = ult_linhat.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type IN (6 , 9, 53)
            AND ult_linhat.data_ult_linhat = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23952
    GROUP BY patient_id) tb_crag ON tb_crag.patient_id = inicio_real.patient_id
    LEFT JOIN (SELECT 
        e.patient_id,
            CASE o.value_coded
                WHEN 1705 THEN 'REINICIO'
                ELSE ''
            END AS estado_permanencia,
            encounter_datetime AS data_consulta
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
            AND p.value IS NOT NULL
            AND p.value <> ''
            AND p.voided = 0) telef ON telef.person_id = inicio_real.patient_id
    WHERE
        data_inicio BETWEEN :startDate AND :endDate
            OR data_gravida IS NOT NULL
            OR (ult_cv > 1000 AND penult_cv > 1000)
            OR resul_tb_lam IS NOT NULL
            OR resul_tb_crag IS NOT NULL
            OR permanencia.estado_permanencia = 'REINICIO') activos
WHERE
    patient_id NOT IN (SELECT 
            pg.patient_id
        FROM
            patient p
                INNER JOIN
            patient_program pg ON p.patient_id = pg.patient_id
                INNER JOIN
            patient_state ps ON pg.patient_program_id = ps.patient_program_id
        WHERE
            pg.voided = 0 AND ps.voided = 0
                AND p.voided = 0
                AND pg.program_id = 2
                AND ps.state IN (7 , 8, 9, 10)
                AND ps.end_date IS NULL
                AND location_id = :location
                AND ps.start_date <= :endDate)
GROUP BY patient_id
