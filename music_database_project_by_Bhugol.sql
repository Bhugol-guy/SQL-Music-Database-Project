# Music Database Project On MySQL #

create database music_database_project;
use music_database_project;

select * from album2;

-- who is the senoir most employee based on the job title ? --
select * from employee;
select last_name, first_name, levels from employee order by levels desc limit 1;

-- which countries has the most invoices --
select*from invoice;
select billing_country, count(*) as num_of_invoices from invoice group by billing_country order by num_of_invoices desc limit 1;

-- what are the top 3 values of total invoice --
select total as top_3_values from invoice order by total desc limit 3;

-- which city has the best customers? we would like to throw a promotional music frstival in the city we made the most money.
-- write a query that returns one city that has the highest sum of invoice total. --
-- return both the city name and sum of all invoice total --
select billing_city, round(sum(total)) as total_invoice from invoice group by billing_city order by total_invoice desc;

-- who is the best customer? the customer who has spent the most moneywill be 
# decleared the best customer. write a query that returns 
# the person who has spent the most money --

select* from customer order by country asc;
select first_name, last_name, count(*) as num from customer group by first_name,last_name;
select customer_id, count(*) as num from customer group by customer_id;

SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    round(SUM(invoice.total)) AS total_amount
FROM
    customer
        JOIN
    invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY total_amount DESC limit 10;

-- write a query to return the email, first name, last name and genre of rock music listners . 
# return your list,order alphabetically by email starting with A

select*from customer;
select*from genre;
select *from track;

select distinct customer.email, customer.first_name, customer.last_name
from customer join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on invoice_line.track_id=track.track_id where track.track_id in
(select track.track_id 
from track join genre 
on track.genre_id=genre.genre_id
 where genre.name like 'Rock')
order by customer.email asc;

-- Lets invite the artist who have written the most rock music in our dataset.  
# write a query that returns artist name and total track count of the top 10 rock bands --


select * from artist;

select artist.name, count(*) as total from artist join album2 on artist.artist_id=album2.artist_id
join track on album2.album_id=track.album_id where track.album_id in 
(select track.album_id from track join genre on track.genre_id=genre.genre_id where genre.name like 'Rock') 
group by artist.name order by total desc limit 10;

select artist.artist_id,artist.name,count(artist.artist_id) as number_of_songs
from track join album2 on album2.album_id = track.album_id 
join artist on artist.artist_id=album2.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name like '%Rock%'
group by artist.artist_id, artist.name
order by number_of_songs Desc
limit 10;

-- Return all the track names that have a song length longer than the average song length 
# return the name and the milisecond of each track. order the song length with tyhe longest song listed first --

select*from track; 
select name, milliseconds from track where milliseconds > (select avg(milliseconds) from track ) order by milliseconds desc;


-- ADVANCED --
-- Find how much amount spent by each customer on artists? write a query to return customer name , artist name and total spent --

select customer.first_name, artist.name, round(sum(invoice.total))as total_spent from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on invoice_line.track_id=track.track_id
join album2 on track.album_id=album2.album_id
join artist on album2.artist_id=artist.artist_id
group by customer.first_name,artist.name;

with best_selling_artist as 
( select artist.artist_id as artist_id, artist.name as artist_name, 
sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
from invoice_line 
join track on track.track_id=invoice_line.track_id
join album2 on album2.album_id=track.album_id
join artist on artist.artist_id=album2.artist_id 
group by artist_id, artist_name
order by total_sales desc
limit 1 )

select c.customer_id,c.first_name,c.last_name,bsa.artist_name,
sum(il.unit_price*il.quantity) as amount_spent 
from invoice as i
join customer as c on c.customer_id=i.customer_id
join invoice_line as il on il.invoice_id=i.invoice_id
join track as t on t.track_id=il.track_id
join album2 as alb on alb.album_id=t.album_id
join best_selling_artist as bsa on bsa.artist_id=alb.artist_id
group by 1,2,3,4
order by 5 desc;

-- we want to find the most popular music gerne by each country
# we determine the most popular gerne as the gerne with the highest amount of purchase
# write a query that returns each country with the top gerne
# For countries where maximum number of purchase is shared,return each gerne

with country_wise_purchase as 
(select customer.country as country, genre.name as genre_name, count(genre.name) as total_purchase_count from customer
join invoice on invoice.customer_id=customer.customer_id
join invoice_line on invoice_line.invoice_id=invoice.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
group by 1,2)

select country as most_popular_gerne, max(total_purchase_count) as total_purchase  
from country_wise_purchase
group by 1; 

with popular_genre as
(
select count(invoice_line.quantity) as purchase, customer.country, genre.name, genre.genre_id, 
row_number() over( partition by customer.country order by count(invoice_line.quantity) desc) as RowNo 
from invoice_line
join invoice on invoice.invoice_id = invoice_line.invoice_id
join customer on customer.customer_id = invoice.customer_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
group by 2,3,4
order by 2 asc,1 desc
)
select*from popular_genre where RowNo<=1;

-- write a query that determines the customer that has spent the most on music for each country
# write a query that returns the country along with the top customer and how much they spent
# for counties where top amount spent is shared , provide all customers who spent this amount 

with recursive
customer_with_country as (
select customer.customer_id, first_name, last_name, billing_country, sum_total as total_spending 
from invoice
join customer on customer.customer_id = invoice.customer-id
group by 1,2,3,4
order by 2,3 desc )

country_max_spending as (
select billing_country, max(total_spending) as max_spending
from customer_with_country
group by billing_country)

select cc.billing_country,cc.total_spending,cc.first_name,cc.last_name,cc.customer_id 
from customer_with_country as cc
join country_max_spending as ms
on cc.billing_country = ms.billing_country
where cc.total_spending=ms.max_spending
order by 1;






