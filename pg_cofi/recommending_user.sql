--puts element elem on index idx in array arr -> returns array with elem on the right posision
CREATE OR REPLACE FUNCTION array_set_elementi(arr INTEGER[], elem INTEGER, idx INTEGER)
RETURNS INTEGER[] AS $$
BEGIN
    if cardinality(arr) < idx then
        arr:= arr || array_fill(null::INTEGER, array[idx- cardinality(arr)]);
    end if;
    arr[idx]:= elem;
    RETURN arr;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION array_set_elementr(arr REAL[], elem REAL, idx REAL)
RETURNS REAL[] AS $$
BEGIN
    if cardinality(arr) < idx then
        arr:= arr || array_fill(null::REAL, array[idx- cardinality(arr)]);
    end if;
    arr[idx]:= elem;
    RETURN arr;
END; $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS recommending_user(INTEGER);
CREATE FUNCTION recommending_user(u_id INTEGER) RETURNS INTEGER[] AS
$$
DECLARE	
	-- vrednosti predlogov
	rec REAL ARRAY[10]; 
	-- movie_id with the highest predicted rating (or should we give movi title?)
	movies INTEGER ARRAY [10];
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
		FOR i IN 1..10 LOOP
			rec = array_append(rec, 0:: REAL);
			movies = array_append(movies, 0:: INTEGER);
		END LOOP;
		
				
		FOR movie in (SELECT m.movie_id as mov
					  FROM "Movie" m
					  WHERE m.movie_id not in (SELECT r.movie_id 
										 FROM "Rating" r 
										 WHERE r.user_id=u_id) 
					  and
					  m.movie_id in (SELECT ra.movie_id 
									  FROM "Rating" ra, "CommonMovieAggregate" c
									  WHERE ((c.u1=u_id and ra.user_id=c.u2) or (c.u2=u_id and ra.user_id=c.u1)) 
												 and c.cosine_sim > 0.975
									  )
					  )
		LOOP
			r := cofi_user(u_id, movie);
			
			-- if the rating is smaller than the smallest in the rec -> don't put it in the array rec
			IF r <= (SELECT(rec)[10]) THEN 
					CONTINUE;
			-- otherwise: 
			ELSE
				rec = array_set_elementr(rec, r, 10);
				movies = array_set_elementi(movies,movie,10);
			END IF;
			
			-- puting movie with highest predicted rating in the first place in the array rec
			FOR j IN REVERSE 10..1 BY 1 LOOP			
					tmp := (SELECT(rec)[j]);
					tmp_movie := (SELECT(movies)[j]);
					
					l := j - 1;
					WHILE j>=1 AND (SELECT(rec)[l])<tmp LOOP
						rec = array_set_elementr(rec, ((SELECT rec)[l]),l+1);
						movies = array_set_elementi(movies, ((SELECT movies)[l]),l+1);
						
						l := l - 1;
					END LOOP;				
					rec = array_set_elementr(rec, tmp, l+1);
					movies = array_set_elementi(movies,tmp_movie,l+1);
								
			END LOOP;
			
		END LOOP;
		RETURN movies;
END;
$$
LANGUAGE PLPGSQL;