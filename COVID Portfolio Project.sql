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



-- This caluclates the COVID-19 contraction rate in Brazil over time
-- The contraction rate is: (total_cases / population) * 100

SELECT 
    country,                                       -- Country name (Brazil in this case)
    date,                                          -- date of the recorded data
    population,                                    -- population size
    total_cases,                                   -- cumulative COVID-19 cases as of that date

    -- calculate contraction rate
    (CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS ContractionRate
FROM 
    PortfolioProject..Covid_deaths
WHERE country = 'Brazil'                           -- filter for Brazil only
ORDER BY 
    1, 2;                                          -- sorts results by country and by chronological date



-- Query calculates the maximum number of COVID-19 cases (infection count)
-- and the corresponding % of population infected for each coutnry

SELECT 
    country, 
    population,
    MAX(total_cases) AS HighestInfectionCount,     -- highest total cases recorded
    MAX(CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..Covid_deaths

-- remove below comment to filter for specific country
-- WHERE country = 'Brazil'
GROUP BY country, population                       -- group by country and population
ORDER BY PercentPopulationInfected DESC;           -- sorts countries from highest to lowest percent infected



-- This calculates the total death count and death rate from COVID-19 from each continent, using the max values available in the dataset

SELECT 
    continent, 
    MAX(total_deaths) AS TotalDeathCount,          -- highest cumulative death count

    -- death rate = (total_deaths / population) * 100
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL                        -- filters out rows where continent is missing
GROUP BY continent                                 -- group by continent 
ORDER BY TotalDeathCount DESC;                     -- orders by highest death toll



-- This calculates the COVID-19 death count and death rate
-- for each location (where continent data is available)
SELECT 
    location, 
    population,
    MAX(total_deaths) AS TotalDeathCount,          -- Gets highest total_deaths value recorded for each location
                                                   -- death rate (total_deaths / population) * 100
    MAX(CAST(total_deaths AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationDied
FROM 
    PortfolioProject..CovidDeaths

-- optional filter: uncomment to pull specific country    
-- WHERE country = 'Brazil'

-- optional filter to only include rows where continent is known
WHERE continent IS NOT NULL
GROUP BY location, population                      
ORDER BY TotalDeathCount DESC;



-- This caclculates total new COVID-19 cases and deaths
-- and computes the overall death rate (new deaths / new cases * 100)
-- accross all records where a continent is specified 

SELECT SUM(new_cases), SUM(new_deaths), CAST(SUM(new_deaths) AS FLOAT)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%states%'
WHERE continent is not NULL
-- GROUP BY date
order by 1,2;


-- This query joins COVID deaths and vaccination data
-- then calculates a cumulative (rolling) vaccination total per country over time

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,

    -- Rolling total vaccinations per country over time
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
FROM PortfolioProject..CovidDeaths dea            -- 'dea' = deaths table (includes population and cases)
JOIN PortfolioProject..CovidVaccinations vac      -- 'vac' = vaccinations table (vacc data)
    ON dea.location = vac.location                -- joining on matching country
    and dea.date = vac.date                       -- and on matching date
WHERE dea.continent is not null                   -- filters out global/unassigned entries
ORDER BY 1,2,3                                    -- sorts by continent, then country, then date


-- This query uses a CTE to calculate cumulative vaccinations per country over time
-- final SELECT calculates the vaccination rate up to that date

WITH PopvsVacc (continent, location, date, population, new_vaccinations, RollingVaccTotal) as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,

    -- Calculates the cumulative total of new vaccinations over time for each country
    SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null                    -- exludes rows with NULL continent values (e.g., global totals, ships)
-- ORDER BY 2,3
)
SELECT * , (RollingVaccTotal/population)*100       -- provides the updated cumulative count of % population vaccinated
FROM PopvsVacc


    
-- This query creates a temporary table that tracks, for each location and date, 
-- the cumulative number of COVID-19 vaccinations administered (rolling total)
-- and then calculates the vaccination rate (% of population vaccinated) up to that date
    
DROP Table if exists #PercentPopulationVaccinated          -- This ensures that if the temporary table #PercentPopulationVaccinated exists from a previous run,
                                                                it gets deleted first, avoiding errors when creating it again.
    
    Create Table #PercentPopulationVaccinated              -- Create a temporary table to store vaccination info
(
Continent nvarchar(255),
location NVARCHAR(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccTotal numeric,
)

Insert into #PercentPopulationVaccinated                    -- insert data into temp table
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccTotal
--, (RollingVaccTotal)
FROM PortfolioProject..CovidDeaths dea                       -- selecting data from two tables (dea, vac) that contain death and population info
JOIN PortfolioProject..CovidVaccinations vac                 -- and vaccination data by location and date
    ON dea.location = vac.location                           -- two tables are joined on matching location and date so that data points are pulled 
    and dea.date = vac.date                                  -- from the same location and date in both datasets
WHERE dea.continent is not null                              -- filtering is applied to exlude rows with missing continent info
-- ORDER BY 2,3
                                                             -- Key column is RollingVaccTotal, which is calculated with the SUM
    
SELECT *, (RollingVaccTotal/population)*100                  -- select from the temp table and calculate the vaccination percentage
FROM #PercentPopulationVaccinated                            -- Query adds new computed column which is the percentage of the population vaccinated up to that date
                                                             -- PercentVaccinated = RollingVaccTotal / population   * 100


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


-- New working table that can be used

SELECT *
FROM PercentPopulationVaccinated
