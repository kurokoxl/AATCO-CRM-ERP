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

-- Grant necessary privileges to the application database user
\echo Applying privileges for :DB_OWNER on database :DB_NAME

-- Connect rights
GRANT CONNECT ON DATABASE :"DB_NAME" TO :"DB_OWNER";

-- Schema permissions
GRANT USAGE, CREATE ON SCHEMA public TO :"DB_OWNER";

-- Existing objects
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO :"DB_OWNER";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO :"DB_OWNER";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO :"DB_OWNER";

-- Future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO :"DB_OWNER";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO :"DB_OWNER";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON FUNCTIONS TO :"DB_OWNER";

\echo Privilege adjustments complete.
