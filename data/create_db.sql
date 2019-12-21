-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.1-beta
-- PostgreSQL version: 10.0
-- Project Site: pgmodeler.io

DROP DATABASE IF EXISTS movielens;
CREATE DATABASE movielens;

\c movielens;

DROP TABLE IF EXISTS "User" CASCADE;
CREATE TABLE "User" (
	user_id integer NOT NULL,
	gender char(1),
	zip_code varchar(10),
	"age_id" smallint,
	"occupation_id" integer,
	CONSTRAINT "User_pk" PRIMARY KEY (user_id)
);

DROP TABLE IF EXISTS "Age" CASCADE;
CREATE TABLE "Age" (
	age_id smallint NOT NULL,
	lower_bound smallint,
	upper_bound smallint,
	CONSTRAINT "Age_pk" PRIMARY KEY (age_id)
);
COMMENT ON TABLE "Age" IS 'Represents the age groups of users. Age with ID age_id represents the interval [lower_bound, upper_bound)';

ALTER TABLE "User" DROP CONSTRAINT IF EXISTS "Age_fk" CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "Age_fk" FOREIGN KEY ("age_id")
REFERENCES "Age" (age_id) MATCH FULL
ON DELETE SET NULL ON UPDATE CASCADE;

DROP TABLE IF EXISTS "Movie" CASCADE;
CREATE TABLE "Movie" (
	movie_id integer NOT NULL,
	movie_title text,
	release_date date,
	imdb_url text,
	CONSTRAINT "Movie_pk" PRIMARY KEY (movie_id)
);

DROP TABLE IF EXISTS "Occupation" CASCADE;
CREATE TABLE "Occupation" (
	occupation_id integer NOT NULL,
	ocupation varchar(50),
	CONSTRAINT "Occupation_pk" PRIMARY KEY (occupation_id)
);

ALTER TABLE "User" DROP CONSTRAINT IF EXISTS "Occupation_fk" CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "Occupation_fk" FOREIGN KEY ("occupation_id")
REFERENCES "Occupation" (occupation_id) MATCH FULL
ON DELETE SET NULL ON UPDATE CASCADE;

DROP TABLE IF EXISTS "Rating" CASCADE;
CREATE TABLE "Rating" (
	"user_id" integer NOT NULL,
	"movie_id" integer NOT NULL,
	rating smallint,
	"timestamp" timestamp,
	CONSTRAINT "Rating_pk" PRIMARY KEY ("user_id","movie_id")
);

ALTER TABLE "Rating" DROP CONSTRAINT IF EXISTS "User_fk" CASCADE;
ALTER TABLE "Rating" ADD CONSTRAINT "User_fk" FOREIGN KEY ("user_id")
REFERENCES "User" (user_id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Rating" DROP CONSTRAINT IF EXISTS "Movie_fk" CASCADE;
ALTER TABLE "Rating" ADD CONSTRAINT "Movie_fk" FOREIGN KEY ("movie_id")
REFERENCES "Movie" (movie_id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
