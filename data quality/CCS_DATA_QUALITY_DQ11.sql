/*
NAME:  	CCS LISTA DE PACIENTES COM SEGUIMENTO SEM FILA E COM FILA SEM SEGUIMENTO NA MESMA DATA
Created by: Colaco Cardoso
creation date: 20/02/2019
Description:
        - 	PCCS LISTA DE PACIENTES COM SEGUIMENTO SEM FILA E COM FILA SEM SEGUIMENTO NA MESMA DATA

Modified by: Agnaldo Samuel
Mofication date: 04/04/2023
*/
-- (Seguimento)


select DISTINCT 	seguimento_sem_fila.patient_id,
		DATE_FORMAT(seguimento_sem_fila.data_seguimento,'%d/%m/%Y') AS data_seguimento,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) nome,
		DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
        ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
        p.gender,
		pid.identifier as nid
from
(
	select * from
	(
		SELECT distinct	p.patient_id, max(e.encounter_datetime) AS data_seguimento
		FROM 	patient p
				inner join encounter e on p.patient_id=e.patient_id
		WHERE	p.voided=0 and e.encounter_type in (6,9) AND e.voided=0 and
				e.encounter_datetime  BETWEEN DATE_SUB(:endDate, INTERVAL 12 MONTH) AND  :endDate and
				e.location_id=:location
		GROUP BY patient_id
	) seguimento
	where not exists
	(
		select * from
		(
			SELECT 	distinct p.patient_id, e.encounter_datetime AS data_fila
			FROM 	patient p
					inner join encounter e on p.patient_id=e.patient_id
			WHERE	p.voided=0 and e.encounter_type=18 AND e.voided=0 and
					e.encounter_datetime BETWEEN DATE_SUB(:endDate, INTERVAL 12 MONTH) AND  :endDate and
					e.location_id=:location
			ORDER BY 1,2
		) fila
		where fila.patient_id=seguimento.patient_id and fila.data_fila=seguimento.data_seguimento
	)
) seguimento_sem_fila
LEFT JOIN
(	/* Patients on ART who initiated the ARV DRUGS: ART Regimen Start Date */

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

) inicio on inicio.patient_id =seguimento_sem_fila.patient_id

LEFT JOIN person p ON p.person_id=seguimento_sem_fila.patient_id

LEFT JOIN
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
) pid on pid.patient_id=seguimento_sem_fila.patient_id
LEFT JOIN
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
) pn on pn.person_id=seguimento_sem_fila.patient_id