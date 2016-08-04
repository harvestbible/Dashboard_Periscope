DECLARE @BudgetYear  INT = [Calendar_Year|datepart(yy, getdate())];
DECLARE @BudgetMonth TINYINT =[Calendar_Month|datepart(mm, getdate())];
DECLARE @NumSun TINYINT,
@WeeklyBudgetAmount money = 460000,
 @BeginningDate DATETIME, @EndingDate DATETIME

-- SELECT @BeginningDate = '1-1-2016', @EndingDate = '12-31-2016';
SELECT @BeginningDate = concat('1-1-', @BudgetYear), @EndingDate = concat('12-31-', @BudgetYear);
WITH dates (date)
AS
(
SELECT @BeginningDate
UNION all
SELECT dateadd(d,1,date)
FROM dates
WHERE date < @EndingDate
)

--select * from dates
--select date from dates where datename(dw, date) = 'sunday'
--option (maxrecursion 1000)


SELECT  month(date) as BudgetMonth
, year(date) as BudgetYear
, count(1) as NumSundaysInMonth
,  count(1) * @WeeklyBudgetAmount as WeeklyBudgetAmount
into #t1
from dates d1 where datename(dw, date) = 'sunday'

group by year(date), month(date)
option (maxrecursion 1000)

--select * from #t1
select *  into #t2 
from  
(
select BudgetMonth, BudgetYear, month_map.month_name, 'Budget' as type
	, (select sum(d2.WeeklyBudgetAmount) from #t1 d2  where d2.BudgetMonth <= d1.BudgetMonth)  'CumulativeSum'
  , month_map.month_name+'-'+right(BudgetYear,2) as month_name_two

from #t1 d1
join [month_map] on BudgetMonth = month_map.month_num
union
     
select BudgetMonth, BudgetYear, month_name, 'Burn', sum(expense) over (order by BudgetYear, BudgetMonth rows unbounded preceding) as cumulative_sum, month_name+'-'+right(BudgetYear,2)
from
(
select BudgetMonth, BudgetYear,sum(expense) as expense
from
(
SELECT  t3.[CalendarMonth] as BudgetMonth, t3.[CalendarYear] as BudgetYear
, SUM(t1.amount) as Expense --, t2.GLCode 
	 
FROM [Analytics].[DW].[FactExpense] t1
INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
INNER JOIN [Analytics].DW.DimDate T3
ON t1.DateID = t3.DateID
INNER JOIN DW.DimEntity T4
ON t1.EntityID = t4.EntityID
   
WHERE  
t3.[CalendarYear] = @BudgetYear --(getdate())
AND t3.[CalendarMonth] <= @BudgetMonth  --month(getdate())  --3
--AND t3.[CalendarMonth] = @BudgetMonth  --month(getdate())  --3


AND t4.Code = 'HBC'
AND t2.fundcode = '025'  
AND t2.GLCode NOT IN ('30010', '30058', '30075', '30046', '90139', '90145', '90260')
AND t2.DepartmentCode <> '9120'
AND t2.TenantID = 3
GROUP BY  t3.[CalendarYear], t3.[CalendarMonth] --, t2.GLCode 
--order by t3.[CalendarYear], t3.[CalendarMonth] --, t2.GLCode 

UNION All
SELECT t3.[CalendarMonth] as BudgetMonth, t3.[CalendarYear] as BudgetYear
  , SUM(t1.amount) as Expense --, t2.GLCode 
FROM [DW].[FactFinancialOther] T1
INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
INNER JOIN [Analytics].DW.DimDate T3
ON t1.DateID = t3.DateID

WHERE  t3.[CalendarYear] = @BudgetYear 
AND t3.[CalendarMonth] <= @BudgetMonth 
and t2.entitycode = 'HBC'
AND t2.fundcode = '025'  
--AND t2.GLCode NOT IN ('30010', '30058', '30075', '30046')
AND t2.GLCode  IN ('24225', '24230', '24233',  '24235', '24272', '15026','15146','15151')

--AND t2.DepartmentCode <> '9120'
AND t2.TenantID = 3
GROUP BY  t3.[CalendarMonth], t3.[CalendarYear] --, t2.GLCode 

UNION All

SELECT t3.[CalendarMonth] as BudgetMonth, t3.[CalendarYear] as BudgetYear
  , -1 * SUM(t1.amount) as Expense
FROM [DW].[FactRevenue] T1
INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
INNER JOIN [Analytics].DW.DimDate T3
ON t1.DateID = t3.DateID

WHERE  t3.[CalendarYear] = @BudgetYear 
AND t3.[CalendarMonth] <= @BudgetMonth 
and t2.entitycode = 'HBC'
AND t2.fundcode = '025'  
--AND t2.GLCode  IN ('30010', '30058', '30075', '30046')

 AND t2.GLCode  IN ('30030','30042','31025','32010','32012','35115','35004', '37010','37020','37021','37025')
--AND t2.DepartmentCode = '9120'
AND t2.TenantID = 3
GROUP BY  t3.[CalendarMonth], t3.[CalendarYear]
 ) t2
  group by BudgetMonth, BudgetYear
) t3
JOIN [month_map] on t3.BudgetMonth = month_map.month_num
) t4

select * from
 (
select 'YTD Budget (460/wk)' as type, cumulativesum as value 
from #t2 
where BudgetMonth = @BudgetMonth and type = 'Budget'
  
union
  
select 'YTD Actual Burn', cumulativesum 
from #t2 
where BudgetMonth = @BudgetMonth and type = 'Burn'
  
union

 select 'YTD Under/(Over) Expenses', 
(select cumulativesum 
from #t2 
where BudgetMonth = @BudgetMonth and type = 'Budget') -
  (select cumulativesum 
from #t2 
where BudgetMonth = @BudgetMonth and type = 'Burn')
   ) t9
order by case when type = 'YTD Budget (460/wk)' then 1 when type = 'YTD Actual Burn' then 2 else 3 end 


  
drop table #t1
drop table #t2