DECLARE @BudgetYear int = [Calendar_Year|datepart(yy, getdate())]
DECLARE @BudgetMonth int = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(select 'YTD Actual Burn' as type, (select max(cumulative_actual_burn) from [actualexpenseforhbflinechart2_cumulative]) as value
union
 
select 'YTD Budget', (select max(cumulative_budget) from [projectedexpenseforhbflinechart2_cumulative] where BudgetMonth = @BudgetMonth)
union
 
select 'YTD Under/Over Burn',  (select max(cumulative_actual_burn) from [actualexpenseforhbflinechart2_cumulative]) - (select max(cumulative_budget) from [projectedexpenseforhbflinechart2_cumulative] where BudgetMonth = @BudgetMonth)
)
select * from t1
order by case when type = 'YTD Budget' then 1 when type = 'YTD Actual Burn' then 2 else 3 end