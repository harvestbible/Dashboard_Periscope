/*
Actual expenses for HCA LineChart2
*/
DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

select *, 'Budget', month_name+'-'+right(BudgetYear,2) from [projectedexpenseforhcalinechart2_cumulative]
union
select *, 'Actual Burn', month_name+'-'+right(CalendarYear,2) from [actualexpensesforhcalinechart2_cumulative]