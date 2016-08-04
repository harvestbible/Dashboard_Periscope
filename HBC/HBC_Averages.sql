USE Analytics
/*
HBC Averages
*/

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]

DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]
DECLARE @NumSunCurrent INT
DECLARE @NumSunPrior INT

--For Current Year
,  @YTDrevenue MONEY
, @AttendanceCountCurrent INT

--For Prior Year
,  @YTDrevenuePrior MONEY
, @AttendanceCountPrior int

--For Rolling 12 month Current
,  @YTDrevenueRollCurrent MONEY
, @AttendanceCountRollCurrent INT
, @NumSunRollCurrent INT

--For Rolling 12 month Prior
,  @YTDrevenueRollPrior MONEY
, @AttendanceCountRollPrior INT
, @NumSunRollPrior INT

	--------revenue
	--;WITH YTDrevenue AS (
	SELECT SUM(t1.amount) as RevenueAmount
	, t3.[CalendarYear]
	INTO #YTDrevenue
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN DW.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	WHERE 
	((t3.[CalendarYear] =  @ReportYear
	AND t3.[CalendarMonth] <= @ReportMonth)
		OR (t3.[CalendarYear] =  @ReportYear -1
	AND t3.[CalendarMonth] <= @ReportMonth))
	AND t4.Code = 'HBC'
	AND t2.[GLCode] = '30010'
	AND t2.[DepartmentCode] = '3015'
	AND fundcode = '025' 
	AND t2.[TenantID] = 3
	group by t3.[CalendarYear]
	--)

	----------current rolling 12months revenue
	--;WITH RollrevenueCurrent AS (
	SELECT @YTDrevenueRollCurrent = SUM(t1.amount)  -- as RollRevenueAmount
	--, t3.[CalendarYear]
	--INTO #RollrevenueCurrent
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN DW.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	WHERE 
	((t3.[CalendarYear] =  @ReportYear
	AND t3.[CalendarMonth] <= @ReportMonth)
		OR (t3.[CalendarYear] =  @ReportYear -1
	AND t3.[CalendarMonth] > @ReportMonth))
	AND t4.Code = 'HBC'
	AND t2.[GLCode] = '30010'
	AND t2.[DepartmentCode] = '3015'
	AND fundcode = '025'  
	AND t2.[TenantID] = 3

	----------prior rolling 12months revenue
	SELECT @YTDrevenueRollPrior = SUM(t1.amount)  -- as RollRevenueAmount
	--, t3.[CalendarYear]
	--INTO #RollrevenueCurrent
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN DW.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	WHERE 
	((t3.[CalendarYear] =  @ReportYear -1
	AND t3.[CalendarMonth] <= @ReportMonth)
		OR (t3.[CalendarYear] =  @ReportYear -2
	AND t3.[CalendarMonth] > @ReportMonth))
	AND t4.Code = 'HBC'
	AND t2.[GLCode] = '30010'
	AND t2.[DepartmentCode] = '3015'
	AND fundcode = '025'  
	AND t2.[TenantID] = 3

	--------------attendance
	-------------- attendance dates current YTD
	SELECT   ActualDate, DateID
	INTO #LastNSundaysCurrentYear
	FROM DW.DimDate
	WHERE
		--DateID <= 20160229 -- Last Day of reporting period month
		actualdate  <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
		--and DateID >= 20160101 
		AND actualdate >= CONVERT(DATE, '01/01/' +  CONVERT(VARCHAR(4), @ReportYear) )
		AND CalendarDayOfWeekLabel = 'Sunday'

	SELECT @NumSunCurrent = COUNT(1) FROM #LastNSundaysCurrentYear

	--------------attendance dates prior YTD
	SELECT ActualDate, DateID
	INTO #LastNSundaysPriorYear
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))))
		AND actualdate >= CONVERT(DATE, '01/01/' +  CONVERT(VARCHAR(4), @ReportYear -1) )
		AND CalendarDayOfWeekLabel = 'Sunday'

	SELECT @NumSunPrior = COUNT(1) FROM #LastNSundaysPriorYear

	--------------attendance dates current rolling 12 month
	SELECT ActualDate, DateID
	INTO #LastNSundaysCurrentRoll
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=   DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
		AND actualdate >=  convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))
		AND CalendarDayOfWeekLabel = 'Sunday'

		--select * from #LastNSundaysPriorYear

	SELECT @NumSunRollCurrent = COUNT(1) FROM #LastNSundaysPriorYear

	--------------attendance dates prior rolling 12 month
	SELECT ActualDate, DateID
	INTO #LastNSundaysPriorRoll
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))))
		AND actualdate >=  convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -2))
		AND CalendarDayOfWeekLabel = 'Sunday'

	SELECT @NumSunRollPrior = COUNT(1) FROM #LastNSundaysPriorYear

	-----------------------------------------------------
	----------Attendance data current 

