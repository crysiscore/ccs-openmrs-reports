/*
Name: CCS LISTA DE PACIENTES QUE LEVANTARAM ARV NUM PERIODO
Description:
              -  LISTA DE PACIENTES QUE LEVANTARAM ARV NUM PERIODO
               - CDC Modified Copy

Created By: Agnaldo Samuel
Created Date: 25-10-2021

Change by: Agnaldo  Samuel
Change Date: 
Change Reason:   */


select 	pid.identifier NID,
			DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
			DATE_FORMAT(visita.ultimo_levantamento,	'%d/%m/%Y') as ultimo_levantamento,
            DATE_FORMAT(ult_lev_prox_mar.value_datetime,	'%d/%m/%Y') as proxim_marcado,
            p.gender,
            pat.value as telefone,
			ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
			/*case tipo.value_coded
				when 1257 then 'MANTER'
				when 1256 then 'INICIAR'
				when 1259 then 'ALTERAR'
				when 1705 then 'REINICIAR'
				when 1369 then 'TRANSFERIDO DE'
				when 1708 then 'SAIDA'
				when 6282 then 'C. INTOLERANCIA'
				when 1258 then 'ALTERAR'
				when 981 then 'ALTERAR'
				when 1260 then 'INTERROMPER'
				when 1107 then 'NENHUM'
			else 'OUTRO' end as tipo,
			transferido.data_transferido_de as data_transferido_de,
			if(transferido.program_id is null,null,if(transferido.program_id=1,'PRE-TARV','TARV')) as transferido_de,*/
			tipo_dispensa.tipodispensa,
			DATE_FORMAT(saida.encounter_datetime,'%d/%m/%Y') as encounter_datetime,
			saida.estado,
			regime.ultimo_regime,
			DATE_FORMAT(regime.data_regime,'%d/%m/%Y') as data_regime,
		     concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
             DATE_FORMAT(ult_recepcao_lev.data_ult_levantamento, 	'%d/%m/%Y') as data_ult_levantamento,
             DATE_FORMAT(ult_recepcao_lev.prox_marcado,	'%d/%m/%Y') as prox_marcado,
             DATE_FORMAT(ult_seguimento.encounter_datetime,'%d/%m/%Y') as data_ult_consulta,
             DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') as consulta_prox_marcado,
           	 pad3.county_district AS 'Distrito' ,
			 pad3.address2 AS 'PAdministrativo' ,
             pad3.address6 AS 'Localidade' ,
			 pad3.address5 AS 'Bairro' ,
			 pad3.address1 AS 'PontoReferencia' 
	from
		(	select e.patient_id,max(encounter_datetime) ultimo_levantamento,location_id
			from encounter e inner join patient p on e.patient_id=p.patient_id
			where encounter_type=18 and e.voided=0  and p.voided=0 and 
            encounter_datetime between :startDate and :endDate and location_id=:location 
			group by e.patient_id
		) visita 	
            JOIN person p ON p.person_id=visita.patient_id
		left join	
		(	
        SELECT patient_id,MIN(data_inicio) data_inicio
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
					  
						/* UNION
						
						 Patients with first drugs pick up date set: Recepcao Levantou ARV
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND 
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id		 */
					
				
				
			) inicio
		GROUP BY patient_id	
		) inicio_real on visita.patient_id=inicio_real.patient_id	
		/*left join	
		(	select max_tipo.patient_id,max_tipo.ultimo_obs,obs.value_coded
			from
			(select 	patient_id,max(obs_datetime) ultimo_obs
			from 	encounter e inner join obs o on e.encounter_id=o.encounter_id
			where 	e.voided=0 and o.voided=0 and encounter_type in (6,9,18) and concept_id=1255 and 
					encounter_datetime between :startDate and :endDate and e.location_id=:location
			group by patient_id
			) max_tipo,
			obs
			where 	max_tipo.patient_id=obs.person_id and 
					max_tipo.ultimo_obs=obs.obs_datetime and 
					obs.concept_id=1255 and obs.voided=0 and 
					obs.obs_datetime between :startDate and :endDate and obs.location_id=:location
		) tipo on tipo.patient_id=visita.patient_id  */
        
		left join patient_identifier pid on pid.patient_id=visita.patient_id  and pid.identifier_type=2
		left join person_name pn on pn.person_id=visita.patient_id and pn.preferred=1
        left join person_attribute pat on pat.person_id=visita.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
              
		/* left join
		(	select 	pg.patient_id,max(ps.start_date) data_transferido_de,pg.program_id
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id in (1,2) and ps.state in (28,29) and 
					ps.start_date between :startDate and :endDate and location_id=:location	
			group by pg.patient_id
		) transferido on transferido.patient_id=visita.patient_id and transferido.data_transferido_de<=visita.ultimo_levantamento */
		left join
		(	
			select 	pg.patient_id,ps.start_date encounter_datetime,location_id,
					case ps.state
						when 7 then 'TRANSFERIDO PARA'
						when 8 then 'SUSPENSO'
						when 9 then 'ABANDONO'
						when 10 then 'OBITO'
					else 'OUTRO' end as estado
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and location_id=:location and 
					ps.start_date between :startDate and :endDate		
		) saida on saida.patient_id=visita.patient_id
		left join 
		(
			select 	ultimo_lev.patient_id,
					case o.value_coded
					when 1703 then 'AZT+3TC+EFV'
						when 6100 then 'AZT+3TC+LPV/r'
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 6104 then 'ABC+3TC+EFV'
						when 23784 then 'TDF+3TC+DTG'
						when 23786 then 'ABC+3TC+DTG'
						when 6116 then 'AZT+3TC+ABC'
						when 6106 then 'ABC+3TC+LPV/r'
						when 6105 then 'ABC+3TC+NVP'
						when 6108 then 'TDF+3TC+LPV/r'
						when 23790 then 'TDF+3TC+LPV/r+RTV'
						when 23791 then 'TDF+3TC+ATV/r'
						when 23792 then 'ABC+3TC+ATV/r'
						when 23793 then 'AZT+3TC+ATV/r'
						when 23795 then 'ABC+3TC+ATV/r+RAL'
						when 23796 then 'TDF+3TC+ATV/r+RAL'
						when 23801 then 'AZT+3TC+RAL'
						when 23802 then 'AZT+3TC+DRV/r'
						when 23815 then 'AZT+3TC+DTG'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
						when 23797 then 'ABC+3TC+DRV/r+RAL'
						when 23798 then '3TC+RAL+DRV/r'
						when 23803 then 'AZT+3TC+RAL+DRV/r'						
						when 6243 then 'TDF+3TC+NVP'
						when 6103 then 'D4T+3TC+LPV/r'
						when 792 then 'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'						
						when 1311 then 'ABC+3TC+LPV/r'
						when 1312 then 'ABC+3TC+NVP'
						when 1313 then 'ABC+3TC+EFV'
						when 1314 then 'AZT+3TC+LPV/r'
						when 1315 then 'TDF+3TC+EFV'						
						when 6330 then 'AZT+3TC+RAL+DRV/r'						
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r'
						when 6326 then 'AZT+3TC+ABC+LPV/r'
						when 6327 then 'D4T+3TC+ABC+EFV'
						when 6328 then 'AZT+3TC+ABC+EFV'
						when 6109 then 'AZT+DDI+LPV/r'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
						when 21163 then 'AZT+3TC+LPV/r'						
						when 23799 then 'TDF+3TC+DTG'
						when 23800 then 'ABC+3TC+DTG'
						else 'OUTRO' end as ultimo_regime,
					ultimo_lev.encounter_datetime data_regime
			from 	obs o,				
					(	select p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id								
						where 	encounter_type=18 and e.voided=0 and
								encounter_datetime <=:endDate and e.location_id=:location and p.voided=0
						group by patient_id
					) ultimo_lev
			where 	o.person_id=ultimo_lev.patient_id and o.obs_datetime=ultimo_lev.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 and o.location_id=:location
		) regime on regime.patient_id=visita.patient_id
        
  left join    
  ( 
  select e.patient_id, ult_recp.encounter_datetime as data_ult_levantamento, max(o.value_datetime) as prox_marcado
  from 
               
  encounter e,
        obs o,
        	(	select patient_id,max(encounter_datetime) encounter_datetime,location_id
			    from encounter 
			where encounter_type=52 and voided=0 and encounter_datetime   -- between :startDate and :endDate and location_id=:location 
			group by patient_id
		) ult_recp  	
        
        where  e.encounter_id = o.encounter_id
        and e.encounter_datetime =ult_recp.encounter_datetime
        and e.patient_id =ult_recp.patient_id
        and o.concept_id= 23866          
        group by e.patient_id
        ) ult_recepcao_lev on ult_recepcao_lev.patient_id=visita.patient_id
        
