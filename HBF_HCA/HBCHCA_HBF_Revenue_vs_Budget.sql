DECLARE @BudgetYear int = [Calendar_Year|datepart(yy, getdate())]
DECLARE @BudgetMonth int = [Calendar_Month|datepart(mm, getdate())];

select *, 'Actual Revenue', month_name+'-'+right(CalendarYear,2)  from [actualrevenueforhbflinechart1_cumulative]

union

select *, 'Budget Revenue', month_name+'-'+right(BudgetYear,2)  from [projectedrevenueforhbflinechart1_cumulative]