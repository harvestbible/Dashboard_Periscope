DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth INT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(
select 'Fiscal YTD Actual Burn' as type, max(actual_burn) as value from [actualexpensesforhcalinechart2_cumulative]
union
select 'Fiscal YTD Budget', ytd_budget from [projectedexpenseforhcalinechart2_cumulative] where BudgetMonth = @ReportMonth
union
select 'YTD Under/(Over) Burn', (select ytd_budget from [projectedexpenseforhcalinechart2_cumulative] where BudgetMonth = @ReportMonth) - (select max(actual_burn) from [actualexpensesforhcalinechart2_cumulative]) 
)
select * from t1
order by case when type = 'Fiscal YTD Budget' then 1 when type = 'Fiscal YTD Actual Burn' then 2 else 3 end