DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]


; WITH LastnSundays AS (
	SELECT  ActualDate, DateID
	 
	FROM DW.DimDate
	WHERE
		ActualDate >= (convert(date,  convert(varchar(10),@ReportMonth ) + '/01/'+  convert(varchar(10),@ReportYear)))
		AND CalendarDayOfWeekLabel = 'Sunday'
	    AND ActualDate <= DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
	--ORDER BY ActualDate DESC
	)

	--select * from LastnSundays

, LastnWeekends AS (
	SELECT 'Current Week' AS SectionName, LastnSundays.ActualDate, DateID FROM LastnSundays
	UNION
	SELECT 'Previous Week' AS SectionName, LastnSundays.ActualDate,  CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)   FROM LastnSundays
)

--select * from LastnWeekends order by dateid


, FullAttendance AS (
	SELECT DISTINCT
		  LastnWeekends.SectionName
		, LastnWeekends.ActualDate AS WeekendDate
		--, DimCampus.Code
		, CASE WHEN DimCampus.Code = '--' AND DimMinistry.Name IN ('Camp','Other') THEN 'Camp / Other' ELSE 
			CASE WHEN DimCampus.Code  = '--' THEN Campus2.Code ELSE DimCampus.Code END END AS Campus
		, DimMinistry.Name AS MinistryName
		, CASE WHEN DimMinistry.Name IN (
			  'AU - Churchwide Services'
			, 'CC - Churchwide Services'
			, 'CL - Churchwide Services'
			, 'DR - Chuchwide Services'
			, 'EL - Churchwide Services'
			, 'NI - Churchwide Services'
			, 'RM - Churchwide Services'
			, 'Camp'
			, 'Other') THEN 'ADULTS' ELSE
			'KIDS' END AS AttendanceCategory
		, FactAttendance.AttendanceCount
	FROM DW.FactAttendance
	INNER JOIN LastnWeekends 
		ON FactAttendance.InstanceDateID = LastnWeekends.DateID
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
	
)

--select *  FROM FullAttendance

SELECT
	SectionName, WeekendDate
	, CASE Campus
		WHEN 'RM' THEN 2
		WHEN 'EL' THEN 3
		WHEN 'CL' THEN 4
		WHEN 'NI' THEN 5
		WHEN 'CC' THEN 6
		WHEN 'AU' THEN 7
		WHEN 'DR' THEN 8
		WHEN 'Camp / Other' THEN 9 END AS RowNumber
	, Campus, MinistryName, AttendanceCategory, SUM(AttendanceCount) AS AttendanceCount
	into #FullAttendance2
FROM FullAttendance
where campus <> 'Camp / Other'
GROUP BY 
	SectionName, WeekendDate
	, CASE Campus
		WHEN 'RM' THEN 2
		WHEN 'EL' THEN 3
		WHEN 'CL' THEN 4
		WHEN 'NI' THEN 5
		WHEN 'CC' THEN 6
		WHEN 'AU' THEN 7
		WHEN 'DR' THEN 8
		WHEN 'Camp / Other' THEN 9 END
	, Campus, MinistryName, AttendanceCategory
--

-- select *  FROM #FullAttendance2

	SELECT  -- campus
      case when campus = 'AU' then 'Aurora'
           when campus = 'CC' then 'Chicago Cathedral'
           when campus = 'CL' then 'Crystal Lake'
           when campus = 'DR' then 'Deerfield Rd'
           when campus = 'EL' then 'Elgin'
           when campus = 'NI' then 'Niles'
           when campus = 'RM' then 'Rolling Meadows' end as campus, 
	sum(attendancecount), 
	--round((sum(attendancecount) * 1.0) / 
	--	(
	--	SELECT sum(attendancecount) FROM  #FullAttendance2 WHERE AttendanceCategory = 'ADULTS' and campus <> 'Camp / Other'
	--	),0)as rowPercent
	round((sum(attendancecount) * 1.0) / 
	(
	SELECT sum(attendancecount) FROM  #FullAttendance2 WHERE AttendanceCategory = 'ADULTS' and campus <> 'Camp / Other'
	),2)as rowPercent,
  'Attendance'

FROM  #FullAttendance2 
WHERE AttendanceCategory = 'ADULTS'
and campus <> 'Camp / Other'
group by  campus

union

   SELECT 
		 case t5.name
			WHEN 'UNKNOWN' THEN 'Deerfield Rd'
			ELSE t5.name 
			end  as Campus, 
		  SUM(t1.amount) as RevenueAmount,
		  round((SUM(t1.amount) * 1.0) / 
					(select SUM(t1.amount)
					  FROM [Analytics].[DW].[FactRevenue] t1

						LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
						ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
						JOIN [Analytics].DW.DimDate T3
						ON t1.DateID = t3.DateID
						INNER JOIN DW.DimEntity t4
						ON t1.EntityID = t4.EntityID
						AND t1.TenantID = t4.TenantID
						LEFT JOIN [Analytics].[DW].[DimCampus] t5
						ON t1.[CampusID] = t5.[CampusID]
						
						WHERE
						t3.[CalendarYear] = @ReportYear 
						AND t3.[CalendarMonth] <=  @ReportMonth  
						AND t4.Code = 'HBC'
						AND t2.[GLCode] = '30010'
						AND t2.[DepartmentCode] = '3015'
						AND t2.fundcode = '025'  
						AND t2.TenantID = 3),2) as rowPercent,
     'Contribution' as legend
		  
		   
	FROM [Analytics].[DW].[FactRevenue] t1
	
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
		ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	INNER JOIN [Analytics].DW.DimDate T3
		ON t1.DateID = t3.DateID
	INNER JOIN DW.DimEntity t4
		ON t1.EntityID = t4.EntityID
		AND t1.TenantID = t4.TenantID
	LEFT JOIN [Analytics].[DW].[DimCampus] t5
		ON t1.[CampusID] = t5.[CampusID]
	
	WHERE
	t3.[CalendarYear] = @ReportYear 
	AND t3.[CalendarMonth] <=  @ReportMonth 
	AND t4.Code = 'HBC'
	AND t2.[GLCode] = '30010'
	AND t2.[DepartmentCode] = '3015'
	AND t2.fundcode = '025'  
	AND t2.TenantID = 3
	GROUP BY  t5.name 
 order by 
   4 desc, 2 desc
drop table #FullAttendance2