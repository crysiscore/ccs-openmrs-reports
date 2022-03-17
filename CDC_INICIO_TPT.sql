
USE bagamoio;
SET @startDate:='2015-01-21';
SET @endDate:='2022-03-20';
SET @location:=212;

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
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 
(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=165308 AND o.value_coded =1256 -- Inicio 
	GROUP BY p.patient_id

) inicio_prof on inicio_prof.patient_id = reg_3hp.patient_id and reg_3hp.data_reg_3hp = inicio_prof.data_inicio_3hp

)  inicio_real_3hp

left join(  -- todas as consultas com prescricao 3HP

 SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  total_consultas_3hp on total_consultas_3hp.patient_id =inicio_real_3hp.patient_id 

left join(  -- ultima visita com prescricao 3HP no periodo

 SELECT p.patient_id, max(encounter_datetime) as ultima_cons_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=1719 AND o.value_coded IN (23954, 23984)-- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
  
)  ult_visit_3hp on ult_visit_3hp.patient_id =inicio_real_3hp.patient_id 

 where datediff(ult_visit_3hp.ultima_cons_3hp,inicio_real_3hp.data_inicio_3hp)/30 >= 4 and total_consultas_3hp.total >=3


--   segundo criterio




select inicio_real_3hp.patient_id, inicio_real_3hp.data_inicio_3hp, tpt_dispensa_tr.data_3hp_trim , tpt_dispensa_men.total from 
( select reg_3hp.patient_id, inicio_prof.data_inicio_3hp 
	from 
	(	SELECT p.patient_id, max(encounter_datetime) data_reg_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type = 60  AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23985 AND o.value_coded IN (23954, 23984) -- 3HP e 3HP + Piridoxine
	GROUP BY p.patient_id
) reg_3hp inner join 

(  -- ESTADO DA PROFLAXIA 
SELECT p.patient_id, max(encounter_datetime) data_inicio_3hp
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type IN (6,9) AND e.encounter_datetime BETWEEN @startDate AND @endDate
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
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =23720 -- Trimestral 
	GROUP BY p.patient_id
  
) tpt_dispensa_tr on tpt_dispensa_tr.patient_id =inicio_real_3hp.patient_id  and tpt_dispensa_tr.data_3hp_trim = inicio_real_3hp.data_inicio_3hp



left join (  -- Tipo dispensa 3hp mensal

-- ESTADO DA PROFLAXIA 
SELECT p.patient_id, count(*) as total
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- Trimestral 
	GROUP BY p.patient_id
  
) tpt_dispensa_men on tpt_dispensa_men.patient_id =inicio_real_3hp.patient_id