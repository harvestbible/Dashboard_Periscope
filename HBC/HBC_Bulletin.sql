DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())];
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())];
DECLARE @NumSun TINYINT;
DECLARE @NumSunApril TINYINT;
DECLARE @BulletinAmount MONEY = 460000;
DECLARE @AprilAddAmount MONEY = 20000;
DECLARE @d1 DATETIME;
DECLARE @d2 DATETIME;
DECLARE @d3 DATETIME;
DECLARE @d4 DATETIME;
DECLARE @ytdbul MONEY;

select @d3 = '4-1-2016';
select @d4 = '4-30-2016';

select @d1 = CONVERT(datetime, '01/01/' +  CONVERT(VARCHAR(4), @ReportYear) )

--to get the date for the end of the period
select @d2 =  DATEADD(d,-1, (convert(datetime, convert(varchar(10),@ReportMonth +1 ) + '/01/'+  convert(varchar(10),@ReportYear))))

; with dates (date)
as
(
select @d1
union all
select dateadd(d,1,date)
from dates
where date < @d2
)

select @NumSun =   count(1) from dates where datename(dw, date) = 'sunday'
OPTION (MAXRECURSION 1000)
--select @NumSun 

;with datesApril (date)
as
(
select @d3
union all
select dateadd(d,1,date)
from datesApril
where date < @d4
)

select @NumSunApril =   count(1) from datesApril where datename(dw, date) = 'sunday'
OPTION (MAXRECURSION 1000)

--select @NumSunApril 
--SELECT @NumSun * @BulletinAmount AS YTDBulletin


SELECT  @ytdbul = CASE @ReportYear
WHEN 2016 THEN  
	CASE 
		WHEN @ReportMonth in (1, 2,3)  THEN  @NumSun * @BulletinAmount 
		WHEN @ReportMonth in (4,5,6,7,8,9,10, 11, 12) THEN  (@NumSun * @BulletinAmount) +  (@NumSunApril * @AprilAddAmount)
	END
ELSE
	 @NumSun * 440000

END --AS YTDBulletin

; with t1 as
(
select 'YTD Bulletin' as type, @ytdbul as value 

union
select 'YTD (Under)/Over Bulletin', (select cumulative_total
from [actualgivingforlinechart2_cumulative] where CalendarMonth = @ReportMonth) - (@ytdbul)
 )
select * from t1
order by case when type = 'YTD Bulletin' then 1 else 2 end