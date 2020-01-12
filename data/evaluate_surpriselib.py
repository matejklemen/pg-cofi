from surprise import SVD
from surprise import Dataset
from surprise import Reader
from surprise import accuracy

import os
from time import time

# Assumes `data_splits.write_splits()` was called (i.e. that data splits exist)
train_path = os.path.join("ml-1m", "train", "ratings.dat")
val_path = os.path.join("ml-1m", "val", "ratings.dat")
test_path = os.path.join("ml-1m", "test", "ratings.dat")

reader = Reader(line_format="user item rating timestamp", sep="::")

# (n_epochs, n_factors)
param_grid = [(5, 100), (5, 200), (10, 100), (10, 200), (5, 500), (10, 500)]

train_set = Dataset.load_from_file(train_path, reader=reader).build_full_trainset()
val_set = Dataset.load_from_file(val_path, reader=reader).build_full_trainset().build_testset()
test_set = Dataset.load_from_file(test_path, reader=reader).build_full_trainset().build_testset()

best_rmse, best_n_epochs, best_n_factors = float("inf"), None, None

for (n_epochs, n_factors) in param_grid:
	print(f"n_epochs={n_epochs}, n_factors={n_factors}")
	model = SVD(n_epochs=n_epochs, n_factors=n_factors)
	model.fit(train_set)
	preds = model.test(val_set)
	curr_rmse = accuracy.rmse(preds)
	
	if curr_rmse < best_rmse:
		best_rmse = curr_rmse
		best_n_epochs = n_epochs
		best_n_factors = n_factors

print(f"Best params: n_epochs={best_n_epochs}, n_factors={best_n_factors}, best RMSE = {best_rmse}")

t1 = time()
model = SVD(n_epochs=best_n_epochs, n_factors=best_n_factors)
model.fit(train_set)
t2 = time()
print(f"Time spent fitting: {t2 - t1}s")
t1 = time()
preds = model.test(test_set)
accuracy.rmse(preds)
t2 = time()
print(f"Time spent evaluating: {t2 - t1}s")