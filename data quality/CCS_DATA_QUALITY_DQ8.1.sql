/*

Name: CCS DATA QUALITY REPORT RDQ1
Created by: Agnaldo Samuel <agnaldosamuel@ccsaude.org.mz>
creation date: 16/08/2022
Description-
              - Pacientes com mais de uma data de inicio TPT - INH
*/
select
       pid.identifier AS NID,
       CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
	   p.gender,
	   DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
       ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
       DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
       all_inicios.*
from (
select in_inh_1.patient_id,
       in_inh_1.data_inicio_tpi as prim_data_inicio_inh,
       in_inh_2.data_inicio_tpi as seg_data_inicio_inh

from
        (
           
select patient_id, min(data_inicio_tpi) data_inicio_tpi
	from (
			/*
					Patients who have  (Profilaxia
					TPT with the value 'Isoniazida (INH)' and Estado da Profilaxia with the
					value 'Inicio (I)') marked on Ficha Clínica , Ficha Seguimento and Ficha Resumo
			*/

			select p.patient_id, min(obsInicioINH.obs_datetime) data_inicio_tpi
			from patient p
				inner join encounter e on p.patient_id = e.patient_id
				inner join obs o on o.encounter_id = e.encounter_id
				inner join obs obsInicioINH on obsInicioINH.encounter_id = e.encounter_id
			where e.voided=0 and p.voided=0 and o.voided=0 and e.encounter_type in (6,9,53)and o.concept_id=23985 and o.value_coded=656
				and obsInicioINH.concept_id=165308 and obsInicioINH.value_coded=1256 and obsInicioINH.voided=0
				and obsInicioINH.obs_datetime between (:endDate - interval 10 year) and :endDate and  e.location_id=:location
				group by p.patient_id

			union

			/*
			 *   Patients who have Regime de TPT with the values ('Isoniazida' or
					'Isoniazida + Piridoxina') and 'Seguimento de tratamento TPT' = (‘Inicio’ or
					‘Re-Inicio’) marked on Ficha de Levantamento de TPT (FILT) during the
					previous reporting period (INH Start Date)
			 *
			 */
			select p.patient_id,min(seguimentoTPT.obs_datetime) data_inicio_tpi
			from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
				inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
			where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime between (:endDate - interval 10 year ) and :endDate
				and seguimentoTPT.voided =0 and seguimentoTPT.concept_id = 23987 and seguimentoTPT.value_coded in (1256,1705)
				and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
				group by p.patient_id


	 	)
	inicio_INH group by patient_id

        )  in_inh_1

        left join  (select patient_id, max(data_inicio_tpi) data_inicio_tpi

	from (
			/*
					Patients who have  (Profilaxia
					TPT with the value 'Isoniazida (INH)' and Estado da Profilaxia with the
					value 'Inicio (I)') marked on Ficha Clínica , Ficha Seguimento and Ficha Resumo
			*/

			select p.patient_id, max(obsInicioINH.obs_datetime) data_inicio_tpi
			from patient p
				inner join encounter e on p.patient_id = e.patient_id
				inner join obs o on o.encounter_id = e.encounter_id
				inner join obs obsInicioINH on obsInicioINH.encounter_id = e.encounter_id
			where e.voided=0 and p.voided=0 and o.voided=0 and e.encounter_type in (6,9,53)and o.concept_id=23985 and o.value_coded=656
				and obsInicioINH.concept_id=165308 and obsInicioINH.value_coded=1256 and obsInicioINH.voided=0
				and obsInicioINH.obs_datetime between (:endDate - interval 10 year) and :endDate and  e.location_id=:location
				group by p.patient_id

			union

			/*
			 *   Patients who have Regime de TPT with the values ('Isoniazida' or
					'Isoniazida + Piridoxina') and 'Seguimento de tratamento TPT' = (‘Inicio’ or
					‘Re-Inicio’) marked on Ficha de Levantamento de TPT (FILT) during the
					previous reporting period (INH Start Date)
			 *
			 */
			select p.patient_id,max(seguimentoTPT.obs_datetime) data_inicio_tpi
			from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
				inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
			where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime between (:endDate - interval 10 year ) and :endDate
				and seguimentoTPT.voided =0 and seguimentoTPT.concept_id = 23987 and seguimentoTPT.value_coded in (1256,1705)
				and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
				group by p.patient_id


	 	)
	inicio_INH group by patient_id
                           
                              )  in_inh_2 on in_inh_2.patient_id =in_inh_1.patient_id
        where    in_inh_1.data_inicio_tpi <> in_inh_2.data_inicio_tpi

     )  all_inicios

    LEFT JOIN person p ON p.person_id=all_inicios.patient_id

LEFT JOIN
(   SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
					(
						SELECT patient_id,MIN(patient_identifier_id) id
						FROM patient_identifier
						WHERE voided=0
						GROUP BY patient_id
					) pid2
					WHERE pid1.patient_id=pid2.patient_id AND pid1.patient_identifier_id=pid2.id
)  pid ON pid.patient_id=all_inicios.patient_id

LEFT JOIN
(	SELECT patient_id,MIN(data_inicio) data_inicio
		FROM
			(

			 --  Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date

						SELECT 	p.patient_id,MIN(e.encounter_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON o.encounter_id=e.encounter_id
						WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND
								e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND
								e.encounter_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients on ART who have art start date ART Start date*/
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9,53) AND
								o.concept_id=1190 AND o.value_datetime IS NOT NULL AND
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id

						UNION

						/*Patients enrolled in ART Program OpenMRS Program*/
						SELECT 	pg.patient_id,MIN(date_enrolled) data_inicio
						FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
						WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=:endDate AND location_id=:location
						GROUP BY pg.patient_id

						UNION


						/*Patients with first drugs pick up date set in Pharmacy First ART Start Date*/
						  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
						  FROM 		patient p
									INNER JOIN encounter e ON p.patient_id=e.patient_id
						  WHERE		p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=:endDate AND e.location_id=:location
						  GROUP BY 	p.patient_id




			) inicio
		GROUP BY patient_id
)  inicio_real ON inicio_real.patient_id=all_inicios.patient_id

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
) pn ON pn.person_id=all_inicios.patient_id

