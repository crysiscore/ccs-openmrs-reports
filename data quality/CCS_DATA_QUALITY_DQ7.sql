/*
NAME:  Pacientes que tenham início de 2 Tratamentos Preventivo de TB diferentes (3HP e INH)
Created by: Agnaldo Samuel <agnaldosamuel:ccsaude.org.mz>
creation date: 20/02/2023
Description:
        - o	Incluir na lista de Pacientes que tenham início de 2 Tratamentos Preventivo de TB diferentes (3HP e INH);
USE openmrs;
SET :startDate:='2022-03-21';
SET :endDate:='2023-02-12';
SET :location:=208;
*/

select  all_inicios.*,
       pid.identifier AS NID,
       CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
	   p.gender,
	   DATE_FORMAT(p.birthdate,'%d/%m/%Y') AS birthdate ,
       ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
       DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') AS data_inicio,
       DATE_FORMAT(ult_seguimento.encounter_datetime , '%d/%m/%Y') AS data_ult_visita_2

from (
select in_3hp.patient_id,
       in_3hp.data_inicio_3hp ,
       inh.data_inicio_tpi as data_inicio_izoniazida

from
                     (select inicio_3HP.patient_id, min(inicio_3HP.data_inicio_tpi) data_inicio_3hp

                       from (
                                /*	Inicio  3HP na Ficha Clinica, Seguimento e Resumo	     */
                                select p.patient_id, min(estadoProfilaxia.obs_datetime) data_inicio_tpi
                                from patient p
                                inner join encounter e on p.patient_id = e.patient_id
                                inner join obs profilaxia3HP on profilaxia3HP.encounter_id = e.encounter_id
                                inner join obs estadoProfilaxia on estadoProfilaxia.encounter_id = e.encounter_id
                                  where p.voided = 0
                                  and e.voided = 0
                                  and profilaxia3HP.voided = 0
                                  and estadoProfilaxia.voided = 0
                                  and profilaxia3HP.concept_id = 23985
                                  and profilaxia3HP.value_coded = 23954
                                  and estadoProfilaxia.concept_id = 165308
                                  and estadoProfilaxia.value_coded = 1256
                                  and e.encounter_type in (6, 9, 53)
                                  and e.location_id = :location
                                  and estadoProfilaxia.obs_datetime between (:endDate - interval 48 month) and :endDate
                                group by p.patient_id
                                union
                                /* Inicio Usando Outras prescrições DT-3HP na Ficha Clinica  */
                                select p.patient_id, min(outrasPrescricoesDT3HP.obs_datetime) data_inicio_tpi
                                from patient p
                                         inner join encounter e on p.patient_id = e.patient_id
                                         inner join obs outrasPrescricoesDT3HP
                                                    on outrasPrescricoesDT3HP.encounter_id = e.encounter_id
                                where p.voided = 0
                                  and e.voided = 0
                                  and outrasPrescricoesDT3HP.voided = 0
                                  and outrasPrescricoesDT3HP.obs_datetime between (:endDate - interval 48 month) and :endDate
                                  and outrasPrescricoesDT3HP.concept_id = 1719
                                  and outrasPrescricoesDT3HP.value_coded = 165307
                                  and e.encounter_type in (6)
                                  and e.location_id = :location
                                group by p.patient_id
                                union
                                  /*
                                  Patients who have Regime de TPT with the values “3HP or 3HP +
                                  Piridoxina” and “Seguimento de tratamento TPT” = (‘Inicio’ or ‘Re-Inicio’)
                                  marked on Ficha de Levantamento de TPT (FILT)  during the previous
                                  reporting period (3HP Start Date)
                                  */
                                 select p.patient_id, min(seguimentoTPT.obs_datetime) data_inicio_tpi
                                            from patient p
                                                     inner join encounter e on p.patient_id = e.patient_id
                                                     inner join obs regime3HP on regime3HP.encounter_id = e.encounter_id
                                                     inner join obs seguimentoTPT on seguimentoTPT.encounter_id = e.encounter_id
                                            where e.voided = 0
                                              and p.voided = 0
                                              and seguimentoTPT.obs_datetime between (:endDate - interval 48 month) and :endDate
                                              and regime3HP.voided = 0
                                              and regime3HP.concept_id = 23985
                                              and regime3HP.value_coded in (23954, 23984)
                                              and e.encounter_type = 60
                                              and e.location_id = :location
                                              and seguimentoTPT.voided = 0
                                              and seguimentoTPT.concept_id = 23987
                                              and seguimentoTPT.value_coded in (1256, 1705)
                                            group by p.patient_id

                                /** Patients who have Regime de TPT with the values “3HP or 3HP +
                                Piridoxina” and “Seguimento de Tratamento TPT” with values “Continua”
                                or “Fim” or no value marked on the first pick-up date on Ficha de
                                Levantamento de TPT (FILT) during the previous reporting period (FILT 3HP
                                Start Date) and:
                                o No other Regime de TPT with the values “3HP or 3HP +
                                Piridoxina” marked on FILT in the 4 months prior to this FILT 3HP
                                Start Date and
                                o No other 3HP Start Dates marked on Ficha Clinica ((Profilaxia TPT
                                with the value “3HP” and Estado da Profilaxia with the value
                                “Inicio (I)”) or (Outras Prescrições with the value “3HP”/“DT-
                                3HP”)) in the 4 months prior to this FILT 3HP Start Date and
                                o No other 3HP Start Dates marked on Ficha Resumo (Última
                                profilaxia TPT with value “3HP” and Data Inicio da Profilaxia TPT)
                                in the 4 months prior to this FILT 3HP Start Date:   */

                                union
                                (select inicio.patient_id, inicio.data_inicio_tpi
                                 from (select p.patient_id, min(seguimentoTPT.obs_datetime) data_inicio_tpi
                                       from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs regime3HP on regime3HP.encounter_id = e.encounter_id
                                                inner join obs seguimentoTPT on seguimentoTPT.encounter_id = e.encounter_id
                                       where e.voided = 0
                                         and p.voided = 0
                                         and seguimentoTPT.obs_datetime between (:endDate - interval 7 month) and :endDate
                                         and regime3HP.voided = 0
                                         and regime3HP.concept_id = 23985
                                         and regime3HP.value_coded in (23954, 23984)
                                         and e.encounter_type = 60
                                         and e.location_id = :location
                                         and seguimentoTPT.voided = 0
                                         and seguimentoTPT.concept_id = 23987
                                         and seguimentoTPT.value_coded in (1257, 1267)
                                       group by p.patient_id

                                       union

                                       select p.patient_id, min(regime3HP.obs_datetime) data_inicio_tpi
                                       from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs regime3HP on regime3HP.encounter_id = e.encounter_id
                                                left join obs seguimentoTPT
                                                          on (e.encounter_id = seguimentoTPT.encounter_id
                                                              and seguimentoTPT.concept_id = 23987
                                                              and seguimentoTPT.value_coded in (1256, 1257, 1705, 1267)
                                                              and seguimentoTPT.voided = 0)
                                       where e.voided = 0
                                         and p.voided = 0
                                         and regime3HP.obs_datetime between (:endDate - interval 7 month) and :endDate
                                         and regime3HP.voided = 0
                                         and regime3HP.concept_id = 23985
                                         and regime3HP.value_coded in (23954, 23984)
                                         and e.encounter_type = 60
                                         and e.location_id = :location
                                         and seguimentoTPT.obs_id is null
                                       group by p.patient_id) inicio
                                          left join
                                      (select p.patient_id, regime3HP.obs_datetime data_inicio_tpi
                                       from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs regime3HP on regime3HP.encounter_id = e.encounter_id
                                       where e.voided = 0
                                         and p.voided = 0
                                         and regime3HP.obs_datetime between (:endDate - interval 20 month) and :endDate
                                         and regime3HP.voided = 0
                                         and regime3HP.concept_id = 23985
                                         and regime3HP.value_coded in (23954, 23984)
                                         and e.encounter_type = 60
                                         and e.location_id = :location
                                       union
                                       select p.patient_id, estado.obs_datetime data_inicio_tpi
                                       from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs profilaxia3HP on profilaxia3HP.encounter_id = e.encounter_id
                                                inner join obs estado on estado.encounter_id = e.encounter_id
                                       where e.voided = 0
                                         and p.voided = 0
                                         and estado.voided = 0
                                         and profilaxia3HP.voided = 0
                                         and profilaxia3HP.concept_id = 23985
                                         and profilaxia3HP.value_coded = 23954
                                         and estado.concept_id = 165308
                                         and estado.value_coded = 1256
                                         and e.encounter_type in (6, 53)
                                         and e.location_id = :location
                                         and estado.obs_datetime between (:endDate - interval 20 month) and :endDate
                                       union
                                       select p.patient_id, outrasPrecricoesDT3HP.obs_datetime data_inicio_tpi
                                       from patient p
                                                inner join encounter e on p.patient_id = e.patient_id
                                                inner join obs outrasPrecricoesDT3HP
                                                           on outrasPrecricoesDT3HP.encounter_id = e.encounter_id
                                       where e.voided = 0
                                         and p.voided = 0
                                         and outrasPrecricoesDT3HP.obs_datetime between (:endDate - interval 20 month) and :endDate
                                         and outrasPrecricoesDT3HP.voided = 0
                                         and outrasPrecricoesDT3HP.concept_id = 1719
                                         and outrasPrecricoesDT3HP.value_coded = 165307
                                         and e.encounter_type in (6)
                                         and e.location_id = :location) inicioAnterior
                                      on inicioAnterior.patient_id = inicio.patient_id
                                          and
                                         inicioAnterior.data_inicio_tpi between (inicio.data_inicio_tpi - INTERVAL 4 MONTH) and (inicio.data_inicio_tpi - INTERVAL 1 day)
                                 where inicioAnterior.patient_id is null)) inicio_3HP
                       group by inicio_3HP.patient_id)  in_3hp

inner join

(
select in_inh.* from
                   (

select inicio_INH.patient_id, min(inicio_INH.data_inicio_tpi) data_inicio_tpi
	from (
			/*
					Patients who have  (Profilaxia
					TPT with the value “Isoniazida (INH)” and Estado da Profilaxia with the
					value “Inicio (I)”) marked on Ficha Clínica , Ficha Seguimento and Ficha Resumo
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
			 *   Patients who have Regime de TPT with the values (“Isoniazida” or
					“Isoniazida + Piridoxina”) and “Seguimento de tratamento TPT” = (‘Inicio’ or
					‘Re-Inicio’) marked on Ficha de Levantamento de TPT (FILT) during the
					previous reporting period (INH Start Date)
			 * */
			select p.patient_id,min(seguimentoTPT.obs_datetime) data_inicio_tpi
			from	patient p
				inner join encounter e on p.patient_id=e.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
				inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
			where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime between (:endDate - interval 10 year ) and :endDate
				and seguimentoTPT.voided =0 and seguimentoTPT.concept_id = 23987 and seguimentoTPT.value_coded in (1256,1705)
				and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
				group by p.patient_id

			/*union


							Patients who have Regime de TPT with the values (“Isoniazida” or
							“Isoniazida + Piridoxina”) and “Seguimento de Tratamento TPT” with values
							“Continua” or no value marked on the first pick-up date on Ficha de
							Levantamento de TPT (FILT) during the previous reporting period (FILT INH
							Start Date) and:
							o No other Regime de TPT with the values INH values (“Isoniazida”
							or “Isoniazida + Piridoxina”) marked on FILT in the 7 months prior
							to this FILT INH Start Date and
							o No other INH Start Dates marked on Ficha Clinica (Profilaxia (INH)
							with the value “I” (Início) or (Profilaxia TPT with the value
							“Isoniazida (INH)” and Estado da Profilaxia with the value “Inicio
							(I)”) in the 7 months prior to this FILT INH Start Date and
							o No other INH Start Dates marked on Ficha de Seguimento
							(Profilaxia com INH – TPI (Data Início)) in the 7 months prior to
							this FILT INH Start Date and
							o No other INH Start Dates marked onor Ficha resumo (“Última
							profilaxia Isoniazida (Data Início)” or (Última profilaxia TPT with
							value “Isoniazida (INH)” and Data Inicio da Profilaxia TPT)) in the
							7 months prior to this ‘FILT INH Start Date’

			(	select inicio.patient_id, inicio.data_inicio_tpi
				from (
						select p.patient_id,min(seguimentoTPT.obs_datetime) data_inicio_tpi
						from	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on o.encounter_id=e.encounter_id
							inner join obs seguimentoTPT on seguimentoTPT.encounter_id=e.encounter_id
						where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime between (:endDate - interval 10 year ) and :endDate
							and seguimentoTPT.voided =0 and seguimentoTPT.concept_id =23987 and seguimentoTPT.value_coded in (1257)
							and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
							group by p.patient_id
						union
						select p.patient_id,min(seguimentoTPT.obs_datetime) data_inicio_tpi	from	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on o.encounter_id=e.encounter_id
							left join obs seguimentoTPT on (e.encounter_id =seguimentoTPT.encounter_id
							and seguimentoTPT.concept_id =23987
							and seguimentoTPT.value_coded in(1256,1257,1705,1267)
							and seguimentoTPT.voided =0)
						where e.voided=0 and p.voided=0 and seguimentoTPT.obs_datetime between (:endDate - interval  10 year month) and :endDate
							and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
							and seguimentoTPT.obs_id is null
							group by p.patient_id
					)
		 		inicio
				left join
				(
					select p.patient_id,o.obs_datetime data_inicio_tpi
					from patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
					where e.voided=0 and p.voided=0 and o.obs_datetime between (:endDate - interval 20 month) and :endDate
						and o.voided=0 and o.concept_id=23985 and o.value_coded in (656,23982) and e.encounter_type=60 and  e.location_id=:location
					union
					select p.patient_id,obsInicioINH.obs_datetime data_inicio_tpi from patient p
				     	inner join encounter e on p.patient_id = e.patient_id
				        	inner join obs o on o.encounter_id = e.encounter_id
				        	inner join obs obsInicioINH on obsInicioINH.encounter_id = e.encounter_id
				     where e.voided=0 and p.voided=0 and o.voided=0 and e.encounter_type in (6,9,53) and o.concept_id=23985 and o.value_coded=656
				      	and obsInicioINH.concept_id=165308 and obsInicioINH.value_coded=1256 and obsInicioINH.voided=0
				      	and obsInicioINH.obs_datetime between (:endDate - interval 20 month) and :endDate and  e.location_id=:location
				)
				inicioAnterior on inicioAnterior.patient_id=inicio.patient_id
					and inicioAnterior.data_inicio_tpi between (inicio.data_inicio_tpi - INTERVAL 7 MONTH) and (inicio.data_inicio_tpi - INTERVAL 1 day)
				where inicioAnterior.patient_id is null
	  		)    */
	 	)
	inicio_INH group by inicio_INH.patient_id ) in_inh

) inh on in_3hp.patient_id = inh.patient_id
    )   all_inicios

INNER JOIN person p ON p.person_id=all_inicios.patient_id

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

LEFT JOIN (
	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id,e.encounter_id
		FROM

			(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
				FROM 	encounter e inner join patient p on p.patient_id=e.patient_id
				WHERE 	p.voided=0 and e.voided=0 AND e.encounter_type IN (9,6)
				GROUP BY e.patient_id
			) ultimavisita
			INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
			INNER JOIN obs o ON o.encounter_id=e.encounter_id
			WHERE o.concept_id=1410 AND o.voided=0 AND e.voided=0 AND e.encounter_datetime=ultimavisita.encounter_datetime AND
			e.encounter_type IN (9,6) AND e.location_id=:location
			 GROUP BY e.patient_id
            ) ult_seguimento ON ult_seguimento.patient_id = all_inicios.patient_id