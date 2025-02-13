use md_water_services;
show tables;


create view
     combined_analysis_table AS(-- This table assembles data from different tables into one to simplify analysis

select
  location.province_name,
  location.town_name,
  water_source.type_of_water_source,
  location.location_type,
  water_source.number_of_people_served,
  visits.time_in_queue,
  well_pollution.results
from 
 location as location
inner join
 visits as visits
on
	location.location_id = visits.location_id

inner join
  water_source as water_source
on
	visits.source_id = water_source.source_id

left join
  well_pollution as well_pollution
on
	visits.source_id = well_pollution.source_id

where
	visits.visit_count = 1);


WITH province_totals AS (-- This CTE calculates the population of each province
     select 
          province_name,
          sum(number_of_people_served) as total_peoples_served
	 from
          combined_analysis_table
	 group by province_name)

select
      ct.province_name,
      ROUND((SUM(CASE WHEN ct.type_of_water_source = 'well' THEN ct.number_of_people_served ELSE 0 END)*100/pt.total_peoples_served),0) AS well,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'tap_in_home' THEN ct.number_of_people_served ELSE 0 END)*100/pt.total_peoples_served),0) AS tap_in_home,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'tap_in_home_broken' THEN ct.number_of_people_served ELSE 0 END)*100/pt.total_peoples_served),0) AS tap_in_home_broken,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'shared_tap' THEN ct.number_of_people_served ELSE 0 END)*100/pt.total_peoples_served),0) AS shared_tap,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'river' THEN ct.number_of_people_served ELSE 0 END)*100/pt.total_peoples_served),0) AS river
      
from
      combined_analysis_table as ct
inner join 
      province_totals as pt
on ct.province_name = pt.province_name
group by 
     province_name;
      




CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (-- This CTE calculates the population of each town in province
     select 
          province_name,
          town_name,
          sum(number_of_people_served) as total_peoples_served
	 from
          combined_analysis_table
	 group by province_name,town_name)

select
      ct.province_name,
      ct.town_name,
      ROUND((SUM(CASE WHEN ct.type_of_water_source = 'well' THEN ct.number_of_people_served ELSE 0 END)*100/tt.total_peoples_served),0) AS well,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'tap_in_home' THEN ct.number_of_people_served ELSE 0 END)*100/tt.total_peoples_served),0) AS tap_in_home,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'tap_in_home_broken' THEN ct.number_of_people_served ELSE 0 END)*100/tt.total_peoples_served),0) AS tap_in_home_broken,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'shared_tap' THEN ct.number_of_people_served ELSE 0 END)*100/tt.total_peoples_served),0) AS shared_tap,
	  ROUND((SUM(CASE WHEN ct.type_of_water_source = 'river' THEN ct.number_of_people_served ELSE 0 END)*100/tt.total_peoples_served),0) AS river
      
from
      combined_analysis_table as ct
inner join 
      town_totals as tt
on 
      ct.province_name = tt.province_name
      and ct.town_name = tt.town_name
group by 
     province_name, town_name
order by river desc;

select
	province_name,
    town_name,
	case
		when (tap_in_home < 50 and tap_in_home_broken < 50) then province_name
        else 'null'
	end as province_name2
from 
	town_aggregated_water_access;



/* This query creates the Project_progress table*/
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same

source more than once in the future.

*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,

and should refer to the source table. This ensures data integrity.

*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE,
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);



-- Project_progress_query
insert into Project_progress (source_id,
                              Address,
                              Town,
                              Province,
                              Source_type,
                              Improvement)

SELECT
	water_source.source_id,
    location.address,
	location.town_name,
	location.province_name,
	water_source.type_of_water_source,
    case 
        when (water_source.type_of_water_source = 'well' and  well_pollution.results like '%Chemical%') then 'Install RO filter'
        when (water_source.type_of_water_source = 'well' and  well_pollution.results like '%Biological%') then 'Install UV filter'
		when water_source.type_of_water_sourcecombined_analysis_table = 'river'  then 'Drill well'
        when (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30) then CONCAT("Install ", FLOOR(visits.time_in_queue/30), " taps nearby")
		when (water_source.type_of_water_source = 'tap_in_home_broken') then 'Diagnose local infrastructure'
        else 'null' 
    end  	as Improvement
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
where
    visits.visit_count = 1
    AND ( -- And one of the following (OR) options must be true as well.
		well_pollution.results != 'Clean'
		OR  water_source.type_of_water_source IN ('tap_in_home_broken','river')
		OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
		)
limit 30000;
