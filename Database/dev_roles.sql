-- =====================================================================
-- LOCAL DEVELOPMENT ONLY (mounted by docker-compose.yml).
--
-- schema.sql creates the ems_api role WITHOUT a password, on purpose:
-- real passwords never go in the repository. Locally we give it a simple
-- one so the backend container can log in. On AWS the password will come
-- from Secrets Manager instead.
-- =====================================================================

ALTER ROLE ems_api PASSWORD 'ems_api_dev';