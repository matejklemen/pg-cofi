import psycopg2
import os
from data_splits import get_test_examples
from time import time


if __name__ == "__main__":
	# Obtain credentials from env vars
	username = os.environ.get("PG_USER")
	passwd = os.environ.get("PG_PASS")
	host = os.environ.get("PG_HOST", "localhost")

	if not username or not passwd:
		raise ValueError("Please set the PG_USER and PG_PASS environment variables with your username and password")

	# Contains (user, movie, actual rating) triples
	test_set = get_test_examples()

	conn = psycopg2.connect(host=host, port=5432, user=username, password=passwd, dbname="movielens")
	cur = conn.cursor()

	start_time = time()
	sum_of_square_errs = 0.0
	num_examples = 0

	for (curr_user, curr_movie, gt_rating) in test_set:
		try:
			cur.execute(f"SELECT cofi_user({curr_user}, {curr_movie})");
			curr_pred = cur.fetchone()[0]

			sum_of_square_errs += (gt_rating - curr_pred) ** 2
			num_examples += 1
		except Exception as e:
			print("Skipped an example due to:")
			print(e)

	rmse = (sum_of_square_errs / num_examples) ** 0.5
	end_time = time()
	print(f"RMSE: {rmse:.3f}")
	print(f"Elapsed time: {end_time - start_time:.3f}s (for {num_examples}/{len(test_set)} examples)")

	cur.close()
	conn.close()
