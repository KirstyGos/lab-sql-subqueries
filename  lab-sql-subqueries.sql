USE sakila;

#only do join where necessary 

# 1. How many copies of the film Hunchback Impossible exist in the inventory system?
-- use table film, inventory
SELECT F.title, COUNT(I.inventory_id) AS num_films
FROM film AS F
INNER JOIN inventory AS I ON F.film_id = I.film_id
WHERE title = 'Hunchback Impossible';


# 2. List all films whose length is longer than the average of all the films.
-- use table film    
SELECT title, length, avg_length
FROM film, (
	SELECT ROUND(AVG(length)) AS avg_length
	FROM film
) AS film_avg
WHERE length > avg_length;

SELECT title, length, avg_length
FROM film
INNER JOIN (
	SELECT ROUND(AVG(length)) AS avg_length
	FROM film
) AS film_avg
WHERE length > avg_length;

# 3. Use subqueries to display all actors who appear in the film Alone Trip.
# use tables actor, film_actor and film

SELECT 
	A.actor_id,
    A.first_name,
    A.last_name,
    film_title.title
FROM actor A
INNER JOIN film_actor FA ON A.actor_id = FA.actor_id
INNER JOIN (
	SELECT title, film_id
    FROM film 
) AS film_title ON FA.film_id = film_title.film_id
WHERE film_title.title = 'Alone Trip';

# Correct solution, but expensive:
SELECT A.*
FROM actor A
WHERE EXISTS(
	SELECT TRUE
    FROM film_actor FA
    INNER JOIN film F ON F.film_id = FA.film_id
    WHERE F.title = 'Alone Trip'
    AND FA.actor_id = A.actor_id
);

# Better solution in practise:
SELECT A.*
FROM actor A
INNER JOIN film_actor FA USING (actor_id)
INNER JOIN film F USING (film_id)
WHERE F.title = 'Alone Trip';

# 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
# use table category
SELECT * FROM category;

SELECT C.name AS category, F.film_id, F.title
FROM category AS C
INNER JOIN film_category AS FA USING (category_id)
INNER JOIN film AS F USING (film_id)
WHERE C.name = 'Family';
	

# 5. Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.
#use tables customer -> address -> city -> country
SELECT COUNT(*) FROM country
WHERE country = 'Canada';


SELECT customer_id, first_name, last_name, email, country
FROM customer, (
	SELECT country
	FROM country
) AS country
WHERE country = 'Canada'
;

SELECT C.customer_id, C.first_name, C.last_name, C.email, CO.country
FROM customer AS C
INNER JOIN address AS B USING (address_id) 
INNER JOIN city AS CI USING (city_id)
INNER JOIN country AS CO USING (country_id)
GROUP BY C.customer_id
HAVING CO.country = 'Canada';

# 6. Which are the films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.
# need to count and then get max and list the films of the actor. How many films has actor been in, then list films
# use tables actor and film

SELECT title, MPA.* FROM film
INNER JOIN film_actor AS FA2 ON FA2.film_id = film.film_id
INNER JOIN (
	SELECT COUNT(FA.film_id) AS film_count, A.first_name, A.last_name, actor_id
	FROM film_actor AS FA
	INNER JOIN actor AS A USING (actor_id)
	GROUP BY A.actor_id
	ORDER BY film_count DESC
	LIMIT 1
) AS MPA ON FA2.actor_id = MPA.actor_id;

SELECT COUNT(FA.film_id) AS film_count, A.first_name, A.last_name, actor_id
FROM actor AS A
INNER JOIN film_actor AS FA USING (actor_id)
GROUP BY actor_id
ORDER BY film_count DESC
LIMIT 1;

# 7. Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments.

-- query to get the most profitable customer
SELECT C.customer_id, C.first_name, C.last_name, ROUND(SUM(P.amount)) AS sum_payments
FROM customer AS C 
INNER JOIN payment AS P USING (customer_id)
GROUP BY customer_id
ORDER BY sum_payments DESC
LIMIT 1;

SELECT film.* 
FROM film
INNER JOIN inventory USING (film_id)
INNER JOIN rental USING (inventory_id)
INNER JOIN	(
	SELECT C.customer_id, C.first_name, C.last_name, ROUND(SUM(P.amount)) AS sum_payments
	FROM customer AS C 
	INNER JOIN payment AS P USING (customer_id)
	GROUP BY customer_id
	ORDER BY sum_payments DESC
	LIMIT 1
) AS mpc USING (customer_id);


# 8. Get the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client.

-- find total amount spent per client 
SELECT SUM(p.amount) AS total_amount, c.customer_id
FROM customer AS c 
INNER JOIN payment AS p USING (customer_id)
GROUP BY customer_id;

-- find customer_id and total_amount of customers who spent more than the average
SELECT AVG(total_amount) AS avg_payments
FROM (
	SELECT SUM(p.amount) AS total_amount, c.customer_id
	FROM customer AS c 
	INNER JOIN payment AS p USING (customer_id)
	GROUP BY customer_id
) AS total_payments;

-- find customer_id and total_amount of customers with more than average amount
SELECT customer_id, total_amount
FROM customer 
INNER JOIN (
	SELECT AVG(total_amount) AS avg_payments
	FROM (
		SELECT SUM(p.amount) AS total_amount, c.customer_id
		FROM customer AS c 
		INNER JOIN payment AS p USING (customer_id)
		GROUP BY customer_id
	) AS total_payments
) AS atp
INNER JOIN ( 
	SELECT SUM(p.amount) AS total_amount, c.customer_id
	FROM customer AS c 
	INNER JOIN payment AS p USING (customer_id)
	GROUP BY customer_id
) AS amounts USING (customer_id)
WHERE total_amount > avg_payments;

-- Without a second subquery
SELECT customer_id, total_amount
FROM customer 
INNER JOIN (
	SELECT SUM(p.amount) / COUNT(DISTINCT customer_id) AS avg_payments
	FROM customer AS c 
	INNER JOIN payment AS p USING (customer_id)
) AS atp
INNER JOIN ( 
	SELECT SUM(p.amount) AS total_amount, c.customer_id
	FROM customer AS c 
	INNER JOIN payment AS p USING (customer_id)
	GROUP BY customer_id
) AS amounts USING (customer_id)
WHERE total_amount > avg_payments;