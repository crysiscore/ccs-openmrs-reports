/*

Name CCS ACTUALMENTE EM TARV 33 DIAS
Description- 
              - Pacientes actualmente em tarv, com data do proximo seguimento nao superior a data corremte em 28 dias

Created By@ Colaco C.
Created Date@ NA

Change by@ Agnaldo  Samuel
Change Date@ 06/06/2021 
Change Reason@ Bug fix
    -- Peso e altura incorrecta ( Anibal J.) 
    -- Excluir ficha resumo e APPSS na determinacao da ultima visita
    -- Revelacao de diagnostico da ficha clinica ( Mauricio T.)

Change Date@ 18/11/2021 
Change by@ Agnaldo  Samuel
Change Reason@ Bug fix
-- Correcao do erro da maior data da proxima consulta entre a consulta clinica e o fila

Change Date@ 13/05/2022 
Change by@ Agnaldo  Samuel
Change Reason@ Change request
-- Adicao da variavel profilaxia ctz ( Mauricio T.)

*/

SELECT * 
FROM 
(SELECT 	
            inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
			DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
            weight.peso AS peso,
            height.altura ,
            hemog.hemoglobina,
            cd4.value_numeric AS cd4,
            cv.carga_viral_qualitativa,
           	profilaxia_ctz.estado AS profilaxia_ctz,
            DATE_FORMAT(cv.data_ultima_carga,'%d/%m/%Y') AS data_ult_carga_v ,
            cv.valor_ultima_carga AS carga_viral_numeric,
            cv.origem_resultado AS origem_cv,
            keypop.populacaochave,
            linha_terapeutica.linhat AS linhaterapeutica,
            tipo_dispensa.tipodispensa,
            DATE_FORMAT(ccu_rastreio.dataRegisto,'%d/%m/%Y') AS rastreio_ccu ,
			DATE_FORMAT(ult_mestr.value_datetime,'%d/%m/%Y')   data_ult_mestruacao,
			IF( ptv.date_enrolled IS NULL, 'Nao', 	DATE_FORMAT(ptv.date_enrolled,'%d/%m/%Y') ) AS inscrito_ptv_etv,
			escola.nivel_escolaridade,
			telef.value AS telefone,
            regime.ultimo_regime,
			marcado_tb.tratamento_tb,
			DATE_FORMAT(  marcado_tb.data_marcado_tb , '%d/%m/%Y') AS data_marcado_tb,
            DATE_FORMAT(regime.data_regime,'%d/%m/%Y') AS data_regime,
            DATE_FORMAT(gravida_real.data_gravida,'%d/%m/%Y') AS data_gravida,
			DATE_FORMAT(lactante_real.date_enrolled,'%d/%m/%Y') AS data_lactante,
            DATE_FORMAT(ult_fila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
			DATE_FORMAT(ultimoFila.value_datetime,'%d/%m/%Y')   AS proximo_marcado,
            -- DATE_FORMAT(3_ult_vis.encounter_datetime,'%d/%m/%Y') as data_visita_3,
            -- DATE_FORMAT(2_ult_vis.encounter_datetime,'%d/%m/%Y') as data_visita_2,
            DATE_FORMAT(ult_vis.encounter_datetime,'%d/%m/%Y') AS data_ult_visita,
              DATE_FORMAT(ult_seguimento.encounter_datetime ,'%d/%m/%Y') AS data_ult_visita_2,
            DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') AS data_proxima_visita,
            risco_adesao.factor_risco AS factor_risco_adesao,
			IF(programa.patient_id IS NULL,'NAO','SIM') inscrito_programa,
			IF(mastercard.patient_id IS NULL,'NAO','SIM') temmastercard,
			IF(mastercardFResumo.patient_id IS NULL,'NAO','SIM') temmastercardFR,
			IF(mastercardFClinica.patient_id IS NULL,'NAO','SIM') temmastercardFC,
			IF(mastercardFAPSS.patient_id IS NULL,'NAO','SIM') temmastercardFA,
            DATE_FORMAT(mastercardFAPSS.dataRegisto,'%d/%m/%Y') AS  data_ult_vis_apss,
            DATE_FORMAT(mastercardFAPSS.value_datetime,'%d/%m/%Y')  AS  data_prox_apss,
			IF(DATEDIFF(:endDate,visita.value_datetime)<=28,'ACTIVO EM TARV','ABANDONO NAO NOTIFICADO') estado,
			IF(DATEDIFF(:endDate,visita.value_datetime)>28,DATE_FORMAT(DATE_ADD(visita.value_datetime, INTERVAL 28 DAY),'%d/%m/%Y'),'') dataAbandono,
			DATE_FORMAT( ult_levant_master_card.data_ult_lev_master_card,'%d/%m/%Y')  AS data_ult_lev_master_card ,
            conset.consentimento,
            revelacao.estado AS estado_revelacao,
			IF(gaaac.member_id IS NULL,'NÃO','SIM') emgaac,
            pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'

			
	FROM	
	(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(	
			
				/*Patients on ART who initiated the ARV DRUGS@ ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date@ ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program@ OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy@ First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate AND e.location_id=:location
						  GROUP BY 	p.patient_id
					  

				
				
			) inicio
		GROUP BY patient_id	
	)inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		
		LEFT JOIN 
			(	SELECT pad1.*
				FROM person_address pad1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_address_id) id 
					FROM person_address
					WHERE voided=0
					GROUP BY person_id
				) pad2
				WHERE pad1.person_id=pad2.person_id AND pad1.person_address_id=pad2.id
			) pad3 ON pad3.person_id=inicio_real.patient_id				
			LEFT JOIN 			
			(	SELECT pn1.*
				FROM person_name pn1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_name_id) id 
					FROM person_name
					WHERE voided=0
					GROUP BY person_id
				) pn2
				WHERE pn1.person_id=pn2.person_id AND pn1.person_name_id=pn2.id
			) pn ON pn.person_id=inicio_real.patient_id			
			LEFT JOIN
			(       SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
					(
						SELECT patient_id,MIN(patient_identifier_id) id
						FROM patient_identifier
						WHERE voided=0
						GROUP BY patient_id
					) pid2
					WHERE pid1.patient_id=pid2.patient_id AND pid1.patient_identifier_id=pid2.id
			) pid ON pid.patient_id=inicio_real.patient_id
		
		INNER JOIN		
		(	SELECT ultimavisita.patient_id,ultimavisita.value_datetime,ultimavisita.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type 
					FROM 	encounter e 
					INNER JOIN obs o ON o.encounter_id=e.encounter_id 
					INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND o.voided =0  AND e.encounter_type IN (6,9,18) AND  o.concept_id IN (5096 ,1410)
						AND	e.location_id=:location AND e.encounter_datetime <=:endDate  AND o.value_datetime IS  NOT NULL
					GROUP BY p.patient_id
				) ultimavisita

		) visita ON visita.patient_id=inicio_real.patient_id
		LEFT JOIN 
			(

				SELECT 	e.patient_id,
						CASE o.value_coded
						WHEN 1703 THEN 'AZT+3TC+EFV'
						WHEN 6100 THEN 'AZT+3TC+LPV/r'
						WHEN 1651 THEN 'AZT+3TC+NVP'
						WHEN 6324 THEN 'TDF+3TC+EFV'
						WHEN 6104 THEN 'ABC+3TC+EFV'
						WHEN 23784 THEN 'TDF+3TC+DTG'
						WHEN 23786 THEN 'ABC+3TC+DTG'
						WHEN 6116 THEN 'AZT+3TC+ABC'
						WHEN 6106 THEN 'ABC+3TC+LPV/r'
						WHEN 6105 THEN 'ABC+3TC+NVP'
						WHEN 6108 THEN 'TDF+3TC+LPV/r'
						WHEN 23790 THEN 'TDF+3TC+LPV/r+RTV'
						WHEN 23791 THEN 'TDF+3TC+ATV/r'
						WHEN 23792 THEN 'ABC+3TC+ATV/r'
						WHEN 23793 THEN 'AZT+3TC+ATV/r'
						WHEN 23795 THEN 'ABC+3TC+ATV/r+RAL'
						WHEN 23796 THEN 'TDF+3TC+ATV/r+RAL'
						WHEN 23801 THEN 'AZT+3TC+RAL'
						WHEN 23802 THEN 'AZT+3TC+DRV/r'
						WHEN 23815 THEN 'AZT+3TC+DTG'
						WHEN 6329 THEN 'TDF+3TC+RAL+DRV/r'
						WHEN 23797 THEN 'ABC+3TC+DRV/r+RAL'
						WHEN 23798 THEN '3TC+RAL+DRV/r'
						WHEN 23803 THEN 'AZT+3TC+RAL+DRV/r'						
						WHEN 6243 THEN 'TDF+3TC+NVP'
						WHEN 6103 THEN 'D4T+3TC+LPV/r'
						WHEN 792 THEN 'D4T+3TC+NVP'
						WHEN 1827 THEN 'D4T+3TC+EFV'
						WHEN 6102 THEN 'D4T+3TC+ABC'						
						WHEN 1311 THEN 'ABC+3TC+LPV/r'
						WHEN 1312 THEN 'ABC+3TC+NVP'
						WHEN 1313 THEN 'ABC+3TC+EFV'
						WHEN 1314 THEN 'AZT+3TC+LPV/r'
						WHEN 1315 THEN 'TDF+3TC+EFV'						
						WHEN 6330 THEN 'AZT+3TC+RAL+DRV/r'						
						WHEN 6102 THEN 'D4T+3TC+ABC'
						WHEN 6325 THEN 'D4T+3TC+ABC+LPV/r'
						WHEN 6326 THEN 'AZT+3TC+ABC+LPV/r'
						WHEN 6327 THEN 'D4T+3TC+ABC+EFV'
						WHEN 6328 THEN 'AZT+3TC+ABC+EFV'
						WHEN 6109 THEN 'AZT+DDI+LPV/r'
						WHEN 6329 THEN 'TDF+3TC+RAL+DRV/r'
						WHEN 21163 THEN 'AZT+3TC+LPV/r'						
						WHEN 23799 THEN 'TDF+3TC+DTG'
						WHEN 23800 THEN 'ABC+3TC+DTG'
						ELSE 'OUTRO' END AS ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				FROM 	encounter e
                INNER JOIN
                         ( SELECT e.patient_id,MAX(encounter_datetime) encounter_datetime 
                         FROM encounter e 
                         INNER JOIN obs o ON e.encounter_id=o.encounter_id
                         WHERE 	encounter_type =18 AND e.voided=0 AND o.voided=0 
                         GROUP BY e.patient_id
                         ) ultimofila
				ON e.patient_id=ultimofila.patient_id
                INNER JOIN obs o ON o.encounter_id=e.encounter_id 
				WHERE  ultimofila.encounter_datetime = e.encounter_datetime AND
                        encounter_type =18 AND e.voided=0 AND o.voided=0 AND 
						o.concept_id=1088 AND e.location_id=:location
              
			) regime ON regime.patient_id=inicio_real.patient_id
            
            
		LEFT JOIN 
		(SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
				WHERE 	e.voided=0  AND e.encounter_type=18 AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=5096 AND o.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND 
			e.encounter_type=18 AND e.location_id=:location 
		) ultimoFila ON ultimoFila.patient_id=inicio_real.patient_id
        
		LEFT JOIN
		(
			SELECT 	pg.patient_id
			FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
			WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
		) programa ON programa.patient_id=inicio_real.patient_id
		LEFT JOIN 
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter 
			WHERE 	encounter_type = 52 AND voided=0
			GROUP BY patient_id
		) mastercard ON mastercard.patient_id = inicio_real.patient_id
        /** **********************   CCU Rastreio  ********************************** **/
	     LEFT JOIN 
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter 
			WHERE 	encounter_type = 28 AND form_id = 122 AND voided = 0
			GROUP BY patient_id
		) ccu_rastreio ON ccu_rastreio.patient_id = inicio_real.patient_id
		
		LEFT JOIN 
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter 
			WHERE 	encounter_type = 53 AND form_id = 165 AND voided=0
			GROUP BY patient_id
		) mastercardFResumo ON mastercardFResumo.patient_id = inicio_real.patient_id
		
		LEFT JOIN 
		(
			SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
			FROM 	encounter 
			WHERE 	encounter_type IN (6,9) AND form_id = 163 AND voided=0
			GROUP BY patient_id
		) mastercardFClinica ON mastercardFClinica.patient_id = inicio_real.patient_id
	
		LEFT JOIN 
		(  
             SELECT e.patient_id, ult_apss.dataRegisto,o.value_datetime
			  FROM    encounter e  INNER JOIN 
              (
				SELECT 	patient_id, MAX(encounter_datetime) dataRegisto
						FROM 	encounter 
						WHERE 	encounter_type IN (34,35) AND form_id = 164 AND voided=0
						GROUP BY patient_id 
               ) ult_apss
			ON e.patient_id = ult_apss.patient_id
            INNER JOIN obs o ON o.encounter_id =e.encounter_id
            WHERE e.encounter_type IN (34,35)
             AND ult_apss.dataRegisto = e.encounter_datetime 
             AND o.voided=0 AND o.concept_id = 6310
             GROUP BY patient_id
		) mastercardFAPSS ON mastercardFAPSS.patient_id = inicio_real.patient_id
    
    /************************** keypop concept_id = 23703 ****************************/
               LEFT JOIN 
		(SELECT ultimavisita_keypop.patient_id,ultimavisita_keypop.encounter_datetime data_keypop,
        CASE o.value_coded
					WHEN '1377'  THEN 'HSH'
					WHEN '20454' THEN 'PID'
					WHEN '20426' THEN 'REC'
					WHEN '1901'  THEN 'MTS'
					WHEN '23885' THEN 'Outro'
				ELSE '' END AS populacaochave
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime, e.encounter_type
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0  AND o.voided=0   AND o.concept_id=23703 AND e.encounter_type IN (6,9,34,35)  AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_keypop
			INNER JOIN encounter e ON e.patient_id=ultimavisita_keypop.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=23703 AND o.voided=0 AND e.encounter_datetime=ultimavisita_keypop.encounter_datetime AND 
			e.encounter_type IN (6,9,34,35)  AND e.location_id=:location 
			GROUP BY e.patient_id
		) keypop ON keypop.patient_id=inicio_real.patient_id
	
		LEFT JOIN
		(
			SELECT DISTINCT member_id FROM gaac_member WHERE voided=0
		) gaaac ON gaaac.member_id=inicio_real.patient_id
        
        /************  Peso  *********************/
        LEFT JOIN 
		(SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_numeric peso
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				       AND 	e.voided=0 AND o.voided=0   AND o.concept_id=5089 AND e.encounter_type IN (6,9) AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=5089 AND o.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND 
			e.encounter_type IN (6,9) AND e.location_id=:location 
		) weight ON weight.patient_id=inicio_real.patient_id
               /************  Altura  *********************/
		 LEFT JOIN 
		(SELECT ultimavisita_peso.patient_id,ultimavisita_peso.encounter_datetime,o.value_numeric AS altura
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0   AND o.concept_id=5090 AND e.encounter_type IN (6,9) AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_peso
			INNER JOIN encounter e ON e.patient_id=ultimavisita_peso.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=5090 AND o.voided=0 AND e.encounter_datetime=ultimavisita_peso.encounter_datetime AND 
			e.encounter_type IN (6,9) AND e.location_id=:location 
		) height ON height.patient_id=inicio_real.patient_id
        
                       /************  Hemoglobina  *********************/
		LEFT JOIN 
		(SELECT ultimavisita_hemoglobina.patient_id,ultimavisita_hemoglobina.encounter_datetime,o.value_numeric hemoglobina
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
	                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0 AND o.voided=0   AND o.concept_id=1692 AND e.encounter_type IN (6,9) AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_hemoglobina
			INNER JOIN encounter e ON e.patient_id=ultimavisita_hemoglobina.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=1692 AND o.voided=0 AND e.encounter_datetime=ultimavisita_hemoglobina.encounter_datetime AND 
			e.encounter_type IN (6,9) AND e.location_id=:location 
		) hemog ON hemog.patient_id=inicio_real.patient_id
        
   /*****************************   gravida nos ultimos 12 mesmes   *************************************************/
   LEFT JOIN 
	(	SELECT patient_id, data_gravida
		FROM
			( SELECT p.patient_id,MAX(obs_datetime) data_gravida
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON e.encounter_id=o.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND concept_id = 1982 AND value_coded = 1065 
					AND e.encounter_type =6 AND o.obs_datetime BETWEEN DATE_SUB(:endDate, INTERVAL 12 MONTH) AND  :endDate  AND 
					e.location_id=:location
			GROUP BY p.patient_id
			) gravida
			/*** union
			
			select pp.patient_id,pp.date_enrolled as data_gravida
			from 	patient_program pp 
			where 	pp.program_id in (3,4,8) and pp.voided=0 and  pp.date_completed is null and
					pp.date_enrolled between  date_sub(:endDate, interval 9 MONTH) and  :endDate  and pp.location_id=:location
			) gravida
            
          
		group by patient_id   ***/
	) gravida_real ON gravida_real.patient_id=inicio_real.patient_id

	  /************************* LACTANTES *********************************************/
     LEFT JOIN  (	SELECT patient_id,  date_enrolled
		FROM
			(SELECT p.patient_id,MAX(obs_datetime) date_enrolled
			FROM 	patient p 
					INNER JOIN encounter e ON p.patient_id=e.patient_id
					INNER JOIN obs o ON e.encounter_id=o.encounter_id
			WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND concept_id = 6332 AND value_coded = 1065 
					AND e.encounter_type =6 AND o.obs_datetime BETWEEN DATE_SUB(:endDate, INTERVAL 18 MONTH) AND :endDate  AND 
					e.location_id=:location
			GROUP BY p.patient_id
		
			) lactante 
		       
	) lactante_real ON lactante_real.patient_id=inicio_real.patient_id 
              
			/** **************************************** Tipo dispensa  concept_id = 23739 **************************************** **/
    LEFT JOIN 
		( SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 23888  THEN 'DISPENSA SEMESTRAL'
					WHEN 1098 THEN 'DISPENSA MENSAL'
					WHEN 23720 THEN 'DISPENSA TRIMESTRAL'
				ELSE '' END AS tipodispensa,
                e.encounter_datetime
                FROM encounter e INNER JOIN
                ( SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_tipo_dis
					FROM 	obs o
					INNER JOIN encounter e ON o.encounter_id=e.encounter_id
					WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23739 AND o.location_id=:location
					GROUP BY patient_id ) ult_dispensa
					ON e.patient_id =ult_dispensa.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53)
             AND ult_dispensa.data_ult_tipo_dis = e.encounter_datetime 
             AND o.voided=0 AND o.concept_id = 23739
             GROUP BY patient_id
		) tipo_dispensa ON tipo_dispensa.patient_id=inicio_real.patient_id
        
        /** ************************** LinhaTerapeutica concept_id = 21151  * ********************************************** **/
        LEFT JOIN 
		(
SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 21148  THEN 'SEGUNDA LINHA'
					WHEN 21149  THEN 'TERCEIRA LINHA'
					WHEN 21150  THEN 'PRIMEIRA LINHA'
				ELSE '' END AS linhat,
                encounter_datetime AS data_ult_linha
				FROM 	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ult_linhat
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151 
							GROUP BY patient_id
				) ult_linhat
			INNER JOIN encounter e ON e.patient_id=ult_linhat.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53) AND ult_linhat.data_ult_linhat =e.encounter_datetime AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151 
            GROUP BY patient_id
		) linha_terapeutica ON linha_terapeutica.patient_id=inicio_real.patient_id
        
        /****************** ****************************  CD4   ********* *****************************************************/
        LEFT JOIN(  
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN 
		    (            
            SELECT 	cd4_max.patient_id, MAX(cd4_max.encounter_datetime) AS encounter_datetime
            FROM ( SELECT e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e 
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND e.location_id=:location  AND
							o.voided=0 AND o.concept_id=1695 AND e.encounter_type IN (6,9,53)  
			
					UNION ALL
					SELECT 	 e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e 
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND  e.location_id=:location  AND
							o.voided=0 AND o.concept_id=5497 AND e.encounter_type =13 ) cd4_max
			GROUP BY patient_id ) cd4_temp 
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id 
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id IN (1695,5497) AND e.encounter_type IN (6,9,13,53)   
			GROUP BY patient_id   
            
		) cd4 ON cd4.patient_id =  inicio_real.patient_id
       	/**  ******************************************  Levantamento de ARV Master Card  **** ************************************ **/  
            LEFT JOIN (
	SELECT ult_lev_master_card.patient_id,o.value_datetime AS data_ult_lev_master_card
		FROM

			(	SELECT 	e.patient_id,MAX(o.value_datetime) AS value_datetime
				FROM 	encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
				WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type =52 AND o.concept_id=23866 
				GROUP BY patient_id
			) ult_lev_master_card
			INNER JOIN encounter e ON e.patient_id=ult_lev_master_card.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=23866 AND o.voided=0 AND e.voided=0 AND o.value_datetime=ult_lev_master_card.value_datetime AND 
			e.encounter_type =52  
           GROUP BY patient_id
            ) ult_levant_master_card ON ult_levant_master_card.patient_id = inicio_real.patient_id
	    /* ************ ******************************  Ultima mestruacao    ******************** ******************************/
		LEFT JOIN 
		(SELECT ultimavisita_mentruacao.patient_id,ultimavisita_mentruacao.encounter_datetime,o.value_datetime 
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=1465 AND e.encounter_type IN (6,9) AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_mentruacao
			INNER JOIN encounter e ON e.patient_id=ultimavisita_mentruacao.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=1465 AND o.voided=0 AND e.encounter_datetime=ultimavisita_mentruacao.encounter_datetime AND 
			e.encounter_type IN (6,9) AND e.location_id=:location 
		) ult_mestr ON ult_mestr.patient_id=inicio_real.patient_id 
        

          /***********************   Factores de risco de adesao *****************************************************/
          LEFT JOIN (SELECT 
						e.patient_id, 
						o.value_coded,
						CASE  o.value_coded
						WHEN 6436  THEN   'Estigma/Preocupado com a privacidade'
						WHEN 23769 THEN  'ASPECTOS CULTURAIS OU TRADICIONAIS (P)'
						WHEN 23768 THEN  'PERDEU / ESQUECEU / PARTILHOU COMPRIMIDOS (L)'
						WHEN 6303  THEN   'VIOLENCIA BASEADA NO GENERO'
						WHEN 23767 THEN 'SENTE-SE MELHOR (E)'
						WHEN 18698 THEN  'FALTA DE ALIMENTO'
						WHEN 207   THEN 'DEPRESSÃO'
						WHEN 820   THEN 'PROBLEMAS DE TRANSPORTE'
						WHEN 1936  THEN 'UTENTE SETENTE-SE DOENTE'
						WHEN 1956  THEN 'NÃO ACREDITO NO REULTADO'
						WHEN 2015  THEN 'EFEITOS SECUNDARIOS ARV'
						WHEN 2153  THEN  'FALTA DE APOIO'
						WHEN 2155  THEN 'NÃO REVELOU SEU DIAGNOSTICO'
						WHEN 6186  THEN 'NAO ACREDITA NO TRATAMENTO'
						WHEN 23766 THEN 'SÃO MUITOS COMPRIMIDOS (D)'
						WHEN 2017  THEN 'OUTRO MOTIVO DE FALTA'
						WHEN 1603  THEN  'ABUSO DE ALCOOL'
						END AS factor_risco,
                        ult_risco_adesao.data_ult_risco_adesao 
						FROM encounter e INNER JOIN
										(   SELECT e.patient_id, MAX(encounter_datetime) AS data_ult_risco_adesao
											FROM 	obs o
											INNER JOIN encounter e ON o.encounter_id=e.encounter_id
											WHERE 	e.encounter_type IN (6,9,18,35) AND e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=:location
											GROUP BY patient_id ) ult_risco_adesao
						ON ult_risco_adesao.patient_id=e.patient_id
						INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE e.encounter_datetime = ult_risco_adesao.data_ult_risco_adesao AND 
						e.voided=0 AND o.voided=0 AND o.concept_id = 6193 AND o.location_id=:location
						AND e.encounter_type IN (6,9,18,35)
						GROUP BY patient_id ) risco_adesao ON risco_adesao.patient_id =  inicio_real.patient_id AND DATEDIFF(:endDate,risco_adesao.data_ult_risco_adesao)/30 <= 3 

		 /*******************************   Patients enrolled in PTV/ETV Program@ OpenMRS Program ************************************/
        LEFT JOIN (

						/*Patients enrolled in PTV/ETV Program@ OpenMRS Program*/
						SELECT 	pg.patient_id,date_enrolled 
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=8 AND  date_enrolled  BETWEEN DATE_SUB(:endDate , INTERVAL 9 MONTH ) AND :endDate 
						GROUP BY pg.patient_id
        ) ptv ON ptv.patient_id= inicio_real.patient_id

          /* ******************************** ultima carga viral *********** ******************************/
        LEFT JOIN(  
          SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
                ELSE ''
                END  AS carga_viral_qualitativa,
				ult_cv.data_cv data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name AS origem_resultado
                FROM  encounter e 
                INNER JOIN	(
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_cv
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9,13,53) AND e.voided=0 AND o.voided=0 AND o.concept_id IN( 856, 1305) 
							GROUP BY patient_id
				) ult_cv 
                ON e.patient_id=ult_cv.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id 
                 LEFT JOIN form fr ON fr.form_id = e.form_id
                 WHERE e.encounter_datetime=ult_cv.data_cv	
				AND	e.voided=0  AND e.location_id= :location   AND e.encounter_type IN (6,9,13,53) AND
				o.voided=0 AND 	o.concept_id IN( 856, 1305) AND  e.encounter_datetime <= :endDate 
                GROUP BY e.patient_id
		) cv ON cv.patient_id =  inicio_real.patient_id

       /*****************************   ultimo levantamento ************** **********************/
		LEFT JOIN
		(
	
	SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  

		) ult_fila ON ult_fila.patient_id = inicio_real.patient_id

  /*  ************************************   penultimo  levantamento ***** *******************************    
		LEFT JOIN
		(
		
		SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  

		) 2_ult_fila ON 2_ult_fila.patient_id = inicio_real.patient_id

  /* ********* ********************************   3 ultimo  levantamento ******* *****************************   
		LEFT JOIN
		(
		SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 2,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (18) AND e.form_id =130  
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  

		) 3_ult_fila ON 3_ult_fila.patient_id = inicio_real.patient_id
****************************************************************************************************************** */ 
	/*  ** ******************************************  ultima visita  **** ************************************* */ 
		LEFT JOIN (


SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 0,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  
		) ult_vis ON ult_vis.patient_id = inicio_real.patient_id

