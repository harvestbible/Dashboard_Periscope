DECLARE @BudgetYear int = [Calendar_Year|datepart(yy, getdate())]
DECLARE @BudgetMonth int = [Calendar_Month|datepart(mm, getdate())]

select *, 'Actual Burn', month_name+'-'+right(BudgetYear, 2) from [actualexpenseforhbflinechart2_cumulative]
union
select *, 'Budget', month_name+'-'+right(BudgetYear,2) from [projectedexpenseforhbflinechart2_cumulative]