/*

Name 3.	Relatorio com tempo de entrada e saida no OpenMRS por cada usuário na US
Description-
              - P3.	Relatorio com tempo de entrada e saida no OpenMRS por cada usuário na US

Created by: Agnaldo  Samuel
Change Date: 28/02/2023

*/


select e.creator,u.username,   CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto' ,   e.inicio, e.fim , e1.inicio1, e1.fim1,  e2.inicio2, e2.fim2 ,e3.inicio3, e3.fim3 , e4.inicio4,e4.fim4, e5.inicio5, e5.fim5   from

 (
    select  creator , TIME(min(date_created)) as inicio, TIME(max(date_created)) as fim
    from encounter e
  --  order by date_created desc
    where date(date_created) =  :endDate
    and location_id=:location
    group by creator
    ) e
inner join users u on u.user_id =e.creator
     left join person p on p.person_id = u.person_id
      left join person_name pn on pn.person_id =p.person_id
left join (
    select  creator , TIME(min(date_created)) as inicio1, TIME(max(date_created)) as fim1
    from encounter e
  --  order by date_created desc
    where date(date_created) =  date_sub(:endDate , interval 1 DAY )
        and location_id=:location
    group by creator
    ) e1 on e.creator =e1.creator
left join (
    select  creator , TIME(min(date_created)) as inicio2, TIME(max(date_created)) as fim2
    from encounter e
  --  order by date_created desc
    where date(date_created) =  date_sub(:endDate , interval 2 DAY )
        and location_id=:location
    group by creator
    ) e2 on e.creator =e2.creator
left join (
    select  creator , TIME(min(date_created)) as inicio3, TIME(max(date_created)) as fim3
    from encounter e
  --  order by date_created desc
    where date(date_created) =  date_sub(:endDate , interval 3 DAY )
        and location_id=:location
    group by creator
    ) e3 on e.creator =e3.creator
left join (
    select  creator , TIME(min(date_created)) as inicio4, TIME(max(date_created)) as fim4
    from encounter e
  --  order by date_created desc
    where date(date_created) =  date_sub(:endDate , interval 4 DAY )
        and location_id=:location
    group by creator
    ) e4 on e.creator =e4.creator
left join (
    select  creator , TIME(min(date_created)) as inicio5, TIME(max(date_created)) as fim5
    from encounter e
  --  order by date_created desc
    where date(date_created) =  date_sub(:endDate , interval 5 DAY )
        and location_id=:location
    group by creator
    ) e5 on e.creator =e5.creator ;