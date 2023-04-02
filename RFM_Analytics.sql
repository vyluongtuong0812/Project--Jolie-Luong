
-- Inspecting Data
select * from [dbo].[Data_RFM]

--checking unique values
select distinct [STATUS] from [dbo].[Data_RFM] --(would be a nice one to plot)
select distinct [YEAR_ID] from [dbo].[Data_RFM] 
select distinct[PRODUCTLINE] from [dbo].[Data_RFM]
select distinct[COUNTRY] from [dbo].[Data_RFM]
select distinct [DEALSIZE] from [dbo].[Data_RFM]
select distinct [TERRITORY] from [dbo].[Data_RFM]

-- Analysis 

-- Analysis 1 - Sales by Product Line
select Productline, 
		sum(Sales) as Revenue
from [dbo].[Data_RFM]
group by Productline
order by 2 desc

-- Analysis 2 - Sales by Year
select YEAR_ID, 
		sum(Sales) as Revenue
from [dbo].[Data_RFM]
group by YEAR_ID
order by 2 desc

-- Analysis 3 - Sales by DealSize 
select DealSize, 
		sum(Sales) as Revenue
from [dbo].[Data_RFM]
group by DealSize
order by 2 desc

-- Analysis 4 - Best Month for Sales per Year 
select Month_ID, 
		sum(Sales) as Revenue,
		count(ordernumber) as frequency
from [dbo].[Data_RFM]
where YEAR_ID = 2003 --change year to see the rest
group by month_ID
order by 2 desc
-- November seems to be the best month]

-- Analysis 5 - What Product Line Sells Most in Best Month
select Month_ID, 
		sum(Sales) as Revenue,
		productline,
		count(ordernumber) as frequency
from [dbo].[Data_RFM]
where YEAR_ID = 2003 and month_id = 11 --change year to see the rest
group by Month_ID, productline
order by 2 desc
-- What product do they sells in November -- Classic Cars

-- RFM Explanation
-- Analysis 6 - Who is the Best Customer
drop table if exists #rfm;
with rfm as
(
	select 
			customername,
			sum(sales) as MonetaryValue,
			avg(sales) as AvgMonetaryvalue,
			count(ordernumber) as frequency,
			max(orderdate) as last_order_date,
			(select max(orderdate) from [dbo].[Data_RFM]) as max_order_date,
			datediff(DD, max(orderdate), (select max(orderdate) from [dbo].[Data_RFM])) as recency
	from [dbo].[Data_RFM]
	group by customername
),
rfm_calc as
(

	select r.*,
		NTILE(4) over (order by Recency desc) as rfm_recency,
		NTILE(4) over (order by frequency) as rfm_frequency,
		NTILE(4) over (order by Monetaryvalue) as rfm_monetary
	from rfm r
)
select c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
		cast(rfm_recency as varchar) 
		+ cast(rfm_frequency as varchar) 
		+ cast(rfm_monetary as varchar)
		as rfm_cell_string
into #rfm
from rfm_calc c 

select * from #rfm

select customername, rfm_recency, rfm_frequency, rfm_monetary,
		case
			when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers' 
			when rfm_cell_string in (133,134,143, 244,334,343,344,144,234) then 'slipping away, cannot lose'
			when rfm_cell_string in(311,411,331,421,221,412) then 'new customers'
			when rfm_cell_string in (222,223,233,322,232) then 'potential churners'
			when rfm_cell_string in (323,333,321,422,332,432,423) then 'active' -- customers who buy often & recently, but at low price points
			when rfm_cell_string in (433,434,443,444) then 'loyal'
		end rfm_segment
from #rfm

-- Analysis 7 - What Product Codes sell together
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[Data_RFM] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [dbo].[Data_RFM]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[Data_RFM] s
order by 2 desc

---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [dbo].[Data_RFM]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[Data_RFM]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc