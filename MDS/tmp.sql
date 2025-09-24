/*
Name:CCS PACIENTES EM MDS
Description:
              - Pacientes actualmente em tarv, com data do proximo seguimento nao superior a data corremte em 28 dias inscritos em pelo menos 1 MDS

Created By: Agnaldo Samuel
Created Date: 28/03/2021

Change by: Agnaldo  Samuel
Change Date: 13/09/2021
Change Reason: Bug fix
-- Correcao no sub-consulta que busca o  ultimo seguimento
-- Adicao do novo modelo Farmacia Privada
-- filtro de pacientes em MDS num periodo
*/



SELECT *
FROM
(SELECT 	inicio_real.patient_id,
			CONCAT(pid.identifier,' ') AS NID,
            CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			p.gender,
            ROUND(DATEDIFF(:endDate,p.birthdate)/365) idade_actual,
            DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') as data_inicio,
			DATE_FORMAT(modelodf.data_modelo ,'%d/%m/%Y') as data_inscricao,
            IF(ga.data_ga is null, 'NAO',ga.tipo_model ) as gaac,
            IF(af.data_af is null, 'NAO',af.tipo_model ) as abordagef,
			IF(ca.data_ca is null, 'NAO',ca.tipo_model ) as clubesad,
			IF(pu.data_pu is null, 'NAO',pu.tipo_model ) as paragemun,
			IF(fr.data_fr is null, 'NAO',fr.tipo_model ) as fluxor,
			IF(dt.data_dt is null, 'NAO',dt.tipo_model ) as dispensat,
			IF(dc.data_dc is null, 'NAO',dc.tipo_model ) as dispensac,
			IF(ds.data_ds is null, 'NAO',ds.tipo_model ) as dispensas,
			IF(fp.data_fp is null, 'NAO',fp.tipo_model ) as f_privada,
			IF(saaj.data_saaj is null, 'NAO',saaj.tipo_model ) as saaj,
			IF(pu_tarv.data_pu_tarv is null, 'NAO',pu_tarv.tipo_model ) as pu_tarv,
			IF(pu_tb.data_pu_tb is null, 'NAO',pu_tb.tipo_model ) as pu_tb,
			IF(bm.data_bm is null, 'NAO',bm.tipo_model ) as brigad,
			IF(cm.data_cm is null, 'NAO',cm.tipo_model ) as clinicas,
			IF(db.data_db is null, 'NAO',db.tipo_model ) as bimestral,
			IF(da.data_da is null, 'NAO',da.tipo_model ) as anual,
			IF(dc_ape.data_dc_ape is null, 'NAO',dc_ape.tipo_model ) as ape,
			IF(dd.data_dd is null, 'NAO',dd.tipo_model ) as descentralizada,
			IF(ex.data_ex is null, 'NAO',ex.tipo_model ) as extensao,



            linha_terapeutica.linhat as linhaterapeutica,
			telef.value AS telefone,
            regime.ultimo_regime,
			DATE_FORMAT(visita.encounter_datetime,'%d/%m/%Y') as data_ult_consulta,
            DATE_FORMAT(visita.value_datetime,'%d/%m/%Y') as consulta_proximo_marcado,
            DATE_FORMAT(fila.encounter_datetime,'%d/%m/%Y') as data_ult_levantamento,
            DATE_FORMAT(fila.value_datetime,'%d/%m/%Y') as fila_proximo_marcado,
			IF(DATEDIFF(:endDate,ultimavisita.value_datetime)<=28,'ACTIVO EM TARV','FALTOSO/ABANDONO') estado,
		    pad3.county_district AS 'Distrito',
			pad3.address2 AS 'Padministrativo',
			pad3.address6 AS 'Localidade',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia'


	FROM
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
	) inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id
		       /**************************     ultima visita ****************************/
      	INNER JOIN
		(
			SELECT lastvis.patient_id,lastvis.value_datetime,lastvis.encounter_type
			FROM
				(	SELECT 	p.patient_id,MAX(o.value_datetime) AS value_datetime, e.encounter_type
					FROM 	encounter e
					INNER JOIN obs o ON o.encounter_id=e.encounter_id
					INNER JOIN patient p ON p.patient_id=e.patient_id
					WHERE 	e.voided=0 AND p.voided=0 and o.voided =0  AND e.encounter_type IN (6,9,18) AND  o.concept_id in (5096 ,1410)
						and	e.location_id=:location AND e.encounter_datetime <=:endDate  and o.value_datetime is  not null
					GROUP BY p.patient_id
				) lastvis
		) ultimavisita ON ultimavisita.patient_id=inicio_real.patient_id

		/************************** Modelos  o.concept_id in (23724,23725,23726,23727,23729,23730,23731,23732,23888) ****************************/
		INNER JOIN
		(

                SELECT 	e.patient_id,
				CASE o.value_coded
 WHEN  165314 THEN 'DISPENSA ANUAL DE ARV'
 WHEN  165179 THEN 'DISPENSA COMUNIT&Aacute;RIA VIA APE'
 WHEN  165265 THEN 'CLINICAS MVEIS (DCCM)'
 WHEN  165264 THEN 'BRIGADAS MVEIS (DCBM)'
 WHEN  23729 THEN 'FLUXO RÁPIDO (FR)'
 WHEN  165321 THEN 'DOENCA AVANCADA POR HIV'
 WHEN  23731 THEN 'DISPENSA COMUNITÁRIA (DC)'
 WHEN  23888 THEN 'DISPENSA SEMESTRAL'
 WHEN  23726 THEN 'CLUBES DE ADESÃO (CA)'
 WHEN  165340 THEN 'DISPENSA BIMESTRAL'
 WHEN  23732 THEN 'OUTRO MODELO'
 WHEN  165178 THEN 'DISPENSA COMUNITÁRIA VIA PROVEDOR'
 WHEN  165319 THEN 'PARAGEM UNICA NO SAAJ'
 WHEN  165318 THEN 'PARAGEM UNICA NOS SERVICOS DE TARV'
 WHEN  23730 THEN 'DISPENSA TRIMESTRAL (DT)'
 WHEN  165315 THEN 'DISPENSA DESCENTRALIZADA DE ARV'
 WHEN  165316 THEN 'EXTENSAO DE HORARIO'
 WHEN  23725 THEN 'ABORDAGEM FAMILIAR (AF)'
 WHEN  165177 THEN 'FARMAC/FARMÁCIA PRIVADA'
 WHEN  165317 THEN 'PARAGEM UNICA NO SECTOR DA TB'
 WHEN  23727 THEN 'PARAGEM ÚNICA (PU)'
 WHEN  23724 THEN 'Gaac (GA)'
 WHEN  165320 THEN 'PARAGEM UNICA NA SMI'

 	ELSE '' END AS modelodf,
                  /*  o.,
                    case o.value_coded
                 	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                    end as estado_mds,  */
				max(encounter_datetime) as data_modelo
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id in (165174)
			 AND o.location_id=:location
            group by patient_id

		) modelodf ON modelodf.patient_id=inicio_real.patient_id and modelodf.data_modelo between :startDate and :endDate and modelodf.value_coded in (1256,1257)

        /*************************************************** Modelos  gaac 23724, ***************************************************************/
        left join (
        select
        	e.patient_id,
                case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_ga
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23724 AND o.location_id=:location
            group by patient_id
            ) ga on ga.patient_id = modelodf.patient_id

                /************************** Modelos  abordagem familiar 23726, ****************************/
		left join (
          select
        	e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_af
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23725 AND o.location_id=:location
            group by patient_id) af on af.patient_id = modelodf.patient_id
                /************************** Modelos  clubes de adesao  23726, ****************************/
		left join (
        select
        e.patient_id,
                 case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_ca
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23726 AND o.location_id=:location
            group by patient_id) ca on ca.patient_id = modelodf.patient_id
	    /************************** Modelos  paragem unica  23727, ****************************/
	left join (

      select
        e.patient_id,
                 case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_pu
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23727 AND o.location_id=:location
            group by patient_id
            ) pu on pu.patient_id = modelodf.patient_id
   /**************************** PARAGEM UNICA NA SMI  165320, ****************************/
    left join (
        select
        e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
                	                    WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
                min(encounter_datetime) as data_smi
            FROM 	obs o
            INNER JOIN encounter e ON e.encounter_id=o.encounter_id
            WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165320 AND o.location_id=:location
            group by patient_id) smi on smi.patient_id = modelodf.patient_id

                /************************** Modelos  fluxo rapido 23729, ****************************/
		left join (
          select
        e.patient_id,
                 case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_fr
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23729 AND o.location_id=:location
            group by patient_id) fr on fr.patient_id = modelodf.patient_id

         /************************** Modelos  dispenmsa trimestral  23730, ****************************/
       left join (

         select e.patient_id,
                 case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_dt
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23730 AND o.location_id=:location
            group by patient_id) dt on dt.patient_id = modelodf.patient_id

     /************************** Modelos  dispenmsa semestral  23888, ****************************/
    left join (

      select
      e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_ds
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23888 AND o.location_id=:location
            group     by patient_id) ds on ds.patient_id = modelodf.patient_id
           /************************** Modelos  dispenmsa comunitaria  23731, ****************************/
      left join (
        select
        e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_dc
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =23731 AND o.location_id=:location
            group by patient_id) dc on dc.patient_id = modelodf.patient_id

