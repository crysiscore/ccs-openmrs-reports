

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
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) min_3hp_mensal
    left join 
     (
SELECT p.patient_id, max(encounter_datetime) data_max_3hp_mensal
			FROM 	patient p 
				INNER JOIN encounter e ON e.patient_id=p.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND e.encounter_type =60 AND e.encounter_datetime BETWEEN @startDate AND @endDate
			AND o.voided=0 AND o.concept_id=23986 AND o.value_coded =1098 -- mensal 
	GROUP BY p.patient_id
    ) max_3hp_mensal on max_3hp_mensal.patient_id = min_3hp_mensal.patient_id
  
) duracao_trat_3hp on duracao_trat_3hp.patient_id =inicio_real_3hp.patient_id


) criterio2 where tpt_trimestral =1 or total_mensal >=4 and duracao <= 120