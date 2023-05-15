select *
from
(	select 	inicio_real.patient_id,
				 DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
				pad3.county_district as 'Distrito',
				pad3.address2 as 'PAdministrativo',
				pad3.address6 as 'Localidade',
				pad3.address5 as 'Bairro',
				pad3.address1 as 'PontoReferencia',
				concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',					
				pid.identifier as NID,
				p.gender,
                resultado_via.resultado_via,
                DATE_FORMAT(repetir_via.data_repeticao,'%d/%m/%Y') as      data_repeticao,
                crioterapia.crioterapia_resultado,
                telef.value as telefone, 
				round(datediff(:endDate,p.birthdate)/365) idade_actual,
                if(pad3.person_address_id is null,' ',concat(' ',ifnull(pad3.address2,''),' ',
                ifnull(pad3.address5,''),' ',ifnull(pad3.address3,''),' ',ifnull(pad3.address1,''),' ',
                ifnull(pad3.address4,''),' ',ifnull(pad3.address6,''))) as endereco,
				DATE_FORMAT(visita.encounter_datetime,'%d/%m/%Y') as  ultima_consulta,
				DATE_FORMAT(visita.value_datetime ,'%d/%m/%Y') as proximo_marcado,
				regime.ultimo_regime,
				DATE_FORMAT(regime.data_regime,'%d/%m/%Y') as data_regime,
				if(programa.patient_id is null,'NAO','SIM') inscrito_programa,
				DATE_FORMAT(inicio_tpi.data_inicio_tpi,'%d/%m/%Y') as data_inicio_tpi,
                DATE_FORMAT(patient_cacum.data_rastreio_cacum,'%d/%m/%Y') as data_rastreio_cacum
		
        from	(
        
            /**** cacum formulario ccu ****/
            
            select patient_id, max(data_rastreio_cacum) data_rastreio_cacum
            from 
                (
				select 	p.patient_id,encounter_datetime as data_rastreio_cacum
				from 	patient p					 
						inner join encounter e on p.patient_id=e.patient_id 
				where 	 p.voided=0 and e.encounter_type=28 and and e.voided=0 and p.voided=0
						e.encounter_datetime between :startDate and :endDate  and e.location_id=:location 
              
                union 
            /******* cacum programa ccu**************/
				select 	pg.patient_id, date_enrolled as data_rastreio_cacum
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=7 and date_enrolled between :startDate and :endDate and location_id=:location
			 ) rastreio_cacum group by patient_id
   
) patient_cacum

left join (
select patient_id,data_inicio
from (	
Select patient_id,min(data_inicio) data_inicio
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
						
			) inicio
		group by patient_id	
	)inicio1
)inicio_real on inicio_real.patient_id = patient_cacum.patient_id
			
            
inner join person p on p.person_id=patient_cacum.patient_id
		
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
			) pad3 on pad3.person_id=patient_cacum.patient_id				
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
			) pn on pn.person_id=patient_cacum.patient_id		
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
			) pid on pid.patient_id=patient_cacum.patient_id	
            

			left join 
			(	SELECT ultimavisita.patient_id,MAX(ultimavisita.encounter_datetime) as encounter_datetime,o.value_datetime
			FROM
				(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e 
							INNER JOIN obs o  ON e.encounter_id=o.encounter_id 		
					WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type in (6,9) AND 
							e.location_id=:location 
					GROUP BY e.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                where  o.concept_id=1410 AND e.encounter_datetime=ultimavisita.encounter_datetime and			
			  o.voided=0  AND e.voided =0 AND e.encounter_type  in (6,9)  AND e.location_id=:location
              group by ultimavisita.patient_id
            
			) visita on visita.patient_id=patient_cacum.patient_id
			left join 
			(
	select 	e.patient_id,
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
                        
                        end as ultimo_regime,
						e.encounter_datetime data_regime
				from 	encounter e
                inner join
                         ( select e.patient_id,max(encounter_datetime) encounter_datetime 
                         from encounter e 
                         inner join obs o on e.encounter_id=o.encounter_id
                         where 	encounter_type =18 and e.voided=0 and o.voided=0 
                         group by e.patient_id
                         ) ultimofila
				on e.patient_id=ultimofila.patient_id
                inner join obs o on o.encounter_id=e.encounter_id 
				where  ultimofila.encounter_datetime = e.encounter_datetime and
                        encounter_type =18 and e.voided=0 and o.voided=0 and 
						o.concept_id=1088 and e.location_id=:location
              group by patient_id
                        
			) regime on regime.patient_id=patient_cacum.patient_id
            
			left join
			(
				select 	pg.patient_id
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=:endDate and location_id=:location
			) programa on programa.patient_id=patient_cacum.patient_id
	
   /** ************************** Resultado VIA concept_id = 2094  * ********************************************** **/
        LEFT JOIN 
		(SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 703  THEN 'VIA Positivo'
					WHEN 664  THEN 'VIA Negativo'
					WHEN 2093  THEN 'Suspeita de cancro'
                    WHEN 5622  THEN 'Outro'
				ELSE '' END AS resultado_via,
                encounter_datetime as data_resultado_via
             from obs o
			INNER JOIN encounter e ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,28,18,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 2094 
            group by patient_id
		) resultado_via ON resultado_via.patient_id=patient_cacum.patient_id and resultado_via.data_resultado_via =patient_cacum.data_rastreio_cacum



/****************************** Repeticao da via *************************************/

left join (

SELECT 	e.patient_id,
				o.value_datetime as data_repeticao,
                o.obs_datetime,
                encounter_datetime 
             from obs o
			INNER JOIN encounter e ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,28,18,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 2116

) repetir_via on repetir_via.patient_id=patient_cacum.patient_id and repetir_via.encounter_datetime =patient_cacum.data_rastreio_cacum

/****************************** Crioterapia CSO VIA POSITIVA *************************************/

left join (

SELECT 	e.patient_id,
					CASE o.value_coded
			       WHEN 1065 THEN 'SIM'
					WHEN 1066  THEN 'ADIADA'
                    END AS crioterapia_resultado,
                    encounter_datetime
             from obs o
			INNER JOIN encounter e ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,28,18,9) AND e.voided=0 AND o.voided=0 AND o.concept_id = 2117

) crioterapia on crioterapia.patient_id=patient_cacum.patient_id and crioterapia.encounter_datetime =patient_cacum.data_rastreio_cacum


