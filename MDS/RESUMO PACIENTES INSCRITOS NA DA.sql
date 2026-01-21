SELECT 	indicador_1.us,
               indicador_1.inscritos_periodo,
                indicador_2.activos_da_cv,
                indicador_3.activos_ds_cv,
                indicador_4.activos_dt_cv,
                indicador_6.activos_dm_cv,
                indicador_7.transferidos_para,
                indicador_8.obitos,
                indicador_9.abandonos

FROM ( SELECT :location AS us,
             SUM(CASE WHEN p.person_id is not null  THEN 1 ELSE 0 END) inscritos_periodo

      FROM (
 /************************************************************   Inscrito  na Ficha FC  e APSS ****************************************************************/
               select mdc_fc_estado.patient_id,
                    min(mdc_fc_estado.data_modelo) as data_inscricao,
                    mdc_fc_estado.status           as estado
               from (select mdc.patient_id,
                            mdc.data_modelo as data_modelo,
                            st.status
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
                               INNER JOIN form f on f.form_id = e.form_id
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

                           ) mdc

                              inner join
                          (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 1256 THEN 'CASO NOVO'
                                      WHEN 1257 THEN 'MANTER'
                                      WHEN 1267 THEN 'COMPLETO'
                                      ELSE o.value_coded end AS status,
                                  min(encounter_datetime)    as data_status,
                                  o.obs_group_id             as obs_group_id

                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id in (165322)
                             and o.value_coded = 1256
                             AND o.location_id = :location
                           group by patient_id, status, o.obs_group_id) st on st.obs_group_id = mdc.obs_group_id and st.patient_id=mdc.patient_id
                     group by mdc.patient_id
                     order by mdc.patient_id, mdc.data_modelo desc) mdc_fc_estado
               group by mdc_fc_estado.patient_id ) novos_inscritos
               INNER JOIN person p ON p.person_id = novos_inscritos.patient_id
      ) indicador_1

INNER JOIN
 /********************************************************  Activos na DA,   * CV abaixo de 1000 cps  ********************************************************/
(

SELECT :location AS us,
             SUM(CASE WHEN  (cv.valor_ultima_carga is not null and  cv.valor_ultima_carga <1000 ) or ( cv.carga_viral_qualitativa is not null) THEN 1  else 0  END ) activos_da_cv

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                      mdc_fc_estado.status           as estado

               from (select mdc.patient_id,
                            mdc.data_modelo as data_modelo,
                            st.status,
                            st.data_status,
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
                               INNER JOIN form f on f.form_id = e.form_id
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
                      group by patient_id)  mdc_grouped_inicio group by mdc_grouped_inicio.patient_id) mdc

                              inner join
                          (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 1256 THEN 'CASO NOVO'
                                      WHEN 1257 THEN 'MANTER'
                                      WHEN 1267 THEN 'COMPLETO'
                                      ELSE o.value_coded end AS status,
                                  max(encounter_datetime)    as data_status,
                                  o.obs_group_id             as obs_group_id

                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165322
                             and o.value_coded in (1257)
                             AND o.location_id = :location
                           group by patient_id, status, o.obs_group_id) st on st.obs_group_id = mdc.obs_group_id and st.patient_id=mdc.patient_id
                     group by mdc.patient_id, mdc.data_modelo
                     order by mdc.patient_id, mdc.data_modelo desc) mdc_fc_estado


               group by mdc_fc_estado.patient_id) activos_da

                         /* ******************************** ultima carga viral  durante o periodo de  inscricao na DA*********** ******************************/
        INNER JOIN(
        SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                WHEN 165331 THEN 'MENOR QUE '
                WHEN 1304  THEN 'CARGA VIRAL SUPRIMIDA'
                WHEN 23814 THEN 'CARGA VIRAL INDETECTAVEL'
                ELSE concat('OUTRO - ',value_coded  )
                END  AS carga_viral_qualitativa,
              o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
				             AND  e.encounter_datetime between   :startDate and  :endDate
							GROUP BY patient_id
				) ult_cv  ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  activos_da.patient_id


)  indicador_2 ON indicador_2.us=indicador_1.us

