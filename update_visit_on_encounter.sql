/* Este comando corrigi o problema de formularios que nao sao apresentados na 
no dashboard do paciente no OpenMRS */
update encounter e set visit_id =NULL 
where visit_id not in (select visit_id from visit);