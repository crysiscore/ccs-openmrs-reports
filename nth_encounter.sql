SET @row_number = 0, @prev_patient_id = -1;
Set @contador = 0;
Set @endDate:= '2023-08-20';
SET @location = 208;

/*
SELECT patient_id, encounter_datetime,  cv_qualitativa, cv_numerico, encounter_type,row_number,contador

FROM (
    SELECTa
        patient_id,
        	CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
				when 165331 then CONCAT('<',o.comments)
                ELSE ''
                END  AS cv_qualitativa,
                o.value_numeric cv_numerico,
                encounter_type,
        encounter_datetime,

        @row_number := IF(@prev_patient_id = patient_id, @row_number + 1, 1) AS row_number,
        @prev_patient_id := patient_id,
        @contador:= IF(@prev_patient_id = patient_id, @contador + 1, 0) AS contador
    FROM encounter e inner join obs o on e.encounter_id=o.encounter_id
    where e.encounter_type IN (6,9,13,51) AND e.voided=0 AND o.voided=0 AND o.concept_id in( 856, 1305)
  #  group by patient_id,encounter_datetime
    ORDER BY patient_id, encounter_datetime DESC
) ranked
WHERE row_number <= 6 ;*/


SELECT patient_id, encounter_datetime as data_cv,  				CASE value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
				when 165331 then CONCAT('<',comments)
                ELSE ''
                END  AS carga_viral_qualitativa,
                value_numeric as carga_viral
                                      FROM (SELECT patient_id,
                                                   encounter_datetime,
                                                   value_coded,
                                                   value_numeric,
                                                   comments,
                                                   @row_number := IF(@prev_patient_id = patient_id, @row_number + 1, 1) AS row_number,
                                                 @prev_patient_id := patient_id
                                              FROM encounter e inner join obs o on e.encounter_id=o.encounter_id
                                              where e.encounter_type IN (6,9,13,51) AND e.voided=0 AND o.voided=0 AND o.concept_id in( 856, 1305)
                                           AND encounter_datetime <= @endDate
                                            ORDER BY patient_id, encounter_datetime DESC) ranked
                                      WHERE row_number <= 6
