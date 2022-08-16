	-- PATIENT PROGRAM ENROLLMENT : TUBERCULOSES
			SELECT 	pg.patient_id ,pg.program_id , pgr.name ,pg. patient_program_id, ps.start_date,ps.state,pws.concept_id, pws.initial, pws.terminal, c.name
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=5 AND    location_id=@location
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
                     LEFT JOIN program_workflow_state pws on ps.state = pws.program_workflow_state_id
			    LEFT JOIN
                    (SELECT  c.concept_id,cn.name FROM concept c
                    INNER JOIN concept_name cn ON c.concept_id=cn.concept_id
                    WHERE locale ='pt' group by c.concept_id

                    ) c on c.concept_id = pws.concept_id
			       LEFT JOIN  program pgr on pgr.program_id = pg.program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=5 AND /*ps.state IN (16,30) AND */  location_id= @location AND ps.start_date <=@endDate
					-- GROUP BY pg.patient_id