INNER JOIN
/********************************************************  Activos na DS,   * CV abaixo de 1000 cps  *********************************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  (cv.valor_ultima_carga is not null and  cv.valor_ultima_carga <1000 ) or ( cv.carga_viral_qualitativa is not null) THEN 1  else 0  END ) activos_ds_cv

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                      mdc_fc_estado.status           as estado

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo as data_modelo,
                            st.status,
                            st.data_status,
                            mdc.form_name,
                            mdc.obs_group_id

                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 23888
                             AND o.location_id = :location
                             and e.encounter_datetime between :startDate and :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                         INNER JOIN

                         (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 1256 THEN 'CASO NOVO'
                                      WHEN 1257 THEN 'MANTER'
                                      WHEN 1267 THEN 'COMPLETO'
                                      ELSE o.value_coded end AS status,
                                  max(encounter_datetime)    as data_status,
                                  o.obs_group_id             as obs_group_id

                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165322
                             and o.value_coded in (1257)
                             AND o.location_id = :location
                           group by patient_id, status, o.obs_group_id) st on st.obs_group_id = mdc.obs_group_id and    st.patient_id=mdc.patient_id
                           group by mdc.patient_id, mdc.modelodf, mdc.data_modelo
                           order by mdc.patient_id, mdc.data_modelo desc) mdc_fc_estado

               group by mdc_fc_estado.patient_id ) activos_ds

                         /* ******************************** ultima carga viral  durante o periodo de  avaliacao - DS*********** ******************************/
        INNER JOIN(
        SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                WHEN 165331 THEN 'MENOR QUE '
                WHEN 1304  THEN 'CARGA VIRAL SUPRIMIDA'
                WHEN 23814 THEN 'CARGA VIRAL INDETECTAVEL'
                ELSE concat('OUTRO - ',value_coded  )
                END  AS carga_viral_qualitativa,
              o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
				             AND  e.encounter_datetime between   :startDate and  :endDate
							GROUP BY patient_id
				) ult_cv  ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  activos_ds.patient_id
               INNER JOIN person p ON p.person_id = activos_ds.patient_id

)  indicador_3 ON indicador_3.us=indicador_1.us



INNER JOIN
/********************************************************  Activos na DT,   * CV abaixo de 1000 cps  *********************************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  (cv.valor_ultima_carga is not null and  cv.valor_ultima_carga <1000 ) or ( cv.carga_viral_qualitativa is not null) THEN 1  else 0  END ) activos_dt_cv

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                      mdc_fc_estado.status           as estado

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo as data_modelo,
                            st.status,
                            st.data_status,
                            mdc.form_name,
                            mdc.obs_group_id

                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 23730
                             AND o.location_id = :location
                             and e.encounter_datetime between :startDate and :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                         INNER JOIN

                         (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 1256 THEN 'CASO NOVO'
                                      WHEN 1257 THEN 'MANTER'
                                      WHEN 1267 THEN 'COMPLETO'
                                      ELSE o.value_coded end AS status,
                                  max(encounter_datetime)    as data_status,
                                  o.obs_group_id             as obs_group_id

                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165322
                             and o.value_coded in (1257)
                             AND o.location_id = :location
                           group by patient_id, status, o.obs_group_id) st on st.obs_group_id = mdc.obs_group_id and    st.patient_id=mdc.patient_id
                           group by mdc.patient_id, mdc.modelodf, mdc.data_modelo
                           order by mdc.patient_id, mdc.data_modelo desc) mdc_fc_estado

               group by mdc_fc_estado.patient_id ) activos_dt

                         /* ******************************** ultima carga viral  durante o periodo de  avaliacao - DS*********** ******************************/
        INNER JOIN(
        SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                WHEN 165331 THEN 'MENOR QUE '
                WHEN 1304  THEN 'CARGA VIRAL SUPRIMIDA'
                WHEN 23814 THEN 'CARGA VIRAL INDETECTAVEL'
                ELSE concat('OUTRO - ',value_coded  )
                END  AS carga_viral_qualitativa,
              o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
				             AND  e.encounter_datetime between   :startDate and  :endDate
							GROUP BY patient_id
				) ult_cv  ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  activos_dt.patient_id
               INNER JOIN person p ON p.person_id = activos_dt.patient_id

)  indicador_4 ON indicador_4.us=indicador_1.us

