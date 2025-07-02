-- View the complete table for initial exploration
SELECT *
FROM PortfolioProject..Covid_vaccinations
order by 3,4


-- View selected relevant columns from Covid_deaths table

SELECT country, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..Covid_deaths
order by 1,2 -- country, then date


-- Death rate for each country and date
-- This query calculates the percentage of deaths among total COVID-19 cases for each country on a given date.
-- Find Total Cases vs Total Deaths (Show the death rate over time)

SELECT 
    country,                 -- country name
    date,                    -- observation date
    total_cases,             -- cumulative number of covid-19 cases up to this date
    total_deaths,            -- cumulative number of covid-19 deaths up to this date

    -- Death rate: (total_deaths / total_cases) * 100
    -- NULLIF prevents division by zero by returning NULL if total_cases is 0
    
    (CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..Covid_deaths
ORDER BY 
    1, 2;                    -- sort results alphabetically by country and then chronologically within each country



-- This summarizes COVID-19 stats by continent
-- Shows maximum reported values for population, total cases, and total deaths per continent,
-- and calculates the percentage of the population that has died due to COVID-19 (death rate)

SELECT 
    continent,                                     -- continent name
    MAX(population) AS population,                 -- highest recorded population for that continent 
    MAX(total_cases) AS TotalCases,                -- highest cumulative case count recorded 
    MAX(total_deaths) AS TotalDeathCount,          -- highest cumulative death count recorded 

    -- Death rate: (total_deaths / population) * 100
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..Covid_deaths                 
WHERE 
    continent IS NOT NULL                          -- filters out rows where continent is missing
GROUP BY 
    continent                                      -- groups the results by continent
ORDER BY 
    TotalDeathCount DESC;                          -- orders results from highest to lowest total death count


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
