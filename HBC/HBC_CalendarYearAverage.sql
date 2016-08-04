USE Analytics
/*
HBC dashboard Calendar Year Averages 
*/

DECLARE @YearForReport INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportYear INT = @YearForReport
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]


---------------set up date ranges for the reporting years
; WITH LastNSundaysCurrentMo AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10), @ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
		AND actualdate >=   convert(date, convert(varchar(10), @ReportMonth  ) + '/01/'+  convert(varchar(10),@ReportYear))
		AND CalendarDayOfWeekLabel = 'Sunday'
)

--select * from  LastNSundaysCurrentMo

	----------Attendance data  current Rolling 12 months
, LastnWeekendsCurrent AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysCurrentMo t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysCurrentMo t1
	)

--select * from LastnWeekendsCurrent order by ActualDate

---------------end of setting up date ranges 1

--Attendance Current Year

--, Attendance AS (
    SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastnWeekendsCurrent.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into #FullAttendanceCurrent
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
 
 -----------------------------------
 --Current Year YTD 

 ;WITH  LastNSundaysYTD AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))
		AND actualdate >=  '01/01/'+  convert(varchar(10),@ReportYear) 
		AND CalendarDayOfWeekLabel = 'Sunday'
)


, LastTwoWeekendsYTDCurrent AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysYTD t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysYTD t1
	)


--select * from	LastTwoWeekendsYTDCurrent ORDER BY ActualDate

	    SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastTwoWeekendsYTDCurrent.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into   #FullAttendanceYTD
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsYTDCurrent 
		ON FactAttendance.InstanceDateID IN ( LastTwoWeekendsYTDCurrent.DateID) 
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
		LastTwoWeekendsYTDCurrent.ActualDate 

		--select * from #FullAttendanceYTD

	---------------------------------One Year Prior
	--One Year Prior Current Month

; WITH LastNSundaysCurrentMoOnePrior AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10), @ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))))
		AND actualdate >=   convert(date, convert(varchar(10), @ReportMonth  ) + '/01/'+  convert(varchar(10),@ReportYear -1))
		AND CalendarDayOfWeekLabel = 'Sunday'
)
, LastTwoWeekendsCurentMoOnePrior AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysCurrentMoOnePrior t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysCurrentMoOnePrior t1
	)

	--#FullAttendanceCurrentMoOnePrior

	    SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastTwoWeekendsCurentMoOnePrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into  #FullAttendanceCurrentMoOnePrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsCurentMoOnePrior 
		ON FactAttendance.InstanceDateID = LastTwoWeekendsCurentMoOnePrior.DateID
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
		LastTwoWeekendsCurentMoOnePrior.ActualDate 
		-- and  t2.Name LIKE '%Kids Weekend')

--One Year Prior YTD
		
;with  LastNSundaysYTDOnePrior AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -1))))
		AND actualdate >=  '01/01/'+  convert(varchar(10),@ReportYear -1) 
		AND CalendarDayOfWeekLabel = 'Sunday'
)
 , LastTwoWeekendsYTDOnePrior AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysYTDOnePrior t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysYTDOnePrior t1
	)

	--#FullAttendanceYTDOnePrior
	SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastTwoWeekendsYTDOnePrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into  #FullAttendanceYTDOnePrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsYTDOnePrior 
		ON FactAttendance.InstanceDateID = LastTwoWeekendsYTDOnePrior.DateID
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
		LastTwoWeekendsYTDOnePrior.ActualDate
	

			---------------------------------Two Years Prior
	--Two Years Prior Current Month

; WITH LastNSundaysCurrentMoTwoPrior AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10), @ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -2))))
		AND actualdate >=   convert(date, convert(varchar(10), @ReportMonth  ) + '/01/'+  convert(varchar(10),@ReportYear -2))
		AND CalendarDayOfWeekLabel = 'Sunday'
)

, LastTwoWeekendsCurentMoTwoPrior AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysCurrentMoTwoPrior t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysCurrentMoTwoPrior t1
	)

	--#FullAttendanceCurrentMoTwoPrior

		SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastTwoWeekendsCurentMoTwoPrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into  #FullAttendanceCurrentMoTwoPrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsCurentMoTwoPrior 
		ON FactAttendance.InstanceDateID = LastTwoWeekendsCurentMoTwoPrior.DateID
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
		LastTwoWeekendsCurentMoTwoPrior.ActualDate

--Two Years Prior YTD
		

