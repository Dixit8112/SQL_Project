select * from dbo.credit_card_transactions;

select city, transaction_date , sum(amount) as total from dbo.credit_card_transactions group by city, transaction_date;

=========================================================================================================================

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte1 as (
select city, sum(amount) as total from dbo.credit_card_transactions group by city
), cte2 as (
select sum(cast(amount as bigint)) as total_spent from dbo.credit_card_transactions
) 
select top 5 cte1.*,   FORMAT(ROUND(total*1.0 / total_spent * 100, 2), 'N2')  as per_contribution from cte1 inner join cte2 on 1=1 order by total desc;


--2- write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type, datepart(month, transaction_date) as month, datepart(year, transaction_date) as year,  sum(amount) as total 
from dbo.credit_card_transactions 
group by card_type, datepart(month, transaction_date), datepart(year, transaction_date)
-- order by card_type, total desc
 )

select a.card_type, a.month, a.year, a.total from (select *, rank() over(partition by card_type order by total desc) as rn
from cte) a where rn=1;

--3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from dbo.credit_card_transactions
order by card_type ,total_spend desc

)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1;

--4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from dbo.credit_card_transactions 
group by city,card_type )
select 
top 1 city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio;

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city, exp_type, sum(amount) as total, rank() over(partition by city order by sum(amount) desc) as rn_desc  
, rank() over(partition by city order by sum(amount) ) as rn_asc
from dbo.credit_card_transactions group by city, exp_type )

select city, max(case when rn_asc=1 then exp_type end) as lowest_expense, min(case when rn_desc=1 then exp_type end) as lowest_expense from cte group by city;

--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type, format(sum(case when gender= 'F' then amount else 0 end)*1.0 / sum(amount),'N2' )  as f_contribution   from dbo.credit_card_transactions  
group by exp_type order by f_contribution ;

--7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type, datepart(month, transaction_date) as mnth, datepart(year, transaction_date) as years, sum(amount) as total
from dbo.credit_card_transactions --where datepart(month, transaction_date) = 1 and datepart(year, transaction_date) = 2014
group by card_type,exp_type, datepart(month, transaction_date), datepart(year, transaction_date) 
 ), cte2 as (
select *,lag(total,1) over(partition by card_type,exp_type order by years,mnth) as prev_mnth_spend
from cte )

select top 1 * ,  (total-prev_mnth_spend) as growth from cte2 where prev_mnth_spend is not null and years = 2014 and mnth = 1 order by growth desc;

--8- during weekends which city has highest total spend to total no of transcations ratio

select top 1 city, sum(amount)*1.0 /count(1) as ratio 
from dbo.credit_card_transactions 
where datepart(weekday, transaction_date) in (1,7)
group by city order by ratio desc ;

--select * , datepart(weekday, transaction_date) from dbo.credit_card_transactions where datepart(weekday, transaction_date) in (1,7);

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as(
select *, rank() over(partition by city order by transaction_date,transaction_id) as rn 
from dbo.credit_card_transactions  ),
cte2 as
(select city, max(case when rn=500 then transaction_date end) as maxd ,max(case when rn=1 then transaction_date end) as mind from cte group by city)
select top 1 city , datediff(day,mind,maxd) as days 
from cte2 where datediff(day,mind,maxd) is not null 
order by days ;


