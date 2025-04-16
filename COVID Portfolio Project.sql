SELECT *
FROM PortfolioProject..Covid_vaccinations
order by 3,4


-- Select Data that is going to be used

SELECT country, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..Covid_deaths
order by 1,2


-- Find Total Cases vs Total Deaths (Show the death rate over time)

SELECT 
    country, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..Covid_deaths
ORDER BY 
    1, 2;

-- This is the Death rate compared across continents

SELECT 
    continent, 
    MAX(population) AS population,
    MAX(total_cases) AS TotalCases,
    MAX(total_deaths) AS TotalDeathCount, 
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..Covid_deaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount DESC;


-- Now lets examine total cases vs population in Brazil
-- This shows the contraction rate over time

SELECT 
    country, 
    date, 
    population,
    total_cases, 
    (CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS ContractionRate
FROM 
    PortfolioProject..Covid_deaths
WHERE country = 'Brazil'
ORDER BY 
    1, 2;


-- Next, let's examine the countries with the highest infection rate relative to population

SELECT 
    country, 
    population,
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..Covid_deaths
-- WHERE country = 'Brazil'
GROUP BY country, population
ORDER BY PercentPopulationInfected DESC;


-- This is a continent-specific analysis for highest death count

SELECT 
    continent, 
    MAX(total_deaths) AS TotalDeathCount, 
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Next, let's look at countries with the highest death count per
SELECT 
    location, 
    population,
    MAX(total_deaths) AS TotalDeathCount, 
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..CovidDeaths
-- WHERE country = 'Brazil'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC;

-- Global Numbers 

SELECT SUM(new_cases), SUM(new_deaths), CAST(SUM(new_deaths) AS FLOAT)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%states%'
WHERE continent is not NULL
-- GROUP BY date
order by 1,2;

-- Total world population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
, (RollingVaccTotal)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3


-- USE CTE

WITH PopvsVacc (continent, location, date, population, new_vaccinations, RollingVaccTotal)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
--, (RollingVaccTotal)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2,3
)
SELECT * , (RollingVaccTotal/population)*100
FROM PopvsVacc


--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location NVARCHAR(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccTotal numeric,
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
--, (RollingVaccTotal)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2,3

SELECT *, (RollingVaccTotal/population)*100
FROM #PercentPopulationVaccinated


-- Create a View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
--, (RollingVaccTotal)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2,3


-- Now we have a new working table within this view that we can use

SELECT *
FROM PercentPopulationVaccinated
