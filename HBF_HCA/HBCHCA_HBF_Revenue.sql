DECLARE @BudgetYear int = [Calendar_Year|datepart(yy, getdate())]
DECLARE @BudgetMonth int = [Calendar_Month|datepart(mm, getdate())];

with t1 as (
   select 
   'YTD Budget Revenue' as Revenue_Type, 
    (select max(cumulative_budget) from [projectedrevenueforhbflinechart1_cumulative] where BudgetMonth = @BudgetMonth) as Revenue

union

select 
   'YTD Actual Revenue', 
   (select max(cumulative_actual) from [actualrevenueforhbflinechart1_cumulative]) 

union

select
   'YTD (Under) / Over Revenue',
   (select max(cumulative_actual) from [actualrevenueforhbflinechart1_cumulative]) -
    (select max(cumulative_budget) from [projectedrevenueforhbflinechart1_cumulative] where BudgetMonth = @BudgetMonth)
  )
select * from t1 
order by case when Revenue_Type = 'YTD Budget Revenue' then 1 when Revenue_Type = 'YTD Actual Revenue' then 2 else 3 end