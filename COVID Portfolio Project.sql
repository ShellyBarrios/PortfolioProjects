
--All table data, including cases and deaths, ordered by location and date
--Excluding continent when NULL because continent shows in 'location' as country

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--All table data, including tests and vaccinations, ordered by location and date
--Excluding continent when NULL because continent shows in 'location' as country

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date


--Pulling only certain data from COvidDeaths table

SELECT	location, 
		date, 
		total_cases, 
		new_cases, 
		total_deaths, 
		population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Total deaths as a perdentage of total cases in United States by date
--Shows percentage of Covid-positive population who died

SELECT	location, 
		date, 
		total_cases, 
		total_deaths, 
		(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


--Total cases as a percentage of population in United States by date
==Shows percentage of overall population who contracted Covid

SELECT	location, 
		date, 
		population, 
		total_cases, 
		(total_cases/population)*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


--By country, total cases as a percentage of population ordered by highest percentage

SELECT	location, 
		population, 
		MAX(total_cases) AS HighestInfectionCount, 
		MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


--By country, total deaths as a percentage of population ordered by highest percentage

SELECT	location, 
		population, 
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount, 
		MAX(CAST(total_deaths AS int)/population)*100 AS PercentPopulationDeaths
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


--Total deaths by continent

SELECT	continent, 
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global total deaths as percentage of total cases by date

SELECT	date, 
		SUM(new_cases) AS total_cases, 
		SUM(CAST(new_deaths AS int)) AS total_deaths, 
		SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Rolling total of vaccinations by country and date
--Using table aliases and joining tables

SELECT	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--USE CTE
--Use RollingPeopleVaccinated number in calculation to determine PercentVaccinated

WITH PopvsVac (Contenent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT	*, 
		(RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM PopvsVac


--TEMP TABLE
--Use RollingPeopleVaccinated number in calculation to determine PercentVaccinated

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated


--Creating view to store data for later visualizations

USE PortfolioProject
GO
CREATE VIEW RollingPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
--ORDER BY 2,3