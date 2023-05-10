
COVID-19 Data Exploration 

Skills used: Joins, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Exporting Data


SELECT *
FROM `portfolio-project-385613.COVID.CovidVaccinations`
ORDER BY 3,4 --


-- Select Data That I Am Going To Be Using

SELECT Location, date, total_cases, new_cases,total_deaths, population
FROM `portfolio-project-385613.COVID.CovidDeaths`
Order By 1, 2


-- Looking At Total Cases vs Total Deaths


SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
FROM `portfolio-project-385613.COVID.CovidDeaths`
Order By 1, 2


-- Looking At Total Cases vs Total Deaths
-- Shows Likelihood Of Dying If You Caught COVID In The United Kingdom

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
FROM `portfolio-project-385613.COVID.CovidDeaths`
WHERE location like '%Kingdom%'
AND continent IS NOT null
Order By 1, 2


-- Looking At Total Cases vs Population
-- Shows The Percentage Of The Population Who Got COVID

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PopulationInfectedPercentage
FROM `portfolio-project-385613.COVID.CovidDeaths`
WHERE location like '%Kingdom%'
Order By 1, 2

-- Countries With Highest Infection Rate Compared To Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PopulationInfectedPercentage
FROM `portfolio-project-385613.COVID.CovidDeaths`
-- WHERE location like '%Kingdom%'
Group By Location, population
Order By PopulationInfectedPercentage desc

-- Countries With Highest Death Count Per Population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM `portfolio-project-385613.COVID.CovidDeaths`
-- WHERE location like '%Kingdom%'
WHERE continent IS NOT null
Group By Location, population
Order By TotalDeathCount desc

-- Break Result Down By Continent & Continents With Highest Death Count Per Population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM `portfolio-project-385613.COVID.CovidDeaths`
-- WHERE location like '%Kingdom%'
WHERE continent IS NOT null
Group By continent
Order By TotalDeathCount desc

-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(NULLIF(new_deaths,0) as int))/SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
FROM `portfolio-project-385613.COVID.CovidDeaths`
--WHERE location like '%Kingdom%'
WHERE continent IS NOT null
--GROUP BY date 
Order By 1,2

-- Working With COVID Vaccinations Table & Joining With COVID Deaths Table

SELECT *
FROM `portfolio-project-385613.COVID.CovidVaccinations`

FROM `portfolio-project-385613.COVID.CovidDeaths` dea
JOIN `portfolio-project-385613.COVID.CovidVaccinations` vac
ON dea.location = vac.location
AND dea.date = vac.date 

-- Looking At Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population)*100
FROM `portfolio-project-385613.COVID.CovidDeaths` dea
JOIN `portfolio-project-385613.COVID.CovidVaccinations` vac
ON dea.location = vac.location
AND dea.date = vac.date 
WHERE dea.continent IS NOT null
Order By 2,3

-- Create Temp Table to perform Calculation on Partition By in previous query

CREATE TEMP TABLE PercentPopulationVaccinated
(
  Continent STRING,
  Location STRING,
  Date DATE,
  Population INTEGER, 
  New_vaccinations INTEGER,
  RollingPeopleVaccinated INTEGER
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population)*100
FROM `portfolio-project-385613.COVID.CovidDeaths` dea
JOIN `portfolio-project-385613.COVID.CovidVaccinations` vac
ON dea.location = vac.location
AND dea.date = vac.date 
WHERE dea.continent IS NOT null;
--Order By 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PercentPopulationVaccinated

-- Saved Temp Table As A View & Named Dataset & Temp Table.

-- Created A Bucket, bigquery_exports_project. Exported Data To Be Used/Uploaded For Later Visualisations

EXPORT DATA OPTIONS (
    uri='gs://bigquery_exports_project/populationvaccinated*.csv',
    format= 'CSV',
    overwrite=true,
    header=true,
    field_delimiter=','
) AS

SELECT *
FROM `portfolio-project-385613._script9465b09586dcb82b9c644f30748020f73dff821f.PercentPopulationVaccinated` 