; with LastTwoWeekendsCurrent AS (
	SELECT 'Current Week' AS SectionName, #LastNSundaysCurrentYear.ActualDate, DateID FROM #LastNSundaysCurrentYear
	UNION
	SELECT 'Previous Week' AS SectionName, #LastNSundaysCurrentYear.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112) FROM #LastNSundaysCurrentYear
)

	 SELECT DISTINCT              
	     LastTwoWeekendsCurrent.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into #FullAttendanceCurrent
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsCurrent 
		ON FactAttendance.InstanceDateID IN ( LastTwoWeekendsCurrent.DateID) 
	INNER JOIN DW.DimMinistry
		ON FactAttendance.MinistryID = DimMinistry.MinistryID
	LEFT JOIN DW.DimCampus
		ON FactAttendance.CampusID = DimCampus.CampusID
	LEFT JOIN DW.DimCampus campus2
		ON DimMinistry.CampusID = campus2.CampusID
	WHERE
		DimMinistry.Name IN (
			  'AU - Churchwide Services'
			, 'CC - Churchwide Services'
			, 'CL - Churchwide Services'
			, 'DR - Chuchwide Services'
			, 'EL - Churchwide Services'
			, 'NI - Churchwide Services'
			, 'RM - Churchwide Services'
			, 'Camp'
			, 'Other')
		
	GROUP BY
		LastTwoWeekendsCurrent.ActualDate 

		----------Attendance data prior 
	; with  LastTwoWeekendsPrior AS (
	SELECT 'Current Week' AS SectionName, #LastNSundaysPriorYear.ActualDate, DateID FROM #LastNSundaysPriorYear
	UNION
	SELECT 'Previous Week' AS SectionName, #LastNSundaysPriorYear.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM #LastNSundaysPriorYear
)
--SELECT * from LastTwoWeekendsPrior

	 SELECT DISTINCT              
		LastTwoWeekendsPrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into #FullAttendancePrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsPrior 
		ON FactAttendance.InstanceDateID IN ( LastTwoWeekendsPrior.DateID) 
	INNER JOIN DW.DimMinistry
		ON FactAttendance.MinistryID = DimMinistry.MinistryID
	LEFT JOIN DW.DimCampus
		ON FactAttendance.CampusID = DimCampus.CampusID
	LEFT JOIN DW.DimCampus campus2
		ON DimMinistry.CampusID = campus2.CampusID
	WHERE
		DimMinistry.Name IN (
			  'AU - Churchwide Services'
			, 'CC - Churchwide Services'
			, 'CL - Churchwide Services'
			, 'DR - Chuchwide Services'
			, 'EL - Churchwide Services'
			, 'NI - Churchwide Services'
			, 'RM - Churchwide Services'
			, 'Camp'
			, 'Other')
		
	GROUP BY
		LastTwoWeekendsPrior.ActualDate 

	----------Attendance data  current Rolling 12 months
	; with  LastTwoWeekendsRollCurrent AS (
	SELECT 'Current Week' AS SectionName, #LastNSundaysCurrentRoll.ActualDate, DateID FROM #LastNSundaysCurrentRoll
	UNION
	SELECT 'Previous Week' AS SectionName, #LastNSundaysCurrentRoll.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM #LastNSundaysCurrentRoll
)
	
		 SELECT DISTINCT              
		LastTwoWeekendsRollCurrent.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into #FullAttendanceRollCurrent
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsRollCurrent 
		ON FactAttendance.InstanceDateID IN ( LastTwoWeekendsRollCurrent.DateID) 
	INNER JOIN DW.DimMinistry
		ON FactAttendance.MinistryID = DimMinistry.MinistryID
	LEFT JOIN DW.DimCampus
		ON FactAttendance.CampusID = DimCampus.CampusID
	LEFT JOIN DW.DimCampus campus2
		ON DimMinistry.CampusID = campus2.CampusID
	WHERE
		DimMinistry.Name IN (
			  'AU - Churchwide Services'
			, 'CC - Churchwide Services'
			, 'CL - Churchwide Services'
			, 'DR - Chuchwide Services'
			, 'EL - Churchwide Services'
			, 'NI - Churchwide Services'
			, 'RM - Churchwide Services'
			, 'Camp'
			, 'Other')
		
	GROUP BY
		LastTwoWeekendsRollCurrent.ActualDate 

	----------Attendance data Prior Rolling 12 months
	; with  LastTwoWeekendsRollPrior AS (
	SELECT 'Current Week' AS SectionName, #LastNSundaysPriorRoll.ActualDate, DateID FROM #LastNSundaysPriorRoll
	UNION
	SELECT 'Previous Week' AS SectionName, #LastNSundaysPriorRoll.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM #LastNSundaysPriorRoll
)	

	SELECT DISTINCT              
		LastTwoWeekendsRollPrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into #FullAttendanceRollPrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsRollPrior 
		ON FactAttendance.InstanceDateID IN ( LastTwoWeekendsRollPrior.DateID) 
	INNER JOIN DW.DimMinistry
		ON FactAttendance.MinistryID = DimMinistry.MinistryID
	LEFT JOIN DW.DimCampus
		ON FactAttendance.CampusID = DimCampus.CampusID
	LEFT JOIN DW.DimCampus campus2
		ON DimMinistry.CampusID = campus2.CampusID
	WHERE
		DimMinistry.Name IN (
			  'AU - Churchwide Services'
			, 'CC - Churchwide Services'
			, 'CL - Churchwide Services'
			, 'DR - Chuchwide Services'
			, 'EL - Churchwide Services'
			, 'NI - Churchwide Services'
			, 'RM - Churchwide Services'
			, 'Camp'
			, 'Other')
		
	GROUP BY
		LastTwoWeekendsRollPrior.ActualDate 

