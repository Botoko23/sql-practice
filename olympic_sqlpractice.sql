-- Dataset Link 
-- https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results resource=download#

-- Write a SQL query to find the total no of Olympic Games held as per the dataset.
select count(distinct games) total_num_games from olympics_history;

-- Write a SQL query to list down all the Olympic Games held so far.
select year, season, city  from olympics_history
order by year;

-- SQL query to fetch total no of countries participated in each olympic games.

with joined as (
	select games, region country from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
)

select games, count(distinct country) total_countries  from joined
group by games
order by games;

-- Write a SQL query to return the Olympic Games which had the highest participating countries 


with all_countries as
		  (select games, nr.region
		  from olympics_history oh
		  join olympics_history_noc_regions nr ON nr.noc=oh.noc
		  group by games, nr.region),
	  tot_countries as
		  (select games, count(1) as total_countries
		  from all_countries
		  group by games)
		  

select distinct
concat(first_value(games) over(order by total_countries)
, ' - '
, first_value(total_countries) over(order by total_countries)) as Lowest_Countries,

concat(first_value(games) over(order by total_countries desc)
, ' - '
, first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
from tot_countries;



-- SQL query to return the list of countries who have been part of every Olympics games.
with joined as (
	select games, region country
	from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
)

select country, Count(distinct games) total_participated_games from joined							
group by country
having Count(distinct games) = (select Count(distinct games) from joined)



select sport, Count(distinct games) no_of_games from olympics_history
where season = 'Summer'
group by sport
having Count(distinct games) = (select Count(distinct games) from olympics_history where season = 'Summer')

-- Using SQL query, Identify the sport which were just played once in all of olympics.
SELECT 
    sport,
    num_of_games,
    games
FROM (
    SELECT 
        sport,
        COUNT(games) OVER (PARTITION BY sport) AS num_of_games,
        games
    FROM 
        olympics_history
) AS sub
WHERE 
    num_of_games = 1;
	
-- Write SQL query to fetch the total no of sports played in each olympics.
select games, count(distinct sport) total_sports from olympics_history
group by games
order by total_sports desc

--  SQL Query to fetch the details of the oldest athletes to win a gold medal at the 
with gold_winners as (
	select * from olympics_history
	where medal = 'Gold' and age != 'NA'
)

select * from gold_winners
where age = (select max(age) from gold_winners)

-- Find the Ratio of male and female athletes participated in all olympic games.
with f_and_m_count as (
select 
	sum(
		case when sex = 'M' then 1 else 0
		end
	) as male_count,
	sum(
		case when sex = 'F' then 1 else 0
		end
	) as female_count
from olympics_history
)

select '1 : ' || round(male_count/cast(female_count as decimal(10,2)), 2) ratio from f_and_m_count


-- Fetch the top 5 athletes who have won the most gold medals.

select name, team, count(medal) gold_won from olympics_history
where medal = 'Gold'
group by name, team
order by  gold_won desc
limit 5


-- Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).


select name, team, count(medal) medals_won from olympics_history
where medal != 'NA'
group by name, team
order by  medals_won desc
limit 5

-- Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with joined as (
	select medal, region country
	from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
),
 top5_team as (
	select country, count(medal) medals_won from joined
	where medal != 'NA'
	group by country
	order by  medals_won desc
	limit 5
)
select *, rank() over(order by medals_won desc) from top5_team

--15
-- List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
with joined as (
	select games, region country, medal from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
)

select 
	games,
	country,
	sum(
		case when medal = 'Gold' then 1 else 0
		end
	) as gold_count,
	sum(
		case when medal = 'Silver' then 1 else 0
		end
	) as silver_count,
	sum(
		case when medal = 'Bronze' then 1 else 0
		end
	) as bronze_count
from joined
group by games, country
order by games, country

--  Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with joined as (
	select games, region country, medal from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
),
grouped as (
	select 
	games,
	country,
	case when medal = 'Gold' then 1 else 0
		end as gold_count,
	case when medal = 'Silver' then 1 else 0
		end as silver_count,
	case when medal = 'Bronze' then 1 else 0
		end as bronze_count
	from joined

),
test as (
select games, country, 
		sum(gold_count) over(partition by games, country) gold_earned,
		sum(silver_count) over(partition by games, country) silver_earned,
		sum(bronze_count) over(partition by games, country) bronze_earned
from grouped
)

select distinct
	games,
	concat(first_value(country) over(partition by games order by gold_earned desc)
	, ' - '
	, first_value(gold_earned) over(partition by games order by gold_earned desc)) max_gold,
	concat(first_value(country) over(partition by games order by silver_earned desc)
	, ' - '
	, first_value(silver_earned) over(partition by games order by silver_earned desc)) max_silver,
	concat(first_value(country) over(partition by games order by bronze_earned desc)
	, ' - '
	, first_value(bronze_earned) over(partition by games order by bronze_earned desc)) max_bronze
from test
order by games

-- Which countries have never won gold medal but have won silver/bronze medals?
with joined as (
	select games, region country, medal from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
	where medal != 'NA'
)

select * from (select country,
	sum(
		case when medal = 'Gold' then 1 else 0
		end
	) as gold_count,
	sum(
		case when medal = 'Silver' then 1 else 0
		end
	) as silver_count,
	sum(
		case when medal = 'Bronze' then 1 else 0
		end
	) as bronze_count
from joined
group by country)
where gold_count = 0

--  In which Sport/event, India has won highest medals.
with joined as (
	select sport, region country, medal from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
	where medal != 'NA'
)
select sport, count(medal) total_medals from joined 
where country = 'India'
group by sport
order by count(medal) desc
limit 1


-- Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
with joined as (
	select games, sport, region country, medal from olympics_history fact
	join olympics_history_noc_regions dim on fact.noc = dim.noc
	where medal != 'NA'
)

select country, sport, games, count(medal) from joined
where country = 'India'
group by country, sport, games
order by count(medal) desc

