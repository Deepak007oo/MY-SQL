
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_amountspent
from sales s
join menu m on s.product_id = m.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) 
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte as (
	select customer_id, order_date, s.product_id, product_name,
    dense_rank() over (partition by customer_id order by order_date ) as Rnk
from sales s join menu m on s.product_id = m.product_id
)
select customer_Id, product_name from cte
where Rnk = 1
group by customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(m.product_id) as most_purchased
from sales s join menu m on s.product_id=m.product_id
group by product_name, m.product_id
order by most_purchased desc
limit 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
    DENSE_RANK() OVER(
      PARTITION BY s.customer_id 
      ORDER BY COUNT(s.customer_id) DESC) AS rnk
  FROM menu m
  JOIN sales s
    ON m.product_id = s.product_id
  GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with cte as (
	select s.customer_id, product_id,
    row_number() over (partition by customer_id order by product_id) as row_num
	from sales s join members m on s.customer_id = m.customer_id and s.order_date > m.join_date
    group by s.customer_id, product_id
)

select customer_id, me.product_name  
from cte join menu me on cte.product_id =  me.product_id
where row_num = 1
order by customer_id;



-- 7. Which item was purchased just before the customer became a member?
with cte as(
select s.customer_id, s.product_id, s.order_date,
dense_rank() over (partition by customer_id order by s.order_date) as rnk
from sales s
join members m on s.customer_id = s.customer_id and s.order_date > m.join_date
group by s.customer_id, s.product_id, s.order_date
order by s.order_date
)

select customer_id, me.product_id, me.product_name
from cte c join menu me on c.product_id = me.product_id
where rnk =1
order by customer_id;
-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id) AS total_items, sum(m.price)
from sales s join menu m on s.product_id= m.product_id
join members me on s.customer_id =  me.customer_id
where s.order_date < me.join_date
group by s.customer_id
order by customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points_cte as(
select product_id,
case
	when product_id = 1 then price*20
    else price*10
End as Points    
    from menu
)

select s.customer_id, sum(pc.Points) as total_points
from points_cte pc join sales s on pc.product_id = s.product_id
group by customer_id
