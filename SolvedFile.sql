CREATE TABLE Players (
    PlayerID INT PRIMARY KEY,
    PlayerName VARCHAR(100),
    TeamName VARCHAR(100),
    Role VARCHAR(50), -- e.g., Batsman, Bowler, All-Rounder, Wicket-Keeper
    DebutYear INT
);
CREATE TABLE Matches (
    MatchID INT PRIMARY KEY,
    MatchDate DATE,
    Location VARCHAR(100),
    Team1 VARCHAR(100),
    Team2 VARCHAR(100),
    Winner VARCHAR(100)
);
CREATE TABLE Performance (
    MatchID INT,
    PlayerID INT,
    RunsScored INT,
    WicketsTaken INT,
    Catches INT,
    Stumpings INT,
    NotOut bit,--[I have used bit to store boolean values cause ssms don't have datatype as bool or boolean ]
    RunOuts INT,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID)
);
CREATE TABLE Teams (
    TeamName VARCHAR(100) PRIMARY KEY,
    Coach VARCHAR(100),
    Captain VARCHAR(100)
);

INSERT INTO Players VALUES
(1, 'Virat Kohli', 'India', 'Batsman', 2008),
(2, 'Steve Smith', 'Australia', 'Batsman', 2010),
(3, 'Mitchell Starc', 'Australia', 'Bowler', 2010),
(4, 'MS Dhoni', 'India', 'Wicket-Keeper', 2004),
(5, 'Ben Stokes', 'England', 'All-Rounder', 2011);

INSERT INTO Matches VALUES
(1, '2023-03-01', 'Mumbai', 'India', 'Australia', 'India'),
(2, '2023-03-05', 'Sydney', 'Australia', 'England', 'England');


INSERT INTO Performance VALUES
(1, 1, 82, 0, 1, 0, 'FALSE', 0),--[here 'false' is 0 in bit type and 0 is representing false]
(1, 4, 5, 0, 0, 1, 'TRUE', 0),--[here 'True' is 1 in bit type and 1 is representing True]
(2, 3, 15, 4, 0, 0, 'FALSE', 0);

INSERT INTO Teams VALUES
('India', 'Rahul Dravid', 'Rohit Sharma'),
('Australia', 'Andrew McDonald', 'Pat Cummins');

create procedure all_tbles as
begin
select * from [dbo].[Performance]
select * from [dbo].[Players]
select * from [dbo].[Teams]
select * from [dbo].[Matches]
end

exec all_tbles

--1. Identify the player with the best batting average 
--(total runs scored divided by the number of matches played) across all matches.
select ply.PlayerName,(SUM(per.RunsScored)/COUNT(per.MatchID)) as batting_average
from Players ply join Performance per on per.PlayerID=ply.PlayerID
group by ply.PlayerName order by batting_average desc;


--2. Find the team with the highest win percentage in matches played across all locations.
select ply.TeamName,
(count(case when m.Winner=ply.TeamName then 1 END)/COUNT(per.MatchID))*100 as  win_percentage
from Players ply join Performance per on per.PlayerID=ply.PlayerID
join Matches m on per.MatchID=m.MatchID
group by ply.TeamName order by win_percentage desc

--Explanation:
--COUNT(case when m.Winner=ply.TeamName then 1 END): This counts the number of matches where the team is the winner.
--COUNT(per.MatchID): This counts the total number of matches each team has played
--WinPercentage: The win percentage is computed by dividing the number of wins by the total number of matches played and multiplying by 100 to convert it into a percentage.
--ORDER BY win_percentage DESC: Orders the results by win percentage in descending order so the team with the highest win percentage comes first.
--TOP 1: Limits the result to only the team with the highest win percentage.

--3. Identify the player who contributed the highest percentage of their 
--team's total runs in any single match.
with teamsruns as(
select per.MatchID,ply.TeamName,SUM(per.RunsScored)as teams_total_runs
from Performance per join Players ply on ply.PlayerID=per.PlayerID
group by ply.TeamName,per.MatchID),
playercontri as(
select per.MatchID,ply.TeamName,t.teams_total_runs,ply.PlayerName,
per.RunsScored,(CAST(per.RunsScored as float)/ t.teams_total_runs)*100 as contribution_of_player
from Players ply join Performance per on per.PlayerID=ply.PlayerID
join teamsruns t on t.TeamName=ply.TeamName and t.MatchID=per.MatchID)

