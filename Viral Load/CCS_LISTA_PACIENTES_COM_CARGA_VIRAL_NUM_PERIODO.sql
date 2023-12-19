/*
Name: CCS LISTA DE PACIENTES COM EXAME DE CARGA VIRAL NUM PERIODO
Description:
              -  CCS LISTA DE PACIENTES COM EXAME DE CARGA VIRAL NUM PERIODO


Created By: Bruno M.
Created Date: 18-11-2020

Change by: Agnaldo  Samuel/ Bruno Madeira
Change Date: 10/06/2021 
Change Reason: Bug fix 
               - Considerar a carga viral qualitativa na query

*/

/*
Name: CCS LISTA DE PACIENTES COM EXAME DE CARGA VIRAL NUM PERIODO
Description:
              -  CCS LISTA DE PACIENTES COM EXAME DE CARGA VIRAL NUM PERIODO


Created By: Bruno M.
Created Date: 18-11-2020

Change by: Agnaldo  Samuel/ Bruno Madeira
Change Date: 10/06/2021
Change Reason: Bug fix
               - Considerar a carga viral qualitativa na query

*/



select 	pid.identifier as NID,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
		carga2.primeira_carga_viral_qualitativa,
		carga2.data_primeira_carga,
		carga2.valor_primeira_carga,
        carga2.Origem_Resultado_primeira ,

		if(carga2.data_primeira_carga<>carga1.data_ultima_carga, DATE_FORMAT(carga1.data_ultima_carga,'%d/%m/%Y') ,'') as data_ultima_carga,
		if(carga2.data_primeira_carga<>carga1.data_ultima_carga,carga1.carga_viral_qualitativa,'') as carga_viral_qualitativa,
        if(carga2.data_primeira_carga<>carga1.data_ultima_carga,carga1.valor_ultima_carga,'') as valor_ultima_carga,
        if(carga2.data_primeira_carga<>carga1.data_ultima_carga,carga1.Origem_Resultado,'') as origem_ultimo,
        inicio_real.data_inicio,
		pe.gender,
		round(datediff(:endDate,pe.birthdate)/365) idade_actual,
	   DATE_FORMAT(inicio_segunda.data_regime,'%d/%m/%Y') data_regime,
	   inicio_segunda.regime_segunda_linha,
	   DATE_FORMAT(seguimento.data_seguimento,'%d/%m/%Y') data_seguimento,
        telef.value AS telefone

from

	(	    SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
				when 165331 then CONCAT('<',o.comments)
                ELSE ''
                END  AS carga_viral_qualitativa,
				ult_cv.data_cv_qualitativa data_ultima_carga ,
                o.value_numeric valor_ultima_carga,
                fr.name as Origem_Resultado
                FROM  encounter e
                inner join	(
							SELECT 	e.patient_id,max(encounter_datetime) as data_cv_qualitativa
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id in( 856, 1305)
							group by patient_id
				) ult_cv
                on e.patient_id=ult_cv.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
                 left join form fr on fr.form_id = e.form_id
                 where e.encounter_datetime=ult_cv.data_cv_qualitativa
				and	e.voided=0  AND e.location_id= :location   AND e.encounter_type in (6,9,13,51,53) and
				o.voided=0 AND 	o.concept_id in( 856, 1305) and  e.encounter_datetime between :startDate and :endDate
                group by e.patient_id

		) carga1



		inner join person_name pn on pn.person_id=carga1.patient_id and pn.preferred=1 and pn.voided=0
		inner join patient_identifier pid on pid.patient_id=carga1.patient_id and pid.identifier_type=2 and pid.voided=0
		inner  join person pe on pe.person_id=carga1.patient_id and pe.voided=0
	/* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0
	) telef  ON telef.person_id = carga1.patient_id


left join

(	  SELECT 	e.patient_id,
				CASE o.value_coded
                WHEN 1306  THEN  'Nivel baixo de detencao'
                WHEN 23814 THEN  'Indectetavel'
                WHEN 23905 THEN  'Menor que 10 copias/ml'
                WHEN 23906 THEN  'Menor que 20 copias/ml'
                WHEN 23907 THEN  'Menor que 40 copias/ml'
                WHEN 23908 THEN  'Menor que 400 copias/ml'
                WHEN 23904 THEN  'Menor que 839 copias/ml'
				when 165331 then CONCAT('<',o.comments)
                ELSE ''
                END  AS primeira_carga_viral_qualitativa,
				ult_cv.data_cv_qualitativa data_primeira_carga ,
                o.value_numeric valor_primeira_carga,
                fr.name as Origem_Resultado_primeira
                FROM  encounter e
                inner join	(
							SELECT 	e.patient_id,min(encounter_datetime) as data_cv_qualitativa
							from encounter e inner join obs o on e.encounter_id=o.encounter_id
							where e.encounter_type IN (6,9,13,51,53) AND e.voided=0 AND o.voided=0 AND o.concept_id in( 856, 1305)
							group by patient_id
				) ult_cv
                on e.patient_id=ult_cv.patient_id
				inner join obs o on o.encounter_id=e.encounter_id
                 left join form fr on fr.form_id = e.form_id
                 where e.encounter_datetime=ult_cv.data_cv_qualitativa
				and	e.voided=0  AND e.location_id= :location   AND e.encounter_type in (6,9,13,51,53) and
				o.voided=0 AND 	o.concept_id in( 856, 1305)
                group by e.patient_id

		) carga2 on carga2.patient_id = carga1.patient_id


        left join
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


						/* UNION

						Patients with first drugs pick up date set: Recepcao Levantou ARV
						SELECT 	p.patient_id,MIN(value_datetime) data_inicio
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs o ON e.encounter_id=o.encounter_id
						WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND
								o.concept_id=23866 AND o.value_datetime IS NOT NULL AND
								o.value_datetime<=:endDate AND e.location_id=:location
						GROUP BY p.patient_id	 */


			) inicio
		GROUP BY patient_id
	)inicio_real on inicio_real.patient_id=carga1.patient_id
		/* ******************************* Ultima consulta **************************** */


left join (
	Select ultimavisita.patient_id,ultimavisita.encounter_datetime data_seguimento ,o.value_datetime,e.location_id,e.encounter_id
		from

			(	select 	e.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e
				where 	e.voided=0 and e.encounter_type in (9,6)
				group by e.patient_id
			) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
			where o.concept_id=1410 and o.voided=0 and e.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and
			e.encounter_type in (9,6) and e.location_id=:location
            ) seguimento on seguimento.patient_id = carga1.patient_id



		/* ******************************* data e regime da segunda  consulta **************************** */
        left join (


	 select data_inicio_segund.patient_id, data_inicio_segund.data_regime, regime_seg.regime_segunda_linha, data_inicio_segund.value_coded

				from (
				select 	p.patient_id ,min(encounter_datetime) as data_regime, o.value_coded
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=:location and
						e.encounter_datetime<=:endDate and o.voided=0 and o.concept_id=21151 and o.value_coded=21148
				group by p.patient_id ) data_inicio_segund

				left join (
				select 	patient_id,
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
					else 'OUTRO' end as regime_segunda_linha,
					e.encounter_datetime data_regime
					from encounter e inner join obs o on e.encounter_id=o.encounter_id
			       where encounter_type in (6, 9) and e.voided=0 and o.voided=0 and
				   o.concept_id =1087 and e.location_id=:location ) regime_seg on regime_seg.patient_id= data_inicio_segund.patient_id
				   and data_inicio_segund.data_regime= regime_seg.data_regime



		) inicio_segunda on inicio_segunda.patient_id=carga1.patient_id



