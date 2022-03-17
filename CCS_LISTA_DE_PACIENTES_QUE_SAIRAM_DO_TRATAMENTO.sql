USE 1_maio;
SET @startDate:='2017-01-01';
SET @endDate:='2018-01-01';
SET @location:=208;

select 	saida_real.patient_id,
		saida_real.encounter_datetime as data_saida,
		saida_real.estado,
                tipo_dispensa.tipodispensa,
                   estadio_oms.estadio_om,
                   profissao.value_text as profissao,
		pe.county_district as 'Distrito',
		pe.address2 as 'PAdministrativo',
		pe.address6 as 'Localidade',
		pe.address5 as 'Bairro',
		pe.address1 as 'PontoReferencia',
	
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
		pid.identifier as NID,
		p.gender,
		round(datediff(@endDate,p.birthdate)/365) idade_actual		
	
from 
		(	select 	pg.patient_id,ps.start_date encounter_datetime,
					case ps.state
					when 7 then 'TRANSFERIDO PARA'
					when 8 then 'SUSPENDEU TRATAMENTO'
					when 9 then 'ABANDONO'
					when 10 then 'OBITO'
					else 'OUTRO' end as estado
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and location_id=@location
                  
                  union all
                    
                   Select ultimavisita_perm_tarv.patient_id, ultimavisita_perm_tarv.encounter_datetime ,
                     CASE o.value_coded
					WHEN '1707'  THEN 'ABANDONO'
					WHEN '1709' THEN 'SUSPENDEU TRATAMENTO'
					WHEN '1706' THEN 'TRANSFERIDO PARA'
					WHEN '1366'  THEN 'OBITO'
				ELSE 'OUTRO' END AS estado
			from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime, e.encounter_type
				from 	encounter e 
                        inner join obs o on o.encounter_id =e.encounter_id
				       and 	e.voided=0  and o.voided=0   and o.concept_id=6273 and e.encounter_type IN (6,9)  and e.location_id=@location 
				group by e.patient_id
			) ultimavisita_perm_tarv
			inner join encounter e on e.patient_id=ultimavisita_perm_tarv.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=6273 and o.voided=0 and e.encounter_datetime=ultimavisita_perm_tarv.encounter_datetime and 
			e.encounter_type in (6,9)  and e.location_id=@location 
			group by e.patient_id
		) saida_real
        
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
	) pn on pn.person_id=saida_real.patient_id	

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
	) pid on pid.patient_id=saida_real.patient_id

left join 
	(
		select person_id,gender,birthdate from person 
		where voided=0 
		group by person_id
		
	) p on p.person_id = pn.person_id

left join person_address pe on pe.person_id=saida_real.patient_id and pe.preferred=1
          
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
					WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 23739 AND o.location_id=@location
					group by patient_id ) ult_dispensa
					on e.patient_id =ult_dispensa.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53)
             and ult_dispensa.data_ult_tipo_dis = e.encounter_datetime 
             AND o.voided=0 AND o.concept_id = 23739
             group by patient_id
		) tipo_dispensa ON tipo_dispensa.patient_id=saida_real.patient_id
        
           /* *********************** estadio OMS concept_id = 5356  * ********************************************** **/
        LEFT JOIN 
		(
        			    SELECT e.patient_id,
						 o.value_coded AS estadio,
                         case o.value_coded
                         when 1204 then 'ESTADIO I OMS'
                         when 1205 then 'ESTADIO II OMS'
                         when 1206 then 'ESTADIO III OMS'
                         when 1207 then 'ESTADIO IV OMS'
                         end as estadio_om,
                  	     e.encounter_datetime as data_linhat
			FROM encounter e
               INNER JOIN (
                   SELECT patient_id,  MAX(e.encounter_datetime) as data_estadio
                   FROM 	   encounter e     
                                inner join obs o on o.encounter_id =e.encounter_id
								where e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 5356 
                                and e.location_id=@location
                   group by patient_id
                     
                   ) ultimo_estadio on ultimo_estadio.patient_id=e.patient_id
			INNER JOIN  obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 5356  and e.encounter_datetime=ultimo_estadio.data_estadio
            group by patient_id
		) estadio_oms ON estadio_oms.patient_id=saida_real.patient_id
        
           /* *********************** estadio OMS concept_id = 5356  * ********************************************** **/
        LEFT JOIN 
		(
        			    SELECT e.patient_id,
						o.value_text
                  	    FROM encounter e
               INNER JOIN (
                   SELECT patient_id,  MAX(e.encounter_datetime) as data_prof
                   FROM 	   encounter e     
                                inner join obs o on o.encounter_id =e.encounter_id
								where e.encounter_type = 53 AND e.voided=0 AND o.voided=0 AND o.concept_id = 1459 
                                and e.location_id=@location
                   group by patient_id
                     
                   ) ultimo_prof on ultimo_prof.patient_id=e.patient_id
			INNER JOIN  obs o ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type = 53 AND e.voided=0 AND o.voided=0 AND o.concept_id = 1459  and e.encounter_datetime=ultimo_prof.data_prof
            group by patient_id
		) profissao ON profissao.patient_id=saida_real.patient_id        
        
        
        
where saida_real.encounter_datetime between @startDate and @endDate;