-- Employee Attrition: exploratory SQL analysis (SQL Server)
-- Run create_and_load_table.sql first.
-- "attrition rate" = share of employees with Attrition = 'Yes'.

use HRAnalytics;
go

------------------------------------------------------------------
-- 1. Overall summary
------------------------------------------------------------------
select
	count(*) as [total employees],
	sum(case when Attrition = 'Yes' then 1 else 0 end) as [employees who left],
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %],
	cast(avg(1.0 * Age) as decimal(5, 1)) as [avg age],
	cast(avg(1.0 * MonthlyIncome) as decimal(10, 0)) as [avg monthly income],
	cast(avg(1.0 * YearsAtCompany) as decimal(5, 1)) as [avg years at company]
from dbo.Employees;
go

------------------------------------------------------------------
-- 2. Attrition by overtime
------------------------------------------------------------------
select
	OverTime,
	count(*) as employees,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as [left],
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by OverTime
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 3. Attrition by department
------------------------------------------------------------------
select
	Department,
	count(*) as employees,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as [left],
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by Department
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 4. Attrition by job role (with average pay)
------------------------------------------------------------------
select
	JobRole,
	count(*) as employees,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as [left],
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %],
	cast(avg(1.0 * MonthlyIncome) as decimal(10, 0)) as [avg monthly income],
	cast(avg(1.0 * YearsAtCompany) as decimal(5, 1)) as [avg years at company]
from dbo.Employees
group by JobRole
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 5. Attrition by marital status
------------------------------------------------------------------
select
	MaritalStatus,
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by MaritalStatus
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 6. Attrition by business travel
------------------------------------------------------------------
select
	BusinessTravel,
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by BusinessTravel
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 7. Attrition by job satisfaction (1 = low ... 4 = very high)
------------------------------------------------------------------
select
	JobSatisfaction,
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by JobSatisfaction
order by JobSatisfaction;
go

------------------------------------------------------------------
-- 8. Attrition by age band
------------------------------------------------------------------
select
	case
		when Age <= 25 then '1. 18-25'
		when Age <= 35 then '2. 26-35'
		when Age <= 45 then '3. 36-45'
		when Age <= 55 then '4. 46-55'
		else '5. 56+'
	end as [age band],
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by
	case
		when Age <= 25 then '1. 18-25'
		when Age <= 35 then '2. 26-35'
		when Age <= 45 then '3. 36-45'
		when Age <= 55 then '4. 46-55'
		else '5. 56+'
	end
order by [age band];
go

------------------------------------------------------------------
-- 9. Attrition by monthly income band
------------------------------------------------------------------
select
	case
		when MonthlyIncome < 3000 then '1. under 3,000'
		when MonthlyIncome < 5000 then '2. 3,000-4,999'
		when MonthlyIncome < 8000 then '3. 5,000-7,999'
		when MonthlyIncome < 12000 then '4. 8,000-11,999'
		else '5. 12,000+'
	end as [income band],
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by
	case
		when MonthlyIncome < 3000 then '1. under 3,000'
		when MonthlyIncome < 5000 then '2. 3,000-4,999'
		when MonthlyIncome < 8000 then '3. 5,000-7,999'
		when MonthlyIncome < 12000 then '4. 8,000-11,999'
		else '5. 12,000+'
	end
order by [income band];
go

------------------------------------------------------------------
-- 10. Attrition by tenure band (years at the company)
------------------------------------------------------------------
select
	case
		when YearsAtCompany <= 1 then '1. 0-1 years'
		when YearsAtCompany <= 5 then '2. 2-5 years'
		when YearsAtCompany <= 10 then '3. 6-10 years'
		else '4. 11+ years'
	end as [tenure band],
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by
	case
		when YearsAtCompany <= 1 then '1. 0-1 years'
		when YearsAtCompany <= 5 then '2. 2-5 years'
		when YearsAtCompany <= 10 then '3. 6-10 years'
		else '4. 11+ years'
	end
order by [tenure band];
go

------------------------------------------------------------------
-- 11. Riskiest overtime x marital status combinations (at least 20 employees)
------------------------------------------------------------------
select
	OverTime,
	MaritalStatus,
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from dbo.Employees
group by OverTime, MaritalStatus
having count(*) >= 20
order by [attrition rate %] desc;
go

------------------------------------------------------------------
-- 12. Leavers vs. stayers: average ratings and pay
------------------------------------------------------------------
select
	Attrition,
	count(*) as employees,
	cast(avg(1.0 * MonthlyIncome) as decimal(10, 0)) as [avg monthly income],
	cast(avg(1.0 * YearsAtCompany) as decimal(5, 1)) as [avg years at company],
	cast(avg(1.0 * YearsSinceLastPromotion) as decimal(5, 2)) as [avg years since promotion],
	cast(avg(1.0 * JobSatisfaction) as decimal(4, 2)) as [avg job satisfaction],
	cast(avg(1.0 * EnvironmentSatisfaction) as decimal(4, 2)) as [avg environment satisfaction],
	cast(avg(1.0 * WorkLifeBalance) as decimal(4, 2)) as [avg work-life balance]
from dbo.Employees
group by Attrition;
go

------------------------------------------------------------------
-- 13. Top 20 highest-paid employees who left
------------------------------------------------------------------
select top 20
	EmployeeNumber,
	JobRole,
	Department,
	Age,
	MonthlyIncome,
	YearsAtCompany,
	YearsSinceLastPromotion,
	OverTime
from dbo.Employees
where Attrition = 'Yes'
order by MonthlyIncome desc;
go

------------------------------------------------------------------
-- 14. Job roles ranked by attrition rate within each department
------------------------------------------------------------------
with role_rates as (
	select
		Department,
		JobRole,
		count(*) as employees,
		cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as attrition_rate
	from dbo.Employees
	group by Department, JobRole
)
select
	Department,
	JobRole,
	employees,
	attrition_rate as [attrition rate %],
	rank() over (partition by Department order by attrition_rate desc) as [rank in department]
from role_rates
order by Department, [rank in department];
go

------------------------------------------------------------------
-- 15. Views
------------------------------------------------------------------
-- Attrition summary per job role
create or alter view dbo.vw_job_role_attrition as
select
	JobRole,
	count(*) as employees,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as employees_left,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as attrition_rate_pct,
	cast(avg(1.0 * MonthlyIncome) as decimal(10, 0)) as avg_monthly_income
from dbo.Employees
group by JobRole;
go

-- Simple rule-based "high-risk" profile found in the EDA: works overtime AND is single.
-- This is a descriptive filter, not the machine learning model.
create or alter view dbo.vw_high_risk_profile as
select *
from dbo.Employees
where OverTime = 'Yes'
	and MaritalStatus = 'Single';
go

select * from dbo.vw_job_role_attrition order by attrition_rate_pct desc;
go

-- Attrition rate inside vs. outside the high-risk profile
-- (a join is used because SQL Server does not allow subqueries inside GROUP BY)
with flagged as (
	select
		e.Attrition,
		case when h.EmployeeNumber is not null then 'High-risk profile' else 'Everyone else' end as [group]
	from dbo.Employees as e
	left join dbo.vw_high_risk_profile as h
		on h.EmployeeNumber = e.EmployeeNumber
)
select
	[group],
	count(*) as employees,
	cast(100.0 * sum(case when Attrition = 'Yes' then 1 else 0 end) / count(*) as decimal(5, 2)) as [attrition rate %]
from flagged
group by [group];
go
