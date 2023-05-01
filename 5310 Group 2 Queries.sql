/* 1. Find the total amount spent by each user on flights, car rentals, and hotels.  */
SELECT users.user_id, users.first_name, users.last_name,
       SUM(flight_seat.price) as total_flight_expenses,
       SUM(car_rental_reservation.total_price) as total_car_rental_expenses,
       SUM(hotel_reservations.total_price) as total_hotel_expenses
FROM users
LEFT JOIN flight_reservation ON users.user_id = flight_reservation.user_id
LEFT JOIN flight_seat ON flight_reservation.flight_seat_id = flight_seat.flight_seat_id
LEFT JOIN car_rental_reservation ON users.user_id = car_rental_reservation.car_id
LEFT JOIN hotel_reservations ON users.user_id = hotel_reservations.user_id
GROUP BY users.user_id, users.first_name, users.last_name;

/* 2. Find the top 5 most popular hotels based on the number of reservations:  */
SELECT hotels.hotel_id, hotels.hotel_name, COUNT(hotel_reservations.hotel_reservation_id) as reservation_count
FROM hotels
JOIN hotel_reservations ON hotels.hotel_id = hotel_reservations.hotel_id
GROUP BY hotels.hotel_id, hotels.hotel_name
ORDER BY reservation_count DESC
LIMIT 5;

/* 3. Find the most popular airlines based on the number of reservations:  */
SELECT airline.airline_id, airline.airline_name, COUNT(flight_reservation.flight_reservation_id) as reservation_count
FROM airline
JOIN flight ON airline.airline_id = flight.airline_id
JOIN flight_reservation ON flight.flight_id = flight_reservation.flight_id
GROUP BY airline.airline_id, airline.airline_name
ORDER BY reservation_count DESC;

/*  4. Analyzing the most popular city pair for flight reservations:    */
SELECT c1.city_name AS departure_city, c2.city_name AS arrival_city, COUNT(flight_reservation.flight_reservation_id) AS reservation_count
FROM flight_reservation
JOIN flight ON flight_reservation.flight_id = flight.flight_id
JOIN city c1 ON flight.departure_city_id = c1.city_id
JOIN city c2 ON flight.arrival_city_id = c2.city_id
GROUP BY departure_city, arrival_city
ORDER BY reservation_count DESC
LIMIT 10;

/*  5. Analyzing the average spending per user on flights, car rentals, and hotels:    */
SELECT users.user_id, users.first_name, users.last_name,
       AVG(CAST(flight_seat.price AS numeric)) as avg_flight_expenses,
       AVG(CAST(car_rental_reservation.total_price AS numeric)) as avg_car_rental_expenses,
       AVG(CAST(hotel_reservations.total_price AS numeric)) as avg_hotel_expenses
FROM users
LEFT JOIN flight_reservation ON users.user_id = flight_reservation.user_id
LEFT JOIN flight_seat ON flight_reservation.flight_seat_id = flight_seat.flight_seat_id
LEFT JOIN car_rental_orders ON users.user_id = car_rental_orders.order_id
LEFT JOIN car_rental_reservation ON car_rental_orders.car_rental_reservation_id = car_rental_reservation.car_rental_reservation_id
LEFT JOIN hotel_orders ON users.user_id = hotel_orders.order_id
LEFT JOIN hotel_reservations ON hotel_orders.hotel_reservation_id = hotel_reservations.hotel_reservation_id
GROUP BY users.user_id, users.first_name, users.last_name;


/* 6. Which users are likely to book hotel/flight/car rental from us?   */
WITH hotel_booking_count AS (
    SELECT
        users.user_id,
        COUNT(hotel_orders.hotel_reservation_id) AS hotel_reservation_count
    FROM
        users
        JOIN hotel_orders ON hotel_orders.order_id = users.user_id
    GROUP BY
        users.user_id
),
flight_booking_count AS (
    SELECT
        users.user_id,
        COUNT(order_flight.flight_reservation_id) AS flight_reservation_count
    FROM
        users
        JOIN order_flight ON order_flight.order_id = users.user_id
    GROUP BY
        users.user_id
),
car_rental_booking_count AS (
    SELECT
        users.user_id,
        COUNT(car_rental_orders.car_rental_reservation_id) AS car_rental_reservation_count
    FROM
        users
        JOIN car_rental_orders ON car_rental_orders.order_id = users.user_id
    GROUP BY
        users.user_id
)
SELECT
    users.user_id,
    COALESCE(hotel_booking_count.hotel_reservation_count, 0) AS hotel_bookings,
    COALESCE(flight_booking_count.flight_reservation_count, 0) AS flight_bookings,
    COALESCE(car_rental_booking_count.car_rental_reservation_count, 0) AS car_rental_bookings
