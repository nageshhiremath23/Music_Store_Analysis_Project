#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#
		
											/*  BASIC QUERIES  */
        
/* Q1: Who is the senior most employee based on job title? */

select first_name, last_name, levels, address, city, country, email
from employee
order by levels Desc
limit 1;



/* Q2: Which countries have the most Invoices? */

select count(total) as Total,billing_country
from invoice
group by billing_country
order by Total DESC
limit 10; 



/* Q3: What are top 3 values of total invoice? */


select total
from invoice
order by total desc
limit 3;



/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select sum(total) as TOTAL,billing_city 
from invoice
group by billing_city
order by total DESC;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/


select customer.customer_id, customer.first_name, customer.last_name, sum(total) as Spent  
from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id, customer.first_name, customer.last_name
order by Spent DESC
limit 1;


#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#

										/*  MODEARATE QUERIES  */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */


select email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by email, first_name, last_name
order by email;


/*Method 2 */

select distinct email, first_name, last_name
from customer
join invoice
on customer.customer_id = invoice.customer_id
join invoice_line
on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
		select track_id from track
        join genre 
        on track.genre_id=genre.genre_id
        where genre.name LIKE 'Rock'
	)
order by email;



/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 5 rock bands. */


select artist.artist_id, artist.name, COUNT(artist.artist_id) as Total_Songs
from track
join album2
on track.album_id = album2.album_id
join artist
on artist.artist_id = album2.artist_id
join genre
on track.genre_id = genre.genre_id
where genre.name LIKE 'Rock'
group by artist.artist_id, artist.name
order by Total_Songs DESC
limit 5;


/* Q3: Return all the track names that have a song length longer than the average song length.                                '251177.7431'
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds
from track
where milliseconds >
		(
		select avg(milliseconds) as Track_Length 
		from track)
order by milliseconds DESC;



#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#==========#===========#============#============#=============#===========#============#=============#===============#===========#============#

												/*    Advance Queries   */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */   


WITH best_selling_artist AS (
	select artist.artist_id as artist_id, artist.name as artist_name, 
		SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
	from invoice_line
    join track on track.track_id = invoice_line.track_id
    join album2 on album2.album_id = track.album_id
    join artist on artist.artist_id = album2.artist_id
    group by artist.artist_id, artist.name
    order by total_sales DESC
    limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
	SUM(il.unit_price*il.quantity) AS amount_spent
from invoice  i
join customer  c on c.customer_id = i.customer_id
join invoice_line  il on il.invoice_id = i.invoice_id
join track  t on t.track_id = il.track_id
join album2  alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by  c.customer_id, c.first_name, c.last_name, bsa.artist_name
order by amount_spent DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

		/* Method 1: Using CTE */

with my_cte as (
	select count(invoice_line.quantity) as purchases, customer.country, genre.genre_id, genre.name,
    row_number() over(partition by customer.country  order by count(invoice_line.quantity) desc) as Row_No
	from invoice_line
    join invoice on invoice.invoice_id = invoice_line.invoice_id
    join customer on customer.customer_id = invoice.customer_id
    join track on track.track_id = invoice_line.track_id
    join genre on genre.genre_id = track.genre_id
    group by customer.country, genre.genre_id, genre.name
    order by customer.country  asc,purchases desc
)
select * from my_cte 
where Row_no<=1;

		/* Method 2: Using RECURSIVE */

with recursive sales_per_country as
(
	select count(*) as purchase_per_genre, customer.country, genre.name, genre.genre_id
    from invoice_line
    join invoice on invoice.invoice_id = invoice_line.invoice_id
    join customer on customer.customer_id = invoice.customer_id
    join track on track.track_id = invoice_line.track_id
    join genre on genre.genre_id = track.genre_id
    group by 2,3,4
    order by 2
),

	max_genre_per_country as 
		(select max(purchase_per_genre) as max_genre_number, country
        from sales_per_country
        group by 2
        order by 2)
        
	select sales_per_country.* 
    from sales_per_country
    join max_genre_per_country on max_genre_per_country.country = sales_per_country.country
    where sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number;
	

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: Using RECURSIVE */

with recursive customer_with_country as (
	select customer.customer_id, customer.first_name, customer.last_name, billing_country, sum(total) as total_spending
    from invoice
    join customer on customer.customer_id = invoice.customer_id
    group by 1,2,3,4
    order by 2,3 DESC ),
    
    country_max_spending as (
    select billing_country, max(total_spending) as max_spending
    from customer_with_country
    group by billing_country)

select cwc.billing_country, cwc.total_spending, cwc.first_name, cwc.last_name, cwc.customer_id
from customer_with_country as cwc
join country_max_spending as cms
on cwc.billing_country = cms.billing_country
where cwc.total_spending = cms.max_spending
order by 1;

/* Method 2: Using CTE */


with customer_with_country as (
	select customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spendng,
    row_number() over (partition by billing_country order by sum(total) desc) as Row_No
    from invoice
    join customer
    on customer.customer_id = invoice.customer_id
    group by 1,2,3,4
    order by 4 asc,5 desc)
    
select * from customer_with_country
where Row_No<=1;