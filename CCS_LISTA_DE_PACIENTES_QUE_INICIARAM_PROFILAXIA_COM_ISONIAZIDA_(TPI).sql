/*
Name: CCS LISTA DE PACIENTES QUE INICIARAM PROFILAXIA COM ISONIAZIDA (TPI)
Description:
              - CCS LISTA DE PACIENTES QUE INICIARAM PROFILAXIA COM ISONIAZIDA (TPI)

Created By: Agnaldo S.
Created Date: NA

Change by: Agnaldo  Samuel
Change Date: 06/06/2021 
Change Reason: Bug fix
-- CD4 & Tipo de dispensa
*/

	select *
from 

(Select inicio_tpi.patient_id,
		inicio_tpi.data_inicio_tpi,
		terminou_tpi.data_final_tpi,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) nome,
		pid.identifier as nid,
        round(datediff(:endDate,p.birthdate)/365) idade_actual,
		 DATE_FORMAT(seguimento.ultimo_seguimento, '%d/%m/%Y') as ultimo_seguimento,
        DATE_FORMAT(ult_seguimento.value_datetime,'%d/%m/%Y') as data_proxima_visita,
        DATE_FORMAT(levantamento.ultimo_levantamneto, '%d/%m/%Y') as data_ultimo_levantamento,
        DATE_FORMAT(proximo_levantamento.value_datetime,'%d/%m/%Y') as data_proximo_levantamento,
		if(obs.value_coded is not null,if(obs.value_coded in (1065,1257),'Sim','Não'),'SI') recebeu_profilaxia,
		 DATE_FORMAT(date_add(date_add(inicio_tpi.data_inicio_tpi, interval 6 month), interval -1 day) ,'%d/%m/%Y') as data_completa_6meses,
		DATE_FORMAT(inicio_tarv.data_inicio ,'%d/%m/%Y')  as data_inicio_tarv,
        saida.estado
       
from 
(	select inicio_tpi.patient_id,min(inicio_tpi.data_inicio_tpi) data_inicio_tpi
	from 
	(	select 	p.patient_id,min(o.value_datetime) data_inicio_tpi
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9,53) and e.location_id=:location
		group by p.patient_id
		
		union 
		
		select 	p.patient_id,min(e.encounter_datetime) data_inicio_tpi
		from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
		where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and :endDate and
				o.voided=0 and o.concept_id=6122 and o.value_coded=1256 and e.encounter_type in (6,9) and  e.location_id=:location
		group by p.patient_id	
		
	) inicio_tpi
	group by inicio_tpi.patient_id
) inicio_tpi
left join 
(	

	select patient_id, max(data_final_tpi) data_final_tpi
	from 
		(
			select 	p.patient_id,max(o.value_datetime) data_final_tpi
			from	patient p
					inner join encounter e on p.patient_id=e.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
			where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and curdate() and
					o.voided=0 and o.concept_id=6129 and e.encounter_type in (6,9,53) and e.location_id=:location
			group by p.patient_id
			
			union 
			
			select 	p.patient_id,max(e.encounter_datetime) data_final_tpi
			from	patient p
					inner join encounter e on p.patient_id=e.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
			where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and curdate() and
					o.voided=0 and o.concept_id=6122 and o.value_coded=1267 and e.encounter_type=6 and  e.location_id=:location
			group by p.patient_id
		) endTPI
	group by patient_id
	
) terminou_tpi on inicio_tpi.patient_id=terminou_tpi.patient_id and inicio_tpi.data_inicio_tpi<terminou_tpi.data_final_tpi
left join 
(	Select patient_id,min(data_inicio) data_inicio
		from
			(	
				
				/*Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date*/
			
				Select 	p.patient_id,min(e.encounter_datetime) data_inicio
				from 	patient p 
						inner join encounter e on p.patient_id=e.patient_id	
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and o.voided=0 and p.voided=0 and 
						e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
						e.encounter_datetime<=:endDate and e.location_id=:location
				group by p.patient_id
		
				union
		
				/*Patients on ART who have art start date: ART Start date*/
				Select 	p.patient_id,min(value_datetime) data_inicio
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9,53) and 
						o.concept_id=1190 and o.value_datetime is not null and 
						o.value_datetime<=:endDate and e.location_id=:location
				group by p.patient_id

				union

				/*Patients enrolled in ART Program: OpenMRS Program*/
				select 	pg.patient_id,min(date_enrolled) data_inicio
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=:endDate and location_id=:location
				group by pg.patient_id
				
				/*union
				
				  Cause Null for mistyped arv pickup dates
				  Patients with first drugs pick up date set in Pharmacy: First ART Start Date
				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							inner join encounter e on p.patient_id=e.patient_id
				  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=:endDate and e.location_id=:location
				  GROUP BY 	p.patient_id */
			  
			) inicio_real
		group by patient_id
)inicio_tarv on inicio_tpi.patient_id=inicio_tarv.patient_id

left join 
(	select  p.patient_id,max(encounter_datetime) ultimo_seguimento
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
	where 	e.voided=0 and p.voided=0 and e.encounter_datetime  and
			e.encounter_type in (6,9) and e.location_id=:location
	group by p.patient_id
) seguimento on inicio_tpi.patient_id=seguimento.patient_id 

left join obs on obs.person_id=seguimento.patient_id and obs.obs_datetime=seguimento.ultimo_seguimento and obs.voided=0 and obs.concept_id =6122 and obs.location_id=:location

left join (
	Select ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type in (9,6) 
				group by p.patient_id
			) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
			e.encounter_type in (9,6) and e.location_id=:location 
            ) ult_seguimento on ult_seguimento.patient_id = inicio_tpi.patient_id


left join (
	select  p.patient_id,max(encounter_datetime) ultimo_levantamneto
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
	where 	e.voided=0 and p.voided=0 and e.voided=0 and
			e.encounter_type=18 and e.location_id=:location
	group by p.patient_id
)levantamento on levantamento.patient_id = inicio_tpi.patient_id



left join (
Select ultimo_levantamento.patient_id,ultimo_levantamento.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type=18 
				group by p.patient_id
			) ultimo_levantamento
			inner join encounter e on e.patient_id=ultimo_levantamento.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=5096 and o.voided=0 and e.voided=0 and e.encounter_datetime=ultimo_levantamento.encounter_datetime and 
			e.encounter_type=18 and e.location_id=:location 
            ) proximo_levantamento on proximo_levantamento.patient_id = inicio_tpi.patient_id


left join 
(	select pid1.*
	from patient_identifier pid1
	inner join 
		(
			select patient_id,min(patient_identifier_id) id 
			from patient_identifier
			where voided=0
			group by patient_id
		) pid2
	where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
) pid on pid.patient_id=inicio_tpi.patient_id
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
) pn on pn.person_id=inicio_tpi.patient_id
/* Get patient birthdate and Age */
left  join person p on p.person_id=inicio_tpi.patient_id

LEFT JOIN
			(		
				SELECT 	pg.patient_id,ps.start_date encounter_datetime,location_id,
						CASE ps.state
							WHEN 7 THEN 'TRANSFERIDO PARA'
							WHEN 8 THEN 'SUSPENSO'
							WHEN 9 THEN 'ABANDONO'
							WHEN 10 THEN 'OBITO'
						ELSE 'OUTRO' END AS estado
				FROM 	patient p 
						INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
				WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
						pg.program_id=2 AND ps.state IN (7,8,9,10) AND ps.end_date IS NULL AND location_id=:location AND ps.start_date<= :endDate
			
			) saida ON saida.patient_id=inicio_tpi.patient_id
) tpi 
group by patient_id
