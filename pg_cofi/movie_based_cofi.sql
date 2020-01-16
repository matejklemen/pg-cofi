\c movielens;

DROP TABLE IF EXISTS "CommonUserAggregate" CASCADE;

-- pre-compute similarities
CREATE TABLE "CommonUserAggregate" AS
SELECT
	r1.movie_id AS m1,
	r2.movie_id AS m2,
	COUNT(*) AS N,
	LEAST(SUM(r1.rating * r2.rating) / (SQRT(SUM(r1.rating * r1.rating)) * SQRT(SUM(r2.rating * r2.rating))), 1) AS cosine_sim
FROM
	"Rating" AS r1 JOIN
	"Rating" AS r2 ON r1.user_id = r2.user_id
WHERE
	-- store each common movie once per (m1, m2) pair, i.e. (m1, m2, user) = (m2, m1, user)
	r1.movie_id < r2.movie_id
GROUP BY 
	m1, m2;

ALTER TABLE "CommonUserAggregate" ADD PRIMARY KEY (m1, m2);

DROP FUNCTION IF EXISTS cofi_movie(INTEGER, INTEGER);

/* Movie-based collaborative filtering: "User will rate a new movie similarly to how this user rated 
	other movies with similar ratings (by other users) as this one"
	Example use: get predicted rating of user with ID 1 for movie with ID 1 
	> SELECT cofi_user(1, 1);
*/
CREATE FUNCTION cofi_movie(u_id INTEGER, m_id INTEGER) RETURNS REAL AS
$$
-- store result into a temporary variable as functions don't seem to play nice with the `with` statement
DECLARE	result REAL;
BEGIN
	WITH 
	-- source user ID can be in either `u1` or `u2` column of aggregate table, storing similarities
	sims1 AS (
		SELECT 
			COALESCE(SUM(agg1.cosine_sim), 0) AS sum_of_sims,
			COALESCE(SUM(agg1.cosine_sim * r1.rating), 0) AS weighted_ratings 
		FROM 
			(SELECT * FROM "CommonUserAggregate" WHERE m1 = m_id) AS agg1
			JOIN (SELECT * FROM "Rating" WHERE user_id = u_id) AS r1
			ON agg1.m2 = r1.movie_id
	),
	sims2 AS (
		SELECT 
			COALESCE(SUM(agg2.cosine_sim), 0) AS sum_of_sims,
			COALESCE(SUM(agg2.cosine_sim * r2.rating), 0) AS weighted_ratings
		FROM 
			(SELECT * FROM "CommonUserAggregate" WHERE m2 = m_id) AS agg2
			JOIN (SELECT * FROM "Rating" WHERE user_id = u_id) AS r2
			ON agg2.m1 = r2.movie_id
	)
	-- weighted sum of ratings / sum of similarities
	SELECT ((SELECT weighted_ratings FROM sims1) + (SELECT weighted_ratings FROM sims2)) / 
			((SELECT sum_of_sims FROM sims1) + (SELECT sum_of_sims FROM sims2)) INTO result;

	RETURN result;
END;
$$
LANGUAGE PLPGSQL;
