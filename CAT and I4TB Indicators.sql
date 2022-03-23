SELECT 	indicador_1.us, new_0_14, new_15, consulta_pick_up_0_14, consulta_pick_up_15,
	new_0_14 + consulta_pick_up_0_14 AS new_0_14_consulta_pick_up_0_14, new_15 + consulta_pick_up_15 AS new_15_consulta_pick_up_15,
	SUM(CASE WHEN indicador_4.idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) tx_curr_0_14,  -- idade_actual
	SUM(CASE WHEN indicador_4.idade_actual > 14 THEN 1 ELSE 0 END) tx_curr_15,
	0_14_criancas_inicio_ttTB, `>14adultos_inicio_ttTB`,
	tb_not_tpt_0_14, tb_not_tpt_15,
	tb_in_tpt_0_14, tb_in_tpt_15,
	new_tarv_tb_0_14, new_tarv_tb_15,
	new_tarv_screen_0_14, new_tarv_screen_15,
	tx_curr_rastreio_0_14,  tx_curr_rastreio_15,
	txt_plhiv_tpt_0_14, txt_plhiv_tpt_15,
	txt_new_tpt_0_14, txt_new_tpt_15,
	txt_curr_tpt_0_14, txt_curr_tpt_15,
	txt_plhiv_3hp_tpt_0_14, txt_plhiv_3hp_tpt_15,
	txt_new_3hp_tpt_0_14, txt_new_3hp_tpt_15,
	txt_curr_tpt_3hp_0_14, txt_curr_tpt_3hp_15,
	txt_complete_tpt_0_14, txt_complete_tpt_15,
	txt_new_complete_tpt_0_14, txt_new_complete_tpt_15,
	txt_curr_tpt_complete_0_14, txt_curr_tpt_complete_15,
	txt_complete_3hp_tpt_0_14, txt_complete_3hp_tpt_15,
	txt_new_complete_3hp_tpt_0_14,txt_new_complete_3hp_tpt_15,
	txt_curr_tpt_complete_3hp_0_14, txt_curr_tpt_complete_3hp_15
FROM

(
SELECT :location AS us,  
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) new_0_14, -- idade_actual
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) new_15

