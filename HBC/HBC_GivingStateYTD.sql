DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(
select 'YTD Proj Give (460/wk)' as type, max(projected_cumulative) as value
from [projectedgivingforlinechart2_cumulative]
where BudgetMonth = @ReportMonth
union
select 'YTD Actual Giving', max(cumulative_total) 
from [actualgivingforlinechart2_cumulative]
  where CalendarMonth = @ReportMonth
union select 'YTD (Under)/Over Giving', (select max(cumulative_total) from [actualgivingforlinechart2_cumulative]) - (select max(projected_cumulative) from [projectedgivingforlinechart2_cumulative] where BudgetMonth <= @ReportMonth)
)
select * from t1
order by case when type = 'YTD Proj Give (460/wk)' then 1 when type = 'YTD Actual Giving' then 2 else 3 end