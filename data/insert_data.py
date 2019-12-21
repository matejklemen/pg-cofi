import psycopg2
import pandas as pd
import os


def none_to_null(value):
	return "null" if value is None else str(value)


def insert_genres(cursor):
	# Note: doubled single quote in "Children's" to avoid syntax error when inserting into db
	id2genre = list(enumerate(["Action", "Adventure", "Animation", "Children''s", "Comedy", "Crime", "Documentary", "Drama", "Fantasy", "Film-Noir", "Horror", "Musical", "Mystery", "Romance", "Sci-Fi", "Thriller", "War","Western"], 1))
	genre2id = {genre: genre_id for genre_id, genre in id2genre}

	records = [f"({genre_id},'{genre}')" for genre_id, genre in id2genre]
	print(f"Inserting {len(records)} genres...")
	cursor.execute('INSERT INTO "Genre" (genre_id, genre) VALUES {}'.format(",".join(records)))
	return genre2id

def insert_age_encoding(cursor, data_version):
	if data_version == "ml-1m":
		# Mapping from ID to age interval (lower_bound(incl.), upper_bound(excl.))
		id2interval = {
			1: (1, 18),
			18: (18, 25),
			25: (25, 35),
			35: (35, 45),
			45: (45, 50),
			50: (50, 55),
			56: (56, 150)
		}
		records = []
		for age_id, (lb, ub) in id2interval.items():
			records.append(f"({age_id},{none_to_null(lb)},{none_to_null(ub)})")
		print(f"Inserting {len(records)} age intervals...")
		cursor.execute('INSERT INTO "Age" (age_id, lower_bound, upper_bound) VALUES {}'.format(",".join(records)))
	else:
		raise NotImplementedError("Age encoding currently only defined for 'ml-1m' version of the dataset")


def insert_occupation(cursor, data_version):
	if data_version == "ml-1m":
		id2occupation = {
			0: '"other" or not specified',
			1: "academic/educator",
			2: "artist",
			3: "clerical/admin",
			4: "college/grad student",
			5: "customer service",
			6: "doctor/health care",
			7: "executive/managerial",
			8: "farmer",
			9: "homemaker",
			10: "K-12 student",
			11: "lawyer",
			12: "programmer",
			13: "retired",
			14: "sales/marketing",
			15: "scientist",
			16: "self-employed",
			17: "technician/engineer",
			18: "tradesman",
			19: "unemployed",
			20: "writer"
		}
		records = []
		for occ_id, description in id2occupation.items():
			records.append(f"({occ_id},'{description}')")
		print(f"Inserting {len(records)} occupations...")
		cursor.execute('INSERT INTO "Occupation" (occupation_id, occupation) VALUES {}'.format(",".join(records)))
	else:
		raise NotImplementedError("Age encoding currently only defined for 'ml-1m' version of the dataset")


# TODO: currently only works for 1m version
def insert_users(cursor):
	df = pd.read_csv(os.path.join("ml-1m", "users.dat"), sep="::", engine="python", header=None, names=["UserID", "Gender", "Age", "Occupation", "Zip-code"])
	records = []
	for idx_row in range(df.shape[0]):
		ex = df.iloc[idx_row]
		records.append(f"({ex['UserID']},'{ex['Gender']}',{ex['Age']},{ex['Occupation']},'{ex['Zip-code']}')")
	print(f"Inserting {len(records)} users...")
	cursor.execute('INSERT INTO "User" (user_id, gender, age_id, occupation_id, zip_code) VALUES {}'.format(",".join(records)))


def insert_movies(cursor, genre_encoder):
	df = pd.read_csv(os.path.join("ml-1m", "movies.dat"), sep="::", engine="python", header=None, names=["MovieID", "Title", "Genres"])
	records_movies = []
	records_categories = []
	for idx_row in range(df.shape[0]):
		ex = df.iloc[idx_row]
		movie_title = ex['Title'].replace("'", "''")
		records_movies.append(f"({ex['MovieID']},'{movie_title}')")

		for curr_genre in ex["Genres"].split("|"):
			# single quotes are doubled in encoder, so double them here aswell
			processed_genre = curr_genre.replace("'", "''")
			records_categories.append(f"({ex['MovieID']},{genre_encoder[processed_genre]})")
	
	print(f"Inserting {len(records_movies)} movies...")
	cursor.execute('INSERT INTO "Movie" (movie_id, movie_title) VALUES {}'.format(",".join(records_movies)))
	print(f"Inserting {len(records_categories)} movie-category mappings...")
	cursor.execute('INSERT INTO "MovieCategory" (movie_id, genre_id) VALUES {}'.format(",".join(records_categories)))


def insert_ratings(cursor):
	df = pd.read_csv(os.path.join("ml-1m", "ratings.dat"), sep="::", engine="python", header=None, names=["UserID", "MovieID", "Rating", "Timestamp"])
	records = []
	for idx_row in range(df.shape[0]):
		ex = df.iloc[idx_row]
		records.append(f"({ex['UserID']},{ex['MovieID']},{ex['Rating']},to_timestamp({ex['Timestamp']}))")

	print(f"Inserting {len(records)} ratings...")
	cursor.execute('INSERT INTO "Rating" (user_id, movie_id, rating, timestamp) VALUES {}'.format(",".join(records)))

if __name__ == "__main__":
	# Obtain credentials from env vars
	username = os.environ.get("PG_USER")
	passwd = os.environ.get("PG_PASS")
	host = os.environ.get("PG_HOST", "localhost")

	if not username or not passwd:
		raise ValueError("Please set the PG_USER and PG_PASS environment variables with your username and password")

	conn = psycopg2.connect(host=host, port=5432, user=username, password=passwd, dbname="movielens")
	cur = conn.cursor()
	
	insert_age_encoding(cur, "ml-1m")
	conn.commit()

	insert_occupation(cur, "ml-1m")
	conn.commit()

	insert_users(cur)
	conn.commit()

	genres = insert_genres(cur)
	insert_movies(cur, genres)
	conn.commit()

	insert_ratings(cur)
	conn.commit()

	cur.close()
	conn.close()
