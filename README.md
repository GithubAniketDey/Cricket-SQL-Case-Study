# Cricket-SQL-Case-Study
This case study focuses on analyzing cricket match data using SQL. It is designed to challenge my SQL skills, covering schema design, data insertion, and complex queries, including the use of joins, subqueries, window functions, and aggregate functions.
I will work with the following tables:
1.	Players: Information about players.
2.	Matches: Details of cricket matches.
3.	Performance: Player-specific performance in matches.
4.	Teams: Team information.
________________________________________
Table Schemas
1. Players Table
CREATE TABLE Players (
    PlayerID INT PRIMARY KEY,
    PlayerName VARCHAR(100),
    TeamName VARCHAR(100),
    Role VARCHAR(50), -- e.g., Batsman, Bowler, All-Rounder, Wicket-Keeper
    DebutYear INT
);
2. Matches Table
CREATE TABLE Matches (
    MatchID INT PRIMARY KEY,
    MatchDate DATE,
    Location VARCHAR(100),
    Team1 VARCHAR(100),
    Team2 VARCHAR(100),
    Winner VARCHAR(100)
);
3. Performance Table
CREATE TABLE Performance (
    MatchID INT,
    PlayerID INT,
    RunsScored INT,
    WicketsTaken INT,
    Catches INT,
    Stumpings INT,
    NotOut BOOLEAN,
    RunOuts INT,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID)
);
4. Teams Table
CREATE TABLE Teams (
    TeamName VARCHAR(100) PRIMARY KEY,
    Coach VARCHAR(100),
    Captain VARCHAR(100)
);
________________________________________
Sample Data
Insert the following data into the tables:
Players Table
INSERT INTO Players VALUES
(1, 'Virat Kohli', 'India', 'Batsman', 2008),
(2, 'Steve Smith', 'Australia', 'Batsman', 2010),
(3, 'Mitchell Starc', 'Australia', 'Bowler', 2010),
(4, 'MS Dhoni', 'India', 'Wicket-Keeper', 2004),
(5, 'Ben Stokes', 'England', 'All-Rounder', 2011);
Matches Table
INSERT INTO Matches VALUES
(1, '2023-03-01', 'Mumbai', 'India', 'Australia', 'India'),
(2, '2023-03-05', 'Sydney', 'Australia', 'England', 'England');
Performance Table
INSERT INTO Performance VALUES
(1, 1, 82, 0, 1, 0, FALSE, 0),
(1, 4, 5, 0, 0, 1, TRUE, 0),
(2, 3, 15, 4, 0, 0, FALSE, 0);
Teams Table
INSERT INTO Teams VALUES
('India', 'Rahul Dravid', 'Rohit Sharma'),
('Australia', 'Andrew McDonald', 'Pat Cummins');
________________________________________
Evaluation Criteria
1.	Correctness of queries.
2.	Efficiency of SQL logic.
3.	Proper use of advanced SQL techniques like window functions and joins.
4.	Output formatting and clarity.
