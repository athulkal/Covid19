/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select _location, __date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select _location, _date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where _location like '%United Kingdom%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select _location, _date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where _location like '%United Kingdom%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select _location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where _location like '%states%'
Group by _location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select _location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where _location like '%states%'
Where continent is not null 
Group by _location
order by TotalDeathCount desc



-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
--Group By _date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea._location, dea._date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea._location Order by dea._location, dea._Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea._location = vac._location
	and dea._date = vac._date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, _location, _Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea._location, dea._date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea._location Order by dea._location, dea._Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea._location = vac._location
	and dea._date = vac._date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
_location nvarchar(255),
_Date _datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea._location, dea._date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea._location Order by dea._location, dea._Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea._location = vac._location
	and dea._date = vac._date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea._location, dea._date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea._location Order by dea._location, dea._Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea._location = vac._location
	and dea._date = vac._date
where dea.continent is not null 



-- Total percentage vaccinated around the world

WITH PopvsVac (continent, _location, _date, population, new_vaccinations, cumulative_vaccines) AS
(
    SELECT
        dea.continent,
        dea._location,
        dea._date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea._location ORDER BY dea._date) AS cumulative_vaccines
    FROM
        coviddeaths AS dea
    JOIN
        covidvaccinations AS vac
    ON
        dea._location = vac._location
        AND dea._date = vac._date
    WHERE
        dea.continent IS NOT NULL
)
SELECT
    _location,
    MAX(cumulative_vaccines) AS total_vaccines,
    (MAX(cumulative_vaccines::numeric) / MAX(population::numeric)) * 100.0 AS percentage_vaccinated
FROM
    PopvsVac
GROUP BY
    _location
HAVING
    MAX(cumulative_vaccines) IS NOT NULL
ORDER BY
    _location;
