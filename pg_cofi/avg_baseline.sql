-- Assumes the 'movielens' db exists - if it doesn't, run `data/create_db.sql` before this script
\c movielens;

DROP TABLE IF EXISTS "AverageMovieRating" CASCADE;

CREATE TABLE "AverageMovieRating" AS 
SELECT
	movie_id,
	AVG(rating) as avg_rating
FROM "Rating" 
GROUP BY movie_id;

ALTER TABLE "AverageMovieRating" ADD PRIMARY KEY (movie_id);

DROP FUNCTION IF EXISTS avg_baseline(integer);

/* Baseline approach: "User will rate movie with the mean rating of all existing ratings"
	Example use: get average rating for movie with ID 1193
	> SELECT avg_baseline(1193); 
*/
CREATE FUNCTION avg_baseline(m_id integer) RETURNS real AS
$$
BEGIN
	RETURN avg_rating FROM "AverageMovieRating" WHERE movie_id = m_id;
END;
$$
LANGUAGE PLPGSQL;

