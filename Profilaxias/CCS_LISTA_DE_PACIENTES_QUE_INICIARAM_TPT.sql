/*
Name: CCS LISTA DE PACIENTES QUE INICIARAM TPT
CriatedBy: Agnaldo Samuel
Description: CCS LISTA DE PACIENTES QUE INICIARAM TPT

 Pacientes com primeiro inicio de TPT no periodo informado.
   Parametros esperados:
   - :location  = unidade sanitaria
   - :startDate = data inicial do periodo
   - :endDate   = data final do periodo

 Nota:
   O Regime TPT (concept_id = 23985) pode estar registado nos encounters:
   - 6  = S.TARV: ADULTO SEGUIMENTO
   - 9  = S.TARV: PEDIATRIA SEGUIMENTO
   - 60 = Tratamento Profilatico da Tuberculose (TPT)
   - 53 = S.TARV: FICHA RESUMO

   O conceito usado para Estado TPT depende do tipo de encounter:
   - encontros 6 ,9 e 53 usam concept_id 165308 = Estado da profilaxia
   - encontro 60 usa concept_id 23987 = Seguimento de tratamento TPT

   A identificacao do inicio usa value_coded 1256 = Inicio/Iniciar,
   e seleciona o primeiro evento pela menor data.

   Para o encounter 53 (Ficha Resumo), a data clinica do TPT e lida de
   obs.obs_datetime no conceito 165308, porque o encounter_datetime
   corresponde apenas a data de registo da ficha.
*/

