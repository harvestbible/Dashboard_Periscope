/*
Projected revenue for HCA line chart 1
*/

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

select *, 'Budget Revenue', month_name+'-'+right(BudgetYear,2) from [projectedrevenueforhcalinechart1_cumulative]
union
select *, 'Actual Revenue', month_name+'-'+right(CalendarYear,2) from [actualrevenueforhcalinechart1_cumulative]