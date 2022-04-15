CREATE TABLE DatabaseRestore.Roles (
    RoleId INT IDENTITY(1,1),
    RoleName VARCHAR(50) NOT NULL,
    RoleExecute VARCHAR(MAX) NOT NULL
);

INSERT INTO DatabaseRestore.Roles ( RoleName, RoleExecute )
VALUES ('db_developer', 'IF NOT EXISTS ( SELECT * FROM sys.database_principals WHERE name = ''db_developer'' )
BEGIN
    CREATE ROLE [db_developer] AUTHORIZATION [dbo];
    GRANT ALTER ANY APPLICATION ROLE TO [db_developer];
    GRANT ALTER ANY ASSEMBLY TO [db_developer];
    GRANT ALTER ANY DATABASE DDL TRIGGER TO [db_developer];
    GRANT ALTER ANY DATASPACE TO [db_developer];
    GRANT ALTER ANY FULLTEXT CATALOG TO [db_developer];
    GRANT ALTER ANY MESSAGE TYPE TO [db_developer];
    GRANT ALTER ANY SCHEMA TO [db_developer];
    GRANT CREATE AGGREGATE TO [db_developer];
    GRANT CREATE ASSEMBLY TO [db_developer];
    GRANT CREATE DATABASE DDL EVENT NOTIFICATION TO [db_developer];
    GRANT CREATE DEFAULT TO [db_developer];
    GRANT CREATE FULLTEXT CATALOG TO [db_developer];
    GRANT CREATE FUNCTION TO [db_developer];
    GRANT CREATE PROCEDURE TO [db_developer];
    GRANT CREATE ROLE TO [db_developer];
    GRANT CREATE RULE TO [db_developer];
    GRANT CREATE SCHEMA TO [db_developer];
    GRANT CREATE SERVICE TO [db_developer];
    GRANT CREATE SYNONYM TO [db_developer];
    GRANT CREATE TABLE TO [db_developer];
    GRANT CREATE TYPE TO [db_developer];
    GRANT CREATE VIEW TO [db_developer];
    GRANT CREATE XML SCHEMA COLLECTION TO [db_developer];
    GRANT DELETE TO [db_developer];
    GRANT EXECUTE TO [db_developer];
    GRANT INSERT TO [db_developer];
    GRANT REFERENCES TO [db_developer];
    GRANT SELECT TO [db_developer];
    GRANT SHOWPLAN TO [db_developer];
    GRANT UPDATE TO [db_developer];
    GRANT VIEW DATABASE STATE TO [db_developer];
    GRANT VIEW DEFINITION TO [db_developer];
END;'),
( 'db_application_less', 'IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name=''db_application_less'')  
BEGIN
    CREATE ROLE [db_application_less] AUTHORIZATION [dbo];
    GRANT DELETE TO [db_application_less]; -- Permission to delete vaules   
    GRANT EXECUTE TO [db_application_less]; -- Permission to execute stored procedures   
    GRANT INSERT TO [db_application_less]; -- Permission to insert vaules   
    GRANT SELECT TO [db_application_less]; -- Permission to select vaules   
    GRANT UPDATE TO [db_application_less]; -- Permission to update vaules   
    GRANT VIEW DEFINITION TO [db_application_less]'' -- Permission to view database metadata  
END;'),
('db_application','IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name=''db_application'')
BEGIN
    CREATE ROLE [db_application] AUTHORIZATION [dbo];
    GRANT ALTER ANY SCHEMA TO [db_application]; -- Permission to drop tables    
    GRANT CREATE TABLE TO [db_application]; -- Permission to create tables    
    GRANT DELETE TO [db_application]; -- Permission to delete vaules    
    GRANT EXECUTE TO [db_application]; -- Permission to execute stored procedures    
    GRANT INSERT TO [db_application]; -- Permission to insert vaules    
    GRANT SELECT TO [db_application]; -- Permission to select vaules    
    GRANT UPDATE TO [db_application]; -- Permission to update vaules    
    GRANT VIEW DEFINITION TO [db_application]; -- Permission to view database metadata  
END;'),
('db_executor', 'IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name=''db_executor'')
BEGIN
    CREATE ROLE db_executor;
    GRANT EXECUTE TO db_executor;
END;'),
('db_procreader', 'IF NOT EXISTS ( SELECT * FROM sys.database_principals WHERE name = ''db_procreader'' )
BEGIN
    CREATE ROLE [db_procreader] AUTHORIZATION [dbo];
    GRANT VIEW DEFINITION TO [db_procreader]; -- Permission to view database metadata  
END;
');



