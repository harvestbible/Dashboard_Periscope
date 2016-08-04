DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth INT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(
select 'Fiscal YTD Budget Revenue' as type, cumulative_budget as value from [projectedrevenueforhcalinechart1_cumulative] where BudgetMonth = @ReportMonth

union
select 'Fiscal YTD Actual Revenue', max(cumulative_revenue) from [actualrevenueforhcalinechart1_cumulative]

union

select 'YTD (Under) / Over Revenue', (select max(cumulative_revenue) from [actualrevenueforhcalinechart1_cumulative]) - (select cumulative_budget from [projectedrevenueforhcalinechart1_cumulative] where BudgetMonth = @ReportMonth) 
)
select * from t1
order by case when type = 'Fiscal YTD Budget Revenue' then 1 when type = 'Fiscal YTD Actual Revenue' then 2 else 3 end