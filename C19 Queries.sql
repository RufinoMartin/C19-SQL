/*

Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, 
Aggregate Functions, Creating Views, Converting Data Types

*/


-- Creation of synonyms of both tables for swifter manipulation --

CREATE SYNONYM Deaths FOR [Covid Analysis].[dbo].[CovidDeaths]
CREATE SYNONYM Vaccinations FOR [Covid Analysis].[dbo].[CovidVaccinations]

--- FIRST DATASET: CASES & DEATHS ---

select *
FROM Deaths
order by 3,4;

select *
from Vaccinations
order by 1,2;

-- 1. Total Cases vs Total Deaths  --> tableau

--    > Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Deaths
Where location like '%arg%' --insert any state--
and continent is not null 
order by 1,2;


-- 1.2 Net Death % --> tableau candidate

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- 1.2 Total Death Count --> Tableau

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc



-- 2. Total Cases vs Population

--    > Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Deaths
Where location like '%arg%'
order by 1,2;

-- 3. Countries with Highest Infection Rate compared to Population --> Tableau

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Deaths
--Where location like '%arg%'
Group by Location, Population
order by PercentPopulationInfected desc;

-- 3.1 Infected Population + Date --> Tableau

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Deaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc

-- 4. Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%arg%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;

-- 5. Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%arg%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- 6. Global Net Numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Deaths
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
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;

-- 7.1 Without new vaccinations --> Tableau Candidate

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3



-- 8. Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
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


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated;





-- Creating Views to store data for later visualizations --


--> 1. At least One Dose: Population vs Vaccination

Create VIEW Percent_Population_Vaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null; 
 
--> 2 . Shows likelihood of dying if you contract covid in your country

Create VIEW Mortality_Likelihood AS
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Deaths
Where location like '%arg%' --insert any state--
and continent is not null 
order by 1,2;

--> 3. Countries with Highest Infection Rate compared to Population

Create VIEW Top_Infected_Countries AS
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Deaths
--Where location like '%arg%'
Group by Location, Population
order by PercentPopulationInfected desc;

--> 4. Countries with Highest Death Count per Population

Create VIEW National_Mortality AS
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%arg%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;

--> 5. Contintents with the highest death count per population

Create VIEW Continental_Mortality AS
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Deaths
--Where location like '%arg%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

