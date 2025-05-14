select *
from
	(select 	inscricao.patient_id,
			  DATE_FORMAT(inscricao.data_abertura, '%d/%m/%Y') AS data_abertura,
			pe.gender,
			if(cd4.value_numeric is not null , cd4.value_numeric , if(cd4_perc.value_numeric is not null, concat(cd4_perc.value_numeric, '%'), '' )
			 ) AS cd4,
			if(cd4.encounter_datetime is not null , DATE_FORMAT(cd4.encounter_datetime,'%d/%m/%Y')  , if(cd4_perc.encounter_datetime is not null, DATE_FORMAT(cd4_perc.encounter_datetime,'%d/%m/%Y') , '' )
			 ) AS data_cd4,
			pe.dead,
			pe.death_date,
			timestampdiff(year,pe.birthdate,inscricao.data_abertura) idade_abertura,
			timestampdiff(year,pe.birthdate,:endDate) idade_actual,
			pad3.county_district as 'Distrito',
			pad3.address2 as 'PAdministrativo',
			pad3.address6 as 'Localidade',
			pad3.address5 as 'Bairro',
			pad3.address1 as 'PontoReferencia',
			concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
			pid.identifier as NID,
			transferido.data_transferido_de,
			if(transferido.program_id is null,null,if(transferido.program_id=1,'PRE-TARV','TARV')) as transferido_de,
			inicio_real.data_inicio,
			 DATE_FORMAT(estadio.data_estadio, '%d/%m/%Y') AS data_estadio,
			estadio.valor_estadio,
			 DATE_FORMAT(seguimento.data_seguimento, '%d/%m/%Y') AS  data_seguimento,
			if(inscrito_cuidado.date_enrolled is null,'NAO','SIM') inscrito_programa,
			inscrito_cuidado.date_enrolled data_inscricao_programa,
			proveniencia.referencia,
			pat.value as telefone,
			contacto.data_aceita,
			diagnostico.data_diagnostico


	from
			(
				select patient_id,min(data_abertura) data_abertura
				from
				(
					select 	p.patient_id,min(e.encounter_datetime) data_abertura
					from 	patient p
							inner join encounter e on e.patient_id=p.patient_id
					where 	e.voided=0 and p.voided=0 and e.encounter_type in (5,7) and
							e.encounter_datetime<=:endDate and e.location_id = :location
					group by p.patient_id

					union

					select 	pg.patient_id,min(date_enrolled) data_abertura
					from 	patient p
							inner join patient_program pg on p.patient_id=pg.patient_id
					where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled<=:endDate and location_id=:location
					group by p.patient_id

					union

					Select 	p.patient_id,min(o.value_datetime) data_abertura
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=53 and
							o.concept_id=23891 and o.value_datetime is not null and
							o.value_datetime<=:endDate and e.location_id=:location
					group by p.patient_id
				) allInscrito
				group by patient_id
			) inscricao
			inner join person pe on pe.person_id=inscricao.patient_id and inscricao.data_abertura between :startDate and :endDate
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
			) pad3 on pad3.person_id=inscricao.patient_id
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
			) pn on pn.person_id=inscricao.patient_id
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
			) pid on pid.patient_id=inscricao.patient_id
			left join
			(
				select patient_id,max(data_transferido_de) data_transferido_de,program_id
				from
					(
						select 	pg.patient_id,max(ps.start_date) data_transferido_de,pg.program_id
						from 	patient p
								inner join patient_program pg on p.patient_id=pg.patient_id
								inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
						where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
								pg.program_id in (1,2) and ps.state in (28,29) and
								ps.start_date between :startDate and :endDate and location_id=:location
						group by pg.patient_id

						union

						Select 	p.patient_id,max(obsRegisto.value_datetime) data_transferido_de,if(obsTarv.value_coded=6276,2,1) program_id
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id
								inner join obs obsTrans on e.encounter_id=obsTrans.encounter_id and obsTrans.voided=0 and obsTrans.concept_id=1369 and obsTrans.value_coded=1065
								inner join obs obsTarv on e.encounter_id=obsTarv.encounter_id and obsTarv.voided=0 and obsTarv.concept_id=6300 and obsTarv.value_coded in (6276,6275)
								inner join obs obsRegisto on e.encounter_id=obsRegisto.encounter_id and obsRegisto.voided=0 and obsRegisto.concept_id=23891
						where 	p.voided=0 and e.voided=0 and e.encounter_type=53 and
								obsRegisto.value_datetime between :startDate and :endDate and e.location_id=:location
					) maxTransferido
				group by patient_id
			) transferido on transferido.patient_id=inscricao.patient_id and transferido.data_transferido_de<=inscricao.data_abertura
			left join
			(		Select patient_id,min(data_inicio) data_inicio
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

						union


						/*Patients with first drugs pick up date set in Pharmacy: First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
						  FROM 		patient p
									inner join encounter e on p.patient_id=e.patient_id
						  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=:endDate and e.location_id=:location
						  GROUP BY 	p.patient_id

						/*union

						Patients with first drugs pick up date set: Recepcao Levantou ARV
						Select 	p.patient_id,min(value_datetime) data_inicio
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id
								inner join obs o on e.encounter_id=o.encounter_id
						where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=52 and
								o.concept_id=23866 and o.value_datetime is not null and
								o.value_datetime<=:endDate and e.location_id=:location
						group by p.patient_id  */


					) inicio
				group by patient_id
			) inicio_real on inscricao.patient_id=inicio_real.patient_id
			left join
			(	select 	o.person_id patient_id,o.obs_datetime data_estadio,
						case o.value_coded
						when 1204 then 'I'
						when 1205 then 'II'
						when 1206 then 'III'
						when 1207 then 'IV'
						else 'OUTRO' end as valor_estadio
				from 	obs o,
						(	select 	p.patient_id,min(encounter_datetime) as encounter_datetime
							from 	patient p
									inner join encounter e on p.patient_id=e.patient_id
									inner join obs o on o.encounter_id=e.encounter_id
							where 	encounter_type in (6,9) and e.voided=0 and
									encounter_datetime between :startDate and :endDate and e.location_id=:location
									and p.voided=0 and o.voided=0 and o.concept_id=5356
							group by patient_id
						) d
				where 	o.person_id=d.patient_id and o.obs_datetime=d.encounter_datetime and o.voided=0 and
						o.concept_id=5356 and o.location_id=:location and o.value_coded in (1204,1205,1206,1207)
				group by d.patient_id
			)estadio on estadio.patient_id=inscricao.patient_id
