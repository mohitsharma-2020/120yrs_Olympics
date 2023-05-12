
--1. How many olympics games have been held?
create view total_olympic_games as
SELECT COUNT (DISTINCT games) as Total_Games
FROM events


--2. List down all Olympics games held so far
create view total_olympic_games_names as
SELECT ev.games, ev.year, ev.city
FROM events ev
GROUP BY ev.games, ev.year, ev.city
--ORDER BY ev.year


--3. MentiON the total no of natiONs who participated in each olympics game?
create view total_nations_in_games as
WITH COUNTries as
	(
	SELECT ev.Games, rg.regiON
	FROM 
		events ev
		JOIN 
		regiONs rg
		ON
		ev.NOC = rg.NOC
		GROUP BY 
		ev.Games, rg.regiON
	)

	SELECT c.Games AS [Games played], COUNT(1) AS COUNTries
	FROM COUNTries c
	GROUP BY c.games
	--ORDER BY c.Games

--4. Which year saw the highest and lowest no of COUNTries participating in olympics
create view high_low_nations_inGames as
WITH cte AS
(
SELECT c.Games AS [Games played], COUNT(1) AS COUNTries
FROM 
	(
		SELECT ev.Games, rg.regiON
		FROM 
		events ev
		JOIN 
		regiONs rg
		ON
		ev.NOC = rg.NOC
		GROUP BY 
		ev.Games, rg.regiON
	) c
GROUP BY c.games
)

SELECT	DISTINCT cONcat(FIRST_VALUE(b.[Games played]) over (ORDER BY b.COUNTries DESC),' - ',
				FIRST_VALUE(b.COUNTries) over (ORDER BY b.COUNTries DESC)) [Highest COUNTries],
				cONcat(FIRST_VALUE(b.[Games played]) over (ORDER BY b.COUNTries),' - ',
				FIRST_VALUE(b.COUNTries) over (ORDER BY b.COUNTries)) [Lowest COUNTries]
FROM cte b


--5. Which natiON has participated in all of the olympic games
create view nation_in_All_games as

WITH total_games AS
	(
		SELECT COUNT(DISTINCT games) total_g
		FROM events
	),	
	COUNTries_participated AS
	(
		SELECT ev.games, rg.regiON AS COUNTries, ev.noc
		FROM events ev
		JOIN regiONs rg ON ev.NOC = rg.NOC
		GROUP BY ev.Games, rg.regiON, ev.noc
	),
	[all matches played] AS
	(
		SELECT cp.COUNTries, COUNT(1) AS [games participated]
		FROM COUNTries_participated cp
		GROUP BY cp.COUNTries
	)

SELECT *
FROM 
	[all matches played] amp
	inner JOIN
	total_games tg ON amp.[games participated] = tg.total_g

--6. Identify the sport which was played in all summer olympics.
create view sport_played_inSummer_games as

WITH total_games AS
	(
		SELECT SeasON, COUNT(DISTINCT games) AS [Number of Games]
		FROM events
		GROUP BY seasON
	),

	sports AS
	(
		SELECT sport, COUNT(DISTINCT games) Games_played
		FROM events
		WHERE seasON = 'summer'
		GROUP BY sport
	)
	
SELECT s.Sport, s.Games_played, tg.[Number of Games]
FROM 
	sports s
	JOIN 
	total_games tg 
	ON s.games_played = tg.[Number of Games]

--7. Which Sports were just played ONly ONce in the olympics.
create view sports_played_once as
WITH sports_once AS
	(
		SELECT DISTINCT games,sport as sport_played
		FROM events
	),

	game_counter as
	(
		SELECT sport_played as sports, COUNT(1) AS No_of_Games
		FROM sports_once
		GROUP BY sport_played
	)
	
SELECT *
FROM game_counter gc
JOIN sports_once s
ON gc.sports = s.sport_played
WHERE gc.No_of_Games = 1
	

--8. Fetch the total no of sports played in each olympic games.
create view Total_sports_played as
SELECT Games, COUNT(DISTINCT Sport) [Number of Sports]
FROM
	events
GROUP BY 
	games
--ORDER BY[Number of Sports] DESC

--9. Fetch oldest athletes to win a gold medal
create view oldest_athletes_won_gold as
select *
from events
where medal = 'gold' and age in (select max(age) from events where medal = 'gold')


--10. Find the Ratio of male and female athletes participated in all olympic games.
create view male_female_ratio as
with male_athletes as
(
	select sex, count(*) [Total Male Athletes]
	from events
	where sex = 'm'
	group by sex
),
female_athlete as
(
	select sex, count(*) [Total Female Athletes]
	from events
	where sex = 'f'
	group by sex
)

select concat('1 : ',round(cast(max(ma.[Total Male Athletes])as float)/cast(max(fa.[Total female Athletes]) as float),2)) as Ratio
from male_athletes ma
full join 
female_athlete fa 
on ma.Sex = fa.sex