/************************* DOENCA AVANCADA POR HIV  165321, ****************************/
      left join (
        select
        e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
                    WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
                min(encounter_datetime) as data_dah
            FROM 	obs o
            INNER JOIN encounter e ON e.encounter_id=o.encounter_id
            WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165321 AND o.location_id=:location
            group by patient_id) dah on dah.patient_id = modelodf.patient_id

/************************** FARMAC/Farmácia Privada  165177, ****************************/
      left join (
        select
        e.patient_id,
                  case o.value_coded
                	WHEN '1256'  THEN 'INICIO (I)'
					WHEN '1257' THEN 'CONTINUA (C)'
                    WHEN '23888' THEN 'FIM (F)'
                    WHEN '1267' THEN 'FIM (F)'
                ELSE '' END AS tipo_model,
				min(encounter_datetime) as data_fp
			FROM 	obs o
			INNER JOIN encounter e ON e.encounter_id=o.encounter_id
			WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165177 AND o.location_id=:location
            group by patient_id)  fp on fp.patient_id = inicio_real.patient_id
	            /************************** DISPENSA ANUAL DE ARV  ****************************/
	            left join (
	                        select
                            e.patient_id,
                                      case o.value_coded
                                    	WHEN '1256'  THEN 'INICIO (I)'
                                        WHEN '1257' THEN 'CONTINUA (C)'
                                        WHEN '23888' THEN 'FIM (F)'
                                        WHEN '1267' THEN 'FIM (F)'
                                    ELSE '' END AS tipo_model,
	                        min(encounter_datetime) as data_da
                            FROM 	obs o
                            INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                            WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165314 AND o.location_id=:location
                            group by patient_id) da on da.patient_id = inicio_real.patient_id
	            /**************************  COMUNIT&Aacute;RIA VIA APE  ****************************/
	              left join (
                             select
                             e.patient_id,
                                          case o.value_coded
                                    WHEN '1256'  THEN 'INICIO (I)'
                                       WHEN '1257' THEN 'CONTINUA (C)'
                                         WHEN '23888' THEN 'FIM (F)'
                                         WHEN '1267' THEN 'FIM (F)'
                                        ELSE '' END AS tipo_model,
                               min(encounter_datetime) as data_dc_ape
                             FROM 	obs o
                             INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                             WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165179 AND o.location_id=:location
                             group by patient_id) dc_ape on dc_ape.patient_id = inicio_real.patient_id
	            /************************** CLINICAS MVEIS (DCCM)  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            WHEN '1256'  THEN 'INICIO (I)'
                                            WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                    min(encounter_datetime) as data_cm
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165265 AND o.location_id=:location
                                 group by patient_id) cm on cm.patient_id = inicio_real.patient_id
	            /************************** BRIGADAS MVEIS (DCBM)  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                               WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                  min(encounter_datetime) as data_bm
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165264 AND o.location_id=:location
                                 group by patient_id) bm on bm.patient_id = inicio_real.patient_id

	            /************************** DISPENSA BIMESTRAL  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                        	WHEN '1256'  THEN 'INICIO (I)'
                                             WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                 min(encounter_datetime) as data_db
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165340 AND o.location_id=:location
                                 group by patient_id) db on db.patient_id = inicio_real.patient_id

	            /************************** DISPENSA DESCENTRALIZADA DE ARV  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                              WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                        min(encounter_datetime) as data_dd
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165315 AND o.location_id=:location
                                 group by patient_id) dd on dd.patient_id = inicio_real.patient_id
	            /************************** EXTENSAO DE HORARIO  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                             WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                     min(encounter_datetime) as data_ex
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165316 AND o.location_id=:location
                                 group by patient_id) ex on ex.patient_id = inicio_real.patient_id
	            /************************** PARAGEM UNICA NO SAAJ  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                              WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                          min(encounter_datetime) as data_saaj
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165319 AND o.location_id=:location
                                 group by patient_id) saaj on saaj.patient_id = inicio_real.patient_id
	            /************************** PARAGEM UNICA NOS SERVI&Ccedil;OS DE TARV  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                            WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                      min(encounter_datetime) as data_pu_tarv
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165318 AND o.location_id=:location
                                 group by patient_id) pu_tarv on pu_tarv.patient_id = inicio_real.patient_id
	            /************************** PARAGEM UNICA NO SECTOR DA TB  ****************************/
	                left join (
                                 select
                                 e.patient_id,
                                            case o.value_coded
                                            	WHEN '1256'  THEN 'INICIO (I)'
                                            WHEN '1257' THEN 'CONTINUA (C)'
                                             WHEN '23888' THEN 'FIM (F)'
                                             WHEN '1267' THEN 'FIM (F)'
                                            ELSE '' END AS tipo_model,
                                           min(encounter_datetime) as data_pu_tb
                                 FROM 	obs o
                                 INNER JOIN encounter e ON e.encounter_id=o.encounter_id
                                 WHERE 	e.encounter_type IN (6,9) AND e.voided=0 AND o.voided=0 AND o.concept_id =165317 AND o.location_id=:location
                                 group by patient_id) pu_tb on pu_tb.patient_id = inicio_real.patient_id
	                /************************** ultima visita ****************************/



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
			) pad3 ON pad3.person_id=inicio_real.patient_id
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
			) pn ON pn.person_id=inicio_real.patient_id
			LEFT JOIN
			(       SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
					(
						SELECT patient_id,MIN(patient_identifier_id) id
						FROM patient_identifier
						WHERE voided=0
						GROUP BY patient_id
					) pid2
					WHERE pid1.patient_id=pid2.patient_id AND pid1.patient_identifier_id=pid2.id
			) pid ON pid.patient_id=inicio_real.patient_id

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
						else 'OUTRO' end as ultimo_regime,
						e.encounter_datetime data_regime,
                        o.value_coded
				from 	encounter e
                inner join
                         ( select e.patient_id,max(encounter_datetime) encounter_datetime
                         from encounter e
                         inner join obs o on e.encounter_id=o.encounter_id
                         where 	encounter_type in (6,9) and e.voided=0 and o.voided=0
                         group by e.patient_id
                         ) ultimolev
				on e.patient_id=ultimolev.patient_id
                inner join obs o on o.encounter_id=e.encounter_id
				where  ultimolev.encounter_datetime = e.encounter_datetime and
                        encounter_type in (6,9) and e.voided=0 and o.voided=0 and
						o.concept_id=1087 and e.location_id=:location
              group by patient_id

			) regime on regime.patient_id=inicio_real.patient_id

        /** ************************** LinhaTerapeutica concept_id = 21151  * ********************************************** **/
        LEFT JOIN
		(SELECT 	e.patient_id,
				CASE o.value_coded
					WHEN 21148  THEN 'SEGUNDA LINHA'
					WHEN 21149  THEN 'TERCEIRA LINHA'
					WHEN 21150  THEN 'PRIMEIRA LINHA'
				ELSE '' END AS linhat,
                max(encounter_datetime) as data_ult_linha
			FROM 	obs o
			INNER JOIN encounter e ON o.encounter_id=e.encounter_id
			WHERE 	e.encounter_type IN (6,9,53) AND e.voided=0 AND o.voided=0 AND o.concept_id = 21151
            group by patient_id
		) linha_terapeutica ON linha_terapeutica.patient_id=inicio_real.patient_id

	          /* ******************************** ultima levantamento *********** ******************************/
 		left JOIN
		(	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime
			FROM
				(	SELECT 	e.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e
							INNER JOIN obs o  ON e.encounter_id=o.encounter_id
					WHERE 	e.voided=0 AND o.voided=0 AND e.encounter_type =18 AND
							e.location_id=:location
					GROUP BY e.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				INNER JOIN obs o ON o.encounter_id=e.encounter_id
                where  o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime and
			  o.voided=0  AND e.voided =0 AND e.encounter_type =18  AND e.location_id=:location
		) fila ON fila.patient_id=inicio_real.patient_id


	/*  ** ******************************************  ultima seguimento  **** ************************************* */
		left JOIN
		(		Select ultimoSeguimento.patient_id,ultimoSeguimento.encounter_datetime,o.value_datetime
	from

		(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
			from 	encounter e
			inner join patient p on p.patient_id=e.patient_id
			where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=:location
			group by p.patient_id
		) ultimoSeguimento
		inner join encounter e on e.patient_id=ultimoSeguimento.patient_id
		inner join obs o on o.encounter_id=e.encounter_id
		where o.concept_id=1410 and o.voided=0 and e.voided=0 and e.encounter_datetime=ultimoSeguimento.encounter_datetime and
		e.encounter_type in (6,9)
		) visita ON visita.patient_id=inicio_real.patient_id

	/* ******************************* Telefone **************************** */
	LEFT JOIN (
		SELECT  p.person_id, p.value
		FROM person_attribute p
     WHERE  p.person_attribute_type_id=9
    AND p.value IS NOT NULL AND p.value<>'' AND p.voided=0
	) telef  ON telef.person_id = inicio_real.patient_id

	WHERE inicio_real.patient_id NOT IN  -- Pacientes que sairam do programa TARV
	 (
			SELECT 	pg.patient_id
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=2 AND    location_id=:location
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date

			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=2 AND ps.state IN (7,8,9,10) AND   location_id=:location	 AND ps.start_date <=:endDate
					GROUP BY pg.patient_id

	)  and DATEDIFF(:endDate,ultimavisita.value_datetime) <= 28
) activos
GROUP BY patient_id