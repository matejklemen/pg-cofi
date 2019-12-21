# pg-cofi
Collaborative filtering implemented in PostgreSQL.


## Creating the database
Make sure you have PostgreSQL installed (tested with v10.10) and a sample user created.  
To create the schema, move into the `data/` directory and run the `create_db.sql` script. Make sure to replace **matej** with your username.
```bash
$ cd data/
$ psql -U matej -f create_db.sql
```

## Importing the data