\c movielens;

DROP TABLE IF EXISTS "AvgUserRating";

CREATE TABLE "AvgUserRating" AS
SELECT user_id, AVG(rating) as avg_rating
FROM "Rating" 
GROUP BY user_id;

ALTER TABLE "AvgUserRating" ADD PRIMARY KEY (user_id);

DROP TABLE IF EXISTS "NormalizedRating";

CREATE TABLE "NormalizedRating" AS
SELECT 
	r.user_id AS user_id,
	r.movie_id AS movie_id,
	(r.rating - avgr.avg_rating) AS rating,
	r.timestamp
FROM 
	"Rating" AS r JOIN 
	"AvgUserRating" AS avgr ON 
	avgr.user_id = r.user_id;

ALTER TABLE "NormalizedRating" ADD PRIMARY KEY (user_id, movie_id);

DROP TABLE IF EXISTS "CommonMovieAggregate" CASCADE;

-- pre-compute similarities
CREATE TABLE "CommonMovieAggregate" AS
SELECT
	r1.user_id AS u1,
	r2.user_id AS u2,
	COUNT(*) AS N,
	-- add small constant to prevent division by zero
	SUM(r1.rating * r2.rating) / (SQRT(SUM(r1.rating * r1.rating)) * SQRT(SUM(r2.rating * r2.rating)) + 1e-10) AS cosine_sim
FROM
	"NormalizedRating" AS r1 JOIN
	"NormalizedRating" AS r2 ON r1.movie_id = r2.movie_id
WHERE
	-- store each common user once per (u1, u2) pair, i.e. (u1, u2, movie) = (u2, u1, movie)
	r1.user_id < r2.user_id
GROUP BY 
	u1, u2;

ALTER TABLE "CommonMovieAggregate" ADD PRIMARY KEY (u1, u2);

DROP FUNCTION IF EXISTS cofi_user(INTEGER, INTEGER);

/* User-based collaborative filtering: "User will rate a new movie similarly to people who rated this movie and 
	rated other movies similarly as the user".
	Note: does not handle case where there are no similar users for the query (raises divide by zero in that case).

	Example use: get predicted rating of user with ID 1 for movie with ID 1 
	> SELECT cofi_user(1, 1); 
*/

CREATE FUNCTION cofi_user(u_id INTEGER, m_id INTEGER) RETURNS REAL AS
$$
DECLARE	result REAL;
BEGIN
	WITH 
	-- source user ID can be in either `u1` or `u2` column of aggregate table
	sims1 AS (
		SELECT 
			COALESCE(SUM(agg1.cosine_sim), 0) AS sum_of_sims,
			COALESCE(SUM(agg1.cosine_sim * r1.rating), 0) AS weighted_ratings 
		FROM 
			(SELECT * FROM "CommonMovieAggregate" WHERE u1 = u_id) AS agg1
			JOIN (SELECT * FROM "NormalizedRating" WHERE movie_id = m_id) AS r1
			ON agg1.u2 = r1.user_id
	),
	sims2 AS (
		SELECT 
			COALESCE(SUM(agg2.cosine_sim), 0) AS sum_of_sims,
			COALESCE(SUM(agg2.cosine_sim * r2.rating), 0) AS weighted_ratings
		FROM 
			(SELECT * FROM "CommonMovieAggregate" WHERE u2 = u_id) AS agg2
			JOIN (SELECT * FROM "NormalizedRating" WHERE movie_id = m_id) AS r2
			ON agg2.u1 = r2.user_id
	)
	-- weighted sum of ratings / sum of similarities
	SELECT ((SELECT weighted_ratings FROM sims1) + (SELECT weighted_ratings FROM sims2)) / 
			((SELECT sum_of_sims FROM sims1) + (SELECT sum_of_sims FROM sims2)) INTO result;

	RETURN result + (SELECT avg_rating FROM "AvgUserRating" WHERE user_id = u_id);
END;
$$
LANGUAGE PLPGSQL;

