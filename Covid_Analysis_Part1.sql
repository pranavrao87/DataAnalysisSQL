
-- DEATHS TABLE
Select *
From PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Selecting data that will be used

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2


-- Total Cases vs Total Deaths (checking the death percentage from cases)
-- shows likelihood of dying if infected w/ covid in a certain country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%' -- Checking US stats for death percentage from cases
and continent is not null
order by 1,2


-- Looking at total cases vs pop
-- Shows what % of pop got covid
Select Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like 'United States' 
order by 1,2

-- Looking @ countries w/ highest infection rate compared to pop
Select Location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like 'United States' 
group by location, population
order by PercentPopulationInfected desc

-- Countries w/ highest death count compared to pop

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like 'United States' 
where continent is not null
group by location
order by TotalDeathCount desc



-- Trying to group by continent instead of location
-- Continents w/ highest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is null -- continent data in this dataset has a NULL location
group by location
order by TotalDeathCount desc



-- Global numbers	
-- Have to sum 'new_cases' to get the total global cases w/o counting repeats that come w/ using 'total_cases'
-- If using 'total_cases' would have to do something like SUM(MAX(total_cases)) 
-- to find the final # of total_cases and sum them up globally
Select date, SUM(new_cases) as GlobalCases, SUM(cast(new_deaths as int)) as GlobalDeaths, 
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1

-- Running total cases and deaths across globe
Select SUM(new_cases) as GlobalCases, SUM(cast(new_deaths as int)) as GlobalDeaths, 
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1

-- VACCINATIONS TABLE + DEATHS TABLE JOIN
-- first looking @ total pop vs vaccinations

-- sum new vacs and partition it by location so new locaiton = count restarts
-- Next order it by location and date to show the rolling count over time
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, 
	dea.date) as RollingVaccinationCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location	
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3


-- USE CTE To calculate % of pop vaccinated referencing RollingVaccinationCount and pop

with PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingVaccinationCount) -- Defining columns in CTE
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, 
	dea.date) as RollingVaccinationCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
-- Must execute w/ above definition of CTE
Select *, (RollingVaccinationCount/Population)*100 as RollingVaccinationPercentage
from PopvsVac
order by 2, 3



-- NOW WITH TEMP TABLE 

DROP Table if exists #PercentPopulationVaccinated -- Drop the temp table before creating it again to avoid running into errors when modifying
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingVaccinationCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, 
	dea.date) as RollingVaccinationCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingVaccinationCount/Population)*100 as RollingVaccinationPercentage
from #PercentPopulationVaccinated
order by 2, 3
 


-- Creating View to store data for later visualizations
Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, 
	dea.date) as RollingVaccinationCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

-- View is permanent and can be saved and accessed later
Select *
From PercentPopulationVaccinated