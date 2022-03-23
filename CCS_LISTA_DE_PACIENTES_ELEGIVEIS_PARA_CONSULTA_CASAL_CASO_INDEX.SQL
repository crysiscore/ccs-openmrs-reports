    
    
     /***************************    Confidente  Nome ****************************************/
     
SELECT      f_nome.patient_id,
DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
 ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
             CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
             confidente.nome as nome_confidente, f_nome.nome_confidente as nome_familiar , 	DATE_FORMAT(f_nome.encounter_datetime,'%d/%m/%Y') AS data_registo ,   f_parentesco.parentesco ,   f_idade.idade, 
			f_teste_hiv.teste_hiv  ,  f_cuidados_hiv.cuidados_hiv ,  f_ccr.ccr ,f_nid.nid as nid_familiar ,  
			DATE_FORMAT(ult_seguimento.encounter_datetime, '%d/%m/%Y') AS data_ult_consulta,
            DATE_FORMAT(ult_seguimento.value_datetime, '%d/%m/%Y') AS data_proxima_visita,
            DATE_FORMAT(fila.encounter_datetime,'%d/%m/%Y') AS data_ult_levantamento,
            DATE_FORMAT(fila.value_datetime,'%d/%m/%Y') AS fila_proximo_marcado ,
            telef.value AS telefone
            
            FROM ( select 
        e.patient_id,
       o.value_text AS nome_confidente,
       encounter_datetime,
       o.obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23778
            AND e.encounter_datetime BETWEEN :startDate AND :endDate AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23778 
            AND e.location_id=:location
      ) f_nome
    INNER JOIN person p ON p.person_id=f_nome.patient_id
