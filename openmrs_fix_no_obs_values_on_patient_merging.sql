
-- 1054 - Estado civil vazio nos formularos S.TARV: PEDIATRIA/ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1054 and o.value_coded is null; */

update obs o set value_coded = 5622 
where  concept_id = 1054 and o.value_coded is null ;


-- 9120- ANTI-RETROVIRAIS PRESCRITOS

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1087 and o.value_coded is null; */

update obs o set value_coded = 5424 
where  concept_id = 1087 and o.value_coded is null;

-- 1435 - TIPO DE EXPOSIÇÃO ACCIDENTES TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1435 and o.value_text is null and o.voided=0; */

update obs o set value_text = "Sem Informação" 
where  concept_id = 1435 and o.value_text is null ;

-- 1441 -PESSOA DE REFERENCIA - NOME ACCIDENTES TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1441 and o.value_text is null and o.voided=0; */

update obs o set value_text = "Sem Informação" 
where  concept_id = 1441 and o.value_text is null  and o.voided=0;


-- 1442 - PESSOA DE REFERÊNCIA - APELIDO TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1442 and o.value_text is null and o.voided=0; */
update obs o set value_text = "Sem Informação" 
where  concept_id = 1442 and o.value_text is null ;


-- 1443 - NIVEL DE ESCOLARIDADO TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1443 and o.value_text is null and o.voided=0; */
update obs o set  o.value_coded=5622
where  concept_id = 1443 and o.value_coded is null;


-- 1449 -SERIOLOGIA HIV DO CONJUGE TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1449 and o.value_coded is null and o.voided=0; */

update obs o set  o.value_coded=1457
where  concept_id = 1449 and o.value_coded is null ;


-- 1449 -NUMERO DO PROCESSO DO CONJUGE HIV POS TARV: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1450 and o.value_text is null and o.voided=0; */

update obs o set  o.value_text= "Sem Informação" 
where  concept_id = 1450 and o.value_text is null ;


-- 1452 - NUMERO DE FILHOS TESTADOS: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1452 and o.value_numeric is null and o.voided=0; */

update obs o set  o.value_numeric=0 
where  concept_id = 1452 and o.value_numeric is null;


-- 1453 -NUMERO DE FILHOS HIV POS: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1453 and o.value_numeric is null and o.voided=0; */

update obs o set  o.value_numeric=0 
where  concept_id = 1453 and o.value_numeric is null ;

-- 1459 -Outra ocupacao : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1459 and o.value_text is null and o.voided=0; */

update obs o set  o.value_text= "Sem Informação" 
where  concept_id = 1459 and o.value_text is null ;


-- 1469 - DIAGNOSTICO INTERNAMENTO : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1469 and o.value_text is null and o.voided=0;*/

update obs o set  o.value_text= "Sem Informação" 
where  concept_id = 1469 and o.value_text is null  ;


-- 1470 - DATA DE INTERNAMENTO, ENTRADA : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1470 and o.value_datetime is null and o.voided=0;  */

delete from obs  where concept_id = 1470  and value_datetime is null ;


-- 1471 -TRATAMENTO INTERNAMENTO : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1471 and o.value_text is null and o.voided=0; */

delete from obs  where concept_id = 1471  and value_text is null ;

-- 1601 - ALERGIA A MEDICACAO : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1601 and o.value_text is null and o.voided=0; */

delete from obs  where concept_id = 1601  and value_text is null ;

-- 1605 -ALERGIA A MEDICAMENTOS : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1605 and o.value_coded is null and o.voided=0; */

delete from obs  where concept_id = 1605  and value_coded is null ;

-- 1605 -HOSPITALIZACAO: ADULTO INICIAL A

/* select e.encounter_id, e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1606 ; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1606  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 1609 - PESSOA DE REFERENCIA, CONJUNTO: ADULTO INICIAL A

/* select e.encounter_id, e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1609 ;
update  obs set  voided=1, voided_by=1 , void_reason='No value error' , date_voided= sysdate()  where concept_id = 1609  and comments ='Imported by Migration'; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1609  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 1611 - REFERENCIA - NUMERO DE TELEFONE : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1611 and o.value_text is null and o.voided=0; */

delete from obs  where concept_id = 1611  and value_text is null ;

-- 1637  - HEMATOLOGIA, HEMAGRAMA: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1637 and o.value_text is null and o.voided=0;
 */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1637  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;



-- 1656 -NUMERO DE CONVIVENTES: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1656 and o.value_numeric is null and o.voided=0;  */

delete from obs  where concept_id = 1656  and value_numeric is null ;

