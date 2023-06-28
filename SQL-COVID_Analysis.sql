--1.Dataset Overview
SELECT *
FROM PortfolioProjects..CovidDeaths
ORDER BY location, date

SELECT *
FROM PortfolioProjects..CovidVaccinations
ORDER BY location, date

--2.Some Data Discovery
---2.1Death Rate in Total Cases (Canada)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM PortfolioProjects..CovidDeaths
WHERE location like 'Canada'
ORDER BY location, date;

---2.2Average Prevalence Rate in Each Country by Month
SELECT location, 
	YEAR(date) AS year, 
	MONTH(date) AS month, 
	AVG(total_cases) AS avg_cases, 
	AVG(population) AS avg_population, 
	AVG(total_cases/population) *100 AS prevalence_rate
FROM PortfolioProjects..CovidDeaths
GROUP BY location, YEAR(date), MONTH(date)
ORDER BY location, YEAR(date), MONTH(date);

---2.3 10 Highest Prevalence Rate Countries During Whole COVID Period
SELECT TOP (10) location,
	population,
	MAX((total_cases/population) * 100) AS max_prevalence_rate
FROM PortfolioProjects..CovidDeaths
GROUP BY location, population
ORDER BY MAX((total_cases/population) * 100) DESC

---2.4 Top 10 Total Death Country (Exclude Continental and Country Union)
SELECT TOP(10) location, MAX(total_deaths) AS max_deaths
FROM PortfolioProjects..CovidDeaths
GROUP BY location
HAVING location NOT IN ('World','High income','Upper middle income','Europe','Asia','North America','South America',
	'Lower middle income', 'European Union','Africa')
ORDER BY MAX(total_deaths) DESC

---- !!issue of the original data
SELECT continent, location
FROM PortfolioProjects..CovidDeaths
WHERE location = 'Asia'

SELECT continent, location
FROM PortfolioProjects..CovidDeaths
WHERE continent = 'Asia'
-----When the continent is NULL, the location shows the whole continent agrregate. When we need to explore data in
-----countries, we need to exclude data with cotinent IS NULL.

---2.5 Redo 2.4 with new discovery
SELECT TOP(10) location, MAX(total_deaths) AS max_deaths
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MAX(total_deaths) DESC --We got exact same table to 2.4

---2.6 Simply Break Up by Continent (CTE Used)
WITH sub AS (SELECT location,continent, MAX(total_deaths) AS country_deaths
		FROM PortfolioProjects..CovidDeaths
		WHERE continent IS NOT NULL
		GROUP BY location, continent)
SELECT  continent, SUM(country_deaths) AS continent_deaths
FROM sub
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY SUM(country_deaths) DESC

--3 Join in the Vaccine Data and Get Some Information
---3.1 Maximum Vaccine Rate of Each Country in 2023
WITH vac_now AS(SELECT v.location, v.date, v.people_vaccinated, v.people_fully_vaccinated, pop.population
				FROM PortfolioProjects..CovidVaccinations v
				LEFT JOIN (SELECT population, location, date
							FROM PortfolioProjects..CovidDeaths) AS pop
				ON pop.date = v.date AND pop.location = v.location
				WHERE YEAR(v.date) = 2023 AND v.continent IS NOT NULL ) 
SELECT location, 
	AVG(population) AS avg_pop, 
	MAX(people_vaccinated/population) * 100 AS max_vac_rate, 
	MAX(people_fully_vaccinated/population) * 100 AS max_fully_vac_rate
FROM vac_now
GROUP BY location
ORDER BY max_vac_rate DESC, max_fully_vac_rate DESC
----Comment: First 3 contries have vaccine rate more than 100%, which most likely caused by  foreign tourist.