left join(

SELECT patient_id,MAX(encounter_datetime) encounter_datetime, MAX(value_datetime) AS value_datetime --  , source
				FROM
				(
					SELECT ultimofila.patient_id,ultimofila.encounter_datetime,o.value_datetime  -- , 'Fila' as 'source' 
					FROM

					(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	encounter e 
								INNER JOIN patient p ON p.patient_id=e.patient_id 		
						WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=18 AND e.location_id=:location AND 
								e.encounter_datetime between :startDate and :endDate
						GROUP BY p.patient_id
					) ultimofila
					INNER JOIN encounter e ON e.patient_id=ultimofila.patient_id
					INNER JOIN obs o ON o.encounter_id=e.encounter_id			
					WHERE o.concept_id=5096 AND o.voided=0 AND e.encounter_datetime=ultimofila.encounter_datetime AND 
					e.encounter_type=18 AND e.location_id=:location 
					) last_ group by patient_id
) ult_lev_prox_mar on ult_lev_prox_mar.patient_id = visita.patient_id
                        
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
			) pad3 ON pad3.person_id=visita.patient_id		



left join (
	Select ultimavisita.patient_id,ultimavisita.encounter_datetime ,o.value_datetime
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type in (9,6) 
				group by p.patient_id
			) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			left join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
			e.encounter_type in (9,6) and e.location_id=:location 
            ) ult_seguimento on ult_seguimento.patient_id = visita.patient_id


		/** **************************************** Tipo dispensa  concept_id = 23739 **************************************** **/
    LEFT JOIN 
		( SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 23888  THEN 'DISPENSA SEMESTRAL'
					WHEN 1098 THEN 'DISPENSA MENSAL'
					WHEN 23720 THEN 'DISPENSA TRIMESTRAL'
				ELSE '' END AS tipodispensa,
                e.encounter_datetime
                from encounter e inner join
                ( select e.patient_id, max(encounter_datetime) as data_ult_tipo_dis
					FROM 	obs o
					INNER JOIN encounter e ON o.encounter_id=e.encounter_id
					WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23739 AND o.location_id= :location
					group by patient_id ) ult_dispensa
					on e.patient_id =ult_dispensa.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9)
             and ult_dispensa.data_ult_tipo_dis = e.encounter_datetime 
             AND o.voided=0 AND o.concept_id = 23739
             group by patient_id
		) tipo_dispensa ON tipo_dispensa.patient_id=visita.patient_id
        
   