LEFT JOIN (
		SELECT  p.person_id, p.value  
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9 
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0 
	) telef  ON telef.person_id = patient_cacum.patient_id


			left join
			(	select p.patient_id,max(value_datetime) data_inicio_tpi
				from	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and p.voided=0 and o.value_datetime<=:endDate and
						o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9,53) and e.location_id=:location
				group by p.patient_id
				
				union
				
				select p.patient_id,max(e.encounter_datetime) data_inicio_tpi
				from	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and p.voided=0 and o.obs_datetime<=:endDate and
						o.voided=0 and o.concept_id=6122 and o.value_coded=1256 and e.encounter_type in (6,9) and e.location_id=:location
				group by p.patient_id
				
			) inicio_tpi on inicio_tpi.patient_id=patient_cacum.patient_id
	)inicios



where patient_id not in 
			(			
				select 	pg.patient_id
				from 	patient p 
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
						pg.program_id=2 and ps.state=29 and ps.start_date=pg.date_enrolled and 
						ps.start_date between :startDate and :endDate and location_id=:location
				/*union
				
				 TRANSFERED IN PATIENTS FICHA RESUMO
				Select 	p.patient_id
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs obsTrans on e.encounter_id=obsTrans.encounter_id and obsTrans.voided=0 and obsTrans.concept_id=1369 and obsTrans.value_coded=1065
						inner join obs obsTarv on e.encounter_id=obsTarv.encounter_id and obsTarv.voided=0 and obsTarv.concept_id=6300 and obsTarv.value_coded=6276 
						inner join obs obsRegisto on e.encounter_id=obsRegisto.encounter_id and obsRegisto.voided=0 and obsRegisto.concept_id=23891
				where 	p.voided=0 and e.voided=0 and e.encounter_type=53 and  
						obsRegisto.value_datetime between :startDate and :endDate and e.location_id=:location*/

			)
group by patient_id
