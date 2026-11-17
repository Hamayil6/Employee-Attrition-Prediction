-- Employee Attrition: create the database and table, then load the CSV (SQL Server)
-- Before running: edit the file path in the BULK INSERT below.
-- The columns are in the same order as the CSV, so the file loads without a format file.

if db_id('HRAnalytics') is null
	create database HRAnalytics;
go

use HRAnalytics;
go

drop table if exists dbo.Employees;
go

create table dbo.Employees (
	Age int not null,
	Attrition varchar(3) not null,
	BusinessTravel varchar(30) not null,
	DailyRate int not null,
	Department varchar(50) not null,
	DistanceFromHome int not null,
	Education int not null,
	EducationField varchar(50) not null,
	EmployeeCount int not null,
	EmployeeNumber int not null,
	EnvironmentSatisfaction int not null,
	Gender varchar(10) not null,
	HourlyRate int not null,
	JobInvolvement int not null,
	JobLevel int not null,
	JobRole varchar(50) not null,
	JobSatisfaction int not null,
	MaritalStatus varchar(20) not null,
	MonthlyIncome int not null,
	MonthlyRate int not null,
	NumCompaniesWorked int not null,
	Over18 char(1) not null,
	OverTime varchar(3) not null,
	PercentSalaryHike int not null,
	PerformanceRating int not null,
	RelationshipSatisfaction int not null,
	StandardHours int not null,
	StockOptionLevel int not null,
	TotalWorkingYears int not null,
	TrainingTimesLastYear int not null,
	WorkLifeBalance int not null,
	YearsAtCompany int not null,
	YearsInCurrentRole int not null,
	YearsSinceLastPromotion int not null,
	YearsWithCurrManager int not null,
	constraint PK_Employees primary key (EmployeeNumber),
	constraint CK_Employees_Attrition check (Attrition in ('Yes', 'No'))
);
go

-- Notes on the load:
--  * firstrow = 2 skips the header line (it also skips the UTF-8 byte order mark at the start of the file).
--  * The CSV in /data uses LF line endings ('0x0a'). If you re-download the file from Kaggle and it has
--    Windows (CRLF) line endings, change rowterminator to '0x0d0a'.
bulk insert dbo.Employees
from 'C:\path\to\Employee-Attrition-Prediction\data\WA_Fn-UseC_-HR-Employee-Attrition.csv'
with (
	firstrow = 2,
	fieldterminator = ',',
	rowterminator = '0x0a',
	codepage = '65001',
	tablock
);
go

-- Sanity checks (expected: 1470 rows; 1233 'No' and 237 'Yes')
select count(*) as [total rows] from dbo.Employees;
go

select
	Attrition,
	count(*) as employees
from dbo.Employees
group by Attrition;
go