SELECT *
FROM (
    SELECT
        inicio_tpt.patient_id,
        inicio_tpt.data_tpt,
        inicio_tpt.estado,
        inicio_tpt.regime_tpt_nome,
        DATE_FORMAT(inicio_tarv.data_inicio, '%d/%m/%Y') AS data_inicio_tarv,
        DATE_FORMAT(seguimento.ultimo_seguimento, '%d/%m/%Y') AS data_ultimo_seguimento,
        DATE_FORMAT(ult_seguimento.value_datetime, '%d/%m/%Y') AS data_proximo_seguimento,
        pid.identifier AS NID,
        CONCAT(IFNULL(pn.given_name, ''), ' ', IFNULL(pn.middle_name, ''), ' ', IFNULL(pn.family_name, '')) AS nome,
        p.birthdate,
        TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) AS idade,
        saida.estado AS estado_saida
    FROM (
        SELECT
            e.patient_id,
            DATE_FORMAT(
                CASE
                    WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                    ELSE e.encounter_datetime
                END,
                '%d/%m/%Y'
            ) AS data_tpt,
            'Início' AS estado,
            e.encounter_type,
            e.encounter_id,
            estado_tpt.concept_id AS conceito_estado_tpt,
            regime.value_coded AS regime_tpt,
            CASE regime.value_coded
                WHEN 656 THEN 'Isoniazida'
                WHEN 23982 THEN 'Isoniazida + Piridoxina'
                WHEN 165306 THEN 'LFX'
                WHEN 23983 THEN 'Levofloxacina + Piridoxina'
                WHEN 23954 THEN '3HP'
                WHEN 23984 THEN '3HP + Piridoxina'
                WHEN 165305 THEN '1HP'
            END AS regime_tpt_nome
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
          AND e.encounter_type IN (6, 9,53, 60)
          AND e.location_id = :location
          AND (
              CASE
                  WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                  ELSE e.encounter_datetime
              END
          ) >= :startDate
          AND (
              CASE
                  WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                  ELSE e.encounter_datetime
              END
          ) < DATE_ADD(:endDate, INTERVAL 1 DAY)
          AND NOT EXISTS (
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
                    (e2.encounter_type IN (6, 9, 53) AND estado_tpt2.concept_id = 165308)
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
                ) >= :startDate
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
        ORDER BY
            CASE
                WHEN e.encounter_type = 53 AND estado_tpt.concept_id = 165308 THEN estado_tpt.obs_datetime
                ELSE e.encounter_datetime
            END,
            e.patient_id
    ) inicio_tpt
    LEFT JOIN (
        SELECT patient_id, MIN(data_inicio) AS data_inicio
        FROM (
            SELECT p.patient_id, MIN(e.encounter_datetime) AS data_inicio
            FROM patient p
            INNER JOIN encounter e
                ON p.patient_id = e.patient_id
            INNER JOIN obs o
                ON o.encounter_id = e.encounter_id
            WHERE e.voided = 0
              AND o.voided = 0
              AND p.voided = 0
              AND e.encounter_type IN (18, 6, 9)
              AND o.concept_id = 1255
              AND o.value_coded = 1256
              AND e.encounter_datetime <= :endDate
              AND e.location_id = :location
            GROUP BY p.patient_id

            UNION

            SELECT p.patient_id, MIN(value_datetime) AS data_inicio
            FROM patient p
            INNER JOIN encounter e
                ON p.patient_id = e.patient_id
            INNER JOIN obs o
                ON e.encounter_id = o.encounter_id
            WHERE p.voided = 0
              AND e.voided = 0
              AND o.voided = 0
              AND e.encounter_type IN (18, 6, 9, 53)
              AND o.concept_id = 1190
              AND o.value_datetime IS NOT NULL
              AND o.value_datetime <= :endDate
              AND e.location_id = :location
            GROUP BY p.patient_id

            UNION

            SELECT pg.patient_id, MIN(date_enrolled) AS data_inicio
            FROM patient p
            INNER JOIN patient_program pg
                ON p.patient_id = pg.patient_id
            WHERE pg.voided = 0
              AND p.voided = 0
              AND program_id = 2
              AND date_enrolled <= :endDate
              AND location_id = :location
            GROUP BY pg.patient_id
        ) inicio_real
        GROUP BY patient_id
    ) inicio_tarv
        ON inicio_tpt.patient_id = inicio_tarv.patient_id
    LEFT JOIN (
        SELECT p.patient_id, MAX(encounter_datetime) AS ultimo_seguimento
        FROM patient p
        INNER JOIN encounter e
            ON p.patient_id = e.patient_id
        WHERE e.voided = 0
          AND p.voided = 0
          AND e.encounter_type IN (6, 9)
          AND e.location_id = :location
        GROUP BY p.patient_id
    ) seguimento
        ON inicio_tpt.patient_id = seguimento.patient_id
    LEFT JOIN (
        SELECT ultimavisita.patient_id, ultimavisita.encounter_datetime, o.value_datetime, e.location_id, e.encounter_id
        FROM (
            SELECT p.patient_id, MAX(encounter_datetime) AS encounter_datetime
            FROM encounter e
            INNER JOIN patient p
                ON p.patient_id = e.patient_id
            WHERE e.voided = 0
              AND p.voided = 0
              AND e.encounter_type IN (9, 6)
            GROUP BY p.patient_id
        ) ultimavisita
        INNER JOIN encounter e
            ON e.patient_id = ultimavisita.patient_id
        INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
        WHERE o.concept_id = 1410
          AND o.voided = 0
          AND e.encounter_datetime = ultimavisita.encounter_datetime
          AND e.encounter_type IN (9, 6)
          AND e.location_id = :location
    ) ult_seguimento
        ON ult_seguimento.patient_id = inicio_tpt.patient_id
    LEFT JOIN (
        SELECT p.patient_id, MAX(encounter_datetime) AS ultimo_levantamneto
        FROM patient p
        INNER JOIN encounter e
            ON p.patient_id = e.patient_id
        WHERE e.voided = 0
          AND p.voided = 0
          AND e.voided = 0
          AND e.encounter_type = 18
          AND e.location_id = :location
        GROUP BY p.patient_id
    ) levantamento
        ON levantamento.patient_id = inicio_tpt.patient_id
    LEFT JOIN (
        SELECT ultimo_levantamento.patient_id, ultimo_levantamento.encounter_datetime, o.value_datetime, e.location_id, e.encounter_id
        FROM (
            SELECT p.patient_id, MAX(encounter_datetime) AS encounter_datetime
            FROM encounter e
            INNER JOIN patient p
                ON p.patient_id = e.patient_id
            WHERE e.voided = 0
              AND p.voided = 0
              AND e.encounter_type = 18
            GROUP BY p.patient_id
        ) ultimo_levantamento
        INNER JOIN encounter e
            ON e.patient_id = ultimo_levantamento.patient_id
        INNER JOIN obs o
            ON o.encounter_id = e.encounter_id
        WHERE o.concept_id = 5096
          AND o.voided = 0
          AND e.voided = 0
          AND e.encounter_datetime = ultimo_levantamento.encounter_datetime
          AND e.encounter_type = 18
          AND e.location_id = :location
          AND o.value_datetime IS NOT NULL
    ) proximo_levantamento
        ON proximo_levantamento.patient_id = inicio_tpt.patient_id
    LEFT JOIN (
        SELECT pid1.*
        FROM patient_identifier pid1
        INNER JOIN (
            SELECT patient_id, MIN(patient_identifier_id) AS id
            FROM patient_identifier
            WHERE voided = 0
            GROUP BY patient_id
        ) pid2
            ON pid1.patient_id = pid2.patient_id
           AND pid1.patient_identifier_id = pid2.id
    ) pid
        ON pid.patient_id = inicio_tpt.patient_id
    LEFT JOIN (
        SELECT pn1.*
        FROM person_name pn1
        INNER JOIN (
            SELECT person_id, MIN(person_name_id) AS id
            FROM person_name
            WHERE voided = 0
            GROUP BY person_id
        ) pn2
            ON pn1.person_id = pn2.person_id
           AND pn1.person_name_id = pn2.id
    ) pn
        ON pn.person_id = inicio_tpt.patient_id
    LEFT JOIN person p
        ON p.person_id = inicio_tpt.patient_id
    LEFT JOIN (
        SELECT
            pg.patient_id,
            ps.start_date AS encounter_datetime,
            location_id,
            CASE ps.state
                WHEN 7 THEN 'TRANSFERIDO PARA'
                WHEN 8 THEN 'SUSPENSO'
                WHEN 9 THEN 'ABANDONO'
                WHEN 10 THEN 'OBITO'
                ELSE 'OUTRO'
            END AS estado
        FROM patient p
        INNER JOIN patient_program pg
            ON p.patient_id = pg.patient_id
        INNER JOIN patient_state ps
            ON pg.patient_program_id = ps.patient_program_id
        WHERE pg.voided = 0
          AND ps.voided = 0
          AND p.voided = 0
          AND pg.program_id = 2
          AND ps.state IN (7, 8, 9, 10)
          AND ps.end_date IS NULL
          AND location_id = :location
          AND ps.start_date BETWEEN :startDate AND :endDate
    ) saida
        ON saida.patient_id = inicio_tpt.patient_id
) tpi
GROUP BY patient_id;