select Top 1 * from playercontri order by contribution_of_player desc;
--Explanation:
--To identify the player who contributed the highest percentage of their team's total runs in any single match, 
--we need to calculate the percentage contribution of each player in each match. This percentage is determined by the following formula:
--Player Contribution Percentage=Player’s Runs Scored/Team’s Total Runs in the Match×100
--Steps to achieve this:
--Calculate the total runs scored by each team in each match.
--Calculate the contribution percentage for each player.
--Identify the player with the highest contribution percentage.

--4. Determine the most consistent player, defined as the one with the smallest 
--standard deviation of runs scored across matches.

select Top 1 per.PlayerID,ply.PlayerName,STDEV(per.RunsScored) as standard_deviation_runs
from Players ply join Performance per on per.PlayerID=ply.PlayerID
group by ply.PlayerName,per.PlayerID order by standard_deviation_runs


--Explanation:
--STDEV(RunsScored): The STDEV function calculates the standard deviation of the RunsScored for each player across all matches they have participated in.
--GROUP BY PlayerID, PlayerName: We group by PlayerID and PlayerName to calculate the standard deviation for each player individually.
--ORDER BY standard_deviation_runs: We order the results by the standard deviation in ascending order, so the player with the smallest standard deviation (most consistent) is at the top.
--TOP 1: Limits the result to only the player with the smallest standard deviation.

--5. Find all matches where the combined total of runs scored, wickets taken, and catches exceeded 500.
select m.MatchID,m.MatchDate,m.Team1,m.Team2,
(SUM(per.RunsScored)+SUM(per.WicketsTaken)+SUM(per.Catches))[combined total of runs,wickets,catches]
from Matches m join Performance per on per.MatchID=m.MatchID
group by m.MatchID,m.MatchDate,m.Team1,m.Team2
having (SUM(per.RunsScored)+SUM(per.WicketsTaken)+SUM(per.Catches))>500

--Explanation:
--SUM(per.RunsScored) + SUM(per.WicketsTaken) + SUM(per.Catches): This sums up the total runs, wickets, and catches for each match.
--GROUP BY: We group by MatchID, MatchDate, Team1, and Team2 to calculate the totals for each match.
--HAVING: The HAVING clause is used to filter the results and include only those matches where the combined total of runs, wickets, and catches exceeds 500

--6. Identify the player who has won the most "Player of the Match" awards 
--(highest runs scored or wickets taken in a match).
with playerofmatch as(
select per.MatchID,ply.TeamName,ply.PlayerName,
RANK()over(PARTITION by per.[MatchID] order by per.[RunsScored] desc) as runsrank,
RANK()over(PARTITION by per.[MatchID] order by per.[WicketsTaken] desc) as wicketsrank
from Players ply join Performance per on ply.PlayerID=per.PlayerID)

select Top 1 TeamName,PlayerName,COUNT(*) as Player_of_the_Match_count
from playerofmatch
where runsrank=1 or wicketsrank=1
group by TeamName,PlayerName
order by Player_of_the_Match_count desc

--Explanation:
--PlayerOfTheMatch CTE:
--We use two RANK() window functions:
--RANK()over(PARTITION by per.[MatchID] order by per.[RunsScored] desc) as runsrank: Ranks players by their runs scored within each match, so the player with the highest runs will have a rank of 1.
--RANK()over(PARTITION by per.[MatchID] order by per.[WicketsTaken] desc) as wicketsrank: Ranks players by their wickets taken within each match, so the player with the highest wickets will have a rank of 1.
--The PARTITION BY clause ensures that the ranking is done within each match (MatchID), and the ORDER BY ensures that the highest runs or wickets come first.
--Main Query:
--We filter the results to include players who have a rank of 1 in either the runs or wickets category, i.e., the player with the highest runs or highest wickets in each match.
--We use COUNT(*) to count how many times each player was ranked first (i.e., how many "Player of the Match" awards they won).
--TOP 1: Returns the player with the most "Player of the Match" awards.
--ORDER BY Player_of_the_Match_count DESC: Ensures that the player with the most "Player of the Match" awards appears first.

--7. Determine the team that has the most diverse player roles in their squad.
select Top 1 ply.TeamName,COUNT( Distinct ply.Role) as most_diverse_player_roles
from Players ply group by ply.TeamName
order by most_diverse_player_roles desc