LEFT JOIN (
	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
				WHERE 	e.voided=0 AND e.encounter_type IN (9,6) 
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND 
			e.encounter_type IN (9,6) AND e.location_id=:location 
            ) ult_seguimento ON ult_seguimento.patient_id = inicio_real.patient_id
	/*  * *******************************************  penultima visita  *** ************************************** 
		LEFT JOIN (


SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 1,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  
		) 2_ult_vis ON 2_ult_vis.patient_id = inicio_real.patient_id

	/*   ********************************************  3 ultima  visita  *** ***************************************
		LEFT JOIN (


SELECT visita2.patient_id , 
(	SELECT	 visita.encounter_datetime
					FROM 
                    ( SELECT p.patient_id,  e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
						) visita
    WHERE visita.patient_id = visita2.patient_id
    ORDER BY encounter_datetime  DESC
    LIMIT 2,1
) AS encounter_datetime
FROM 	   ( SELECT p.patient_id, e.encounter_datetime FROM  encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type IN (6,9) 
							AND e.encounter_datetime<=:endDate
				) visita2
GROUP BY visita2.patient_id  
		) 3_ult_vis ON 3_ult_vis.patient_id = inicio_real.patient_id
       */     
	/* * **************************** Escolaridade **** ********************************************** */ 
		LEFT JOIN 
		(SELECT ultimavisita_escolaridade.patient_id,
		CASE o.value_coded
                WHEN 1445  THEN  'NENHUMA EDUCAÇÃO FORMAL'
                WHEN 1446 THEN  'PRIMARIO'
               WHEN 1447 THEN  'SECONDÁRIO, NIVEL BASICO'
              WHEN 1448 THEN  ' UNIVERSITARIO'
               WHEN 6124 THEN  'TÉCNICO BÁSICO'
                WHEN 1444 THEN  'TÉCNICO MÉDIO'
               ELSE 'OUTRO'
           END  AS nivel_escolaridade, 
		   ultimavisita_escolaridade.encounter_datetime AS data_ult_esc
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=1443 AND e.encounter_type =53 AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_escolaridade
			INNER JOIN encounter e ON e.patient_id=ultimavisita_escolaridade.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=1443 AND o.voided=0 AND e.encounter_datetime=ultimavisita_escolaridade.encounter_datetime AND 
			e.encounter_type =53 AND e.location_id=:location 
		) escola ON escola.patient_id=inicio_real.patient_id
                /** ************************** Profilaxia CTZ  6121 ********************************************** **/
        LEFT JOIN 
		(
                SELECT e.patient_id,
                ficha_seguimento.data_ult_seguimento,
				CASE o.value_coded
				WHEN 1256 THEN 'NOVO'
				WHEN 1257 THEN 'CONTINUA'
				WHEN 1267 THEN 'TERMINA'
                WHEN 1065 THEN 'SIM'
                WHEN 1066 THEN 'NAO'
			    ELSE '' END AS estado
				FROM (
							SELECT 	e.patient_id,MAX(encounter_datetime) AS data_ult_seguimento
							FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id
							WHERE e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 6121 AND e.form_id=163
                            AND e.location_id=:location
							GROUP BY patient_id
				      )  ficha_seguimento
                
			INNER JOIN encounter e ON e.patient_id=ficha_seguimento.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND ficha_seguimento.data_ult_seguimento =e.encounter_datetime AND e.voided=0 AND o.voided=0 AND o.concept_id = 6121
                     AND e.location_id=:location
            GROUP BY patient_id
		) profilaxia_ctz ON profilaxia_ctz.patient_id=inicio_real.patient_id 