-- 1659  - INFORMAÇÃO CIVIL PARA PACIENTES HIV POSITIVOS: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1659 and o.value_text is null and o.voided=0;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1659  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 1659 - SITUACAO SOCIAL: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1660 and o.value_text is null and o.voided=0; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1660  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 1661 -DIAGNÓSTICO HIV : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1661 and o.value_text is null and o.voided=0; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1661  and value_coded is null  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 1666 - Nº DE PARCEIROS NOS ULTIMOS 3 MESES : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1666 and o.value_coded is null and o.voided=0; */

delete from obs  where concept_id = 1666  and value_coded is null   and value_text is null and value_numeric is null  ;


-- 1687 - EXPOSIÇÃO HIV POR ACIDENTE: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1687 and o.value_coded is null and o.voided=0;  */

delete from obs  where concept_id = 1687  and value_coded is null and value_text is null  ;


-- 5557 - NÚMERO DE ESPOSAS: ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5557 and o.value_numeric is null and o.voided=0; */

delete from obs  where concept_id = 5557  and value_numeric is null ;


-- 5573 - NÚMERO DE FILHOS : ADULTO INICIAL A

/* select e.patient_id, e.encounter_type, et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5573 and o.value_numeric is null and o.voided=0; */
DELETE FROM obs  WHERE  concept_id = 5573 AND value_numeric IS NULL ;


-- 1113 - DATA DE INICIO DO TRATAMENTO TB : ADULTO INICIAL A

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1113 and o.value_datetime is null and o.voided=0 ; */

delete from obs  where concept_id = 1113  and value_datetime is null ;

-- 1190 -DATA DE INICIO DO TARV : ADULTO INICIAL A

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1190 and o.value_datetime is null and o.voided=0 ; */

delete from obs  where concept_id = 1190  and value_datetime is null ;


-- 1268 -TRATAMENTO DE TUBERCULOSE: ADULTO INICIAL A

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1268 and o.value_coded is null and o.voided=0 ;   */
SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1268  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 1342 - INDICE MASSA CORPORAL: ADULTO INICIAL A

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1342 and o.value_numeric is null and o.voided=0 ;  */

delete from obs  where concept_id = 1342  and value_numeric is null ;

-- 1410  DATA DE PROXIMA CONSULTA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1410 and o.value_datetime is null and o.voided=0 ;  */

delete from obs  where concept_id = 1410  and value_datetime is null ;


-- 1714  ADESAO

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1714 and o.value_coded is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1714  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 5085  PRESSÃO ARTERIAL SISTÓLICA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5085 and o.value_numeric is null and o.voided=0 ; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5085  and value_numeric is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 5086 PRESSÃO ARTERIAL DIASTÓLICA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5086 and o.value_numeric is null and o.voided=0 ;  */
SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5086  and value_numeric is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 5088 TEMPERATURA (C)

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5088 and o.value_numeric is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5088  and value_numeric is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 5089 PESO (KG)

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5089 and o.value_numeric is null and o.voided=0 ; */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5089  and value_numeric is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 5090 ALTURA (CM)

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5090 and o.value_numeric is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5090  and value_numeric is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 5356 ESTADIO OMS ACTUAL

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 5356 and o.value_coded is null and o.voided=0 ;  */
SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 5356  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6120 DATA DE FIM DO TRATAMENTO TB

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 6120 and o.value_datetime is null and o.voided=0 ;  */
SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6120  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6121 PROFILAXIA COM COTRIMOXAZOL


/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 6121 and o.value_coded is null and o.voided=0 ;  */

delete from obs  where concept_id = 6121  and value_coded is null ;


-- 6122  PROFILAXIA COM ISONIAZIDA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6122 and o.value_coded is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6122  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 6126  DATA DE INICIO DA PROFILAXIA COM COTRIMOXAZOL

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6126 and o.value_datetime is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6126  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6127   DATA DE FIM DA PROFILAXIA COM COTRIMOXAZOL

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6127 and o.value_datetime is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6127  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6128  DATA DE INICIO DA PROFILAXIA COM ISONIAZIDA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6128 and o.value_datetime is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6128  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6129   DATA DE FIM DA PROFILAXIA COM ISONIAZIDA

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6129 and o.value_datetime is null and o.voided=0 ;  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6129  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;

-- 6257  RASTREIO DE TB

