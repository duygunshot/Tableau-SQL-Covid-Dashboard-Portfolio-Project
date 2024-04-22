SELECT * FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
AND continent != ''
ORDER BY 3,4;

--SELECT * FROM [PortfolioProject].[dbo].[CovidVaccinations]
--ORDER BY 3,4;

--Select Datas That Are Going To Be Used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
ORDER BY 1,2;


--Looking At Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, 
(CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS death_percentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE location LIKE '%states%' AND continent != ''
ORDER BY 1;


--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, 
(CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT,population),0)) * 100 AS PercentPopulationInfected
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
--WHERE location LIKE '%states%'
ORDER BY 1;


--Looking at the Country with the highest infection rate compares to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX(CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT,population),0) * 100) AS PercentPopulationInfected
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


--Showing countries with Highest Death Count per Population
SELECT location, MAX(CONVERT(FLOAT,total_deaths)) AS TotalDeathCount 
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Breaks things down by continent
SELECT location, MAX(CONVERT(FLOAT,total_deaths)) AS TotalDeathCount 
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Showing continents with the highest death count per population
SELECT continent, MAX(CONVERT(FLOAT,total_deaths)) AS HighestDeathCountPerPopulation 
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
GROUP BY continent
ORDER BY HighestDeathCountPerPopulation DESC;


--GLOBAL NUMBERS
SELECT CONVERT(DATE,date) AS Date, SUM(CONVERT(FLOAT,new_cases)) AS TotalNewCases, SUM(CONVERT(FLOAT,new_deaths)) AS TotalDeathCases,
SUM(CONVERT(FLOAT,new_deaths))/SUM(NULLIF(CONVERT(FLOAT,new_cases),0)) *100 AS DeathPercentage
--total_cases, total_deaths, (CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS death_percentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent != ''
GROUP BY Date
ORDER BY 1;


--Looks at Total Population vs Vaccinations
SELECT dea.continent, dea.location, CONVERT(DATE,dea.date) AS Date, dea.population, vac.new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CONVERT(DATE,dea.date)) AS RollingPeopleVaccianted
FROM [PortfolioProject].[dbo].[CovidDeaths] AS dea
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 1,2,3;


--USE CTE
WITH PopvsVac(Continent, Location,Date, Population,NewVaccinations, RollingPeopleVaccianted)
AS (
SELECT dea.continent, dea.location, CONVERT(DATE,dea.date) AS Date, dea.population, vac.new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CONVERT(DATE,dea.date)) AS RollingPeopleVaccianted
FROM [PortfolioProject].[dbo].[CovidDeaths] AS dea
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != ''
--ORDER BY 1,2,3
)
SELECT *, (RollingPeopleVaccianted/NULLIF(Population,0))*100 
FROM PopvsVac
ORDER BY 1,2,3;


--USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATE,
Population INT,
NewVaccinations INT,
RollingPeopleVaccianted FLOAT)

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, CONVERT(DATE,dea.date) AS Date, dea.population, vac.new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CONVERT(DATE,dea.date)) AS RollingPeopleVaccianted
FROM [PortfolioProject].[dbo].[CovidDeaths] AS dea
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != ''


SELECT *, (RollingPeopleVaccianted/NULLIF(Population,0))*100 
FROM #PercentPopulationVaccinated
ORDER BY 1,2,3;

--Creating view to store datas for later visualization
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, CONVERT(DATE,dea.date) AS Date, dea.population, vac.new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CONVERT(DATE,dea.date)) AS RollingPeopleVaccianted
FROM [PortfolioProject].[dbo].[CovidDeaths] AS dea
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != '';

SELECT * FROM PercentPopulationVaccinated;