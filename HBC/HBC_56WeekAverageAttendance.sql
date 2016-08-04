USE Analytics

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]
	--select	  DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))

; WITH LastnSundays AS (
	SELECT top 107 ActualDate, DateID
	FROM DW.DimDate
	WHERE CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
	ORDER BY ActualDate DESC
	)

	--select * from LastnSundays

, LastnWeekends AS (
	SELECT 'Current Week' AS SectionName, LastnSundays.ActualDate, DateID FROM LastnSundays
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundays.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundays
)

--select * from LastnWeekends order by dateid

, Attendance AS (
   SELECT DISTINCT              
    ROW_NUMBER() OVER (ORDER BY LastnWeekends.ActualDate) AS RowNum
		, LastnWeekends.ActualDate AS WeekendDate
		--, DimCampus.Code
		--, CASE WHEN DimCampus.Code = '--' AND DimMinistry.Name IN ('Camp','Other') THEN 'Camp / Other' ELSE 
		--	CASE WHEN DimCampus.Code  = '--' THEN Campus2.Code ELSE DimCampus.Code END END AS Campus
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekends 
		ON FactAttendance.InstanceDateID IN ( LastnWeekends.DateID) 
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
		LastnWeekends.ActualDate 
)

--SELECT * from Attendance

SELECT TOP 56             
    ra1.WeekendDate
    , ra1.AttendanceCount as Attendance
    , (SELECT SUM(ra2.AttendanceCount) / 52 FROM Attendance ra2 WHERE ra2.RowNum BETWEEN ra1.RowNum - 52 and ra1.RowNum) AS [52 WK Average]
FROM Attendance ra1
ORDER BY ra1.WeekendDate DESC