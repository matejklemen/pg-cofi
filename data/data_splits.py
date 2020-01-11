import pandas as pd
import os
import numpy as np

"""
	Creates three directories for train/validation/test sets, each consisting the corresponding ratings
	for that set.
	They are created inside the map `src_path`.
"""

# Which version of the movielens dataset we are splitting (map with this name must exist in relative dir)
src_path = "ml-1m"
RANDOM_SEED = 1337

def write_splits():
	df = pd.read_csv(os.path.join(src_path, "ratings.dat"), sep="::", engine="python", header=None, names=["UserID", "MovieID", "Rating", "Timestamp"])
	num_ratings = df.shape[0]
	print(f"Total number of ratings: {num_ratings}")

	TRAIN_SIZE, VAL_SIZE, TEST_SIZE = 0.7, 0.1, 0.2
	indices = np.random.permutation(num_ratings)

	train_indices = indices[: int(TRAIN_SIZE * num_ratings)] 
	
	val_test = indices[int(TRAIN_SIZE * num_ratings):]
	# renormalize proportion ("how much of `val_test` does validation set take?")
	val_rel_prop = VAL_SIZE / (VAL_SIZE + TEST_SIZE)
	val_indices = val_test[: int(val_rel_prop * val_test.shape[0])]
	test_indices = val_test[int(val_rel_prop * val_test.shape[0]):]

	train_path = os.path.join(src_path, "train")
	val_path = os.path.join(src_path, "val")
	test_path = os.path.join(src_path, "test")
	# guard to create dirs if they don't exist
	if not os.path.exists(train_path):
		os.mkdir(train_path)
	if not os.path.exists(val_path):
		os.mkdir(val_path)
	if not os.path.exists(test_path):
		os.mkdir(test_path)

	print(f"**Writing training ratings.dat to {train_path}**")
	np.savetxt(os.path.join(train_path, "ratings.dat"), df.iloc[train_indices], delimiter="::", fmt=["%d", "%d", "%d", "%d"])
	print(f"**Writing validation ratings.dat to {val_path}**")
	np.savetxt(os.path.join(val_path, "ratings.dat"), df.iloc[val_indices], delimiter="::", fmt=["%d", "%d", "%d", "%d"])
	print(f"**Writing test ratings.dat to {test_path}**")
	np.savetxt(os.path.join(test_path, "ratings.dat"), df.iloc[test_indices], delimiter="::", fmt=["%d", "%d", "%d", "%d"])


def _get_examples(set_name):
	assert set_name in {"train", "val", "test"}

	df = pd.read_csv(os.path.join(src_path, set_name, "ratings.dat"), sep="::", engine="python", header=None, names=["UserID", "MovieID", "Rating", "Timestamp"])
	ret = []
	for i in range(df.shape[0]):
		ex = df.iloc[i]
		ret.append((ex["UserID"], ex["MovieID"], ex["Rating"]))
	return ret


"""
	Returns list of triples (user_id, movie_id, ground truth rating).
	Assume data splits exist (call write_splits() if not).
"""
def get_val_examples():
	return _get_examples("val")


def get_test_examples():
	return _get_examples("test")


if __name__ == "__main__":
	np.random.seed(RANDOM_SEED)

	write_splits()
