use projects;
select * from sharktank;

-- 1. What are the most common industries for startups across all seasons?
select Industry, count(*) as Number_of_Startups from sharktank
group by Industry order by Number_of_Startups desc;

-- 2. Which season had the highest total deal amount?
select season_number, sum(total_deal_amount_in_lakhs) as total_deal_amount
from sharktank group by season_number
order by total_deal_amount desc limit 1;

-- 3. What is the average valuation requested for each industry?
select industry, avg(valuation_requested_in_lakhs) as avg_valuation
from sharktank group by industry
order by avg_valuation desc;

-- 4. Who is the most frequent shark on the panel?
select shark, count(*) as present
from 
(
        select 'Namita' as shark from sharktank where namita_present = 'Yes'
        union all
        select 'vineeta' from sharktank where vineeta_present = 'Yes'
        union all
        select 'anupam' from sharktank where anupam_present = 'Yes'
        union all
        select 'aman' from sharktank where aman_present = 'Yes'
        union all
        select 'peyush' from sharktank where peyush_present = 'Yes'
        union all
        select 'amit' from sharktank where amit_present = 'Yes'
        union all
        select 'ashneer' from sharktank where ashneer_present = 'Yes'
    ) as present
group by shark order by present desc;

-- 5. How many deals were accepted in each season?
select season_number, count(*) as deals_accepted
from sharktank where accepted_offer = 'Yes'
group by season_number order by season_number;

-- 6. What is the percentage of startups led by male, female, and mixed-gender presenters?
select case 
	when male_presenters > 0 and female_presenters = 0 then 'male only'
	when female_presenters > 0 and male_presenters = 0 then 'female only'
	else 'mixed gender'
end as presenter_type,count(*) as startup_count,
round(count(*) * 100.0 / (select count(*) from sharktank), 2) as percentage
from sharktank group by presenter_type;

-- 7. Which city has produced the most startups?
select pitchers_city, count(*) as number_of_startups
from sharktank group by pitchers_city
order by number_of_startups desc
limit 1;

