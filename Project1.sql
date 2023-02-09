-- Overall Data for USA (excluding other emission sources)--
SELECT Country, [Year], Total, Per_Capita, Coal, Oil, Gas, 
FROM [Emissions By Country]
WHERE Country like '%USA'
ORDER BY 1,2

--How much does Coal, Oil, & Natural Gas each make up of the total CO2 emissions in USA?--
SELECT Country, [Year], Total, Per_Capita, Coal, Oil, Gas, (Coal/Total) * 100 AS CoalPercentage, (Oil/Total) * 100 AS OilPercentage, 
(Gas/Total) * 100 AS GasPercentage
FROM [Emissions By Country]
WHERE Country like '%USA'
ORDER BY 1,2

--How much does Cement, Flaring, & Other each make up of the total CO2 emissions in USA?--
SELECT Country, [Year], Total, Per_Capita, Cement, Flaring, Other, (Cement/Total) * 100 AS CementPercentage, 
(Flaring/Total) * 100 AS FlaringPercentage, (Other/Total) * 100 AS OtherPercentage
FROM [Emissions By Country]
WHERE Country like '%USA'
ORDER BY 1,2

--Top 20 Countries with Highest Per Capita CO2 emissions--
SELECT Country, MAX(Per_Capita)
FROM [Emissions By Country]
GROUP BY Country
ORDER BY 2 DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY

--Top 20 Countries with Highest Total CO2 Emissions--
SELECT Country, MAX(Total)
FROM [Emissions By Country]
WHERE country is not NULL
GROUP BY Country
ORDER BY 2 DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY

--Top 20 Countries with Highest Total CO2 Emissions in 2020--
SELECT Country, year, MAX(Total)
FROM [Emissions By Country]
WHERE country is not NULL AND year= 2020
GROUP BY Country, [Year]
ORDER BY 3 DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY

--Total CO2 emissions for all countries in 2000 to 2020--
SELECT Year, SUM(Total)
FROM [Emissions By Country]
GROUP BY Year
ORDER BY Year

--Average Per Capita over the years? Using WINDOWS Function--
SELECT Country, Year, Total, Coal, Oil, Gas, Per_Capita,
AVG(Per_Capita) OVER (PARTITION BY Country ORDER BY Year) AS RunningTotalPerCapita
FROM [Emissions By Country]

--Running Sum of Total Emissions over the years? Using WINDOWS Function--
SELECT Country, Year, Coal, Oil, Gas, Per_Capita, Total,
SUM(Total) OVER (PARTITION BY Country ORDER BY Year) AS RunningTotal
FROM [Emissions By Country]

--Change in Per Capita emissions each year in the USA using WINDOWS Function--
SELECT Country, Year, Total, Per_Capita, Per_Capita - LAG(Per_Capita, 1, Per_Capita) OVER (PARTITION BY country ORDER BY Year) AS ChangeInPer_Capita
FROM [Emissions By Country]
WHERE Country = 'USA'
ORDER BY 2

--Yearly Average temp for each country over the years--
SELECT tem.country, tem.year, AVG(AvgTemperature) as YearlyAvgTemp
FROM Project1..[City AVG Temperatures] tem
Group BY tem.country, tem.[Year]
Order BY 1,2

--Join + Window Function (does not group by year as needed so we use CTE in next query)--
SELECT emi.country, emi.year, (AVG(tem.AvgTemperature) OVER (Partition By emi.year ORDER BY emi.country, emi.year )) as YearlyTotalTemp
FROM Project1..[Emissions By Country] emi
LEFT JOIN Project1..[City AVG Temperatures] tem
ON emi.Country = tem.Country AND
emi.[Year] = tem.[Year]
WHERE AvgTemperature != -99
Group BY emi.country, emi.[Year], tem.AvgTemperature
Order BY 1,2


--Using a CTE for Average temp per year per country--
WITH EmissionsvsTemp
AS

(SELECT emi.country, emi.year, (AVG(tem.AvgTemperature) OVER (Partition By emi.year ORDER BY emi.country, emi.year )) as YearlyAvgTemp
FROM Project1..[Emissions By Country] emi
LEFT JOIN Project1..[City AVG Temperatures] tem
ON emi.Country = tem.Country AND
emi.[Year] = tem.[Year]
Group BY emi.country, emi.[Year], tem.AvgTemperature)

SELECT *
FROM EmissionsvsTemp
Group by Country, [Year], [YearlyAvgTemp]
ORDER BY Country, [Year]


--LAG window function to determine change in Yearly Avg Temp + compare to Total yearly emissions--
WITH EmissionsvsTemp
AS

(SELECT emi.country, emi.year, emi.Total, (AVG(tem.AvgTemperature) OVER (Partition By emi.year ORDER BY emi.country, emi.year )) as YearlyAvgTemp
FROM Project1..[Emissions By Country] emi
LEFT JOIN Project1..[City AVG Temperatures] tem
ON emi.Country = tem.Country AND
emi.[Year] = tem.[Year]
Group BY emi.country, emi.[Year], tem.AvgTemperature, total)

SELECT *, YearlyAvgTemp - LAG(YearlyAvgTemp, 1, YearlyAvgTemp) OVER (PARTITION BY Country ORDER BY YEAR) AS ChangeInTemp
FROM EmissionsvsTemp
Group by Country, [Year], [YearlyAvgTemp], Total
ORDER BY Country, [Year]


--Experimenting with a Temp Table for Average temp per year per country--
DROP Table if exists #EmissionsvsTemp
CREATE TABLE #EmissionsvsTemp
(Country nvarchar(255),
Year datetime, 
YearlyAvgTemp float)

Insert into #EmissionsvsTemp
SELECT emi.country, emi.year, (AVG(tem.AvgTemperature) OVER (Partition By emi.year ORDER BY emi.country, emi.year )) as YearlyAvgTemp
FROM Project1..[Emissions By Country] emi
LEFT JOIN Project1..[City AVG Temperatures] tem
ON emi.Country = tem.Country AND
emi.[Year] = tem.[Year]
Group BY emi.country, emi.[Year], tem.AvgTemperature
ORDER BY 2 DESC 

SELECT * FROM #EmissionsvsTemp
GROUP BY Year, Country, YearlyAvgTemp
ORDER BY Country, [Year]