--8. Identify matches where the runs scored by both teams were unequal and sort them by the 
--smallest difference in total runs between the two teams.
with teamruns as(
select m.MatchID,
SUM(case when ply.teamname=m.Team1 then per.RunsScored else 0 end) as team1runs,
SUM(case when ply.teamname=m.Team2 then per.RunsScored else 0 end) as team2runs
from Matches m join Performance per on per.MatchID=m.MatchID
join players ply on ply.PlayerID=per.PlayerID
group by m.MatchID
)
select Top 1 MatchID,team1runs,team2runs,(team1runs-team2runs) as diff
from teamruns where team1runs<>team2runs
order by diff asc
--Explanation:
--teamruns CTE:
--We calculate the total runs for Team1 and Team2 in each match using a CASE statement to sum the runs for each team separately based on their team name.
--The GROUP BY clause groups by m.MatchID to calculate the total runs for each team in each match.
--Main Query:
--The main query joins the TeamRuns CTE with the Matches table to retrieve match details (MatchID, Team1, Team2).
--The (team1runs-team2runs) calculates the difference in runs between the two teams in each match.
--WHERE team1runs<>team2runs filters to include only matches where the total runs for the two teams are not equal.
--ORDER BY diff asc sorts the matches by the smallest difference in runs scored.

--9.Find players who contributed (batted, bowled, or fielded) in every match that their team participated in.
SELECT 
    p.PlayerName,p.TeamName
FROM Players p JOIN Performance per ON p.PlayerID = per.PlayerID
JOIN Matches m ON per.MatchID = m.MatchID
WHERE 
    (p.TeamName = m.Team1 OR p.TeamName = m.Team2)
GROUP BY  p.PlayerName, p.TeamName HAVING COUNT(DISTINCT per.MatchID) = (
        SELECT COUNT(*) 
        FROM Matches WHERE Team1 = p.TeamName OR Team2 = p.TeamName);
--Explanation:
--Join Tables:
--Join Players, Performance, and Matches to connect players to the matches they participated in.
--Use p.TeamName = m.Team1 OR p.TeamName = m.Team2 to filter matches for the player's team.
--Group and Count:
--Group by player (PlayerID, PlayerName, and TeamName).
--Use COUNT(DISTINCT perf.MatchID) to calculate how many matches the player participated in.
--HAVING Clause:
--Compare the number of matches the player participated in with the total number of matches their team played.
--Use a subquery to count the matches (COUNT(*)) where the team participated as either Team1 or Team2.

--10. Identify the match with the closest margin of victory, based on runs scored by both teams.
with teamruns as(
select m.MatchID, sum(case when ply.TeamName=m.Team1 then per.RunsScored else 0 end) as team1runs,
sum(case when ply.TeamName=m.Team2 then per.RunsScored else 0 end) as team2runs
from Matches m join Performance per on per.MatchID=m.MatchID
join Players ply on ply.PlayerID=per.PlayerID
group by m.MatchID)
select Top 1 MatchID,(team1runs-team2runs) as diffrence
from teamruns order by diffrence;

--Explanation:
--TeamRuns CTE:
--Calculates the total runs scored by Team1 and Team2 in each match using a CASE statement to sum runs for each team separately.
--Groups by MatchID, Team1, and Team2.
--Main Query:
--Calculates the difference between the runs scored by Team1 and Team2 using (Team1Runs - Team2Runs).
--Sorts the matches by the smallest difference in total runs (Difference ).
--Uses TOP 1 to select the match with the closest margin of victory.

--11. Calculate the total runs scored by each team across all matches.
select per.MatchID,ply.TeamName,sum(per.RunsScored)[total runs scored]
from Performance per join Players ply on ply.PlayerID=per.PlayerID
group by per.MatchID,ply.TeamName

--12. List matches where the total wickets taken by the winning team exceeded 2.
select m.MatchID,m.MatchDate,m.Winner,SUM(per.WicketsTaken) as total_wickets_taken
from Matches m 
join Performance per on per.MatchID=m.MatchID
join Players ply on ply.PlayerID=per.PlayerID
where ply.TeamName=m.Winner
group by m.MatchID,m.Winner,m.MatchDate having SUM(per.WicketsTaken)>2;

--Explanation:
--Join Tables:
--Matches is joined with Performance to get player performance in each match.
--Players is joined to link the player's TeamName to ensure we are only considering the winning team's players.
--Filter Winning Team:
--The WHERE  ply.TeamName=m.Winner ensures only the winning team's contributions are counted.
--Group By Match:
--The query groups by m.MatchID,m.Winner,m.MatchDate to calculate totals for each match.
--HAVING Clause:
--The HAVING SUM(per.WicketsTaken) > 2 filters for matches where the total wickets taken by the winning team exceeded 2.