-- 8. What percentage of pitches resulted in deals for each season?
select season_number, 
round(sum(case when accepted_offer = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as deal_percentage
from sharktank group by season_number
order by season_number;

-- 9. You Team have to  promote shark Tank India  season 4, The senior come up with the idea to show highest funding domain wise  and 
-- you were assigned the task to  show the same.
select * from sharktank;

select * from (
select Industry,total_Deal_amount_in_lakhs ,row_number() over ( partition by industry 
order by  total_Deal_amount_in_lakhs desc) as rnk
from sharktank 
)t
where rnk = 1;

-- 10. You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70%
select *,((female/male)*100) as Ratio from (
select Industry,sum(Female_Presenters) as female ,sum(Male_Presenters) as male from sharktank
group by Industry having sum(Female_Presenters)>0 and sum(male_Presenters)>0
)t
where ((female/male)*100) >70;

-- 11 You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per season sale pitch made, 
-- pitches who received offer and pitches that were converted. Also show the percentage of pitches converted and percentage of pitches 
-- received.
select t.season_number , t.total ,Received_Offer , ((Received_Offer/total)*100) as 'received_%', Accepted_Offer,
((Accepted_Offer/total)*100) as 'Accepted_%' 
 from
(
select season_number,count(startup_name) as'total' from sharktank group by season_Number 
)t 
inner join
(
select season_number,count(startup_name) as Received_Offer from sharktank where Received_Offer = 'Yes' group by season_Number
)a on
t.season_number = a.season_number
inner join 
(
select season_number,count(startup_name) as Accepted_Offer from sharktank where Accepted_Offer = 'Yes' group by season_Number
)b on 
a.season_number = b.season_number;

-- 12 As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, how would you 
-- determine the season with the highest average monthly sales and identify the top 5 industries with the highest average monthly sales 
-- during that season to optimize investment decisions?
set @season = ( select season_number from 
(
select season_number , round(avg(Monthly_Sales_in_lakhs),2) as 'average' from sharktank group by season_number
)a order by average desc limit 1 );

select industry , round(avg(monthly_sales_in_lakhs),2) as average from  sharktank where season_number = @season 
group by industry order by average desc
limit 5

-- 13.As a data scientist at our firm, your role involves solving real-world challenges like identifying industries with consistent
 -- increases in funds raised over multiple seasons. This requires focusing on industries where data is available across all three years.
--  Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number of pitches made, offers received
-- and offers converted per season within each industry.

select season_number,industry,round(sum(Total_Deal_Amount_in_lakhs),2) as 'total' 
from sharktank group by season_number,industry

with cte as (
select industry ,
sum(case when season_number = 1 then total_deal_amount_in_lakhs end) as season_1,
sum(case when season_number = 2 then total_deal_amount_in_lakhs end) as season_2,
sum(case when season_number = 3 then total_deal_amount_in_lakhs end) as season_3
from sharktank group by industry
having season_3 > season_2 and season_2 > season_1 and season_1 != 0
)

-- select * from sharktank as t  inner join cte as c on t.industry= c.industry

select t.season_number,t.industry,count(t.startup_Name) AS Total,
    count(case when t.received_offer = 'Yes' then t.startup_Name end) AS Received,
    count(case when t.accepted_offer = 'Yes' then t.startup_Name end) AS Accepted
from sharktank as t join cte as c on t.industry = c.industry
group by t.season_number, c.industry;  

-- 14. Every shark want to  know in how much year their investment will be returned, so you have to create a system for them , where 
-- shark will enter the name of the startup's  and the based on the total deal and quity given in how many years their principal amount 
-- will be returned.

delimiter //
create procedure TOT( in startup varchar(100))
begin
   case 
      when (select Accepted_offer ='No' from sharktank where startup_name = startup)
	        then  select 'Turn Over time cannot be calculated';
	 when (select Accepted_offer ='yes' and Yearly_Revenue_in_lakhs = 'Not Mentioned' from sharktank where startup_name= startup)
           then select 'Previous data is not available';
	 else
         select `startup_name`,`Yearly_Revenue_in_lakhs`,`Total_Deal_Amount_in_lakhs`,`Total_Deal_Equity_%`, 
         `Total_Deal_Amount_in_lakhs`/((`Total_Deal_Equity_%`/100)*`Yearly_Revenue_in_lakhs`) as 'years'
		 from sharktank where Startup_Name= startup;
	
    end case;
end
//
DELIMITER ;


call tot('BluePineFoods');

-- 15. In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks," tends to put 
-- the most money into each deal on average. This comparison helps us see who's the most generous with their investments and how they
--  measure up against their fellow investors.

select * from sharktank;
select sharkname, round(avg(investment),2)  as 'average' from
(
SELECT `Namita_Investment_Amount_in lakhs` AS investment, 'Namita' AS sharkname FROM sharktank WHERE `Namita_Investment_Amount_in lakhs` > 0
union all
SELECT `Vineeta_Investment_Amount_in_lakhs` AS investment, 'Vineeta' AS sharkname FROM sharktank WHERE `Vineeta_Investment_Amount_in_lakhs` > 0
union all
SELECT `Anupam_Investment_Amount_in_lakhs` AS investment, 'Anupam' AS sharkname FROM sharktank WHERE `Anupam_Investment_Amount_in_lakhs` > 0
union all
SELECT `Aman_Investment_Amount_in_lakhs` AS investment, 'Aman' AS sharkname FROM sharktank WHERE `Aman_Investment_Amount_in_lakhs` > 0
union all
SELECT `Peyush_Investment_Amount_in_lakhs` AS investment, 'peyush' AS sharkname FROM sharktank WHERE `Peyush_Investment_Amount_in_lakhs` > 0
union all
SELECT `Amit_Investment_Amount_in_lakhs` AS investment, 'Amit' AS sharkname FROM sharktank WHERE `Amit_Investment_Amount_in_lakhs` > 0
union all
SELECT `Ashneer_Investment_Amount` AS investment, 'Ashneer' AS sharkname FROM sharktank WHERE `Ashneer_Investment_Amount` > 0
)a group by sharkname

-- 16. Develop a system that accepts inputs for the season number and the name of a shark. The procedure will then provide detailed 
-- insights into the total investment made by that specific shark across different industries during the specified season. Additionally, 
-- it will calculate the percentage of their investment in each sector relative to the total investment in that year, giving a 
-- comprehensive understanding of the shark's investment distribution and impact.

delimiter //
create procedure getdetails(in season int, in sharkname varchar(100))
begin
    case
        when sharkname = 'Namita' then
            set @total = (select  sum(`Namita_Investment_Amount_in lakhs`) from sharktank where Season_Number= season );
            select Industry, sum(`Namita_Investment_Amount_in lakhs`) as 'sum' ,(sum(`Namita_Investment_Amount_in lakhs`)/@total)*100 as 'Percent' from sharktank where season_Number = season and `Namita_Investment_Amount_in lakhs` > 0
            group by industry;
        when sharkname = 'Vineeta' then
			set @total = (select  sum(`Vineeta_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
            select industry,sum(`Vineeta_Investment_Amount_in_lakhs`) as 'sum' , (sum(`Vineeta_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent'from sharktank where season_Number = season and `Vineeta_Investment_Amount_in_lakhs` > 0
            group by industry;
        when sharkname = 'Anupam' then
			set @total = (select  sum(`Anupam_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
            select industry,sum(`Anupam_Investment_Amount_in_lakhs`) as 'sum' , (sum(`Anupam_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent' from sharktank where season_Number = season and `Anupam_Investment_Amount_in_lakhs` > 0
            group by Industry;
        when sharkname = 'Aman' then
			set @total = (select  sum(`Aman_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
            select industry,sum(`Aman_Investment_Amount_in_lakhs`) as 'sum',(sum(`Aman_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent'  from sharktank where season_Number = season and `Aman_Investment_Amount_in_lakhs` > 0
             group by Industry;
        when sharkname = 'Peyush' then
			set @total = (select  sum(`Peyush_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
             select industry,sum(`Peyush_Investment_Amount_in_lakhs`) as 'sum' , (sum(`Peyush_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent' from sharktank where season_Number = season and `Peyush_Investment_Amount_in_lakhs` > 0
             group by Industry;
        when sharkname = 'Amit' then
			set @total = (select  sum(`Amit_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
              select industry,sum(`Amit_Investment_Amount_in_lakhs`) as 'sum' , (sum(`Amit_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent' from sharktank where season_Number = season and `Amit_Investment_Amount_in_lakhs` > 0
             group by Industry;
        when sharkname = 'Ashneer' then
			set @total = (select  sum(`Ashneer_Investment_Amount`) from sharktank where Season_Number= season );
            select industry,sum(`Ashneer_Investment_Amount`) , (sum(`Ashneer_Investment_Amount`)/@total)*100 as 'Percent' from sharktank where season_Number = season and `Ashneer_Investment_Amount` > 0
             group by Industry;
        else
            select 'Invalid shark name';
    end case;
end //
delimiter ;
call getdetails(2, 'Namita')

-- 17. In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio across various industries. 
-- By examining their investment patterns and preferences, we aim to uncover any discernible trends or strategies that may shed light on their decision-making
-- processes and investment philosophies.

select sharkname, 
count(distinct industry) as 'unique industy',
count(distinct concat(pitchers_city,' ,', pitchers_state)) as 'unique locations' from 
(
		SELECT Industry, Pitchers_City, Pitchers_State, 'Namita'  as sharkname from sharktank where  `Namita_Investment_Amount_in lakhs` > 0
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Vineeta'  as sharkname from sharktank where `Vineeta_Investment_Amount_in_lakhs` > 0
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam'  as sharkname from sharktank where  `Anupam_Investment_Amount_in_lakhs` > 0 
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Aman'  as sharkname from sharktank where `Aman_Investment_Amount_in_lakhs` > 0
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Peyush'  as sharkname from sharktank where   `Peyush_Investment_Amount_in_lakhs` > 0
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Amit'  as sharkname from sharktank where `Amit_Investment_Amount_in_lakhs` > 0
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam'  as sharkname from sharktank where  `Anupam_Investment_Amount_in_lakhs` > 0 
		union all
		SELECT Industry, Pitchers_City, Pitchers_State, 'Ashneer'  as sharkname from sharktank where `Ashneer_Investment_Amount` > 0
)t  
group by sharkname 
order by  'unique industry' desc ,'unique location' desc