INNER JOIN
/*****************************************************   Activos na DM/FLUXO RAPIDO,   * CV abaixo de 1000 cps  ******************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  (cv.valor_ultima_carga is not null and  cv.valor_ultima_carga <1000 ) or ( cv.carga_viral_qualitativa is not null) THEN 1  else 0  END ) activos_dm_cv

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                      mdc_fc_estado.status           as estado

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo as data_modelo,
                            st.status,
                            st.data_status,
                            mdc.form_name,
                            mdc.obs_group_id

                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 23729
                             AND o.location_id = :location
                             and e.encounter_datetime between :startDate and :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                         INNER JOIN

                         (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 1256 THEN 'CASO NOVO'
                                      WHEN 1257 THEN 'MANTER'
                                      WHEN 1267 THEN 'COMPLETO'
                                      ELSE o.value_coded end AS status,
                                  max(encounter_datetime)    as data_status,
                                  o.obs_group_id             as obs_group_id

                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165322
                             and o.value_coded in (1257)
                             AND o.location_id = :location
                           group by patient_id, status, o.obs_group_id) st on st.obs_group_id = mdc.obs_group_id  and    st.patient_id=mdc.patient_id
                           group by mdc.patient_id, mdc.modelodf, mdc.data_modelo
                           order by mdc.patient_id, mdc.data_modelo desc) mdc_fc_estado

               group by mdc_fc_estado.patient_id ) activos_dm

                         /* ******************************** ultima carga viral  durante o periodo de  avaliacao - DS*********** ******************************/
        INNER JOIN(
        SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                WHEN 165331 THEN 'MENOR QUE '
                WHEN 1304  THEN 'CARGA VIRAL SUPRIMIDA'
                WHEN 23814 THEN 'CARGA VIRAL INDETECTAVEL'
                ELSE concat('OUTRO - ',value_coded  )
                END  AS carga_viral_qualitativa,
              o.comments as valor_comment,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga
                FROM  encounter e
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305)
				             AND  e.encounter_datetime between   :startDate and  :endDate
							GROUP BY patient_id
				) ult_cv  ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                 WHERE e.encounter_datetime=ult_cv.data_cv
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,51,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) /* AND  e.encounter_datetime <= :endDate */
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  activos_dm.patient_id
               INNER JOIN person p ON p.person_id = activos_dm.patient_id

)  indicador_6 ON indicador_6.us=indicador_1.us