--11. Fetch the top 5 athletes who have won the most gold medals.
create view athletes_most_gold as
select top(5) name, team, count(1) as Total_Gold, games
from events
where medal = 'gold'
group by name, team, games
order by Total_Gold desc, name

--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
create view athletes_most_medals as
select top(5) name, team, count(1) as Total_Medals
from events
where medal in ('gold','silver','bronze')
group by name, team
order by Total_medals desc, name

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
create view most_medal_byCountry as
select top(5) rg.region, count(1) as Total_Medals
from events ev
join
regions rg on ev.noc = rg.noc
where medal <> 'NA'
group by rg.region
order by Total_medals desc

--14. List down total gold, silver and bronze medals won by each country.
create view medals_by_countries as
select country,[Gold],[Silver],[Bronze]
		from
		(
			select rg.region as country, ev.medal	
			from events ev join regions rg
			on ev.noc = rg.NOC
		) as source_table
		pivot
		(
			count(Medal)
			for medal
			in([Gold],[Silver],[Bronze])
		) as pivot_table
		--order by [Gold] desc,[Silver] desc,[Bronze]desc


--15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games
create view Total_medals_by_AllCountries as
	select Games, country,[Gold],[Silver],[Bronze]
		from
		(
			select games, rg.region as country, ev.medal	
			from events ev join regions rg
			on ev.noc = rg.NOC
		) as source_table
		pivot
		(
			count(Medal)
			for medal
			in([Gold],[Silver],[Bronze])
		) as pivot_table
		--order by games, country,[Gold] desc,[Silver] desc,[Bronze]desc

--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
create view All_medals_by_countries as
with max_medal as
(
select Games,country,[Gold] as Max_Gold,[Silver] as Max_Silver,[Bronze] as Max_Bronze
		from
		(
			select games, rg.region as country, ev.medal	
			from events ev join regions rg
			on ev.noc = rg.NOC
		) as source_table
		pivot
		(
			count(Medal)
			for medal
			in([Gold],[Silver],[Bronze])
		) as pivot_table
)

select distinct games,
		concat(first_value(country) over(partition by games order by max_gold desc)
    			, ' - '
    			, first_value(max_gold) over(partition by games order by max_gold desc)) as Maximum_Gold,
		concat(first_value(country) over(partition by games order by max_silver desc)
				,' - '
				, first_value(max_silver) over(partition by games order by max_silver desc)) as Maximum_SIlver,
		concat(first_value(country) over(partition by games order by max_bronze desc)
				,' - '
				,first_value(max_bronze) over(partition by games order by max_bronze desc)) as Maximum_Bronze
from max_medal
--order by games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

create view most_medals_by_countries as
with country_medals as
(
	select games,country,[Gold],[Silver],[Bronze]
	from
		(
			select 
				ev.games, rg.region as country, ev.medal
			from
				events ev
				join
				regions rg
				on ev.NOC = rg.NOC
				where ev.medal <> 'NA'
		) as s_table
		pivot
		(
			count(medal)
			for medal
			in([Gold],[Silver],[Bronze])
		) as p_table
), 
total_medals as
(
	select ev.games,rg.region as country, count(1) as Total
	from 
		events ev
		join
		regions rg
		on ev.NOC = rg.NOC
		where ev.medal <> 'NA'
		group by games, rg.region
)

select	distinct cm.Games,
		concat(FIRST_VALUE(cm.country) over (partition by cm.games order by gold desc),
		' - ',
		FIRST_VALUE(Gold) over (partition by cm.games order by gold desc)
		) as Maximum_Gold,
		concat(FIRST_VALUE(cm.country) over (partition by cm.games order by Silver desc),
		' - ',
		FIRST_VALUE(Silver) over (partition by cm.games order by Silver desc)
		) as Maximum_Silver,
		concat(FIRST_VALUE(cm.country) over (partition by cm.games order by Bronze desc),
		' - ',
		FIRST_VALUE(Bronze) over (partition by cm.games order by Bronze desc)
		) as Maximum_Bronze,
		concat(first_value(tm.country) over (partition by tm.games order by tm.total desc),
		' - ',
		first_value(tm.total) over (partition by tm.games order by tm.total desc)) as Total_Medals
from
	country_medals cm
	join
	total_medals tm
	on cm.games = tm.games
	--order by cm.games


--18. Which countries have never won gold medal but have won silver/bronze medals?
create view no_GOld_medal_countries as
with no_gold as
(
	select *
	from
		(
		select 
			ev.games, rg.region, ev.medal
		from 
			events ev
			join 
			regions rg
			on ev.noc = rg.noc
		) as source_table
		pivot
		(
			count(medal)
			for medal
			in([Gold],[Silver],[Bronze])
		) as pivot_table
)

select games, region, gold,silver,bronze
from 
	no_gold
where gold = 0 and (silver > 0 or bronze > 0) 
--order by games, gold desc, silver desc , bronze desc ;