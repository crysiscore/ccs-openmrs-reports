
-- data_ult_estado <>  data_ult_visita_2
-- PROGRAMA TARV TRATAMENTO: STATES
select p.patient_id,pgr.name, pws.program_workflow_state_id, pws.program_workflow_id, pws.concept_id, c.name ,pg.date_enrolled, pg.date_completed,
ps.start_date
from program_workflow_state pws
    left join

(
    select  c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where /* c.concept_id in (6270 ,6269,1707,1706,1256,1366,6269,1706,1709,1707,1366,6269,1798,1707,
1366,6269,1707,1706,1366,6301,6302,1982,50,6248,1369,1369,1369,1369,706,6269,1369,1706,
1366,165231,165232,165233,165234)
 and  */locale ='pt' group by c.concept_id

) c on c.concept_id = pws.concept_id
inner join program_workflow pw on pw.program_workflow_id = pws.program_workflow_id
inner join program pgr on pgr.program_id =pw.program_id
INNER JOIN patient_program pg ON pg.program_id=pgr.program_id
INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
inner join patient p ON p.patient_id=pg.patient_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=8 AND    location_id=@location
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
	WHERE pgr.program_id=8 and	pg.voided=0 AND ps.voided=0 AND p.voided=0
					  AND   location_id= @location AND ps.start_date <=@endDate -- and c.concept_id in (6269,1369)
					/*  and ps.state IN (16,30) */ ;


USE openmrs;
SET @startDate:='2022-03-21';
SET @endDate:='2022-08-20';
SET @location:=208;


	-- PATIENT PROGRAM ENROLLMENT : TUBERCULOSES
			SELECT 	pg.patient_id ,pg.program_id , pgr.name ,pg. patient_program_id, ps.start_date,
			        ps.state,pws.concept_id, pws.initial, pws.terminal, c.name,
			          TIMESTAMPDIFF(MONTH,ps.start_date, @endDate) as duracao_prog
			FROM 	patient p
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
					INNER JOIN (SELECT 	pg.patient_id	, MAX(ps.start_date) AS data_ult_estado
							FROM 	patient p
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
									INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
							WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
									pg.program_id=8 AND    location_id=@location
							GROUP BY  pg.patient_id ) ultimo_estado ON ultimo_estado.patient_id = p.patient_id AND ultimo_estado.data_ult_estado = ps.start_date
                     LEFT JOIN program_workflow_state pws on ps.state = pws.program_workflow_state_id
			    LEFT JOIN
                    (SELECT  c.concept_id,cn.name FROM concept c
                    INNER JOIN concept_name cn ON c.concept_id=cn.concept_id
                    WHERE locale ='pt' group by c.concept_id

                    ) c on c.concept_id = pws.concept_id
			       LEFT JOIN  program pgr on pgr.program_id = pg.program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND
					pg.program_id=8 AND pws.concept_id IN (1982) AND  location_id= @location AND ps.start_date <=@endDate
					-- GROUP BY pg.patient_id

