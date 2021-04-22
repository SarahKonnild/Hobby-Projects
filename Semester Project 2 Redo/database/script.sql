CREATE DATABASE credit_db;

CREATE TABLE production_company (
    id serial not null constraint production_company_pk primary key,
    name varchar(255) unique not null
);

CREATE TABLE movie (
    id serial no null constraint movie_pk primary key,
    name varchar(255) not null
);

CREATE TABLE produces_movie (
    production_company_id integer not null constraint produces_movie_production_company_id_fkey references production_company on delete cascade,
    movie_id integer not null references movie on delete cascade,
    constraint produces_movie_pkey primary key (production_company_id, movie_id)
);

CREATE TABLE cast_members (
    id serial not null constraint cast_pk primary key,
    regdkid varchar(10) not null,
    name varchar(255) not null
);

CREATE TABLE movie_employs (
    movie_id integer not null constraint movie_employs_movie_id_fkey references movie on delete cascade,
    cast_id integer not null constraint movie_employs_cast_id_fkey references cast_members on delete cascade,
    role varchar(255) not null,
    constraint movie_employs_pkey primary key(movie_id, cast_id)
);

CREATE TABLE production(
    id serial not null constraint production_pk primary key,
    name varchar(255) not null,
    year date not null,
    seasons integer default 0,
    episodes integer default 0
);

CREATE TABLE broadcast (
    id serial not null constraint broadcast_pk primary key,
    name varchar(255) not null,
    airdate date not null,
    episode_number integer not null,
    season_number integer not null
);

CREATE TABLE broadcast_employs(
    broadcast_id integer not null constraint broadcast_employs_broadcast_id_fkey references broadcast on delete cascade,
    cast_id integer not null constraint broadcast_employs_cast_id_fkey references cast_members on delete cascade,
    role varchar(255) not null,
    constraint broadcast_employs_pkey primary key (broadcast_id, cast_id)
);

CREATE TABLE produces(
    production_company_id integer not null constraint produces_production_company_id_fkey references production_company on delete cascade,
    production_id integer not null constraint produces_production_id_fkey references production on delete cascade,
    constraint produces_pkey primary key (production_company_id, production_id)
);

CREATE TABLE contains(
    production_id integer not null constraint contains_production_id_fkey references production on delete cascade,
    broadcast_id integer not null constraint contains_broadcast_id_fkey references broadcast on delete cascade,
    constraint contains_pkey primary key (production_id, broadcast_id)
);

--UPDATES
--Update single broadcast season number
CREATE OR REPLACE PROCEDURE update_season_number(production_id_variable integer) AS $$ DECLARE number_of_seasons_temp integer:= 1;
BEGIN
    SELECT coalesce(max(broadcast.season_number),0) INTO number_of_seasons_temp FROM broadcast, produces, contains, WHERE broadcast.id = contains.broadcast_id and contains.production_id = produces.production_id and produces.production_id = production_id_variable;
    UPDATE production SET number_of_seasons = number_of_seasons_temp WHERE id = production_id_variable;
END; $$ LANGUAGE plpgsql;

--Update single broadcast episode number
CREATE OR REPLACE PROCEDURE update_episode_number(production_id_variable integer) AS $$ DECLARE number_of_episodes_temp integer := 1;
BEGIN 
    SELECT count(broadcast.episode_number) INTO number_of_episodes_temp FROM broadcast, produces, contains WHERE broadcast.id = contains.broadcast_id AND contains.production_id = produces.production_id AND produces.production_id = production_id_variable;
    UPDATE production SET number_of_episodes = number_of_episodes_temp WHERE id = production_id_variable;
END; $$ LANGUAGE plpgsql

--Update all broadcasts
CREATE OR REPLACE PROCEDURE update_all_broadcast_sizes() AS $$ DECLARE productions CURSOR FOR SELECT DISTINCT(id) AS id FROM production;
BEGIN
    FOR production IN productions LOOP
        CALL update_season_number(production.id);
        CALL update_episode_number(production.id);
    END LOOP;
END; $$
    LANGUAGE plpgsql;

--function wrapper to enable running procedure as trigger
CREATE OR REPLACE FUNCTION update_all_broadcast_sizes_trigger()
    RETURNS trigger
AS $$
BEGIN
    CALL update_all_broadcast_sizes();
    RETURN NULL;
END; $$
    LANGUAGE plpgsql

--trigger to update broadcast
CREATE TRIGGER update_size_of_broadcast_trigger
    AFTER INSERT OR DELETE OR UPDATE ON contains
EXECUTE PROCEDURE update_all_broadcast_sizes_trigger();

--Index search columns
CREATE INDEX ON movie(name);
CREATE INDEX ON broadcast(name);
CREATE INDEX ON production(name);
CREATE INDEX ON production_company(name);
CREATE INDEX ON cast_members(name);