/* select e.encounter_id, e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
 from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id =6257 and o.voided=0 and   o.value_coded is null and comments ='Imported by Migration';  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6257  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 6258  RASTREIO DE ITS

/* select e.encounter_id , e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 6258   and o.voided=0 and   o.value_coded is null and comments ='Imported by Migration';  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6258  and value_coded is null ;
SET FOREIGN_KEY_CHECKS=1;


-- 6278   DATA DE ELEGIBILIDADE PARA INICIAR O TARV

/* select e.encounter_id , e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 6278   and o.voided=0 and   o.value_datetime is null and comments ='Imported by Migration';  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 6278  and value_datetime is null ;
SET FOREIGN_KEY_CHECKS=1;




-- 1451   OUTROUS PARCEIROS

/* select e.encounter_id , e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1451   and o.voided=0 and   o.value_text is null and comments ='Imported by Migration';  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1451  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;



-- 1468   Enfermaria

/* select e.encounter_id , e.location_id,e.patient_id, e.encounter_type, e.encounter_datetime,et.name, o.concept_id,o.value_coded,o.value_datetime,o.value_numeric,o.value_text,o.comments
from encounter e inner join obs o on o.encounter_id=e.encounter_id inner join encounter_type et on et.encounter_type_id = e.encounter_type
where concept_id = 1468   and o.voided=0 and   o.value_text is null and comments ='Imported by Migration';  */

SET FOREIGN_KEY_CHECKS=0;
delete from obs  where concept_id = 1468  and value_text is null ;
SET FOREIGN_KEY_CHECKS=1;


/* Fix Altura em (cm) problems */

/*
select  person_id, encounter_id,concept_id, value_numeric, replace(value_numeric, '.', ''), concat(replace(value_numeric, '.', ''), '0') + 0.0,  length(value_numeric)  from obs where concept_id =5090
and  value_numeric regexp('\\.')  and length(value_numeric) =3  and  value_numeric < 2;
*/
update obs set value_numeric = concat(replace(value_numeric, '.', ''), '0') + 0.0
where concept_id =5090 and  value_numeric regexp('\\.')  and length(value_numeric) =3  and  value_numeric < 2;
/*
select  person_id, encounter_id,concept_id, value_numeric, replace(value_numeric, '.', '') +0.0, concat(replace(value_numeric, '.', ''), '0') + 0.0,  length(value_numeric)  from obs where concept_id =5090
and  value_numeric regexp('\\.')  and length(value_numeric) =3  and  value_numeric > 2;
*/

update obs set value_numeric = replace(value_numeric, '.', '') +0.0
where concept_id =5090 and  value_numeric regexp('\\.')  and length(value_numeric) =3  and  value_numeric > 2;

/*
 select  person_id, encounter_id,concept_id, value_numeric, replace(value_numeric, '.', ''), concat(replace(value_numeric, '.', ''), '0') + 0.0,  length(value_numeric)  from obs where concept_id =5090
and  value_numeric regexp('\\.')  and length(value_numeric) =4  and  value_numeric > 2 and value_numeric between 10 and 20;
*/
update obs set value_numeric = replace(value_numeric, '.', '') + 0.0
where concept_id =5090 and  value_numeric regexp('\\.')  and length(value_numeric) =4  and  value_numeric > 2 and value_numeric between 10 and 20;

/*
select  person_id, encounter_id,concept_id, value_numeric, replace(value_numeric, '.', '')+0.0, concat(replace(value_numeric, '.', ''), '0') + 0.0,  length(value_numeric)  from obs where concept_id =5090
and  value_numeric regexp('\\.')  and length(value_numeric) =4  and  value_numeric  < 2;
*/
update obs set value_numeric = replace(value_numeric, '.', '') +0.0
where concept_id =5090 and  value_numeric regexp('\\.')  and length(value_numeric) =4  and  value_numeric  < 2;

-- TODO
/*
select  person_id, encounter_id,concept_id, value_numeric, replace(value_numeric, '.', ''), insert(concat(replace(value_numeric, '.', ''),''),4,0,'.') +0.0,  length(value_numeric)  from obs where concept_id =5090
and  value_numeric regexp('\\.')  and length(value_numeric) =5  and  value_numeric  < 2;
*/

update obs set value_numeric =  insert(concat(replace(value_numeric, '.', ''),''),4,0,'.') +0.0
where  concept_id =5090 and  value_numeric regexp('\\.')  and length(value_numeric) =5  and  value_numeric  < 2;


-- PREP Update

update concept set class_id = 11 where concept_id = 165217;
update concept_numeric set hi_normal = 120.0, low_normal = 0 where concept_id=165217;
update concept set datatype_id = 3 where concept_id in (165297, 165298, 165299);