FROM
(
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
	
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN person p ON p.person_id=inicio_real.patient_id
)
) indicador_1
INNER JOIN
-- ex: que tiveram consultas e receberam ARV
(
SELECT 	:location AS us, SUM(CASE WHEN idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) consulta_pick_up_0_14, -- idade_actual
	SUM(CASE WHEN idade_actual > 14 THEN 1 ELSE 0 END) consulta_pick_up_15
FROM
(
SELECT consulta.patient_id,data_consulta, data_pick_up, TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) AS idade_actual
FROM
(
	(	SELECT p.patient_id,(encounter_datetime) data_consulta
		FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
		WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
		GROUP BY p.patient_id
	) consulta
	INNER JOIN 
	(
		SELECT p.patient_id, (encounter_datetime) data_pick_up
		FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
		WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (18,52) AND e.encounter_datetime BETWEEN :startDate AND :endDate
		GROUP BY p.patient_id
	) pick_up ON pick_up.patient_id=consulta.patient_id AND data_consulta=data_pick_up
	INNER JOIN person p ON p.person_id=consulta.patient_id
)
)indicado_2
)indicador_2 ON indicador_1.us=indicador_2.us
INNER JOIN
-- Tx_Curr
(
	SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id		


WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id
) indicador_4 ON indicador_1.us=indicador_4.us
-- Tx_Curr Inicio TT Tb
INNER JOIN
(	
SELECT :location AS us, COUNT(*), 
	SUM(CASE WHEN idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS '0_14_criancas_inicio_ttTB',
	SUM(CASE WHEN idade_actual > 14 THEN 1 ELSE 0 END) AS '>14adultos_inicio_ttTB'
FROM
(
SELECT 	inicio_tb.patient_id,
	data_inicio_tb,
	pid.identifier NID,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual,
	IF(inscrito_programa.date_enrolled IS NULL,'NAO','SIM') inscrito_programa_tb

FROM
	(	SELECT patient_id,MAX(data_inicio_tb) data_inicio_tb
		FROM
		(	SELECT 	p.patient_id,o.value_datetime data_inicio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id=1113 AND o.value_datetime BETWEEN :startDate AND :endDate
			UNION
			
			SELECT 	patient_id,date_enrolled data_inicio_tb
			FROM 	patient_program
			WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN :startDate AND :endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

	LEFT JOIN patient_identifier pid ON pid.patient_id=inicio_tb.patient_id AND pid.identifier_type=2
	LEFT JOIN 
	(
		SELECT 	patient_id,date_enrolled
		FROM 	patient_program
		WHERE	program_id=5 AND voided=0 AND date_enrolled<=:endDate 
	) inscrito_programa ON inscrito_programa.patient_id=inicio_tb.patient_id
	LEFT JOIN person_address pe ON pe.person_id=inicio_tb.patient_id AND pe.preferred=1
	LEFT JOIN person_name pn ON pn.person_id=inicio_tb.patient_id AND pn.preferred=1
 ) inicioTB  
) indicador_5  ON indicador_2.us=indicador_1.us
-- Numero de pacientes em TARV que NÃO estão em TPT e que iniciaram tratamento de TB
INNER JOIN
(
	SELECT us,
	SUM(CASE WHEN idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'tb_not_tpt_0_14',
	SUM(CASE WHEN idade_actual > 14 THEN 1 ELSE 0 END) AS 'tb_not_tpt_15'
FROM
(
SELECT :location AS us, inicioTB.data_inicio_tb,data_inicio_tpi, idade_actual
FROM
(SELECT 	inicio_tb.patient_id,
	data_inicio_tb,
	pid.identifier NID,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual,
	IF(inscrito_programa.date_enrolled IS NULL,'NAO','SIM') inscrito_programa_tb

FROM
	(	SELECT patient_id,MAX(data_inicio_tb) data_inicio_tb
		FROM
		(	SELECT 	p.patient_id,o.value_datetime data_inicio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id=1113 AND o.value_datetime BETWEEN :startDate AND :endDate
			UNION
			
			SELECT 	patient_id,date_enrolled data_inicio_tb
			FROM 	patient_program
			WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN :startDate AND :endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

	LEFT JOIN patient_identifier pid ON pid.patient_id=inicio_tb.patient_id AND pid.identifier_type=2
	LEFT JOIN 
	(
		SELECT 	patient_id,date_enrolled
		FROM 	patient_program
		WHERE	program_id=5 AND voided=0 AND date_enrolled<=:endDate 
	) inscrito_programa ON inscrito_programa.patient_id=inicio_tb.patient_id
	LEFT JOIN person_address pe ON pe.person_id=inicio_tb.patient_id AND pe.preferred=1
	LEFT JOIN person_name pn ON pn.person_id=inicio_tb.patient_id AND pn.preferred=1
 ) inicioTB  
LEFT JOIN	

(	SELECT inicio_tpi.patient_id,MIN(inicio_tpi.data_inicio_tpi) data_inicio_tpi
	FROM 
	(	SELECT 	p.patient_id,MIN(o.value_datetime) data_inicio_tpi
		FROM	patient p
				INNER JOIN encounter e ON p.patient_id=e.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
		WHERE 	e.voided=0 AND p.voided=0 AND o.value_datetime <=:endDate AND
				o.voided=0 AND o.concept_id=6128 AND e.encounter_type IN (6,9,53) 
		GROUP BY p.patient_id
		
		UNION 
		
		SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio_tpi
		FROM	patient p
				INNER JOIN encounter e ON p.patient_id=e.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
		WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_datetime <=:endDate AND
				o.voided=0 AND o.concept_id=6122 AND o.value_coded=1256 AND e.encounter_type IN (6,9) 
		GROUP BY p.patient_id	
		
	) inicio_tpi
	GROUP BY inicio_tpi.patient_id
) inicio_tpi ON inicio_tpi.patient_id=inicioTB.patient_id 
)tb_not_tpt
WHERE data_inicio_tpi IS NULL
)indicador_6  ON indicador_6.us=indicador_1.us  

-- Numero de pacientes em TARV e em TPT que iniciaram tratamento de TB
INNER JOIN
(
	SELECT us,
	SUM(CASE WHEN idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'tb_in_tpt_0_14',
	SUM(CASE WHEN idade_actual > 14 THEN 1 ELSE 0 END) AS 'tb_in_tpt_15'
FROM
(
SELECT :location AS us, inicioTB.data_inicio_tb,data_inicio_tpi, idade_actual
FROM
(SELECT 	inicio_tb.patient_id,
	data_inicio_tb,
	pid.identifier NID,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual,
	IF(inscrito_programa.date_enrolled IS NULL,'NAO','SIM') inscrito_programa_tb

FROM
	(	SELECT patient_id,MAX(data_inicio_tb) data_inicio_tb
		FROM
		(	SELECT 	p.patient_id,o.value_datetime data_inicio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id=1113 AND o.value_datetime BETWEEN :startDate AND :endDate
			UNION
			
			SELECT 	patient_id,date_enrolled data_inicio_tb
			FROM 	patient_program
			WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN :startDate AND :endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

	LEFT JOIN patient_identifier pid ON pid.patient_id=inicio_tb.patient_id AND pid.identifier_type=2
	LEFT JOIN 
	(
		SELECT 	patient_id,date_enrolled
		FROM 	patient_program
		WHERE	program_id=5 AND voided=0 AND date_enrolled<=:endDate 
	) inscrito_programa ON inscrito_programa.patient_id=inicio_tb.patient_id
	LEFT JOIN person_address pe ON pe.person_id=inicio_tb.patient_id AND pe.preferred=1
	LEFT JOIN person_name pn ON pn.person_id=inicio_tb.patient_id AND pn.preferred=1
 ) inicioTB  
LEFT JOIN	

(	SELECT inicio_tpi.patient_id,MIN(inicio_tpi.data_inicio_tpi) data_inicio_tpi
	FROM 
	(	SELECT 	p.patient_id,MIN(o.value_datetime) data_inicio_tpi
		FROM	patient p
				INNER JOIN encounter e ON p.patient_id=e.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
		WHERE 	e.voided=0 AND p.voided=0 AND o.value_datetime <=:endDate AND
				o.voided=0 AND o.concept_id=6128 AND e.encounter_type IN (6,9,53) 
		GROUP BY p.patient_id
		
		UNION 
		
		SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio_tpi
		FROM	patient p
				INNER JOIN encounter e ON p.patient_id=e.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
		WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_datetime <=:endDate AND
				o.voided=0 AND o.concept_id=6122 AND o.value_coded=1256 AND e.encounter_type IN (6,9) 
		GROUP BY p.patient_id	
		
	) inicio_tpi
	GROUP BY inicio_tpi.patient_id
) inicio_tpi ON inicio_tpi.patient_id=inicioTB.patient_id 
)tb_in_tpt
WHERE NOT data_inicio_tpi IS NULL
)indicador_7  ON indicador_7.us=indicador_1.us

-- Numero de novos pacientes em TARV que iniciaram tratamento de TB 
INNER JOIN
(
	SELECT us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,new_tarv_tb.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'new_tarv_tb_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,new_tarv_tb.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'new_tarv_tb_15'
FROM
(
SELECT :location AS us, data_inicio, data_inicio_tb, p.birthdate
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN person p ON p.person_id=inicio_real.patient_id
INNER JOIN
(SELECT 	inicio_tb.patient_id,
	data_inicio_tb,
	pid.identifier NID,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual,
	IF(inscrito_programa.date_enrolled IS NULL,'NAO','SIM') inscrito_programa_tb

FROM
	(	SELECT patient_id,MAX(data_inicio_tb) data_inicio_tb
		FROM
		(	SELECT 	p.patient_id,o.value_datetime data_inicio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id=1113 AND o.value_datetime BETWEEN :startDate AND :endDate
			UNION
			
			SELECT 	patient_id,date_enrolled data_inicio_tb
			FROM 	patient_program
			WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN :startDate AND :endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

	LEFT JOIN patient_identifier pid ON pid.patient_id=inicio_tb.patient_id AND pid.identifier_type=2
	LEFT JOIN 
	(
		SELECT 	patient_id,date_enrolled
		FROM 	patient_program
		WHERE	program_id=5 AND voided=0 AND date_enrolled<=:endDate 
	) inscrito_programa ON inscrito_programa.patient_id=inicio_tb.patient_id
	LEFT JOIN person_address pe ON pe.person_id=inicio_tb.patient_id AND pe.preferred=1
	LEFT JOIN person_name pn ON pn.person_id=inicio_tb.patient_id AND pn.preferred=1
 ) inicioTB ON inicioTB.patient_id=inicio_real.patient_id
 )new_tarv_tb
)indicador_8  ON indicador_8.us=indicador_1.us

-- Numero de novos pacientes em TARV que foram rastreiados para TB 
INNER JOIN
(
	SELECT us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,new_tarv_rastreio.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'new_tarv_screen_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,new_tarv_rastreio.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'new_tarv_screen_15'
FROM
(
SELECT :location AS us, data_inicio, data_rastreio_tb, p.birthdate
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN person p ON p.person_id=inicio_real.patient_id
INNER JOIN
(SELECT  inicio_tb.patient_id, data_rastreio_tb,
	
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual
FROM
	(	SELECT patient_id,MAX(data_rastreio_tb) data_rastreio_tb
		FROM
		(	SELECT 	p.patient_id,o.obs_datetime data_rastreio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9, 53) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id IN (6257,23758)  AND o.obs_datetime BETWEEN :startDate AND :endDate
			-- UNION
			
			-- SELECT 	patient_id,date_enrolled data_inicio_tb
			-- FROM 	patient_program
			-- WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN startDate AND endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

 ) rastreioTB ON rastreioTB.patient_id=inicio_real.patient_id
 )new_tarv_rastreio
)indicador_9  ON indicador_8.us=indicador_1.us

INNER JOIN
-- Tx_Curr que fizeram screaning tb durante o periodo
(
SELECT 	us, 
	SUM(CASE WHEN tx_curr.idade_actual BETWEEN 0 AND 14 THEN 1 ELSE 0 END) tx_curr_rastreio_0_14,  -- idade_actual
	SUM(CASE WHEN tx_curr.idade_actual > 14 THEN 1 ELSE 0 END) tx_curr_rastreio_15
FROM
(
	SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id
WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id
) tx_curr
INNER JOIN
(SELECT  inicio_tb.patient_id, data_rastreio_tb,
	
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual
FROM
	(	SELECT patient_id,MAX(data_rastreio_tb) data_rastreio_tb
		FROM
		(	SELECT 	p.patient_id,o.obs_datetime data_rastreio_tb
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9, 53) AND e.voided=0 AND o.voided=0 AND p.voided=0 AND
					o.concept_id IN (6257,23758)   AND o.obs_datetime BETWEEN :startDate AND :endDate
			-- UNION
			
			-- SELECT 	patient_id,date_enrolled data_inicio_tb
			-- FROM 	patient_program
			-- WHERE	program_id=5 AND voided=0 AND date_enrolled BETWEEN startDate AND endDate 
		) inicio1
		GROUP BY patient_id
	) inicio_tb 
	INNER JOIN person p ON p.person_id=inicio_tb.patient_id

 ) rastreioTB ON rastreioTB.patient_id=tx_curr.patient_id
 
) indicador_10 ON indicador_1.us=indicador_10.us
-- Pessoas que iniciaram qualquer tratamento de TPT durante o mes (Verificar se sao activos no periodo) PLHIV
INNER JOIN
(
SELECT :location AS us, 
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_plhiv_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_plhiv_tpt_15'
FROM
	(
	select inicio_tpt.patient_id,min(inicio_tpt.data_inicio_tpt) data_tx_new_tpt
	from 
	(	select 	p.patient_id,min(o.value_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9,53) and e.location_id=:location
		group by p.patient_id
		
		union 
		
		select 	p.patient_id,min(e.encounter_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1256 and e.encounter_type in (6,9,60) and  e.location_id=:location
		group by p.patient_id
	) inicio_tpt
	group by inicio_tpt.patient_id 
	) tx_new_tpt -- ON pick_up.patient_id=consulta.patient_id AND data_consulta=data_pick_up
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
) indicador_11 ON indicador_1.us=indicador_11.us
INNER JOIN
-- Tx_New que iniciaram qualquer TPT no Periodo
(
SELECT :location AS us,
		SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_new_tpt_0_14',
		SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_new_tpt_15'
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN	
	(
	
	select inicio_tpt.patient_id,min(inicio_tpt.data_inicio_tpt) data_tx_new_tpt
	from 
	(	select 	p.patient_id,min(o.value_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9,53) and e.location_id=:location
		group by p.patient_id
		
		union 
		
		select 	p.patient_id,min(e.encounter_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308)and o.value_coded=1256 and e.encounter_type in (6,9,60) and  e.location_id=:location
		group by p.patient_id
	) inicio_tpt
	group by inicio_tpt.patient_id
	) tx_new_tpt ON tx_new_tpt.patient_id=inicio_real.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
)indicador_12 ON indicador_1.us=indicador_12.us

-- tx_curr que iniciacao TGPT
INNER JOIN
(SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_15'
FROM
(
		SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id
WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id

)tx_curr
INNER JOIN   -- Qualquer inicio TPT
	(
	select inicio_tpt.patient_id,min(inicio_tpt.data_inicio_tpt) data_tx_new_tpt
	from 
	(	select 	p.patient_id,min(o.value_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9,53) and e.location_id=:location
		group by p.patient_id
		
		union 
		
		select 	p.patient_id,min(e.encounter_datetime) data_inicio_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1256 and e.encounter_type in (6,9,60) and  e.location_id=:location
		group by p.patient_id
	) inicio_tpt
	group by inicio_tpt.patient_id
	) tx_new_tpt ON tx_new_tpt.patient_id=tx_curr.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
)indicador_13 ON indicador_1.us=indicador_13.us

-- PVHIV que iniciaram TPT com 3HP
INNER JOIN
(
SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_plhiv_3hp_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_plhiv_3hp_tpt_15'
FROM
	(
  select inicio_3hp.patient_id,inicio_3hp.data_tx_new_3hp as data_tx_new_tpt
	from 
	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
	) registo_3hp 
    inner join 
    	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id in (165308,23987) AND o.value_coded =1256 -- inicio 
	        GROUP BY p.patient_id
	     ) inicio_3hp on  inicio_3hp.patient_id =registo_3hp.patient_id
      
     where inicio_3hp.data_tx_new_3hp =registo_3hp.data_tx_new_reg_3hp 
     
	
    
    
	) tx_new_tpt -- ON tx_new_tpt.patient_id=tx_curr.patient_id  AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
)indicador_14 ON indicador_1.us=indicador_14.us

-- TX_NEW que iniciaram TPT com 3HP
INNER JOIN
(
	SELECT :location AS us,
		SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_new_3hp_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_new_3hp_tpt_15'
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN	
	(
	
select inicio_3hp.patient_id,inicio_3hp.data_tx_new_3hp as data_tx_new_tpt
	from 
	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
	) registo_3hp 
    inner join 
    	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id in (165308,23987) AND o.value_coded =1256 -- inicio 
	        GROUP BY p.patient_id
	     ) inicio_3hp on  inicio_3hp.patient_id =registo_3hp.patient_id
      
     where inicio_3hp.data_tx_new_3hp =registo_3hp.data_tx_new_reg_3hp 
     
	) tx_new_tpt ON tx_new_tpt.patient_id=inicio_real.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id

)indicador_15 ON indicador_1.us=indicador_15.us

-- Number of established ART patients initiated on TPT- 3HP
INNER JOIN
(
	SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_3hp_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_3hp_15'
FROM
(
		SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id
WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id

)tx_curr
INNER JOIN
	(
		
select inicio_3hp.patient_id,inicio_3hp.data_tx_new_3hp as data_tx_new_tpt
	from 
	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
	) registo_3hp 
    inner join 
    	(	SELECT p.patient_id, min(encounter_datetime) data_tx_new_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9,60) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id in (165308,23987) AND o.value_coded =1256 -- inicio 
	        GROUP BY p.patient_id
	     ) inicio_3hp on  inicio_3hp.patient_id =registo_3hp.patient_id
      
     where inicio_3hp.data_tx_new_3hp =registo_3hp.data_tx_new_reg_3hp 
     
	) tx_new_tpt ON tx_new_tpt.patient_id=tx_curr.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id

	
)indicador_16 ON indicador_1.us=indicador_16.us
-- PLHIV (15+) completing TPT- any (e.g. IPT, 3HP, 3RH, etc.) 
INNER JOIN
(
SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_complete_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_complete_tpt_15'
FROM
	(
		select fim_tpt.patient_id,max(fim_tpt.data_fim_tpt) data_tx_new_tpt  -- Completaram TPT no FILT ou FC
	from 
	(			
		select 	p.patient_id,max(e.encounter_datetime) data_fim_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1267 and e.encounter_type in (6,9,53,60) and  e.location_id=:location
		group by p.patient_id )  fim_tpt group by patient_id
	) tx_new_tpt -- ON tx_new_tpt.patient_id=tx_curr.patient_id  AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
) indicador_17 ON indicador_1.us=indicador_17.us
-- Number of new ART patients completing TPT - any (e.g. IPT, 3HP, 3RH, etc)
INNER JOIN
(
		SELECT :location AS us,
		SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_new_complete_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_new_complete_tpt_15'
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN	 -- Completaram TPT no FILT ou FC
	(
select fim_tpt.patient_id,max(fim_tpt.data_fim_tpt) data_tx_new_tpt
	from 
	(			
		select 	p.patient_id,max(e.encounter_datetime) data_fim_tpt
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1267 and e.encounter_type in (6,9,53,60) and  e.location_id=:location
		group by p.patient_id )  fim_tpt group by patient_id
	) tx_new_tpt ON tx_new_tpt.patient_id=inicio_real.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id

)indicador_18 ON indicador_1.us=indicador_18.us

-- Number of established ART patients completing TPT- any (e.g. IPT, 3HP, 3RH, etc)
INNER JOIN
(
		SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_complete_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_complete_15'
FROM
(
		SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id
WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id

)tx_curr
INNER JOIN
	(
select fim_tpt.patient_id,max(fim_tpt.data_fim_tpt) data_tx_new_tpt  -- Completaram TPT no FILT ou FC
	from 
	(			
		select 	p.patient_id,max(e.encounter_datetime) data_fim_tpt  
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id in (6122,23987,165308) and o.value_coded=1267 and e.encounter_type in (6,9,53,60) and  e.location_id=:location
		group by p.patient_id )  fim_tpt group by patient_id
	) tx_new_tpt ON tx_new_tpt.patient_id=tx_curr.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id	

)indicador_19 ON indicador_1.us=indicador_19.us

-- PLHIV (15+) completing TPT- 3HP  /////////////Por reverificar
INNER JOIN
(
	SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_complete_3hp_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_complete_3hp_tpt_15'
FROM
	(


/*** Patients who completed 3HP Therapy - CDC  TFR7 on TPT Completition Cascade ***/
select patient_id, ultima_cons_3hp as data_tx_new_tpt
from 
(
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, total_consultas_3hp.total as total_consultas_3hp ,ult_visit_3hp.ultima_cons_3hp,
 datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 as duration
 from 

   (


select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 
(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded =1256 -- Inicio 
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp

)  inicio_real_3hp

left join(  -- todas as consultas com prescricao 3HP

 SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  total_consultas_3hp on total_consultas_3hp.patient_id =inicio_real_3hp.patient_id 

left join(  -- ultima visita com prescricao 3HP no periodo

 SELECT p.patient_id, max(encounter_datetime) as ultima_cons_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  ult_visit_3hp on ult_visit_3hp.patient_id =inicio_real_3hp.patient_id 

 where datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 >= 4 and total_consultas_3hp.total >=3
) criterio1 

--   segundo criterio

union all


select 

patient_id, data_inicio_3hp as data_tx_new_tpt

from (
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, if( tpt_dispensa_tr.data_3hp_trim is not null ,1,data_3hp_trim)  as tpt_trimestral ,  DATE_FORMAT(duracao_trat_3hp.data_min_3hp_mensal,'%d/%m/%Y') as data_min_3hp_mensal ,
 DATE_FORMAT(duracao_trat_3hp.data_max_3hp_mensal,'%d/%m/%Y') as data_max_3hp_mensal ,tpt_dispensa_men.total as total_mensal,
duracao_trat_3hp.duracao from 
( select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type = 60  AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 

(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded in (1256,1705)  -- Inicio /reinicio
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp
)  inicio_real_3hp


left join (  -- Tipo dispensa 3hp trimestral

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, min(encounter_datetime) data_3hp_trim
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =23720 -- Trimestral 
	GROUP BY p.patient_id
  
) tpt_dispensa_tr on tpt_dispensa_tr.patient_id =inicio_real_3hp.patient_id  and tpt_dispensa_tr.data_3hp_trim = inicio_real_3hp.data_inicio_3hp


left join (  -- Tipo dispensa 3hp mensal

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
  
) tpt_dispensa_men on tpt_dispensa_men.patient_id =inicio_real_3hp.patient_id

left join (  -- Tipo dispensa 3hp mensal
select min_3hp_mensal.patient_id, min_3hp_mensal.data_min_3hp_mensal, max_3hp_mensal.data_max_3hp_mensal, datediff( max_3hp_mensal.data_max_3hp_mensal,min_3hp_mensal.data_min_3hp_mensal) as duracao

from (
SELECT p.patient_id, min(encounter_datetime) data_min_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) min_3hp_mensal
    left join 
     (
SELECT p.patient_id, max(encounter_datetime) data_max_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) max_3hp_mensal on max_3hp_mensal.patient_id = min_3hp_mensal.patient_id
  
) duracao_trat_3hp on duracao_trat_3hp.patient_id =inicio_real_3hp.patient_id


) criterio2 where tpt_trimestral =1 or total_mensal >=4 and duracao <= 120
	) tx_new_tpt -- ON tx_new_tpt.patient_id=tx_curr.patient_id  AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id
)indicador_20 ON indicador_1.us=indicador_20.us

-- Number of new ART patients completing TPT- 3HP
INNER JOIN
(
			SELECT :location AS us,
		SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_new_complete_3hp_tpt_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_new_complete_3hp_tpt_15'
FROM
(SELECT patient_id,data_inicio
FROM
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(/*Patients on ART who initiated the ARV DRUGS ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate 
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
						  GROUP BY 	p.patient_id
					  
						UNION
						
						/*Patients with first drugs pick up date set Recepcao Levantou ARV*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate 
						GROUP BY p.patient_id		
					
				
				
			) inicio
		GROUP BY patient_id	
	)inicio1
WHERE data_inicio BETWEEN :startDate AND :endDate
)inicio_real
INNER JOIN	
	(
	

/*** Patients who completed 3HP Therapy - CDC  TFR7 on TPT Completition Cascade ***/
select patient_id, ultima_cons_3hp as data_tx_new_tpt
from 
(
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, total_consultas_3hp.total as total_consultas_3hp ,ult_visit_3hp.ultima_cons_3hp,
 datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 as duration
 from 

   (


select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 
(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded =1256 -- Inicio 
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp

)  inicio_real_3hp

left join(  -- todas as consultas com prescricao 3HP

 SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  total_consultas_3hp on total_consultas_3hp.patient_id =inicio_real_3hp.patient_id 

left join(  -- ultima visita com prescricao 3HP no periodo

 SELECT p.patient_id, max(encounter_datetime) as ultima_cons_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  ult_visit_3hp on ult_visit_3hp.patient_id =inicio_real_3hp.patient_id 

 where datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 >= 4 and total_consultas_3hp.total >=3
) criterio1 

--   segundo criterio

union all


select 

patient_id, data_inicio_3hp as data_tx_new_tpt

from (
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, if( tpt_dispensa_tr.data_3hp_trim is not null ,1,data_3hp_trim)  as tpt_trimestral ,  DATE_FORMAT(duracao_trat_3hp.data_min_3hp_mensal,'%d/%m/%Y') as data_min_3hp_mensal ,
 DATE_FORMAT(duracao_trat_3hp.data_max_3hp_mensal,'%d/%m/%Y') as data_max_3hp_mensal ,tpt_dispensa_men.total as total_mensal,
duracao_trat_3hp.duracao from 
( select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type = 60  AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 

(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded in (1256,1705)  -- Inicio /reinicio
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp
)  inicio_real_3hp


left join (  -- Tipo dispensa 3hp trimestral

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, min(encounter_datetime) data_3hp_trim
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =23720 -- Trimestral 
	GROUP BY p.patient_id
  
) tpt_dispensa_tr on tpt_dispensa_tr.patient_id =inicio_real_3hp.patient_id  and tpt_dispensa_tr.data_3hp_trim = inicio_real_3hp.data_inicio_3hp


left join (  -- Tipo dispensa 3hp mensal

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
  
) tpt_dispensa_men on tpt_dispensa_men.patient_id =inicio_real_3hp.patient_id

left join (  -- Tipo dispensa 3hp mensal
select min_3hp_mensal.patient_id, min_3hp_mensal.data_min_3hp_mensal, max_3hp_mensal.data_max_3hp_mensal, datediff( max_3hp_mensal.data_max_3hp_mensal,min_3hp_mensal.data_min_3hp_mensal) as duracao

from (
SELECT p.patient_id, min(encounter_datetime) data_min_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) min_3hp_mensal
    left join 
     (
SELECT p.patient_id, max(encounter_datetime) data_max_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) max_3hp_mensal on max_3hp_mensal.patient_id = min_3hp_mensal.patient_id
  
) duracao_trat_3hp on duracao_trat_3hp.patient_id =inicio_real_3hp.patient_id


) criterio2 where tpt_trimestral =1 or total_mensal >=4 and duracao <= 120
		
	) tx_new_tpt ON tx_new_tpt.patient_id=inicio_real.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id

)indicador_21 ON indicador_1.us=indicador_21.us

-- Number of established ART patients completing TPT- 3HP
INNER JOIN
(
			SELECT :location AS us,
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) BETWEEN 0 AND 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_complete_3hp_0_14',
	SUM(CASE WHEN TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) > 14 THEN 1 ELSE 0 END) AS 'txt_curr_tpt_complete_3hp_15'
FROM
(
		SELECT 	:location AS us,coorte12meses_final.patient_id,
	coorte12meses_final.data_inicio,
	TIMESTAMPDIFF(YEAR,p.birthdate,:endDate) idade_actual	
FROM

(SELECT   	inicio_fila_seg_prox.*,
		data_seguimento ultima_consulta,
		data_fila data_usar_c,
		data_proximo_lev data_usar
FROM

(SELECT 	inicio_fila_seg.*,
		MAX(obs_fila.value_datetime) data_proximo_lev,
		MAX(obs_seguimento.value_datetime) data_proximo_seguimento,
		DATE_ADD(data_recepcao_levantou, INTERVAL 30 DAY) data_recepcao_levantou30	
FROM

(SELECT inicio.*,		
		saida.data_estado,		
		max_fila.data_fila,
		max_consulta.data_seguimento,
		max_recepcao.data_recepcao_levantou		
FROM

(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(									
				SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
				FROM 	patient p 
						INNER JOIN encounter e ON p.patient_id=e.patient_id	
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
						e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
						e.encounter_datetime<=:endDate 
				GROUP BY p.patient_id
		
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
						o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

				UNION

				SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
				FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
				WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate 
				GROUP BY pg.patient_id
				
				UNION

				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
				  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate 
				  GROUP BY 	p.patient_id
			  
				UNION

				SELECT 	p.patient_id,MIN(value_datetime) data_inicio
				FROM 	patient p
						INNER JOIN encounter e ON p.patient_id=e.patient_id
						INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
						o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
						o.value_datetime<=:endDate 
				GROUP BY p.patient_id

			) inicio_real
		GROUP BY patient_id
)inicio
-- Aqui encontramos os estado do paciente ate a data final
LEFT JOIN
(
	SELECT patient_id,MAX(data_estado) data_estado
	FROM 
		(
			/*Estado no programa*/
			SELECT 	pg.patient_id,
					MAX(ps.start_date) data_estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,10) AND ps.end_date IS NULL AND 
					ps.start_date<=:endDate 
			GROUP BY pg.patient_id
			
			UNION
			
			/*Estado no estado de permanencia da Ficha Resumo, Ficha Clinica*/
			SELECT 	p.patient_id,
					MAX(o.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs  o ON e.encounter_id=o.encounter_id
			WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
					e.encounter_type IN (53,6) AND o.concept_id IN (6272,6273) AND o.value_coded IN (1706,1366,1709) AND  
					o.obs_datetime<=:endDate 
			GROUP BY p.patient_id
			
			UNION
			
			/*Obito demografico*/			
			SELECT person_id AS patient_id,death_date AS data_estado
			FROM person 
			WHERE dead=1 AND death_date IS NOT NULL AND death_date<=:endDate
					
			UNION
			
			/*Obito na ficha de busca*/
			SELECT 	p.patient_id,
					MAX(obsObito.obs_datetime) data_estado
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id
			WHERE 	e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND 
					e.encounter_type IN (21,36,37) AND  e.encounter_datetime<=:endDate AND  
					obsObito.concept_id IN (2031,23944,23945) AND obsObito.value_coded=1366	
			GROUP BY p.patient_id
			
			
			
		) allSaida
	GROUP BY patient_id			
) saida ON inicio.patient_id=saida.patient_id

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_fila
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_fila ON inicio.patient_id=max_fila.patient_id	

LEFT JOIN
(	SELECT 	p.patient_id,MAX(encounter_datetime) data_seguimento
	FROM 	patient p 
			INNER JOIN encounter e ON e.patient_id=p.patient_id
	WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime<=:endDate
	GROUP BY p.patient_id
) max_consulta ON inicio.patient_id=max_consulta.patient_id
LEFT JOIN
(
	SELECT 	p.patient_id,MAX(value_datetime) data_recepcao_levantou
	FROM 	patient p
			INNER JOIN encounter e ON p.patient_id=e.patient_id
			INNER JOIN obs o ON e.encounter_id=o.encounter_id
	WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
			o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
			o.value_datetime<=:endDate 
	GROUP BY p.patient_id
) max_recepcao ON inicio.patient_id=max_recepcao.patient_id
GROUP BY inicio.patient_id
) inicio_fila_seg

LEFT JOIN
	obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id
	AND obs_fila.voided=0
	AND obs_fila.obs_datetime=inicio_fila_seg.data_fila
	AND obs_fila.concept_id=5096

LEFT JOIN
	obs obs_seguimento ON obs_seguimento.person_id=inicio_fila_seg.patient_id
	AND obs_seguimento.voided=0
	AND obs_seguimento.obs_datetime=inicio_fila_seg.data_seguimento
	AND obs_seguimento.concept_id=1410
	
GROUP BY inicio_fila_seg.patient_id
) inicio_fila_seg_prox
GROUP BY patient_id
) coorte12meses_final
INNER JOIN person p ON p.person_id=coorte12meses_final.patient_id
WHERE (data_estado IS NULL OR (data_estado IS NOT NULL AND  data_usar_c>data_estado)) AND DATE_ADD(data_usar, INTERVAL 28 DAY) >=:endDate
GROUP BY patient_id

)tx_curr
INNER JOIN
	(


/*** Patients who completed 3HP Therapy - CDC  TFR7 on TPT Completition Cascade ***/
select patient_id, ultima_cons_3hp as data_tx_new_tpt
from 
(
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, total_consultas_3hp.total as total_consultas_3hp ,ult_visit_3hp.ultima_cons_3hp,
 datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 as duration
 from 

   (


select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 
(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded =1256 -- Inicio 
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp

)  inicio_real_3hp

left join(  -- todas as consultas com prescricao 3HP

 SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  total_consultas_3hp on total_consultas_3hp.patient_id =inicio_real_3hp.patient_id 

left join(  -- ultima visita com prescricao 3HP no periodo

 SELECT p.patient_id, max(encounter_datetime) as ultima_cons_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  ult_visit_3hp on ult_visit_3hp.patient_id =inicio_real_3hp.patient_id 

 where datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 >= 4 and total_consultas_3hp.total >=3
) criterio1 

--   segundo criterio

union all


select 

patient_id, data_inicio_3hp as data_tx_new_tpt

from (
select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, if( tpt_dispensa_tr.data_3hp_trim is not null ,1,data_3hp_trim)  as tpt_trimestral ,  DATE_FORMAT(duracao_trat_3hp.data_min_3hp_mensal,'%d/%m/%Y') as data_min_3hp_mensal ,
 DATE_FORMAT(duracao_trat_3hp.data_max_3hp_mensal,'%d/%m/%Y') as data_max_3hp_mensal ,tpt_dispensa_men.total as total_mensal,
duracao_trat_3hp.duracao from 
( select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type = 60  AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 

(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded in (1256,1705)  -- Inicio /reinicio
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp
)  inicio_real_3hp


left join (  -- Tipo dispensa 3hp trimestral

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, min(encounter_datetime) data_3hp_trim
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =23720 -- Trimestral 
	GROUP BY p.patient_id
  
) tpt_dispensa_tr on tpt_dispensa_tr.patient_id =inicio_real_3hp.patient_id  and tpt_dispensa_tr.data_3hp_trim = inicio_real_3hp.data_inicio_3hp


left join (  -- Tipo dispensa 3hp mensal

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
  
) tpt_dispensa_men on tpt_dispensa_men.patient_id =inicio_real_3hp.patient_id

left join (  -- Tipo dispensa 3hp mensal
select min_3hp_mensal.patient_id, min_3hp_mensal.data_min_3hp_mensal, max_3hp_mensal.data_max_3hp_mensal, datediff( max_3hp_mensal.data_max_3hp_mensal,min_3hp_mensal.data_min_3hp_mensal) as duracao

from (
SELECT p.patient_id, min(encounter_datetime) data_min_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) min_3hp_mensal
    left join 
     (
SELECT p.patient_id, max(encounter_datetime) data_max_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN :startDate AND :endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) max_3hp_mensal on max_3hp_mensal.patient_id = min_3hp_mensal.patient_id
  
) duracao_trat_3hp on duracao_trat_3hp.patient_id =inicio_real_3hp.patient_id


) criterio2 where tpt_trimestral = 1 or total_mensal >= 4 and duracao <= 120

	) tx_new_tpt ON tx_new_tpt.patient_id=tx_curr.patient_id -- AND data_consulta=data_pick_up
	
	INNER JOIN person p ON p.person_id=tx_new_tpt.patient_id	



)indicador_22 ON indicador_1.us=indicador_22.us

-- Number of established ART patients completing TPT- 3HP
/*
inner join
(

)indicador_23 ON indicador_1.us=indicador_23.us */