/* ******************************* Revelacao do diagnostico **************************** */
	 LEFT JOIN 
		(SELECT ultimavisita_revelacao.patient_id,ultimavisita_revelacao.encounter_datetime,
        CASE o.value_coded  
        WHEN 6338 THEN "REVELADO PARCIALMENTE"
        WHEN 6337 THEN "REVELADO"
        WHEN 6339 THEN "NÃO REVELADO" END AS estado
			FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime, e.encounter_type
				FROM 	encounter e 
                        INNER JOIN obs o ON o.encounter_id =e.encounter_id
				WHERE 	e.voided=0  AND o.voided=0   AND o.concept_id=6340  AND e.encounter_type IN (34,35) AND e.location_id=:location 
				GROUP BY e.patient_id
			) ultimavisita_revelacao
			INNER JOIN encounter e ON e.patient_id=ultimavisita_revelacao.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id			
			WHERE o.concept_id=6340 AND o.voided=0 AND e.encounter_datetime=ultimavisita_revelacao.encounter_datetime AND 
			e.encounter_type IN (34,35) AND e.location_id=:location 
		) revelacao ON revelacao.patient_id=inicio_real.patient_id


        /************************** TRATAMENTO DE TUBERCULOSE NA FICHA CLINICA  ****************************/
               left join 
		( Select ultimavisita_tb.patient_id, ultimavisita_tb.encounter_datetime data_marcado_tb,
        CASE o.value_coded
					WHEN '1256'  THEN 'INICIO'
					WHEN '1257' THEN 'CONTINUA'
				    WHEN '1267' THEN 'COMPLETO'
				ELSE 'OUTRO' END AS tratamento_tb
			from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
                        inner join obs o on o.encounter_id =e.encounter_id
				       and 	e.voided=0  and o.voided=0   and o.concept_id=1268 and e.encounter_type IN (6,9)  and e.location_id=:location 
				group by e.patient_id
			) ultimavisita_tb
			inner join encounter e on e.patient_id=ultimavisita_tb.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=1268 and o.voided=0 and e.encounter_datetime=ultimavisita_tb.encounter_datetime and 
			e.encounter_type in (6,9) and o.value_coded in (1256,1257) and e.location_id=:location 
		) marcado_tb on marcado_tb.patient_id =   inicio_real.patient_id


/* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value  
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9 
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0 
	) telef  ON telef.person_id = inicio_real.patient_id

/* ********************************* Consentimento **********************************/

   LEFT JOIN (
		SELECT ultapss.patient_id,ultapss.encounter_datetime,CASE o.value_coded WHEN 1065 THEN 'Sim' WHEN 1066 THEN 'Nao' END AS consentimento
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=35 AND e.location_id=:location 
                        AND 	e.encounter_datetime<=:endDate
						GROUP BY p.patient_id ) ultapss
                      	INNER JOIN encounter e ON e.patient_id=ultapss.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id			
					WHERE o.concept_id=6306 AND o.voided=0 AND e.encounter_datetime=ultapss.encounter_datetime AND 
					e.encounter_type =35 AND e.location_id=:location 
                    ) conset ON conset.patient_id = inicio_real.patient_id
                    
                    
	WHERE inicio_real.patient_id NOT IN  -- Pacientes que sairam do programa TARV
		(		
			SELECT 	pg.patient_id		
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
									pg.program_id=2 AND    location_id=:location		
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
                                       
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,9,10) AND   location_id=208 AND ps.start_date <=:endDate
					GROUP BY pg.patient_id	 	
		) AND DATEDIFF(:endDate,visita.value_datetime)<= 28 -- De 33 para 28 Solicitacao do Mauricio 27/07/2020
) activos
GROUP BY patient_id