INNER JOIN
/*************************************************************  6. Transferidos para         *******************************************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  transf_para.patient_id is not null  THEN 1  else 0  END ) transferidos_para

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo as data_modelo

                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 165314
                             AND o.location_id = :location
                             and e.encounter_datetime   <=  :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                     group by mdc.patient_id
                   ) mdc_fc_estado


               group by mdc_fc_estado.patient_id) activos_da

                         /* ******************************** Saida TARV: 'TRANSFERIDO PARA' ********** ******************************/
        INNER JOIN(
			SELECT  patient_id, max(encounter_datetime) AS data_saida, motivo_saida FROM (
      -- 'TRANSFERIDO PARA'  programa TARV-TRATAMENTO ( Panel do Paciente)
			SELECT 	pg.patient_id,
			           ps.start_date as encounter_datetime,
			                               'TRANSFERIDO PARA' AS motivo_saida
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=2 AND    location_id=:location		 and ps.start_date between :startDate and :endDate
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date

			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=2 AND ps.state =7  AND   location_id= :location AND   ps.start_date between :startDate and :endDate
					GROUP BY pg.patient_id
		    UNION ALL
           -- Pacientes que sairam do programa TARV-TRATAMENTO ( Ficha Mestra/Home Card Visit)
           SELECT  patient_id , encounter_datetime as data_saida, motivo_saida FROM (
            SELECT homevisit.patient_id,
                       homevisit.encounter_datetime,
					 CASE o.value_coded
					 WHEN 2005  THEN   'Esqueceu a Data'
					 WHEN 2006  THEN   'Esta doente'
					 WHEN 2007  THEN   'Problema de transporte'
					 WHEN 2010  THEN   'Mau atendimento na US'
					 WHEN 23915 THEN   'Medo do provedor de saude na US'
					 WHEN 23946 THEN   'Ausencia do provedor na US'
					 WHEN 2015  THEN   'Efeitos Secundarios'
					 WHEN 2013  THEN   'Tratamento Tradicional'
					 WHEN 1706  THEN   'Transferido para outra US'
					 WHEN 23863 THEN   'AUTO Transferencia'
					 WHEN 2017  THEN   'OUTRO'
					 END AS motivo_saida
					 FROM 	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type=21  AND e.location_id=:location AND
								e.encounter_datetime between :startDate and :endDate
						GROUP BY e.patient_id
					) homevisit
					INNER JOIN encounter e ON e.patient_id=homevisit.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id =2016  AND o.value_coded IN (1706,23863) AND o.voided=0 AND p.voided =0 AND e.voided=0 AND e.encounter_datetime=homevisit.encounter_datetime AND
					e.encounter_type =21 AND e.location_id=:location

             UNION ALL
             SELECT master_card.patient_id,master_card.encounter_datetime,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US'
					 WHEN 1366 THEN 'Obito'
					 END AS motivo_saida
					 FROM	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE  e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND
						       o.concept_id  =6273  AND o.value_coded = 1706 AND
								e.encounter_datetime between :startDate and :endDate
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  =6273  AND o.value_coded = 1706 AND o.voided=0 AND p.voided =0  AND e.voided=0
					AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id ) transfered_out ) all_transfered_out group by patient_id
		)  transf_para ON transf_para.patient_id =  activos_da.patient_id

)  indicador_7 ON indicador_7.us=indicador_1.us