LEFT JOIN 	(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(	
			
				/*Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date: ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program: OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy: First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate AND e.location_id=:location
						  GROUP BY 	p.patient_id
					  

				
				
			) inicio
		GROUP BY patient_id	
	)inicio_real ON inicio_real.patient_id = f_nome.patient_id
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
			) pn ON pn.person_id=f_nome.patient_id			
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
			) pid ON pid.patient_id=f_nome.patient_id
		
    /***************************    FAMILIAR  PARENTESCO ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
       when 23706 then 	'TRABALHADOR'
		when 5622 then 	'OUTRO, NAO CODIFICADO'
		when 23705	then 'PRIMO'
		when 23707	then 'FILHO'
		when 23708	then 'NETO'
		when 970	then 'MAE'
        when 971	then 'PAI'
        when 972	then 'IRMAO'
        when 973 then 'AVO'
        when 975 then 'TIA'
        when 1921	then 'PARCEIRO'
        when 1930 then 'AMIGO OU COLIGA'
        when 1930	then 'AMIGO OU COLEGA'
        when 2034	then 'VIZINHO'
        when 2036 then	'CHEFE DE  BAIRRO'
        when 2036	then 'SECRETARIO DO BAIRRO'
        when 1067	then 'Desconhecido'
        else '' end as parentesco,
        encounter_datetime,
        o.obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.location_id=:location
  ) f_parentesco ON  f_parentesco.patient_id = f_nome.patient_id  and f_parentesco.encounter_datetime = f_nome.encounter_datetime   and  f_nome.obs_group_id =  f_parentesco.obs_group_id
  
      /***************************  FAMILIAR   IDADE   ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
        value_numeric as idade,
        encounter_datetime,
       o.obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23777
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23777
            AND e.location_id=:location
   ) f_idade ON  f_idade.patient_id = f_nome.patient_id  and f_idade.encounter_datetime = f_nome.encounter_datetime  and  f_nome.obs_group_id =  f_idade.obs_group_id
    
    
      /***************************    FAMILIAR  Teste HIV ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
       when 1067	then 'Desconhecido'
         when 664 then 'NEGATIVO'
        when 703	then 'POSITIVO'
        else '' end as teste_hiv,
        encounter_datetime,
        obs_group_id

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23779
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23779
            AND e.location_id=:location
   ) f_teste_hiv ON  f_teste_hiv.patient_id = f_nome.patient_id  and f_teste_hiv.encounter_datetime = f_nome.encounter_datetime   and  f_nome.obs_group_id =  f_teste_hiv.obs_group_id
    
    
    
      /***************************    FAMILIAR  Cuidados HIV ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
        when 1065 then 'Sim'
        when 1066 then 'Nao'
        else '' end as cuidados_hiv,
        encounter_datetime,
       o.obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23780
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23780
            AND e.location_id=:location
    ) f_cuidados_hiv ON  f_cuidados_hiv.patient_id = f_nome.patient_id  and f_cuidados_hiv.encounter_datetime = f_nome.encounter_datetime  and   f_nome.obs_group_id =  f_cuidados_hiv.obs_group_id
    
    
      /***************************    FAMILIAR  CCR  ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       case  value_coded
        when 1065 then 'Sim'
        when 1066 then 'Nao'
        when 23892 then 'Alta'
        else '' end as ccr,
        obs_group_id,
        encounter_datetime

    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1885
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1885
            AND e.location_id=:location
 ) f_ccr ON  f_ccr.patient_id = f_nome.patient_id   and f_ccr.encounter_datetime = f_nome.encounter_datetime and   f_nome.obs_group_id =  f_ccr.obs_group_id
    
    
       /***************************  FAMILIAR   nid   ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
        o.value_text as nid,
        encounter_datetime,
        obs_group_id
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23781
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23781
            AND e.location_id=:location
    ) f_nid ON  f_nid.patient_id = f_nome.patient_id  and f_nid.encounter_datetime = f_nome.encounter_datetime  and   f_nome.obs_group_id =  f_nid.obs_group_id
    
    
    
     /***************************    Confidente  Parceiro ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
            CASE o.value_coded
                WHEN 1921 THEN 'PARCEIRO'
				ELSE ''
            END AS grau_parentesco,
            e.encounter_datetime
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 23704
            AND e.location_id=:location
    GROUP BY patient_id) parceiro  ON parceiro.patient_id = f_nome.patient_id  and parceiro.encounter_datetime = f_nome.encounter_datetime 
    
       /***************************    Confidente  Nome ****************************************/
    LEFT JOIN (SELECT 
        e.patient_id,
       o.value_text AS nome,
       encounter_datetime
    FROM
        (SELECT 
        e.patient_id, MAX(encounter_datetime) AS data_fr
    FROM
        encounter e
    INNER JOIN obs o ON e.encounter_id = o.encounter_id
    WHERE
        e.encounter_type =53
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1740
            AND e.encounter_datetime BETWEEN :startDate AND :endDate
            AND e.location_id=:location
    GROUP BY patient_id) fr
    INNER JOIN encounter e ON e.patient_id = fr.patient_id
    INNER JOIN obs o ON o.encounter_id = e.encounter_id
    WHERE
        e.encounter_type =53
            AND fr.data_fr = e.encounter_datetime
            AND e.voided = 0
            AND o.voided = 0
            AND o.concept_id = 1740
            AND e.location_id=:location
    GROUP BY patient_id) confidente  ON confidente.patient_id = f_nome.patient_id  and confidente.encounter_datetime = f_nome.encounter_datetime 
    
    
     /***************************    ultima consulta ****************************************/
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
            AND e.location_id = :location) ult_seguimento ON ult_seguimento.patient_id = f_nome.patient_id
            
	   /* ******************************** ultima levantamento *********** ******************************/
 		LEFT JOIN		
		(	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime
			FROM
				(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e 
							INNER JOIN obs o  ON e.encounter_id=o.encounter_id 		
					WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type =18 AND 
							e.location_id=:location 
					GROUP BY e.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                WHERE  o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime AND			
			  o.voided=0  AND e.voided =0 AND e.encounter_type =18  AND e.location_id=:location
		) fila ON fila.patient_id=f_nome.patient_id 
 /* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value  
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9 
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0 
	) telef  ON telef.person_id = f_nome.patient_id
