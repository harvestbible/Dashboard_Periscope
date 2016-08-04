DECLARE @BudgetYear int = [Calendar_Year|datepart(yy, getdate())]
DECLARE @BudgetMonth int = [Calendar_Month|datepart(mm, getdate())];

with t1 as (
   select 
   'YTD Actual Revenue' as Type, 
   (select max(cumulative_actual) from [actualrevenueforhbflinechart1_cumulative]) as Value

union

select 
   'YTD Actual Burn' as type, 
   (select max(cumulative_actual_burn) from [actualexpenseforhbflinechart2_cumulative])
    
union
    
select
   'YTD Net Income / (Loss)',
   (select max(cumulative_actual) from [actualrevenueforhbflinechart1_cumulative]) -
   (select max(cumulative_actual_burn) from [actualexpenseforhbflinechart2_cumulative])
  )
select * from t1 
order by case when Type = 'YTD Actual Revenue' then 1 when Type = 'YTD Actual Burn' then 2 else 3 end