
/*
Name: CCS LISTA DE PACIENTES ACTIVOS COM CARGA VIRAL NA FICHA MESTRA - MISAU
Description:
              - CCS LISTA DE PACIENTES ACTIVOS COM CARGA VIRAL NA FICHA MESTRA - MISAU

Created By: Colaco C.
Created Date: NA

Change by: Agnaldo  Samuel
Change Date: 06/06/2021 
Change Reason: Bug fix
 - Considera a carga viral qualitativa ( novos instrumentos)

*/

select 	concat(pid.identifier,' ') as NID,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
		inicio_real.data_inicio,
                pat.value as Telefone,
		DATE_FORMAT(seguimento.data_seguimento,'%d/%m/%Y') as data_seguimento,
		DATE_FORMAT(carga1.data_primeiro_carga,'%d/%m/%Y') as data_primeiro_carga,
		carga1.valor_primeira_carga,
		if(carga1.data_primeiro_carga<>carga2.data_ultima_carga,DATE_FORMAT(carga2.data_ultima_carga,'%d/%m/%Y'),'') as data_ultima_carga,
		if(carga1.data_primeiro_carga<>carga2.data_ultima_carga,carga2.valor_ultima_carga,'') as valor_ultima_carga,		
		DATE_FORMAT(regime.data_regime,'%d/%m/%Y') as data_regime,
		regime.ultimo_regime,
		pe.gender,
		round(datediff(:endDate,pe.birthdate)/365) idade_actual
