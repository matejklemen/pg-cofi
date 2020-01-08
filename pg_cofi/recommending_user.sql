DROP FUNCTION IF EXISTS recommending_user(INTEGER);

CREATE FUNCTION recommending_user(u_id INTEGER) RETURNS INTEGER[] AS
$$
DECLARE	
	-- vrednosti predlogov
	rec REAL ARRAY[5]; 
	-- movie_id with the highest predicted rating (or should we give movi title?)
	movies integer [5];
	--movie that u_id didn't rate
	movie INTEGER; 
	-- rating for movie -> cofi_user(u_id,r)
	r REAL; 
	tmp REAL; 
	tmp_movie INTEGER;
	i INTEGER;
	j INTEGER;
	l INTEGER;
	m INTEGER;
BEGIN	
		FOR i IN 1..5 LOOP
			rec[i] = 0;
		END LOOP;
		
		-- finding movies that u_id didn't rate
		FOR movie in (SELECT m.movie_id
			FROM "Movie" m
			WHERE m.movie_id not in (SELECT r.movie_id FROM "Rating" r WHERE r.user_id=u_id))
			
		LOOP
			r := cofi_user(u_id, movie);
			-- puting movie with highest predicted rating in the first place in the array rec
			FOR j IN REVERSE 5..1 BY 1 LOOP
				-- if the rating is smaller than the smallest in the rec -> don't put it in the array rec
				IF r <= rec[j] THEN 
					EXIT;
				-- otherwise: 
				ELSE
					rec[j]:=r;
					movies[j] := movie;
					
					tmp := rec[j];
					tmp_movie := movies[j];
					
					l := j - 1;
					WHILE j>=1 AND rec[l]<tmp LOOP
						rec[l+1] := rec[l];
						movies[l+1] := movies[l];
						
						l := l - 1;
					END LOOP;					
					rec[l+1] := tmp;
					movies[l+1] := tmp_movie;
				END IF;				
			END LOOP;
			
		END LOOP;
		RETURN movies;
END;
$$
LANGUAGE PLPGSQL;