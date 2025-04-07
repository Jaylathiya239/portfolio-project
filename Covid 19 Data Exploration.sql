/*
Covid 19 Data Exploration
Skills used: Joins, CTE's, Temp Tables, windows Functions, Aggregate Functions,
Creating Views, Converting Data Types
*/

select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

-- Select Data that we are going to be starting with
select Location, date, total_cases, total_deaths,population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 
as DeathPercentage
from PortfolioProject..CovidDeaths
where location like 'india'
and continent is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
select Location, date, Population, total_cases, (total_cases/population) * 100 
as PercentPopulationInfected
from Portfolioproject..CovidDeaths
where location like 'india'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
select Location,Population, MAX(total_cases) HighestInfectionCount,
MAX((total_cases/population)) * 100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where Location like 'india'
group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per population
select Location, Population, MAX(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT
--Showing continents with the highest death per population
select continent, MAX(cast(Total_death as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by TotalDeathCount desc

--GLOBAL NUMBERS
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(New_Cases) * 100 DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Total  Population vs Vaccinations
--Shows Percentage of population that has recived at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) over 
(partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using CTE to perform Calculation on Partition by in previous query
with PopvsVac(Continent, Location, Date, Population, New_Vaccinations,
RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.Location 
order by dea.location, dea.Date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/Population) * 100
from PopvsVac

--Using Temp Table to perform Calculation on partition by in previous query
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location, dea.Date),
(RollingPeopleVaccinated/population) * 100
as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

select *, (RollingPeopleVaccinaated/Population) * 100
from #PercentPopulationVaccinated

--Creating View to store data for later visulizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.Location
order by dea.location, dea.Date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
