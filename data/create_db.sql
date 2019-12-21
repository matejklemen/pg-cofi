-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.1
-- PostgreSQL version: 10.0
-- Project Site: pgmodeler.io

DROP DATABASE IF EXISTS movielens;
CREATE DATABASE movielens;

\c movielens;

DROP TABLE IF EXISTS "User" CASCADE;
CREATE TABLE "User" (
	user_id integer NOT NULL,
	age smallint,
	gender char(1),
	occupation varchar(30),
	zip_code varchar(10),
	CONSTRAINT "User_pk" PRIMARY KEY (user_id)
);

DROP TABLE IF EXISTS "Movie" CASCADE;
CREATE TABLE "Movie" (
	movie_id integer NOT NULL,
	movie_title text,
	release_date date,
	imdb_url text,
	CONSTRAINT "Movie_pk" PRIMARY KEY (movie_id)
);

DROP TABLE IF EXISTS "Rating" CASCADE;
CREATE TABLE "Rating" (
	"movie_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	rating smallint,
	"timestamp" timestamp,
	CONSTRAINT "Rating_pk" PRIMARY KEY ("movie_id","user_id")
);

ALTER TABLE "Rating" DROP CONSTRAINT IF EXISTS "Movie_fk" CASCADE;
ALTER TABLE "Rating" ADD CONSTRAINT "Movie_fk" FOREIGN KEY ("movie_id")
REFERENCES "Movie" (movie_id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Rating" DROP CONSTRAINT IF EXISTS "User_fk" CASCADE;
ALTER TABLE "Rating" ADD CONSTRAINT "User_fk" FOREIGN KEY ("user_id")
REFERENCES "User" (user_id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
