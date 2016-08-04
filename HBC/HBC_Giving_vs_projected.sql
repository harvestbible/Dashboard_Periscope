DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(select
  *, 'Actual' as legend, month_name+'-'+right(CalendarYear,2) as name
from
  [actualgivingforlinechart2_cumulative]
where CalendarMonth <= @ReportMonth

union 

select
  *, 'Projected', month_name+'-'+right(BudgetYear,2)
from
  [projectedgivingforlinechart2_cumulative]
 )
-- order by 2
select * from t1 order by case when legend = 'Projected Revenue' then 1 else 2 end