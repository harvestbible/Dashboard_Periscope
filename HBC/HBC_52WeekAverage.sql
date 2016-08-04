USE Analytics

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

---------------Current Year

; WITH LastnSundaysCurrent AS (
	SELECT top 52 ActualDate, DateID
	FROM DW.DimDate
	WHERE CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
	ORDER BY ActualDate DESC
	)

	--select * from LastnSundaysCurrent

, LastnWeekendsCurrent AS (
	SELECT 'Current Week' AS SectionName, LastnSundaysCurrent.ActualDate, DateID FROM LastnSundaysCurrent
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundaysCurrent.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundaysCurrent
)

--select * from LastnWeekendsCurrent order by dateid

---------------Prev Year

, LastnSundaysPrior AS (
	SELECT top 52 ActualDate, DateID
	FROM DW.DimDate
	WHERE CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))))
	ORDER BY ActualDate DESC
	)

	--select * from LastnSundaysPrior

, LastnWeekendsPrior AS (
	SELECT 'Current Week' AS SectionName, LastnSundaysPrior.ActualDate, DateID FROM LastnSundaysPrior
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundaysPrior.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundaysPrior
)

--select * from LastnWeekendsPrior order by dateid

------------------------

, Attendance AS (
   SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastnWeekendsCurrent.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekendsCurrent 
		ON FactAttendance.InstanceDateID IN ( LastnWeekendsCurrent.DateID) 
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
		LastnWeekendsCurrent.ActualDate 

	UNION

   SELECT DISTINCT              
	'PRIOR' AS TimePeriod
		, LastnWeekendsPrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekendsPrior 
		ON FactAttendance.InstanceDateID IN ( LastnWeekendsPrior.DateID) 
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
		LastnWeekendsPrior.ActualDate 
)

--SELECT * from AttendanceCurrent

, final_table as
(
SELECT 
	CASE TimePeriod
		WHEN 'CURRENT' THEN @ReportYear
		WHEN 'PRIOR' THEN @ReportYear -1
	END AS CalendarYear
	, AVG(AttendanceCount) AS Average52Week
FROM Attendance ra1
GROUP BY TimePeriod
)


select concat('As of ', FORMAT(EOMONTH(convert(varchar, concat(@ReportYear, '-', @ReportMonth, '-01'), 111)), 'M/dd/yyyy', 'en-US')) as date,
       (select Average52Week from final_table where CalendarYear = @ReportYear) as value

union

select concat('As of ', FORMAT(EOMONTH(convert(varchar, concat(@ReportYear - 1, '-', @ReportMonth, '-01'), 111)), 'M/dd/yyyy', 'en-US')) as date,
       (select Average52Week from final_table where CalendarYear = @ReportYear - 1) as value

union

select 'Increase (Decrease)', (select Average52Week from final_table where CalendarYear = @ReportYear) - (select Average52Week from final_table where CalendarYear = @ReportYear - 1)