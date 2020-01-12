CREATE OR REPLACE FUNCTION show_movie_titles(u_id INTEGER)
RETURNS TEXT[] AS $$
DECLARE 
	naslovi TEXT ARRAY[5];
	rec_mov INTEGER ARRAY[5];
	m_id INTEGER;
	m_title TEXT;
BEGIN 
	rec_mov := recommending_user(u_id);
	FOR i in 1..5 LOOP
		m_id := ((SELECT rec_mov)[i]);
		m_title := (SELECT movie_title FROM "Movie" WHERE movie_id=m_id);
		naslovi := array_append(naslovi, m_title);
	END LOOP;
    return naslovi;
END; $$
LANGUAGE plpgsql;
