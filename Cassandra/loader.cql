-- create keyspace-------------------------------------------------------------------------------------
DROP KEYSPACE IF EXISTS sampledb;
CREATE KEYSPACE IF NOT EXISTS sampledb WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3}
AND durable_writes = true;

USE sampledb; 

CONSISTENCY one;
-- create table ----------------------------------------------------------------------------------------
CREATE TABLE R1 (
    R1_ID INT PRIMARY KEY,
);

CREATE TABLE R2 (
    R2_ID INT PRIMARY KEY,
);



-- import data from csv-----------------------------------------------------------------------------------------
COPY R1(R1_ID)
FROM '<path to R1.csv>' WITH DELIMITER=',' AND HEADER=FALSE AND CHUNKSIZE=1000 AND NUMPROCESSES=15;

-- For district.csv
COPY R2(R2_ID)
FROM '<path to R2.csv>' WITH DELIMITER=',' AND HEADER=FALSE AND CHUNKSIZE=1000 AND NUMPROCESSES=15;


---Check if tables were created successfully-------------------------------------------------------------------------------------

--List all keyspaces
DESCRIBE KEYSPACES;

--List all tables within sampledb
USE sampledb;
DESCRIBE TABLES;

--Describe the structure of the sample tables
DESCRIBE TABLE R1;
DESCRIBE TABLE R2;


--Display the first 10 rows from all sample tables
SELECT * FROM R1 LIMIT 10;
SELECT * FROM R2 LIMIT 10;
