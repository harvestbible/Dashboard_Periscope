DECLARE @FiscalYear INT = [Calendar_Year|2016]
	DECLARE @FiscalYear_Prev INT = @FiscalYear -1
	, @CalendarMonth varchar(2) = [Calendar_Month|6]

; WITH witwExpense AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	--, [StaffCode]
	--, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum

	FROM [Analytics].[DW].[FactExpense] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear --year(getdate())
	AND t2.EntityCode  = 'WITW'
	
	AND
	(
		(fundcode = '025'  --for WITW only, department is loaded into "staff code"
		AND [StaffCode]  IN ( '5055', '5158', '5160', '5163', '6207' , '6217', '5162', '7217', '5178', '5180', '7219'
		, '4106', '4056', '4036', '5038', '4016', '5058', '4096', '5078', '5098', '5138' ))
		OR
		(fundcode = '086')
	)
	

	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] --, [StaffCode] --, [DepartmentCode]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)

--select * from witwexpense


	, WITWexpensesother as (
		SELECT     t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
		, SUM(t1.amount) as Amount
		FROM [DW].[FactFinancialOther] T1
		INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
		ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
		INNER JOIN [Analytics].DW.DimDate T3
		ON t1.DateID = t3.DateID
		WHERE  t3.[FiscalYear] = @FiscalYear 
		AND fundcode = '086'
		AND GLCode in ('15151', '15146' )
		and t2.entitycode = 'WITW'
		
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] 
		)

	--select * from WITWexpensesother

	,  ExpensesAll AS
	 (
	select  [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], Amount from witwexpense
	UNION ALL
	select [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], Amount from WITWexpensesother
	)

--Select * from ExpensesAll

,  ExpensesAllSummary AS
	 (
	SELECT  [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], SUM(Amount) as Amount
	,  ROW_NUMBER() OVER(ORDER BY [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth]) AS RowNum
	FROM ExpensesAll
	GROUP BY   [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth]
	 )

,  witwRevenue AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum
	
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear --year(getdate())
	--AND t4.Code = 'witw'
	AND t2.EntityCode  = 'WITW'
	AND fundcode in ('025', 086)
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	),
	
	--Select * from ExpensesAllSummary
curr_result_table as
( 
   /* Current Year Expense Total */
	SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name, Amount --, [StaffCode]
	,	(SELECT SUM(tc.Amount) from ExpensesAllSummary tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
	, 'EXPENSE' as segment
  , 'CURR' as window
  FROM ExpensesAllSummary tr
  JOIN [month_map] on CalendarMonth = month_map.month_num

union

   /* Current Year Revenue Total */
SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name, Amount
	,	(SELECT SUM(tc.Amount) from witwRevenue tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
	, 'REVENUE'
  , 'CURR'
  FROM witwRevenue tr
  JOIN [month_map] on CalendarMonth = month_map.month_num
)
/* ******************************************************************************************************* */
, witwExpense_prev AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	--, [StaffCode]
	--, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum

	FROM [Analytics].[DW].[FactExpense] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear_Prev --year(getdate())
	AND t2.EntityCode  = 'WITW'
	
	AND
	(
		(fundcode = '025'  --for WITW only, department is loaded into "staff code"
		AND [StaffCode]  IN ( '5055', '5158', '5160', '5163', '6207' , '6217', '5162', '7217', '5178', '5180', '7219'
		, '4106', '4056', '4036', '5038', '4016', '5058', '4096', '5078', '5098', '5138' ))
		OR
		(fundcode = '086')
	)
	

	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] --, [StaffCode] --, [DepartmentCode]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)

--select * from witwexpense


	, WITWexpensesother_prev as (
		SELECT     t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
		, SUM(t1.amount) as Amount
		FROM [DW].[FactFinancialOther] T1
		INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
		ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
		INNER JOIN [Analytics].DW.DimDate T3
		ON t1.DateID = t3.DateID
		WHERE  t3.[FiscalYear] = @FiscalYear_Prev 
		AND fundcode = '086'
		AND GLCode in ('15151', '15146' )
		and t2.entitycode = 'WITW'
		
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] 
		)

	--select * from WITWexpensesother

	,  ExpensesAll_prev AS
	 (
	select  [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], Amount from witwexpense_prev
	UNION ALL
	select [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], Amount from WITWexpensesother_prev
	)

--Select * from ExpensesAll

,  ExpensesAllSummary_prev AS
	 (
	SELECT  [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth], SUM(Amount) as Amount
	,  ROW_NUMBER() OVER(ORDER BY [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth]) AS RowNum
	FROM ExpensesAll_prev
	GROUP BY   [FiscalYear], [FiscalMonth], [CalendarYear], [CalendarMonth]
	 )

,  witwRevenue_prev AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum
	
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear_Prev --year(getdate())
	AND t2.EntityCode  = 'WITW'
	AND fundcode in ('025', 086)
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)
	
	--Select * from ExpensesAllSummary


, result_table as
  (
    /* Previous Year Expense Total */
    SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name,  Amount --, [StaffCode]
	,	(SELECT SUM(tc.Amount) from ExpensesAllSummary_prev tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
  , 'EXPENSE' as segment
  , 'PREV' as window
	FROM ExpensesAllSummary_prev tr
  JOIN [month_map] on CalendarMonth = month_map.month_num

union

/* Previous Year Revenue Total */

	SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name,  Amount
	,	(SELECT SUM(tc.Amount) from witwRevenue_prev tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
 	, 'REVENUE'
  , 'PREV' as window
  FROM witwRevenue_prev tr
  JOIN [month_map] on [CalendarMonth] = month_map.month_num
  )

, final_result_table as
(select * from result_table
 union
 select * from curr_result_table
 ) 

select 
'Rev' as 'WITW US', 
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'REVENUE' and window = 'PREV') as '1 Year Prior', 
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'REVENUE' and window = 'CURR') as '[Calendar_Year]'

union

select 
'Exp', 
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'EXPENSE' and window = 'PREV'),
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'EXPENSE' and window = 'CURR')

union

select
'Net Income',
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'REVENUE' and window = 'PREV') - (select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'EXPENSE' and window = 'PREV'),
(select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'REVENUE' and window = 'CURR') - (select CumulativeSum from final_result_table where CalendarMonth = @CalendarMonth and segment = 'EXPENSE' and window = 'CURR')