FROM
    users
    LEFT JOIN hotel_booking_count ON users.user_id = hotel_booking_count.user_id
    LEFT JOIN flight_booking_count ON users.user_id = flight_booking_count.user_id
    LEFT JOIN car_rental_booking_count ON users.user_id = car_rental_booking_count.user_id
ORDER BY
    hotel_bookings DESC,
    flight_bookings DESC,
    car_rental_bookings DESC;

/* 7. Find ​​the top 10 users who spent the most in hotels in the year 2019. */
SELECT
  users.user_id,
  users.first_name,
  users.last_name,
  SUM(hotel_reservations.total_price) AS total_spent
FROM
  users
  INNER JOIN hotel_reservations
  ON users.user_id = hotel_reservations.user_id
WHERE
  EXTRACT(YEAR FROM hotel_reservations.check_in_date) = 2019
GROUP BY
  users.user_id,
  users.first_name,
  users.last_name
ORDER BY
  total_spent DESC
LIMIT 10;

/* 8. Find the average length of stay for each hotel room type */
SELECT h.hotel_name, hrt.room_type,
ROUND(AVG(DATE_PART('day', hr.check_out_date - hr.check_in_date))::numeric, 1)
AS avg_stay_length
FROM hotels h
INNER JOIN hotel_room_types hrt
ON h.hotel_id = hrt.hotel_id
INNER JOIN hotel_reservations hr
ON hrt.room_type_id = hr.room_type_id
GROUP BY h.hotel_name, hrt.room_type
ORDER BY avg_stay_length DESC;


/* 9. Revenue per year for each car company */
SELECT
    EXTRACT(YEAR FROM flight.departure_date) AS Year,
    airline.airline_name,
    SUM(flight_seat.price) as total_revenue
FROM
    flight_seat
    INNER JOIN flight_reservation ON flight_seat.flight_seat_id = flight_reservation.flight_seat_id
    INNER JOIN flight ON flight_reservation.flight_id = flight.flight_id
    INNER JOIN airline ON flight.airline_id = airline.airline_id
GROUP BY
    Year, airline.airline_name
ORDER BY
    Year, total_revenue DESC;

/* 10. Revenue per year for each airline */

SELECT
    EXTRACT(YEAR FROM car_rental_reservation.pick_up_date) AS Year,
    car_rental_companies.car_rental_company_name,
    SUM(car_rental_reservation.total_price) as total_revenue
FROM
    car_rental_reservation
    INNER JOIN cars ON car_rental_reservation.car_id = cars.car_id
    INNER JOIN car_rental_companies ON cars.car_rental_company_id = car_rental_companies.car_rental_company_id
GROUP BY
    Year, car_rental_companies.car_rental_company_name
ORDER BY
    Year, total_revenue DESC;

/* 11. Total revenue across flights, car rental, and hotel reservations for each year */
SELECT
    Year,
    SUM(total_revenue) as total_revenue
FROM
(
    SELECT
        EXTRACT(YEAR FROM flight.departure_date) AS Year,
        SUM(flight_seat.price) as total_revenue
    FROM
        flight_seat
        INNER JOIN flight_reservation ON flight_seat.flight_seat_id = flight_reservation.flight_seat_id
        INNER JOIN flight ON flight_reservation.flight_id = flight.flight_id
    GROUP BY
        Year

    UNION ALL

    SELECT
        EXTRACT(YEAR FROM car_rental_reservation.pick_up_date) AS Year,
        SUM(car_rental_reservation.total_price) as total_revenue
    FROM
        car_rental_reservation
    GROUP BY
        Year

    UNION ALL

    SELECT
        EXTRACT(YEAR FROM hotel_reservations.check_in_date) AS Year,
        SUM(hotel_reservations.total_price) as total_revenue
    FROM
        hotel_reservations
    GROUP BY
        Year
) AS revenue
GROUP BY
    Year
ORDER BY
    Year;

/* 12. What are the top 10 most popular travel destinations for our customers? */
SELECT c.city_name, COUNT(*) AS total_bookings
FROM hotel_reservations hr
JOIN hotels h ON h.hotel_id = hr.hotel_id
JOIN city c ON c.city_id = h.city_id
GROUP BY c.city_name
ORDER BY total_bookings DESC
LIMIT 10;

/* 13. What kind of customers like to book from us (age, gender)? */
SELECT u.gender,
       CONCAT(FLOOR(EXTRACT(YEAR FROM AGE(NOW(), u.date_of_birth)) / 10) * 10, '-',
              FLOOR(EXTRACT(YEAR FROM AGE(NOW(), u.date_of_birth)) / 10) * 10 + 9) AS age_range,
       COUNT(*) AS total_bookings, COUNT(DISTINCT o.user_id) AS unique_customers
FROM orders o
JOIN users u ON u.user_id = o.user_id
GROUP BY u.gender, age_range
ORDER BY u.gender, age_range;
