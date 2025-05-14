-- Tratamento TB
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1d9fbda-1d5f-11e0-b929-000c29ad1d07", "e1d9ef28-1d5f-11e0-b929-000c29ad1d07", "e1d9f036-1d5f-11e0-b929-000c29ad1d07", "e1d9facc-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';

-- pedido de cv na FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1e53c02-1d5f-11e0-b929-000c29ad1d07")
 and locale ='pt';
-- Regime T FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.=c.concept_id in ( 5096)
 and locale ='pt';

-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("70cb2221-d0bd-4e30-bbd5-7da8a3ba01ab" ,"7a72cf0c-5f43-436d-92d9-6f04cbb0a0b9",   "230c81e9-961f-478a-987d-3af637e83e5e", "ae8d45d0-14b9-460e-888d-f883de83be26",
                  "a1d858ea-3a19-41e1-879d-2457440e1d36","4387180e-695f-4c99-8182-33e51907062a",  "b856b79b-2e8e-4764-ae8b-c8b509cdda76",  "f22a9436-4ed4-401c-84ea-0c7dbf910639" )
 and locale ='pt';


-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "e1d446cc-1d5f-11e0-b929-000c29ad1d07","e1d47386-1d5f-11e0-b929-000c29ad1d07","5622AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" )
 and locale ='pt';

-- Resultado de Via
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "5085AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ,"5086AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
 and locale ='pt';
-- Resutlado HPV



-- ------------------------------------ Diagnostico TB
use altomae;

select * from encounter_type where name in ('PTV: PRE-NATAL INICIAL');
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1dae234-1d5f-11e0-b929-000c29ad1d07"  )
 and locale ='pt';

-- Avaliacao Nutricional : Grau
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ('7a72cf0c-5f43-436d-92d9-6f04cbb0a0b9','230c81e9-961f-478a-987d-3af637e83e5e', '7a72cf0c-5f43-436d-92d9-6f04cbb0a0b9',
'ae8d45d0-14b9-460e-888d-f883de83be26','4387180e-695f-4c99-8182-33e51907062a','b856b79b-2e8e-4764-ae8b-c8b509cdda76',
'a1d858ea-3a19-41e1-879d-2457440e1d36','f22a9436-4ed4-401c-84ea-0c7dbf910639')
 and locale ='pt';


  -- Avaliacao Nutricional : Grau

select c.concept_id,cn.name , c.uuid from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid like '%AAAAA%'
 and locale ='pt';


-- Avaliacao Nutricional : Grau
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ('6d6b3f98-4038-4a08-889c-51a7c4079e11' )
 and locale ='pt';

 -- OFicha clinica : Infecções oportunistas

select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.concept_id in (1066,1256 ,1065 ,1267)
 and locale ='pt';

 -- Outras prescricoes : Ficha clinica

select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where cn.name like '%sarcoma%'
 and locale ='pt';



select e.patient_id, e.encounter_type, o.concept_id, o.value_coded, cname.name, encounter_datetime
from encounter e inner join obs o on e.encounter_id=o.encounter_id
left join (select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
 and locale ='pt') cname on cname.concept_id=o.value_coded

where value_coded in (
select c.concept_id from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where cn.name like '%sarcoma%'
 and locale ='pt'

)