/****************** ****************************  CD4  Absoluto  *****************************************************/
        LEFT JOIN(
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN
		    (
            SELECT 	cd4_max.patient_id, MIN(cd4_max.encounter_datetime) AS encounter_datetime
            FROM ( SELECT e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND e.location_id=:location  AND
							o.voided=0 AND o.concept_id=1695 AND e.encounter_type IN (6,9,13,53)
				) cd4_max
			GROUP BY patient_id ) cd4_temp
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id = 1695 AND e.encounter_type IN (6,9,13,53)
			GROUP BY patient_id

		) cd4 ON cd4.patient_id =  inscricao.patient_id
		/****************** ****************************  CD4  Percentual  *****************************************************/
        LEFT JOIN(
            SELECT e.patient_id, o.value_numeric,e.encounter_datetime
            FROM encounter e INNER JOIN
		    (
            SELECT 	cd4_max.patient_id, MIN(cd4_max.encounter_datetime) AS encounter_datetime
            FROM (
					SELECT 	 e.patient_id, o.value_numeric , encounter_datetime
					FROM encounter e
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0  AND  e.location_id=:location  AND
							o.voided=0 AND o.concept_id=730 AND e.encounter_type in (6,9,13,53)  )cd4_max
			GROUP BY patient_id ) cd4_temp
            ON e.patient_id = cd4_temp.patient_id
            INNER JOIN obs o ON o.encounter_id=e.encounter_id
            WHERE e.encounter_datetime=cd4_temp.encounter_datetime AND
			e.voided=0  AND  e.location_id=:location  AND
            o.voided=0 AND o.concept_id =730  AND e.encounter_type in (6,9,13,53)
			GROUP BY patient_id

		) cd4_perc ON cd4_perc.patient_id =  inscricao.patient_id

			left join
			(	select patient_id,min(encounter_datetime) data_seguimento
				from encounter
				where voided=0 and encounter_type in (6,9) and encounter_datetime between :startDate and :endDate
				group by patient_id
			) seguimento on seguimento.patient_id=inscricao.patient_id
			left join
			(
				select 	pg.patient_id,date_enrolled
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled between :startDate and :endDate and location_id=:location
			) inscrito_cuidado on inscrito_cuidado.patient_id=inscricao.patient_id
			left join
			(	select 	p.patient_id,
						case o.value_coded
						when 1595 then 'INTERNAMENTO'
						when 1596 then 'CONSULTA EXTERNA'
						when 1414 then 'PNCT'
						when 1597 then 'ATS'
						when 1987 then 'SAAJ'
						when 1598 then 'PTV'
						when 1872 then 'CCR'
						when 1275 then 'CENTRO DE SAUDE'
						when 1984 then 'HR'
						when 1599 then 'PROVEDOR PRIVADO'
						when 1932 then 'PROFISSIONAL DE SAUDE'
						when 1387 then 'LABORATÓRIO'
						when 1386 then 'CLINICA MOVEL'
						when 6245 then 'ATSC'
						when 1699 then 'CUIDADOS DOMICILIARIOS'
						when 2160 then 'VISITA DE BUSCA'
						when 1985 then 'CPN'
						when 6288 then 'SMI'
						when 5484 then 'APOIO NUTRICIONAL'
						when 6155 then 'MEDICO TRADICIONAL'
						when 1044 then 'PEDIATRIA'
						when 6303 then 'VGB'
						when 6304 then 'ATIP'
						when 6305 then 'OBC'
						when 21275 then 'CLÍNICA'
						else 'OUTRO' end as referencia
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	encounter_type in (5,7,53) and e.voided=0 and
						encounter_datetime between :startDate and :endDate and e.location_id=:location
						and p.voided=0 and o.voided=0 and o.concept_id in (23783,1594)
			)proveniencia on proveniencia.patient_id=inscricao.patient_id
			left join person_attribute pat on pat.person_id=inscricao.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
			left join
			(	select 	p.patient_id,min(encounter_datetime) as data_aceita
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	encounter_type in (34,35) and e.voided=0 and
						encounter_datetime<=:endDate and e.location_id=:location
						and p.voided=0 and o.voided=0 and o.concept_id=6309 and o.value_coded=6307
				group by patient_id
			) contacto on contacto.patient_id=inscricao.patient_id
			left join
			(
				select patient_id,min(data_diagnostico) data_diagnostico
				from
				(
					select 	p.patient_id,min(o.value_datetime) as data_diagnostico
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on o.encounter_id=e.encounter_id
					where 	encounter_type in (5,7) and e.voided=0 and o.value_datetime<=:endDate and e.location_id=:location
							and p.voided=0 and o.voided=0 and o.concept_id=6123
					group by patient_id

					union

					Select 	p.patient_id,min(o.value_datetime) data_diagnostico
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type=53 and
							o.concept_id=22772 and o.value_datetime is not null and
							o.value_datetime<=:endDate and e.location_id=:location
					group by p.patient_id
				) diag
				group by patient_id
			) diagnostico on diagnostico.patient_id=inscricao.patient_id
	)inscritos
group by patient_id