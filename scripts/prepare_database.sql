\set ON_ERROR_STOP on

\if :{?DB_NAME}
\else
  \echo 'ERROR: DB_NAME variable is not set. Use "\\set DB_NAME your_database" before including this file.'
  \quit 1
\endif

\if :{?DB_OWNER}
\else
  \echo 'ERROR: DB_OWNER variable is not set. Use "\\set DB_OWNER your_owner" before including this file.'
  \quit 1
\endif

\echo Dropping database :DB_NAME if it exists...
DROP DATABASE IF EXISTS :"DB_NAME";

\echo Creating database :DB_NAME owned by :DB_OWNER using template0...
CREATE DATABASE :"DB_NAME" OWNER :"DB_OWNER" TEMPLATE template0;

\connect :"DB_NAME"

\echo Connected to :DB_NAME. The database is now ready for data import.