;with  LastNSundaysYTDTwoPrior AS (
	SELECT ActualDate, DateID
	FROM DW.DimDate
	WHERE
	--DateID <= 20150228 and DateID >= 20150101 
		actualdate  <=    DATEADD(d,-1, (convert(date, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear -2))))
		AND actualdate >=  '01/01/'+  convert(varchar(10),@ReportYear -2) 
		AND CalendarDayOfWeekLabel = 'Sunday'
)

 , LastTwoWeekendsYTDTwoPrior AS (
	SELECT 'Current Week'  AS SectionName, t1.ActualDate, DateID FROM LastNSundaysYTDTwoPrior t1
	UNION 
	SELECT   'Previous Week'  AS SectionName, t1.ActualDate, CONVERT(VARCHAR(8), dateadd(d,-1,convert(date,convert(varchar(8),DateID))), 112)  FROM LastNSundaysYTDTwoPrior t1
	)

	--into #FullAttendanceYTDTwoPrior

			SELECT DISTINCT              
		'CURRENT' AS TimePeriod
		, LastTwoWeekendsYTDTwoPrior.ActualDate AS WeekendDate
		, SUM(FactAttendance.AttendanceCount) AS AttendanceCount
		into  #FullAttendanceYTDTwoPrior
	FROM DW.FactAttendance
	INNER JOIN LastTwoWeekendsYTDTwoPrior 
		ON FactAttendance.InstanceDateID = LastTwoWeekendsYTDTwoPrior.DateID
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
		LastTwoWeekendsYTDTwoPrior.ActualDate

	-----------------------Select all totals
	------------------------------
	;
  
  with final_table as
  (SELECT YEAR(fa.WeekendDate) as Year  
	, (SUM(fa.AttendanceCount) / COUNT(DISTINCT(fa.WeekendDate))) as CurrentMonth
	, (
		SELECT (SUM(fa.AttendanceCount) / COUNT(DISTINCT(fa.WeekendDate))) as CurrentMonth
		FROM #FullAttendanceYTD fa
		GROUP BY YEAR(fa.WeekendDate)
	) AS YTD
	FROM #FullAttendanceCurrent fa
	group by YEAR(fa.WeekendDate) --, month(fa.WeekendDate)

	UNION  --One Year Prior

	SELECT YEAR(fa.WeekendDate) as Year  
	, (SUM(fa.AttendanceCount) / COUNT(distinct(fa.WeekendDate))) as CurrentMonth
	, (
		SELECT (SUM(fa.AttendanceCount) / COUNT(DISTINCT(fa.WeekendDate))) as CurrentMonth
		FROM #FullAttendanceYTDOnePrior fa
		GROUP BY YEAR(fa.WeekendDate)
	) AS YTD
	FROM #FullAttendanceCurrentMoOnePrior fa
	GROUP BY  year(fa.WeekendDate) --, month(fa.WeekendDate)

	UNION  --Two Years Prior
	
	SELECT YEAR(fa.WeekendDate) as Year  
	, (SUM(fa.AttendanceCount) / COUNT(distinct(fa.WeekendDate))) as CurrentMonth
	, (
		SELECT (SUM(fa.AttendanceCount) / COUNT(DISTINCT(fa.WeekendDate))) as CurrentMonth
		FROM #FullAttendanceYTDTwoPrior fa
		GROUP BY YEAR(fa.WeekendDate)
	) AS YTD
	FROM #FullAttendanceCurrentMoTwoPrior fa
	GROUP BY  year(fa.WeekendDate) --, month(fa.WeekendDate)
)
  
      select 
      'Current Month' as status
      ,(select CurrentMonth from final_table where Year = @ReportYear - 2) as '2 Years Prior'
      ,(select CurrentMonth from final_table where Year = @ReportYear - 1) as '1 Year Prior'
      ,(select CurrentMonth from final_table where Year = @ReportYear) as '[Calendar_Year]'
    union
    select 
      'YTD'
      ,(select YTD from final_table where Year = @ReportYear - 2) as '2014'
      ,(select YTD from final_table where Year = @ReportYear - 1) as '2015'
      ,(select YTD from final_table where Year = @ReportYear) as '2016'
  
drop table #FullAttendanceCurrent
drop table #FullAttendanceYTD
drop table #FullAttendanceCurrentMoOnePrior
drop table #FullAttendanceYTDOnePrior
drop table #FullAttendanceCurrentMoTwoPrior
drop table #FullAttendanceYTDTwoPrior