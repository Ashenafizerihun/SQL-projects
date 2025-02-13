use md_water_services;
show tables;

DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

/* How many percent of the serveyors record data is correct in reference to the auditors data? */

with
     incorrect_records
AS(

select
     auditor_report.location_id as location_id,
     auditor_report.type_of_water_source as auditor_source,
     auditor_report.true_water_source_score as auditor_score,
     water_quality.subjective_quality_score as surveyor_score,
     visits.record_id,
     employee.employee_name
	
from 
	 auditor_report as auditor_report
inner join
     visits as visits
on 
     auditor_report.location_id = visits.location_id
inner join 
     water_quality as water_quality
on
     visits.record_id = water_quality.record_id
inner join
     employee as employee
on 
     visits.assigned_employee_id = employee.assigned_employee_id
where 
     auditor_report.true_water_source_score != water_quality.subjective_quality_score
     and 
     visits.visit_count = 1
limit 10000),

error_count AS(
select 
     employee_name,
     count(employee_name) as number_of_mistakes
from 
     incorrect_records
group by
     employee_name
order by
     count(employee_name) desc),

avg_error_count_per_empl AS(     
SELECT
     AVG(number_of_mistakes) as avg_error_count
FROM
    error_count),
     
suspect_list AS(

select
	 employee_name,
     number_of_mistakes
from 
     error_count
where 
     number_of_mistakes > (select 
						       avg_error_count
					       from
						       avg_error_count_per_empl))
select *
from 
     suspect_list;
     
     
/* create a view table for the above quesry*/

drop view incorrect_records;
create view 
         incorrect_records
         AS(
			select
				 auditor_report.location_id as location_id,
				 auditor_report.type_of_water_source as auditor_source,
				 auditor_report.true_water_source_score as auditor_score,
				 water_quality.subjective_quality_score as surveyor_score,
				 visits.record_id,
				 employee.employee_name,
                 auditor_report.statements
				
			from 
				 auditor_report as auditor_report
			inner join
				 visits as visits
			on 
				 auditor_report.location_id = visits.location_id
			inner join 
				 water_quality as water_quality
			on
				 visits.record_id = water_quality.record_id
			inner join
				 employee as employee
			on 
				 visits.assigned_employee_id = employee.assigned_employee_id
			where 
				 auditor_report.true_water_source_score != water_quality.subjective_quality_score
				 and 
				 visits.visit_count = 1);
                 
/* create a CTE using a view table */

with 
	error_count 
    AS(  -- This CTE calculates the number of mistakes each employee made
		select 
			 employee_name,
			 count(employee_name) as number_of_mistakes
		from 
			 incorrect_records
		group by
			 employee_name
		order by
			 count(employee_name) desc),
	
    avg_error_count_per_empl 
    AS(-- This CTE return the averahe mistakes made by each employees     
       SELECT
            AVG(number_of_mistakes) as avg_error_count
		FROM
			error_count),
	
    suspect_list 
    AS(-- This CTE SELECTS the employees with above−average mistakes
		select
			 employee_name,
			 number_of_mistakes
		from 
			 error_count
		where 
			 number_of_mistakes > (select 
									   avg_error_count
								   from
									   avg_error_count_per_empl))

-- This query filters all of the records where the "corrupt" employees gathered data.
select
     location_id,
     employee_name,
     statements
from 
	 incorrect_records
where 
     employee_name in (select 
                            employee_name
                       from 
                            suspect_list);

