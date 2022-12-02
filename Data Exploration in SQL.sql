SELECT * FROM indicators;
SELECT * FROM population;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Number of rows in the datasets

SELECT 
    COUNT(*)
FROM
    indicators;-- 640
    
SELECT 
    COUNT(*)
FROM
    population; -- 640

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Datasets for Jharkhand and Bihar

SELECT 
    *
FROM
    indicators
WHERE
    state IN ('Jharkhand' , 'Bihard');
    
 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
-- Population of India

SELECT 
    SUM(population) as total_population
FROM
    population; -- 1,210,854,977

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Average Growth

SELECT 
    AVG(growth) AS avg_growth
FROM
    indicators; -- 19.25%
    
-- Average Growth by State

SELECT 
    State, ROUND(AVG(growth), 2) AS 'avg_growth(%)'
FROM
    indicators
GROUP BY State;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Average Sex ratio

SELECT 
    ROUND(AVG(Sex_Ratio), 0) AS avg_sex_ratio
FROM
    indicators; -- 945
    
-- Average Sex Ratio by State

SELECT 
    State, ROUND(AVG(Sex_Ratio/1000), 0) AS avg_sex_ratio
FROM
    indicators
GROUP BY State
ORDER BY avg_sex_ratio DESC; -- Highest is Kerala @ 1080

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Average Literacy Rate

SELECT 
    State, ROUND(AVG(Literacy), 0) AS avg_literacy_rate
FROM
    indicators
GROUP BY State
HAVING avg_literacy_rate > 90
ORDER BY avg_literacy_rate DESC; -- Only 2 states [Kerala @ 94 & Lakshadweep @ 92]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Top 3 states showing highest growth ratio

SELECT 
    State, ROUND(AVG(growth), 2) AS avg_growth_percent
FROM
    indicators
GROUP BY State
ORDER BY avg_growth_percent DESC
LIMIT 3; -- Nagaland(82.28%), Dadra and Nagar Haveli(55.88%), Daman and Diu(42.74%)

-- Bottom 3 states showing lowest sex ratio

SELECT 
    State, ROUND(AVG(Sex_Ratio/1000), 0) AS avg_sex_ratio
FROM
    indicators
GROUP BY State
ORDER BY avg_sex_ratio ASC
LIMIT 3; -- Dadra and Nagar Haveli(774), Dadra and Nagar Haveli(783), Chandigarh(818)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Top and Bottom 3 states in literacy ratio

CREATE TABLE topstates(
state VARCHAR(255),
topstates FLOAT);

INSERT INTO topstates
SELECT 
    State, ROUND(AVG(literacy), 0) AS avg_literacy_ratio
FROM
    indicators
GROUP BY State
ORDER BY avg_literacy_ratio DESC
LIMIT 3;

SELECT * FROM topstates;

CREATE TABLE bottomstates(
state VARCHAR(255),
topstates FLOAT);

INSERT INTO bottomstates
SELECT 
    State, ROUND(AVG(literacy), 0) AS avg_literacy_ratio
FROM
    indicators
GROUP BY State
ORDER BY avg_literacy_ratio ASC
LIMIT 3;

SELECT * FROM bottomstates;

-- Unioning topstates table and bottomstates table

SELECT 
    *
FROM
    topstates 
UNION SELECT 
    *
FROM
    bottomstates;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- States starting with letter a

SELECT 
    DISTINCT state
FROM
    indicators
WHERE
    state LIKE 'a%';
    
-- States starting with letter a or letter b

SELECT DISTINCT
    state
FROM
    indicators
WHERE
    state LIKE 'a%' OR state LIKE 'b%'
ORDER BY state ASC;

-- States starting with letter a and ending with letter m

SELECT DISTINCT
    state
FROM
    indicators
WHERE
    state LIKE 'a%' AND state LIKE '%m'
ORDER BY state ASC;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Joining both indicators and population tables

ALTER TABLE indicators RENAME COLUMN ï»¿District TO District;
ALTER TABLE population RENAME COLUMN ï»¿District TO District;
SELECT * from indicators;
SELECT * from population;

SELECT 
    a.District, a.State, a.Sex_Ratio/1000, b.Population
FROM
    indicators a
        INNER JOIN
    population b ON a.District = b.District;


-- Finding total number of males and females (using Simultaneous Equation) through join

-- female/males = Sex_Ratio .......1
-- females + males = Population .......2
-- Hence, Population - males = Sex_Ratio * males
-- males(Sex_Ratio + 1) = Population
-- males = Population/(Sex_Ratio + 1)
-- females = Population - Population/(Sex_Ratio + 1)
-- females = Population * (1 - 1/(Sex_Ratio + 1))

SELECT 
    d.state,
    SUM(d.males) AS total_males,
    SUM(d.females) AS total_females
FROM
    (SELECT 
        c.District,
            c.State,
            ROUND(c.Population / (c.Sex_Ratio / 1000 + 1), 0) AS males,
            ROUND(c.Population * (1 - 1 / (c.Sex_Ratio / 1000 + 1)), 0) AS females
    FROM
        (SELECT 
        a.District, a.State, a.Sex_Ratio, b.Population
    FROM
        indicators a
    INNER JOIN population b ON a.District = b.District) c) d
GROUP BY d.state;


-- Total literate and illiterate people through join

-- total literate people/population = literacy_ratio
-- total literate people = literacy_ratio * population
-- Hence, total illiterate people = (1 - literacy_ratio) * population

SELECT 
    d.state,
    SUM(literate_people) AS total_literate_people,
    SUM(illiterate_people) AS total_illiterate_people
FROM
    (SELECT 
        c.district,
            c.state,
            ROUND(c.literacy_ratio * c.Population, 0) AS literate_people,
            ROUND((1 - literacy_ratio) * c.Population, 0) AS illiterate_people
    FROM
        (SELECT 
        a.District,
            a.State,
            a.literacy / 100 AS literacy_ratio,
            a.Sex_Ratio,
            b.Population
    FROM
        indicators a
    INNER JOIN population b ON a.District = b.District) c) d
GROUP BY d.state
ORDER BY d.State ASC;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total Population from previous census and current census

-- previous_census + (growth_percent * previous_census) = population
-- previous_census (1 + growth_percent) = population
-- previous_census = population / (1 + growth_percent)

SELECT 
    SUM(total_previous_census_population),
    SUM(total_current_census_population)
FROM
    (SELECT 
        d.state,
            SUM(d.previous_census_population) AS total_previous_census_population,
            SUM(d.current_census_population) AS total_current_census_population
    FROM
        (SELECT 
        c.District,
            c.State,
            ROUND(c.population / (1 + c.growth_percent), 0) AS previous_census_population,
            c.population AS current_census_population
    FROM
        (SELECT 
        a.District,
            a.State,
            a.growth / 100 AS growth_percent,
            b.Population
    FROM
        indicators a
    INNER JOIN population b ON a.District = b.District) c) d
    GROUP BY d.state
    ORDER BY d.state ASC) e;
    