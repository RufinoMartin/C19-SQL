/*

Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, 
Aggregate Functions, Creating Views, Converting Data Types

*/


--- FIRST DATASET: CASES & DEATHS ---

select *
from CovidDeaths$
order by 3,4;

select *
from CovidVaccinations$
order by 1,2;

-- 1. Total Cases vs Total Deaths

--    > Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths$
Where location like '%arg%' --insert any state--
and continent is not null 
order by 1,2;

-- 2. Total Cases vs Population

--    > Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths$
Where location like '%arg%'
order by 1,2;

-- 3. Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths$
--Where location like '%arg%'
Group by Location, Population
order by PercentPopulationInfected desc;

-- 4. Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths$
--Where location like '%arg%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;

-- 5. Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths$
--Where location like '%arg%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- 6. Global Net Numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths$
--Where location like '%arg%'
where continent is not null 
--Group By date
order by 1,2;


--- SECOND DATASET: VACCINES ---

-- 7. Total Population vs Vaccinations
--    > Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 -->TO USE LATER
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;

-- 8. Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as Outcome
From PopvsVac;

-- 9. Using Temp Table to perform Calculation on Partition with previous query


--    > We create an AdHoc table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);


--     > We insert our previous query into that table.


Insert into #PercentPopulationVaccinated AS PopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated;


-- Creating Views to store data for later visualizations --


--> 1. At least One Dose: Population vs Vaccination

Create VIEW PercentPopulationVaccinated 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null; 
 

--> 2 . Shows likelihood of dying if you contract covid in your country

Create VIEW as Mortality_Likelihood
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths$
Where location like '%arg%' --insert any state--
and continent is not null 
order by 1,2;

--> 3. Countries with Highest Infection Rate compared to Population

Create VIEW as TopInfectedCountries
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths$
--Where location like '%arg%'
Group by Location, Population
order by PercentPopulationInfected desc;

--> 4. Countries with Highest Death Count per Population

Create VIEW AS NationalMortality
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths$
--Where location like '%arg%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;

--> 5. Contintents with the highest death count per population

Create VIEW AS ContinentalMortality
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths$
--Where location like '%arg%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;