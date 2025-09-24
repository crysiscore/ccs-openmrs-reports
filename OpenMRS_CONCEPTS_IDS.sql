-- Tratamento TB
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1d9fbda-1d5f-11e0-b929-000c29ad1d07", "e1d9ef28-1d5f-11e0-b929-000c29ad1d07", "e1d9f036-1d5f-11e0-b929-000c29ad1d07", "e1d9facc-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';

-- pedido de cv na FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("fef178f2-d4c9-4035-9989-11c9afe81ea3")
 and locale ='pt';
-- Regime T FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.=c.concept_id in ( 5096)
 and locale ='pt';

-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in (
"70cb2221-d0bd-4e30-bbd5-7da8a3ba01ab" , "230c81e9-961f-478a-987d-3af637e83e5e", "7a72cf0c-5f43-436d-92d9-6f04cbb0a0b9","7a72cf0c-5f43-436d-92d9-6f04cbb0a0b9",
"b856b79b-2e8e-4764-ae8b-c8b509cdda76" , "ae8d45d0-14b9-460e-888d-f883de83be26’", "4387180e-695f-4c99-8182-33e51907062a","b856b79b-2e8e-4764-ae8b-c8b509cdda76" , "a1d858ea-3a19-41e1-879d-2457440e1d36" ,
                 "f22a9436-4ed4-401c-84ea-0c7dbf910639","ae8d45d0-14b9-460e-888d-f883de83be26")
 and locale ='pt';


-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "bebcfbe3-bb5b-4c5c-a41e-808fc4457fc3",
                  "fef178f2-d4c9-4035-9989-11c9afe81ea3" ,
                 "e1d9ef28-1d5f-11e0-b929-000c29ad1d07",
                 "e1d9f036-1d5f-11e0-b929-000c29ad1d07",
                 "e1d9facc-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';

-- Resultado de Via
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "687d72a2-c123-42b1-8083-968c4588b243",
          "b5c31d5e-165a-4618-aa62-113a0751a400",
          "3069be5c-cd02-4ddb-aa1f-bdd71d3dd6be",
          "018ba584-3158-4075-82f7-c84c51f5085c",
          "bcedb8c1-f1d9-48c2-bfe3-9401950f1c16",
          "870e2d25-c5ef-4e36-89db-0a4a37af214e",
          "0843c71b-be47-4de2-ba16-a08db52c1136",
          "0b639730-70ae-44b8-a90f-c24ce7af31e4",
          "0b35d894-49c6-45bc-880b-8c816f659e6e",
          "d2380393-3621-421f-83fc-846d2d332904",
          "1fb0de79-31c6-4a31-a832-0c29f3c01e93",
          "f46bfb16-240d-4bd3-a497-d23afd377f4f",
          "5d82b491-2ca2-41ea-b091-16ffc5169aa1",
          "c95ec0b3-f175-48e8-8fc0-a6cb2d249ed5",
          "e8aa76e4-f105-4de4-b3d8-617c526cc199",
          "a8b3dd5a-fcc1-4e5c-a6a7-4d51c31b33da",
         "8d4ba67e-3e45-425c-b48c-104028dd7cec",
          "fc78cb84-f9a4-4d64-9569-2ff301af36ea",
          "26b01a43-32d6-4bf9-aa1a-0d8d03aab463",
          "f1f6956f-e2e2-4c37-8c4a-ce4a1c381088",
          "d2eaec39-9c48-443b-a8d5-b2b163d42c53",
          "2e7b0a2a-dae3-460f-b2db-fc8b8d3e9909",
          "815b9762-329d-42c8-9158-d42016c49b85")
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



