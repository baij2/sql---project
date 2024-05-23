select * 
from PortfolioProject..[CovidDeaths.csv]
where continent is not null
order by 3,4


--select * 
--from PortfolioProject..[CovidVaccinations.csv]
--order by 3,4

--Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..[CovidDeaths.csv]
where continent is not null
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country	
select location, date, total_cases, total_deaths, (convert(float, total_deaths)/nullif(convert(float, total_cases), 0))*100 AS DeathPercentage
from PortfolioProject..[CovidDeaths.csv]
where location like '%%states%'
and continent is not null
order by 1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid
select location, date, total_cases, population, (convert(float, total_cases)/nullif(convert(float, population), 0))*100 
AS PercentPopulationInfected
from PortfolioProject..[CovidDeaths.csv]
where location like '%%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
select location, population, max(total_cases) as HighestInfectionRate,
(convert(float, max(total_cases))/nullif(convert(float, population), 0))*100 AS PercentPopulationInfected
from PortfolioProject..[CovidDeaths.csv]
--where location like '%%states%'
group by location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[CovidDeaths.csv]
--where location like '%%states%'
where NOT location = 'Europe' and NOT location = 'World' and NOT location = 'North America' 
and NOT location = 'European Union' and NOT location = 'South America'
group by location
order by TotalDeathCount desc
	
-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[CovidDeaths.csv]
--where location like '%%states%'
--where NOT location = 'Europe' and NOT location = 'World' and NOT location = 'North America' 
--and NOT location = 'European Union' and NOT location = 'South America'
where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT SUM(CAST(new_cases AS int)) AS total_cases, 
       SUM(CAST(new_deaths AS int)) AS total_deaths,
       (SUM(CAST(new_deaths AS int)) * 100.0) / NULLIF(SUM(CAST(new_cases AS int)), 0) AS DeathPercentage
FROM PortfolioProject..[CovidDeaths.csv]
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

--Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..[CovidDeaths.csv] dea
join PortfolioProject..[CovidVaccinations.csv] vac
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3


-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..[CovidDeaths.csv] dea
join PortfolioProject..[CovidVaccinations.csv] vac
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS 
(
    SELECT dea.continent, 
           dea.location, 
           dea.date, 
           CAST(dea.population AS bigint) AS population, 
           CAST(vac.new_vaccinations AS bigint) AS new_vaccinations,
   SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
   AS RollingPeopleVaccinated
    FROM PortfolioProject..[CovidDeaths.csv] dea
    JOIN PortfolioProject..[CovidVaccinations.csv] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
       (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;

-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Contient nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
           dea.location, 
           dea.date, 
           CAST(dea.population AS bigint) AS population, 
           CAST(vac.new_vaccinations AS bigint) AS new_vaccinations,
   SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
   AS RollingPeopleVaccinated
    FROM PortfolioProject..[CovidDeaths.csv] dea
    JOIN PortfolioProject..[CovidVaccinations.csv] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
  --  WHERE dea.continent IS NOT NULL

	SELECT *, 
       (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated
ORDER BY Location, Date;

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, 
           dea.location, 
           dea.date, 
           CAST(dea.population AS bigint) AS population, 
           CAST(vac.new_vaccinations AS bigint) AS new_vaccinations,
   SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
   AS RollingPeopleVaccinated
    FROM PortfolioProject..[CovidDeaths.csv] dea
    JOIN PortfolioProject..[CovidVaccinations.csv] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
		where dea.continent is not null