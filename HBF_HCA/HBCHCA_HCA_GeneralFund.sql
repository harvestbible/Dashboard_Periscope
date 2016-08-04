DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(
select 'Fiscal YTD Actual Revenue'as type, max(cumulative_revenue) as value from [actualrevenueforhcalinechart1_cumulative]
union
select 'Fiscal YTD Actual Burn', max(actual_burn) from [actualexpensesforhcalinechart2_cumulative]
union
select 'Fiscal YTD Net Inc/(Loss)', (select max(cumulative_revenue) as value from [actualrevenueforhcalinechart1_cumulative]) - (select max(actual_burn) from [actualexpensesforhcalinechart2_cumulative])
)
select * from t1 
order by case when type = 'Fiscal YTD Actual Revenue' then 1 when type = 'Fiscal YTD Actual Burn' then 2 else 3 end