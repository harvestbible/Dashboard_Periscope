USE Analytics

DECLARE @ReportYear_16 INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportYear_15 INT = [Calendar_Year|datepart(yy, getdate())] - 1
DECLARE @ReportYear_14 INT = [Calendar_Year|datepart(yy, getdate())] - 2
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

; WITH LastnSundays_16 AS (
	SELECT  ActualDate, DateID
	 
	FROM DW.DimDate
	WHERE
		ActualDate >=  convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_16 -1)) 
		AND CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_16)))))
,

LastnSundays_15 AS (
	SELECT  ActualDate, DateID
	 
	FROM DW.DimDate
	WHERE
		ActualDate >=  convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_15 -1)) 
		AND CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_15)))))
,

LastnSundays_14 AS (
	SELECT  ActualDate, DateID
	 
	FROM DW.DimDate
	WHERE
		ActualDate >=  convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_14 -1)) 
		AND CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear_14)))))

, LastnWeekends_16 AS (
	SELECT 'Current Week' AS SectionName, LastnSundays_16.ActualDate, DateID FROM LastnSundays_16
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundays_16.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundays_16
)

, LastnWeekends_15 AS (
	SELECT 'Current Week' AS SectionName, LastnSundays_15.ActualDate, DateID FROM LastnSundays_15
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundays_15.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundays_15
)

, LastnWeekends_14 AS (
	SELECT 'Current Week' AS SectionName, LastnSundays_14.ActualDate, DateID FROM LastnSundays_14
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundays_14.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundays_14
)

,  FullAttendance_16 AS (
	SELECT distinct
		LastnWeekends_16.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekends_16 
		ON FactAttendance.InstanceDateID IN ( LastnWeekends_16.DateID) 
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
		OR DimMinistry.Name LIKE '%Harvest Kids'
	GROUP BY
		LastnWeekends_16.ActualDate 	
)

,  FullAttendance_15 AS (
	SELECT distinct
		LastnWeekends_15.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekends_15 
		ON FactAttendance.InstanceDateID IN ( LastnWeekends_15.DateID) 
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
		OR DimMinistry.Name LIKE '%Harvest Kids'
	GROUP BY
		LastnWeekends_15.ActualDate 	
)

,  FullAttendance_14 AS (
	SELECT distinct
		LastnWeekends_14.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekends_14 
		ON FactAttendance.InstanceDateID IN ( LastnWeekends_14.DateID) 
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
		OR DimMinistry.Name LIKE '%Harvest Kids'
	GROUP BY
		LastnWeekends_14.ActualDate 	
)
, table_2016 as
(
SELECT  
AVG(attendancecount) as aveatt, Year(FullAttendance_16.WeekendDate) as CalendarYear,  Month(FullAttendance_16.WeekendDate) as CalendarMonth
FROM  FullAttendance_16
GROUP BY Year(FullAttendance_16.WeekendDate),  Month(FullAttendance_16.WeekendDate)
)
, table_2015 as
(
SELECT  
AVG(attendancecount) as aveatt, Year(FullAttendance_15.WeekendDate) as CalendarYear,  Month(FullAttendance_15.WeekendDate) as CalendarMonth
FROM  FullAttendance_15
GROUP BY Year(FullAttendance_15.WeekendDate),  Month(FullAttendance_15.WeekendDate)
)
, table_2014 as
(
SELECT  
AVG(attendancecount) as aveatt, Year(FullAttendance_14.WeekendDate) as CalendarYear,  Month(FullAttendance_14.WeekendDate) as CalendarMonth
FROM  FullAttendance_14
GROUP BY Year(FullAttendance_14.WeekendDate),  Month(FullAttendance_14.WeekendDate)
)

, final_table as 
(
select CalendarMonth, CalendarYear, aveatt, case when CalendarMonth > @ReportMonth then concat(CalendarYear, '-', CalendarYear + 1) else concat(CalendarYear - 1, '-', CalendarYear) end as year_interval, month_name
from table_2016
join [month_map] on table_2016.CalendarMonth = month_map.month_num

union

select CalendarMonth, CalendarYear, aveatt, case when CalendarMonth > @ReportMonth then concat(CalendarYear, '-', CalendarYear + 1) else concat(CalendarYear - 1, '-', CalendarYear) end as year_interval, month_name
from table_2015
join [month_map] on table_2015.CalendarMonth = month_map.month_num

union

select CalendarMonth, CalendarYear, aveatt, case when CalendarMonth > @ReportMonth then concat(CalendarYear, '-', CalendarYear + 1) else concat(CalendarYear - 1, '-', CalendarYear) end as year_interval, month_name
from table_2014
join [month_map] on table_2014.CalendarMonth = month_map.month_num
)
select * from final_table
order by 
  case when 
        CalendarMonth % 12 = (@ReportMonth + 1) % 12 then 1 
   when CalendarMonth % 12=  (@ReportMonth + 2) % 12 then 2 
   when CalendarMonth % 12=  (@ReportMonth + 3) % 12 then 3 
   when CalendarMonth % 12=  (@ReportMonth + 4) % 12 then 4 
   when CalendarMonth % 12=  (@ReportMonth + 5) % 12 then 5 
   when CalendarMonth % 12=  (@ReportMonth + 6) % 12 then 6 
   when CalendarMonth % 12=  (@ReportMonth + 7) % 12 then 7 
   when CalendarMonth % 12=  (@ReportMonth + 8) % 12 then 8 
   when CalendarMonth % 12=  (@ReportMonth + 9) % 12 then 9 
   when CalendarMonth % 12=  (@ReportMonth + 10) % 12 then 10 
   when CalendarMonth % 12=  (@ReportMonth + 11) % 12 then 11
   when CalendarMonth % 12=  (@ReportMonth + 12) % 12 then 12
   -- else 13
  end,
  CalendarYear desc
-- order by 2,1