from						
		
		(	Select ultimavisita.patient_id,ultimavisita.encounter_datetime,max(o.value_datetime) value_datetime,e.location_id
			from
				(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
					from 	encounter e 
							inner join patient p on p.patient_id=e.patient_id 		
					where 	e.voided=0 and p.voided=0 and e.encounter_type in (18,9,6) and 
							e.location_id=:location and e.encounter_datetime<=:endDate
					group by p.patient_id
				) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			left join obs o on o.encounter_id=e.encounter_id and (o.concept_id=5096 OR o.concept_id=1410) and 
			e.encounter_datetime=ultimavisita.encounter_datetime			
			where  o.voided=0 and e.encounter_type in (18,9,6) and e.location_id=:location and datediff(:endDate,o.value_datetime) < 60 
		  group by e.patient_id
		) visita 
		
		inner join
		(select patient_id,min(data_primeiro_carga) data_primeiro_carga,max(value_numeric) valor_primeira_carga
			from	
				(	select 	e.patient_id,
							min(o.obs_datetime) data_primeiro_carga
					from 	encounter e
							inner join obs o on e.encounter_id=o.encounter_id
					where 	e.encounter_type in (6,9) and e.form_id = 163 and e.voided=0 and
							o.voided=0 and o.concept_id=856 and e.encounter_datetime between date_add(:endDate, interval -3 month) and :endDate 
					 and e.location_id=:location
					group by e.patient_id
				) primeiro_carga
				inner join obs o on o.person_id=primeiro_carga.patient_id and o.obs_datetime=primeiro_carga.data_primeiro_carga
			where o.concept_id=856 and o.voided=0
			group by patient_id
		) carga1 on carga1.patient_id = visita.patient_id

		left join
		(	select e.patient_id,max(encounter_datetime) data_ultima_carga, o.value_numeric valor_ultima_carga
			from	
				(	select 	e.patient_id,
							max(o.obs_datetime) data_ultima_carga
					from 	encounter e
							inner join obs o on e.encounter_id=o.encounter_id
					where 	e.encounter_type in (6,9) and e.form_id = 163 and e.voided=0 and
						o.voided=0 and o.concept_id=856 and e.encounter_datetime between date_add(:endDate, interval -3 month) and :endDate 
					and e.location_id=:location
					group by e.patient_id
				) ultima_carga
				inner join encounter e on e.patient_id = ultima_carga.patient_id
				inner join obs o on o.encounter_id=e.encounter_id 
				where  e.encounter_datetime=ultima_carga.data_ultima_carga and  o.concept_id=856 and o.voided=0 and e.voided=0
				and e.form_id = 163
			group by e.patient_id
		) carga2 on carga2.patient_id= visita.patient_id
		
		left join 		
		(	Select patient_id,min(data_inicio) data_inicio
			from
				(	

				/*Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date*/
				
						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p 
								INNER JOIN encounter e ON p.patient_id=e.patient_id	
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
								e.encounter_datetime<= :endDate AND e.location_id= :location
						GROUP BY p.patient_id
				
						UNION
				
						/*Patients on ART who have art start date: ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND 
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
								o.value_datetime<= :endDate AND e.location_id= :location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program: OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<= :endDate AND location_id= :location
						GROUP BY pg.patient_id
						
						UNION
						
						
						/*Patients with first drugs pick up date set in Pharmacy: First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<= :endDate AND e.location_id= :location
						  GROUP BY 	p.patient_id
					  

				) inicio
			group by patient_id
		) inicio_real on inicio_real.patient_id = visita.patient_id

		left join 
		(	select pad1.*
			from person_address pad1
			inner join 
			(
				select person_id,min(person_address_id) id 
				from person_address
				where voided=0
				group by person_id
			) pad2
			where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
		) pad3 on pad3.person_id=visita.patient_id				
		left join 			
		(	select pn1.*
			from person_name pn1
			inner join 
			(
				select person_id,min(person_name_id) id 
				from person_name
				where voided=0
				group by person_id
			) pn2
			where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
		) pn on pn.person_id=visita.patient_id			
		left join
		(       select pid1.*
				from patient_identifier pid1
				inner join
				(
					select patient_id,min(patient_identifier_id) id
					from patient_identifier
					where voided=0
					group by patient_id
				) pid2
				where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
		) pid on pid.patient_id=visita.patient_id

                inner join person pe on pe.person_id=visita.patient_id

		left join 
		(
			select 	ultimo_lev.patient_id,
					case o.value_coded						
						when 6103 then 'D4T+3TC+LPV/r'
							when 792 then 'D4T+3TC+NVP'
							when 1827 then 'D4T+3TC+EFV'
							when 6102 then 'D4T+3TC+ABC'
							when 6116 then 'AZT+3TC+ABC'
							when 6330 then 'AZT+3TC+RAL+DRV/r (3ª Linha)'
							when 6105 then 'ABC+3TC+NVP'
							when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
							when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
							when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
							when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
							when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'
							when 6106 then 'ABC+3TC+LPV/r'
							when 1313 then 'ABC+3TC+EFV(2ª Linha)'
							when 1311 then 'ABC+3TC+LPV/r(2ª Linha)'
							when 23799 then 'TDF+3TC+DTG(2ª Linha)'
							when 23800 then 'ABC+3TC+DTG(2ª Linha)'
							when 21163 then 'AZT+3TC+LPV/r(2ª Linha)'
							when 23801 then 'AZT+3TC+RAL(2ª Linha)'
							when 23802 then 'AZT+3TC+DRV/r(2ª Linha)'
							when 23815 then 'AZT+3TC+DTG(2ª Linha)'
							when 6329 then 'TDF+3TC+RAL+DRV/r(3ª Linha)'
							when 23803 then 'AZT+3TC+RAL+DRV/r(3ª Linha)'							
							when 1703 then 'AZT+3TC+EFV'
							when 6100 then 'AZT+3TC+LPV/r'
							when 1651 then 'AZT+3TC+NVP'
							when 6324 then 'TDF+3TC+EFV'
							when 6243 then 'TDF+3TC+NVP'
							when 6104 then 'ABC+3TC+EFV'
							when 23784 then 'TDF+3TC+DTG'
							when 23786 then 'ABC+3TC+DTG'
							when 23785 then 'TDF+3TC+DTG2'
							when 1311 then 'ABC+3TC+LPV/r(2ª Linha)'
							when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
							when 1314 then 'AZT+3TC+LPV/r(2ª Linha)'
							when 23790 then 'TDF+3TC+LPV/r+RTV(2ª Linha)'
							when 23791 then 'TDF+3TC+ATV/r(2ª Linha)'
							when 23792 then 'ABC+3TC+ATV/r(2ª Linha)'
							when 23793 then 'AZT+3TC+ATV/r(2ª Linha)'
							when 23795 then 'ABC+3TC+ATV/r+RAL(2ª Linha)'
							when 23796 then 'TDF+3TC+ATV/r+RAL(2ª Linha)'
							when 6329 then 'TDF+3TC+RAL+DRV/r(3ª Linha)'
							when 23797 then 'ABC+3TC++RAL+DRV/r(3ª Linha)'
							when 23798 then '3TC+RAL+DRV/r(3ª Linha)'					
					else 'OUTRO' end as ultimo_regime,
					ultimo_lev.encounter_datetime data_regime
			from 	obs o,				
					(	select p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id	
								inner join obs o on o.encounter_id=e.encounter_id
						where 	encounter_type=18 and e.voided=0 and o.concept_id=1088 and 
								encounter_datetime <=:endDate and e.location_id=:location and p.voided=0
						group by patient_id
					) ultimo_lev
			where 	o.person_id=ultimo_lev.patient_id and o.obs_datetime=ultimo_lev.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 and o.location_id=:location
		) regime on regime.patient_id=visita.patient_id

		left join 
		(	select e.patient_id,max(e.encounter_datetime) data_seguimento
			from encounter e
			inner join obs o on e.encounter_id=o.encounter_id
			where o.concept_id=856 and o.voided=0 and e.voided=0 and e.encounter_type in (6,9)  and e.encounter_datetime <= :endDate
			group by e.patient_id
		) seguimento on seguimento.patient_id=carga1.patient_id

		left join person_attribute pat on pat.person_id=inicio_real.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
group by carga1.patient_id