-- ===========================
-- ЧАСТЬ 1: УДАЛЕНИЕ/СОЗДАНИЕ БАЗ
-- ===========================

-- Закрываем активные подключения к базам
DO $$
BEGIN
   PERFORM pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE datname = 'university_main'
     AND pid <> pg_backend_pid();
END $$;

DO $$
BEGIN
   PERFORM pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE datname = 'university_archive'
     AND pid <> pg_backend_pid();
END $$;

DO $$
BEGIN
   PERFORM pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE datname = 'university_test'
     AND pid <> pg_backend_pid();
END $$;

-- Удаляем и создаём базы
DROP DATABASE IF EXISTS university_main;
CREATE DATABASE university_main TEMPLATE = template0 ENCODING = 'UTF8';

DROP DATABASE IF EXISTS university_archive;
CREATE DATABASE university_archive TEMPLATE = template0 CONNECTION LIMIT = 50;

UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'university_test';
DROP DATABASE IF EXISTS university_test;

DROP DATABASE IF EXISTS university_distributed;
CREATE DATABASE university_distributed TEMPLATE = template0 ENCODING = 'LATIN9' TABLESPACE student_data LC_COLLATE = 'C' LC_CTYPE = 'C';

DROP DATABASE IF EXISTS university_backup;
CREATE DATABASE university_backup TEMPLATE = university_main;