--13. Retrieve the top 5 matches with the highest individual scores by any player.
select top 5 per.MatchID,ply.PlayerName,per.RunsScored as highestruns
from Players ply join Performance per on per.PlayerID=ply.PlayerID
order by highestruns desc

--14. Identify all bowlers who have taken at least 5 wickets across all matches.
select ply.PlayerName,SUM(per.WicketsTaken) as wickets_taken
from Players ply join Performance per on per.PlayerID=ply.PlayerID
group by ply.PlayerName having SUM(per.WicketsTaken)>=5;

--15. Find the total number of catches taken by players from the team that won each match.
with winningteam as(
select m.MatchID,m.MatchDate,m.Winner,per.Catches
from Matches m join Performance per on per.MatchID=m.MatchID
join Players ply on ply.PlayerID=per.PlayerID
where ply.TeamName=m.Winner)

select MatchID,MatchDate,Winner,SUM(Catches) as total_catches
from winningteam
group by MatchID,MatchDate,Winner

--CTE (winningteam):
--This part selects the relevant data: MatchID,MatchDate, the Winner of the match, the Catches taken by each player, and player details (PlayerID, PlayerName).
--It filters players whose team matches the Winner of the match.
--Main Query:
--After defining the CTE, the main query calculates the total number of catches for the winning team in each match by summing the Catches for each MatchID,MatchDate and Winner.

--16.  Identify the player with the highest combined impact score in all matches.
--The impact score is calculated as:
--Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
--Only include players who participated in at least 3 matches.
with playerimpact as(
select ply.PlayerName,count(Distinct per.MatchID) as matches_played,
sum((per.RunsScored*1.5)+(per.WicketsTaken*25)+(per.Catches*10)+(per.Stumpings*15)+(per.RunOuts*10)) as impactscore
from Players ply join Performance per on per.PlayerID=ply.PlayerID
group by ply.PlayerName having count(Distinct per.MatchID)>=3
)
select Top 1 * from playerimpact order by impactscore desc

--Explanation:
--CTE (playerimpact):
--Calculates the total impact score based on the formula and filters players with at least 3 matches.
--Main Query:
--Selects the player with the highest impactscore using ORDER BY impactscore DESC and limits the result to 1 using TOP 1.

--17.Find the match where the winning team had the narrowest margin of 
--victory based on total runs scored by both teams.
--If multiple matches have the same margin, list all of them.
with teamsruns as(
select m.MatchID,m.Team1,m.Team2,sum(case when ply.TeamName=m.Team1 then per.RunsScored else 0 end) runsbyteam1
,sum(case when ply.TeamName=m.Team2 then per.RunsScored else 0 end) runsbyteam2
from Matches m join Performance per on per.MatchID=m.MatchID
join Players ply on ply.PlayerID=per.PlayerID
group by m.MatchID,m.Team1,m.Team2)

select  MatchID,Team1,Team2,abs(runsbyteam1-runsbyteam2) as difference
from teamsruns where abs(runsbyteam1-runsbyteam2)=
(select min(abs(runsbyteam1-runsbyteam2)) from teamsruns)

--Explanation:
--CTE (teamsruns): Calculates the total runs for Team1 and Team2 using SUM and CASE WHEN.
--Margin Calculation: The ABS(Team1Runs - Team2Runs) calculates the margin of victory.
--Filter for Narrowest Margin: The WHERE clause filters for the smallest margin.

--18.List all players who have outperformed their teammates in terms of total runs scored in 
--more than half the matches they played.This requires finding matches where a player scored 
--the most runs among their teammates and calculating the percentage.
WITH MaxRunsPerMatch AS (
SELECT perf.MatchID,perf.PlayerID,MAX(perf.RunsScored) AS MaxRuns
FROM Performance perf
GROUP BY perf.MatchID, perf.PlayerID
),
PlayerMatchStats AS (
SELECT perf.PlayerID,COUNT(DISTINCT perf.MatchID) AS TotalMatches,
SUM(CASE WHEN perf.RunsScored = m.MaxRuns THEN 1 ELSE 0 END) AS MatchesWithMaxRuns
FROM Performance perf JOIN 
MaxRunsPerMatch m ON perf.MatchID = m.MatchID AND perf.PlayerID = m.PlayerID
GROUP BY perf.PlayerID
)
SELECT p.PlayerID, p.PlayerName
FROM Players p JOIN PlayerMatchStats pms ON p.PlayerID = pms.PlayerID
WHERE pms.MatchesWithMaxRuns > pms.TotalMatches / 2;

