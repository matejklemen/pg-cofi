# pg-cofi
Collaborative filtering implemented in PostgreSQL.


## Creating the database
Make sure you have PostgreSQL installed (tested with v10.10) and a sample user created.  
To create the schema, move into the `data/` directory and run the `create_db.sql` script. Make sure to replace `<your-username>` with your username.
```bash
$ cd data/
$ psql -U <your-username> -f create_db.sql
```

## Importing the data
Download the [MovieLens 1M Dataset](https://grouplens.org/datasets/movielens/1m/) and extract it into `data/`. The directory structure of `data/` should look like this:
```bash
$ ls data/
create_db.sql 	insert_data.py 	ml-1m/	movielens_model.dbm
```
Then, move into the `data/` directory and run `insert_data.py`. Before running the script:
- set the environment variables `PG_USER` and `PG_PASS` to the username and password of your database user,
- install the dependencies.
```bash
$ # install dependencies
$ pip install -r requirements.txt
$ cd data/
$ # set environment vars
$ export PG_USER=<your-username>
$ export PG_PASS=<your-password>
$ python insert_data.py
```
