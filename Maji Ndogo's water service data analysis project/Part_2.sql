use md_water_services;
show tables;

/* new mail address for an employees*/
select
concat(lower(replace(employee_name,' ','.')),'@ndogowater.gov') as employee_mail
from employee;

/* update the email column data in the employee table by the new mail*/

update employee
set email = (selectphone_number = 
concat(lower(replace(employee_name,' ','.')),'@ndogowater.gov'));

select length(phone_number) 
from employee;

update employee
set phone_number = (select RTRIM(phone_number));

/* count how many of our employees live in each town. */
select 
    distinct town_name,
    count(employee_name) over (
    partition by town_name
    order by town_name) as number_of_employee
from
    employee;
    
/* the number of records each employee collected. */
select
    assigned_employee_id,
    count(assigned_employee_id) as sum_of_record_collected
from visits
group by assigned_employee_id
order by sum_of_record_collected asc
limit 2;

/* the top 3 recorders employee detail info*/
select *
from 
    employee
where 
    assigned_employee_id in ('20','22');

/* Create a query that counts the number of records per town */

select 
    town_name,
    count(location_id) as record_per_town
from location
group by town_name;


/* Create a query that counts the number of records per province */
select 
    province_name,
    count(location_id) as record_per_province
from location
group by province_name;

select 
    town_name,
    province_name,
    count(*) as locations_count
from location
group by town_name,province_name
order by province_name,locations_count desc;

/* the number of records for each location type*/

SELECT 
    CASE 
        WHEN town_name = 'Rural' THEN 'Rural'
        ELSE 'Urban'
    END AS town_type,
    COUNT(*) AS locations_count
FROM location
GROUP BY town_type
ORDER BY locations_count DESC;

/* water_source table analysis */

select count(*)
from water_source;

/* How many people did we survey in total */
select sum(number_of_people_served)
from water_source;

/* How many wells, taps and rivers are there? */
select 
    case
        when type_of_water_source = 'river' then 'river'
        when type_of_water_source = 'well' then 'well'
        else 'taps'
	END as water_source_type,
    count(source_id) as number_of_sources
from 
    water_source
group by water_source_type;

/* How many people share particular types of water sources on average? */

select 
    type_of_water_source,
    round(avg(number_of_people_served),0)
from water_source
group by type_of_water_source;

/* How many people are getting water from each type of source? */
select
    type_of_water_source,
    sum(number_of_people_served) as sum_of_number_of_people_served
from 
    water_source
group by type_of_water_source
order by sum_of_number_of_people_served desc;

/* ranks each type of source based on how many people in total use it using percentage served*/

select
    type_of_water_source,
    round(((sum(number_of_people_served)/ 27628140) * 100),0) as Per_number_of_people_served
from 
    water_source
group by  type_of_water_source
order by Per_number_of_people_served desc;

/* ranks each type of source based on how many people in total use it */

select
    type_of_water_source,
    sum(number_of_people_served) as sum_number_of_people_served,
    rank() over (
    order by sum(number_of_people_served) desc) as rank_number_of_people_served
from 
    water_source
group by type_of_water_source
order by sum_number_of_people_served desc;


/* The sources within each type should be assigned a rank */
select
    source_id,
    type_of_water_source,
    number_of_people_served,
    row_number() over (
    partition by type_of_water_source
    order by number_of_people_served desc) as rank_number_of_people_served
from 
    water_source
where type_of_water_source = 'river'
order by number_of_people_served desc;


/* How long did the survey take in days*/
select
    min(time_of_record),
    max(time_of_record),
    timestampdiff(day,min(time_of_record),max(time_of_record)) as duration
from visits;

/* What is the average total queue time in minutes for water */

select
    avg(case
		    when time_in_queue <> 0 
            then time_in_queue
		end) as avg_time_in_queue
from visits;

/* What is the average queue time on different days? */
select
    dayname(time_of_record) as dayname_of_time_record,
    round(avg(case
		    when time_in_queue <> 0 
            then time_in_queue
		end),0) as avg_time_in_queue
from
    visits
group by dayname_of_time_record;

/* what time during the day people collect water */
select
    TIME_FORMAT(TIME(time_of_record), '%H:00') as hour_of_time_record,
    round(avg(case
		    when time_in_queue <> 0 
            then time_in_queue
		end),0) as avg_time_in_queue
from
    visits
group by hour_of_time_record
order by hour_of_time_record;

/* pivot table; For rows, we will use the hour of the day in that nice format, and then make each column a different day! */

select
    TIME_FORMAT(TIME(time_of_record), '%H:00') as hour_of_time_record,
    round(avg(case
		          when dayname(time_of_record) = 'Sunday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Sunday,
    round(avg(case
		          when dayname(time_of_record) = 'Monday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Monday,
	round(avg(case
		          when dayname(time_of_record) = 'Tuesday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Tuesday,
	round(avg(case
		          when dayname(time_of_record) = 'Wednesday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Wednesday,
	round(avg(case
		          when dayname(time_of_record) = 'Thursday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Thursday,
	round(avg(case
		          when dayname(time_of_record) = 'Friday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Friday,
	round(avg(case
		          when dayname(time_of_record) = 'Saturday' and time_in_queue <> 0 
                  then time_in_queue
		      end),0) as Saturday
              
from
    visitsaccess_to_basic_servicesaccess_to_basic_services
group by hour_of_time_record
order by hour_of_time_record;