INNER JOIN
/*************************************************************  OBITOS     *******************************************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  obito.patient_id is not null  THEN 1  else 0  END ) obitos

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                        mdc_fc_estado.modelodf

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo

                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 165314
                             AND o.location_id = :location
                             and e.encounter_datetime   <=  :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                           ) mdc_fc_estado


               group by mdc_fc_estado.patient_id) activos_da

                         /* ******************************** Saida TARV: 'OBITO' ********** ******************************/
        INNER JOIN(
			SELECT  patient_id, max(encounter_datetime) AS data_saida, motivo_saida
			FROM (
      -- ' OBITO'  programa TARV-TRATAMENTO ( Panel do Paciente)
			SELECT 	pg.patient_id,
			           ps.start_date as encounter_datetime,
			                               'OBITO' AS motivo_saida
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=2 AND    location_id=:location		 and ps.start_date between :startDate and :endDate
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date

			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=2 AND ps.state =10  AND   location_id= :location AND   ps.start_date between :startDate and :endDate
					GROUP BY pg.patient_id
             UNION ALL
             SELECT master_card.patient_id,master_card.encounter_datetime,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US'
					 WHEN 1366 THEN 'Obito'
					 END AS motivo_saida
					 FROM	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE  e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND
						       o.concept_id  =6273  AND o.value_coded = 1366 AND
								e.encounter_datetime between :startDate and :endDate
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  =6273  AND o.value_coded = 1366 AND o.voided=0 AND p.voided =0  AND e.voided=0
					AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id
            UNION ALL
		    /*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) encounter_datetime,
					'OBITO' AS motivo_saida
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366
			GROUP BY p.patient_id
				    ) transfered_out 	group by patient_id

		)  obito ON obito.patient_id =  activos_da.patient_id

)  indicador_8 ON indicador_8.us=indicador_1.us

INNER JOIN
/*************************************************************  ABANDONOS NOTIFICADOS     *******************************************************************/
(
SELECT :location AS us,
             SUM(CASE WHEN  abandono.patient_id is not null  THEN 1  else 0  END ) abandonos

      FROM (
               select mdc_fc_estado.patient_id,
                      max(mdc_fc_estado.data_modelo) as data_inscricao,
                      mdc_fc_estado.modelodf           as modelodf

               from (select mdc.patient_id,
                            mdc.modelodf,
                            mdc.data_modelo as data_modelo
                     from (SELECT e.patient_id,
                                  CASE o.value_coded
                                      WHEN 165314 THEN 'DISPENSA ANUAL DE ARV'
                                      WHEN 23729 THEN 'FLUXO RÁPIDO (FR)'
                                      WHEN 23888 THEN 'DISPENSA SEMESTRAL'
                                      WHEN 23730 THEN 'DISPENSA TRIMESTRAL (DT)'
                                      ELSE '' END         AS modelodf,
                                  f.name                  as form_name,
                                  max(encounter_datetime) as data_modelo,
                                  o.obs_group_id
                           FROM obs o
                                    INNER JOIN encounter e ON e.encounter_id = o.encounter_id
                                    INNER JOIN form f on f.form_id = e.form_id
                           WHERE e.encounter_type IN (6, 9, 34, 35)
                             AND e.voided = 0
                             AND o.voided = 0
                             AND o.concept_id = 165174
                             and o.value_coded = 165314
                             AND o.location_id = :location
                             and e.encounter_datetime   <=  :endDate
                           group by patient_id, modelodf, o.obs_group_id, f.name
                           order by patient_id, data_modelo DESC) mdc

                            ) mdc_fc_estado


               group by mdc_fc_estado.patient_id) activos_da

                         /* ******************************** Saida TARV: 'ABANDONOS' ********** ******************************/
        INNER JOIN(
			SELECT  patient_id, max(encounter_datetime) AS data_saida, motivo_saida
			FROM (
      -- ' ABANDONO'  programa TARV-TRATAMENTO ( Panel do Paciente)
			SELECT 	pg.patient_id,
			           ps.start_date as encounter_datetime,
			                               'ABANDONO' AS motivo_saida
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=2 AND    location_id=:location		 and ps.start_date between :startDate and :endDate
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date

			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=2 AND ps.state =9  AND   location_id= :location AND   ps.start_date between :startDate and :endDate
					GROUP BY pg.patient_id
             UNION ALL
             SELECT master_card.patient_id,master_card.encounter_datetime,
					 CASE o.value_coded
					 WHEN 1706 THEN 'Transferido para outra US'
					 WHEN 1707 THEN 'ABANDONO'
                     WHEN 1366 THEN 'Obito'
					 END AS motivo_saida
					 FROM	(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e
								INNER JOIN obs o  ON o.encounter_id=e.encounter_id
						WHERE  e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND e.location_id=:location AND
						       o.concept_id  =6273   AND o.value_coded = 1707
								AND e.encounter_datetime between :startDate and :endDate
						GROUP BY e.patient_id
					) master_card
					INNER JOIN encounter e ON e.patient_id=master_card.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p on p.patient_id=e.patient_id
					WHERE o.concept_id  =6273    AND o.value_coded = 1707
					  AND o.voided=0 AND p.voided =0  AND e.voided=0
					AND e.encounter_datetime=master_card.encounter_datetime AND
					e.encounter_type IN (6,9) AND e.location_id=:location
				    GROUP BY e.patient_id

				    ) abandonos 	group by patient_id

		)  abandono ON abandono.patient_id =  activos_da.patient_id

)  indicador_9 ON indicador_9.us=indicador_1.us
