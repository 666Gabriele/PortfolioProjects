Select*
from dbo.coviddeaths

--selecting data I am going to use

select location, date, total_cases, new_cases, total_deaths, Population
from portfolio_project..coviddeaths
where continent is not null
order by 1, 2

-- looking at total cases vs total deaths
--shows likelyhood of dying if you contract covid in your country

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from portfolio_project..coviddeaths
where location like '%Lithuania%'
order by 1,2


--likelihood of dying but with a lot of null
SELECT  date, location , CAST(total_deaths AS float) / CAST(total_cases AS FLOAT) * 100 AS Deathpercentage
from portfolio_project..coviddeaths
order by 1,2

--likelihood of dying without showing null
SELECT  date, location , CAST(total_deaths AS float) / CAST(total_cases AS FLOAT) * 100 AS Deathpercentage
from portfolio_project..coviddeaths
WHERE total_cases IS NOT NULL
  AND total_deaths IS NOT NULL
order by 1,2

--looking at the total cases vs Population
--shows what percentage of population has got covid

Select location, date, total_cases, Population, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS PercentPopulationInfected
from portfolio_project..coviddeaths
where location like '%Lithuania%'
order by 1,2

MAX((CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))) * 100 AS PercentPopulationInfected



--looking at countries with highest infection rate compared to population

SELECT 
    location,
    MAX(CONVERT(BIGINT, total_cases)) AS HighestInfectionCount,
    Population,
    FORMAT(MAX((CAST(total_deaths AS DECIMAL(18, 5)) / CAST(total_cases AS DECIMAL(18, 5))) * 100), '0.#####') AS PercentPopulationInfected
FROM portfolio_project..coviddeaths
where continent is not null
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC

--other way but it still shows unrealistic numbers
SELECT 
    location,
    MAX(CAST(total_cases as float)) AS HighestInfectionCount,
    Population,
    FORMAT(MAX((CAST(total_deaths AS DECIMAL(18, 5)) / CAST(total_cases AS DECIMAL(18, 5))) * 100), '0.#####') AS PercentPopulationInfected
FROM portfolio_project..coviddeaths
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC;

--
select location, Population, MAX(Convert(bigint,total_cases)) as HighestInfectionCount, 
MAX((CAST(total_deaths AS decimal(8,2)) / CAST(total_cases AS decimal(8,2))))*100 as PercentPopulationInfected
FROM portfolio_project..coviddeaths
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC
--
SELECT 
    location, population,
    cast(total_cases AS NVARCHAR(MAX)) as HighestInfectionCount
    CAST(total_deaths AS NVARCHAR(MAX)) AS DeathsDescription
FROM portfolio_project..coviddeaths
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC
 --
SELECT 
    location,
    CONVERT(NVARCHAR(9), MAX(total_cases)) AS HighestInfectionCount,
    CONVERT(NVARCHAR(9), Population) AS Population,
   (MAX((CAST(total_deaths AS DECIMAL(18, 5)) / CAST(total_cases AS DECIMAL(18, 5))) * 100)) AS PercentPopulationInfected
FROM portfolio_project..coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--showing countries with highest death count per population

select location, Max(cast(total_deaths as bigint)) as TotalDeathCount
from portfolio_project..coviddeaths
where continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--bringing things down by continent

select continent, Max(cast(total_deaths as bigint)) as TotalDeathCount
from portfolio_project..coviddeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- showing continents with highest death count per population

select continent, Max(cast(total_deaths as bigint)) as TotalDeathCount
from portfolio_project..coviddeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- global numbers

Select location, date, SUM(cast(new_cases as bigint),SUM(Cast(total_deaths as bigint))), SUM(Cast(total_deaths as bigint)/SUM(cast(new_cases as bigint) * 100 as GlobalDeathPercentage
from portfolio_project..coviddeaths
where continent is not null
group by date
order by 1,2

SELECT
    location,
    date,
    SUM(CAST(new_cases AS BIGINT)) AS total_cases,
    SUM(CAST(new_deaths AS BIGINT)) AS total_deaths,
	--FORMAT(SUM(CAST(new_deaths AS DECIMAL(18, 5)) / nullif(SUM(CAST(new_cases AS DECIMAL(18, 5))) * 100), '0.#####') AS GlobalDeathPercentage
    SUM(CAST(new_deaths AS BIGINT)) * 100.0 / NULLIF(SUM(CAST(new_cases AS BIGINT)), 0) AS GlobalDeathPercentage
FROM
    portfolio_project..coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY
    location,
    date
ORDER BY
    location,
    date;

-- looking at total population vs vaccinations
	--use CTE
with PopvsVac (Continent, Location, Date, Population, vac.new_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated,
	RollingPeopleVaccinated/population * 100
FROM
    Portfolio_Project..coviddeaths dea
JOIN
    Portfolio_Project..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date
)
select*, (RollingPeopleVaccinated/Population) *100
from PopvsVac

--other way of uing CTE because previous didn't work for me
WITH PopvsVac (Continent, Location, Date, Population, new_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM
        Portfolio_Project..coviddeaths dea
    JOIN
        Portfolio_Project..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM
    PopvsVac;

--temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population Numeric,
New_Vaccinations Numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
 SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM
        Portfolio_Project..coviddeaths dea
    JOIN
        Portfolio_Project..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
  -- WHERE dea.continent IS NOT NULL
SELECT
    *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM
    #PercentPopulationVaccinated


-- creating view to store data for visualizations (i could not use it becaude  SQl said temporary views not allowed)
create view  #PercentPopulationVaccinated as
SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM
        Portfolio_Project..coviddeaths dea
    JOIN
        Portfolio_Project..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

--creating a view (without hashtag sign)

CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM
    Portfolio_Project..coviddeaths dea
JOIN
    Portfolio_Project..covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL

select *
From PercentPopulationVaccinated