------------------------------

--DECLARE @ReportYear INT = 2016

--DECLARE @ReportMonth TINYINT = 2
--DECLARE @NumSunCurrent INT
--DECLARE @NumSunPrior INT

----For Current Year
--,  @YTDrevenue MONEY
--, @AttendanceCountCurrent INT

----For Prior Year
--,  @YTDrevenuePrior MONEY
--, @AttendanceCountPrior int

----For Rolling 12 month Current
--,  @YTDrevenueRollCurrent MONEY
--, @AttendanceCountRollCurrent INT
--, @NumSunRollCurrent INT

----For Rolling 12 month Prior
--,  @YTDrevenueRollPrior MONEY
--, @AttendanceCountRollPrior INT
--, @NumSunRollPrior INT


SELECT  @AttendanceCountPrior = SUM(AttendanceCount) FROM  #FullAttendancePrior 
SELECT  @AttendanceCountCurrent = SUM(AttendanceCount) FROM  #FullAttendanceCurrent
SELECT  @AttendanceCountRollCurrent = SUM(AttendanceCount) FROM  #FullAttendanceRollCurrent 
SELECT  @AttendanceCountRollPrior = SUM(AttendanceCount) FROM  #FullAttendanceRollPrior

--SELECT @AttendanceCountPrior, @AttendanceCountCurrent, @AttendanceCountRollCurrent, @AttendanceCountRollPrior
--select (@YTDrevenueRollPrior / @NumSunRollCurrent  ) / (@AttendanceCountRollCurrent / @NumSunRollCurrent ) as Rolling12MoPerAdult
--select(@YTDrevenueRollPrior / @NumSunRollPrior  ) / (@AttendanceCountRollPrior / @NumSunRollPrior ) as Rolling12MoPerAdult
    
;with t1 as
(
select CalendarYear ,  @AttendanceCountCurrent/@NumSunCurrent AS WklyAttend, RevenueAmount/@NumSunCurrent  AS WklyGiving
, (RevenueAmount/@NumSunCurrent) / (@AttendanceCountCurrent/@NumSunCurrent)  as GivingPerAdult
, (@YTDrevenueRollCurrent / @NumSunRollCurrent  ) / (@AttendanceCountRollCurrent / @NumSunRollCurrent ) as Rolling12MoPerAdult
from #YTDrevenue where calendaryear = @ReportYear

union
select CalendarYear , @AttendanceCountPrior/@NumSunPrior AS WklyAttend, RevenueAmount/@NumSunPrior AS WklyGiving
, (RevenueAmount/@NumSunPrior) / (@AttendanceCountPrior/@NumSunPrior)  as GivingPerAdult
, (@YTDrevenueRollPrior / @NumSunRollPrior  ) / (@AttendanceCountRollPrior / @NumSunRollPrior ) as Rolling12MoPerAdult
from #YTDrevenue where calendaryear = @ReportYear -1
),
       
t2 as
(
select 'Wkly Giving' as 'YTD', (select wklygiving from t1 where CalendarYear = 2015) as '1 Year Prior', (select wklygiving from t1 where CalendarYear = 2016) as '[Calendar_Year]' 

union
select 'Wkly Adult Attend.' as 'YTD', (select wklyattend from t1 where CalendarYear = 2015) as '2015', (select wklyattend from t1 where CalendarYear = 2016) as '2016' 
 
union
select 'Wkly Giving Per Adult' as 'YTD', (select givingperadult from t1 where CalendarYear = 2015) as '2015', (select givingperadult from t1 where CalendarYear = 2016) as '2016' 

union
select 'Rolling 12 mo per adult' as 'YTD', (select rolling12moperadult from t1 where CalendarYear = 2015) as '2015', (select rolling12moperadult from t1 where CalendarYear = 2016) as '2016' 
)
select * from t2 
order by case when YTD = 'Wkly Giving' then 1 when YTD = 'Wkly Adult Attend.' then 2 when YTD = 'Wkly Giving Per Adult' then 3 else 4 end

drop table #FullAttendanceCurrent
drop table #FullAttendancePrior
drop table #LastNSundaysCurrentYear
drop table #LastNSundaysPriorYear
drop table #YTDrevenue
drop table #LastNSundaysCurrentRoll
drop table #LastNSundaysPriorRoll
drop table #FullAttendanceRollCurrent
drop table #FullAttendanceRollPrior