--Explanation:
--CTE MatchMaxRuns:
--For each match, we find the maximum runs scored by any player (MAX(perf.RunsScored)).
--CTE PlayerMatchCount:
--This counts the total number of matches each player has participated in (COUNT(DISTINCT perf.MatchID)).
--It also counts the number of matches where the player scored the most runs (SUM(CASE WHEN perf.RunsScored = m.MaxRuns THEN 1 ELSE 0 END)).
--Main Query:
--The JOIN combines the Players table with the PlayerMatchCount to get player details.
--The WHERE clause filters players who have outperformed their teammates in more than half of the matches they played (pmc.MatchesWithMaxRuns > pmc.TotalMatches / 2).

--19.Rank players by their average impact per match, considering only those who played at least 
--three matches.The impact is calculated as:
--Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
--Players with the same average impact should share the same rank.
with plyaerimpact as(
select count(Distinct per.MatchID) as total_matches,ply.PlayerName,
sum((per.RunsScored*1.5)+(per.WicketsTaken*25)+(per.Catches*10)+(per.Stumpings*15)+(per.RunOuts*10))as totalimpact
from Performance per join Players ply on ply.PlayerID=per.PlayerID
group by ply.PlayerName having COUNT(Distinct per.MatchID)>=3)
select PlayerName,(totalimpact/total_matches)as avg_impact,
RANK()over(order by (totalimpact/total_matches) desc)[Ranking]
from plyaerimpact

--Explanation:
--CTE PlayerImpact:
--Calculates the total impact for each player based on the provided formula.
--Filters out players who have played fewer than 3 matches with the HAVING COUNT(Distinct per.MatchID)>=3.
--Main Query:
--Computes the average impact per match (avg_impact) as totalimpact/total_matches.
--Uses the RANK() function to assign ranks based on the avg_impact in descending order. 
--Players with the same average impact will have the same rank using rank().

--20.Identify the top 3 matches with the highest cumulative total runs scored by both teams.
--Rank the matches based on total runs using window functions. 
--If multiple matches have the same total runs, they should share the same rank.
with teamsruns as(
select m.MatchID,m.Team1,m.Team2,
SUM(case when ply.TeamName=m.Team1 then per.RunsScored else 0 end) as team1runs,
SUM(case when ply.TeamName=m.Team2 then per.RunsScored else 0 end) as team2runs
from Matches m join Performance per on per.MatchID=m.MatchID join Players ply on ply.PlayerID=per.PlayerID
group by m.MatchID,m.Team1,m.Team2)

select * from
(select MatchID,Team1,Team2,(team1runs+team2runs) as totalruns,
RANK()over(order by (team1runs+team2runs) desc) as Ranking
from teamsruns) as tbl where Ranking<=3 

--Explanation:
--CTE MatchTotalRuns:
--This calculates the total runs scored by each team in a match:
--SUM(case when ply.TeamName=m.Team1 then per.RunsScored else 0 end) calculates the total runs for Team1.
--SUM(case when ply.TeamName=m.Team2 then per.RunsScored else 0 end) calculates the total runs for Team2.
--The GROUP BY ensures we get one row per match for both teams.
--Main Query:
--The main query selects the MatchID, Team1, Team2, and the cumulative total runs (Team1Runs + Team2Runs).
--The RANK() window function ranks the matches based on total runs in descending order. Matches with the same total runs will share the same rank.
--Filter for Top 3 Matches:
--The WHERE clause filters to return only the top 3 matches.

--21.For each player, calculate their running cumulative impact score across all 
--matches they’ve played, ordered by match date.
--Include only players who have played in at least 3 matches.
with playerimpact as(
select per.MatchID,per.PlayerID,m.MatchDate,
((per.RunsScored*1.5)+(per.WicketsTaken*25)+(per.Catches*10)+(per.Stumpings*15)+(per.RunOuts*10))as impact
from Performance per join Matches m on m.MatchID=per.MatchID),

playermatches as(
select PlayerID
from playerimpact
group by PlayerID having COUNT(Distinct MatchID)>=3)

select pi.PlayerID,ply.PlayerName,pi.MatchDate,
SUM(pi.impact)over(partition by pi.playerid order by pi.MatchDate)as CumulativeImpact
from playerimpact pi join Players ply on ply.PlayerID=pi.PlayerID
join playermatches pm on pm.PlayerID=ply.PlayerID


--Explanation:
--CTE PlayerImpact: Calculates the impact for each player in each match.
--CTE PlayerMatches: Filters players who have played in at least 3 matches.
--Main Query:
--Uses SUM() with PARTITION BY to calculate the cumulative impact for each player, ordered by match date.
--Joins Players to get player names.