-- Tratamento TB
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1d9fbda-1d5f-11e0-b929-000c29ad1d07", "e1d9ef28-1d5f-11e0-b929-000c29ad1d07", "e1d9f036-1d5f-11e0-b929-000c29ad1d07", "e1d9facc-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';

-- pedido de cv na FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "e1da2812-1d5f-11e0-b929-000c29ad1d07",
                 "cc8ef88c-6ab6-4404-a036-d415bc42cc1c","4df535db-b8c9-4759-85bb-f4bcb5bebdc6" )
 and locale ='pt';
-- Regime T FC
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ( "e1d6247e-1d5f-11e0-b929-000c29ad1d07" ,"e1da2704-1d5f-11e0-b929-000c29ad1d07")
 and locale ='pt';

-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1d6247e-1d5f-11e0-b929-000c29ad1d07" ,"e1da2704-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';


-- Carga viral
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("687d72a2-c123-42b1-8083-968c4588b243",
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
                 "815b9762-329d-42c8-9158-d42016c49b85" )
 and locale ='pt';



-- ------------------------------------ Diagnostico TB
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("40a9a12b-1205-4a55-bb93-caf15452bf61"  )
 and locale ='pt';

-- Avaliacao Nutricional : Grau
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("0b1a2c8c-55d2-42a8-a3d6-62828f52d49a", "e1d85b22-1d5f-11e0-b929-000c29ad1d07", "aa84f34d-11f7-4466-b784-0fdda716ace2", "e1cf1422-1d5f-11e0-b929-000c29ad1d07", "e1dec764-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';


  -- Avaliacao Nutricional : Grau
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("e1dd5ab4-1d5f-11e0-b929-000c29ad1d07" )
 and locale ='pt';

select c.concept_id,cn.name , c.uuid from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid like '%AAAAA%'
 and locale ='pt';


-- Avaliacao Nutricional : Grau
select c.concept_id,cn.name from concept c
inner join concept_name cn on c.concept_id=cn.concept_id
where c.uuid in ("cc8ef88c-6ab6-4404-a036-d415bc42cc1c", "4df535db-b8c9-4759-85bb-f4bcb5bebdc6","e1da2812-1d5f-11e0-b929-000c29ad1d07", "78a76661-50c0-41cf-b566-de275f17b648",
                 "ae6c048f-8b04-46cb-903e-51d5670db525", "1321eeac-5832-4076-88e9-b1f2cd351ada", "d6eb4797-2c01-4b6e-b43f-be15cd2fdcc2", "7c8e0a9b-3606-4a72-b8cc-89566521fac2" )


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
