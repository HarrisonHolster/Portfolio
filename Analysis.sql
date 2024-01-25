--- Testing
SELECT *
FROM
	CovidProject.dbo.CovidDeaths

SELECT *
FROM
	CovidProject.dbo.CovidVaccinations

-- Looking at the timeline of cases and deaths in each country

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM CovidProject.dbo.CovidDeaths
ORDER BY 1, 2

-- Calculating covid fatality rate in the US (total deaths/total cases in a country)

SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS covid_fatality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

-- Calculating the prevalence of covid in the US (total cases/country's total population)

SELECT
	location,
	date,
	total_cases,
	population,
	(CAST(total_cases AS FLOAT) / population)*100 AS prevalence_rate
FROM CovidProject.dbo.CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

-- Calculating the peak incidence in each country (total cases/country's total population)
-- Finding out which country had the highest infection rate compared to its population

SELECT
	location,
	MAX(total_cases) AS peak_incidence,
	population,
	MAX(CAST(total_cases AS FLOAT)/population)*100 AS infection_rate
FROM CovidProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY infection_rate DESC

-- Finding out which country had the highest fatalities

SELECT
	location,
	MAX(total_deaths) AS total_fatalities
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_fatalities DESC

-- Countries with the highest mortality rate (total deaths/total population)

SELECT
	location,
	(MAX(CAST(total_deaths AS FLOAT)) / (MAX(CAST(population AS FLOAT)))*100) AS mortality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY mortality_rate DESC

-- Total fatalities by continent
SELECT
	location,
	MAX(total_deaths) AS total_fatalities
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_fatalities DESC

-- Continent with the highest mortality rate (total deaths/total population)

SELECT
	location,
	(MAX(CAST(total_deaths AS FLOAT)) / (MAX(CAST(population AS FLOAT)))*100) AS mortality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY mortality_rate DESC

-- Calculating global fatality_rate each day
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))*100 AS fatality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Calculating global fatality rate 
SELECT
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))*100 AS fatality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL


-- Calculating total vaccinated population each day
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) 
		OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccinated_population
FROM
	CovidProject.dbo.CovidDeaths d
JOIN CovidProject.dbo.CovidVaccinations vac
	ON vac.location = d.location
	AND vac.date = d.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3

-- Calculating percentage of population that is vaccinated

DROP TABLE IF EXISTS #VaccinatedPopulationPercentage
CREATE TABLE #VaccinatedPopulationPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime2,
population numeric,
new_vaccinations numeric,
vaccinated_population numeric
)

INSERT INTO #VaccinatedPopulationPercentage
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations)
		OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccinated_population
FROM
	CovidProject.dbo.CovidDeaths d
JOIN CovidProject.dbo.CovidVaccinations vac
	ON vac.location = d.location
	AND d.date = vac.date

SELECT *,
	(vaccinated_population/population)*100 AS vaccinated_population_percentage
FROM #VaccinatedPopulationPercentage
ORDER BY location, date ASC

--- Creating views for visualization
--Percentage of country's population that is vaccinated view

CREATE VIEW VaccinatedPopulationPercentage AS
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations)
		OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccinated_population
FROM
	CovidProject.dbo.CovidDeaths d
JOIN CovidProject.dbo.CovidVaccinations vac
	ON vac.location = d.location
	AND d.date = vac.date
	WHERE d.continent IS NOT NULL

-- Covid fatality rate in the US view

CREATE VIEW us_fatality_rate AS
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS covid_fatality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE location = 'United States'

-- Covid prevalence rate in the US view

CREATE VIEW us_prevalence_rate AS
SELECT
	location,
	date,
	total_cases,
	population,
	(CAST(total_cases AS FLOAT) / population)*100 AS prevalence_rate
FROM CovidProject.dbo.CovidDeaths
WHERE location = 'United States'

-- Covid fatality rate in the us view

CREATE VIEW us_fatality_rate AS
SELECT
	location,
	MAX(total_deaths) AS total_fatalities
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

-- Covid mortality rate in the us view

CREATE VIEW us_mortality_rate AS
SELECT
	location,
	(MAX(CAST(total_deaths AS FLOAT)) / (MAX(CAST(population AS FLOAT)))*100) AS mortality_rate
FROM CovidProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
