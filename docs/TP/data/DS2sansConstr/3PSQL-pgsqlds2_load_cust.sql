ALTER TABLE CUSTOMERS DISABLE TRIGGER ALL;

\COPY CUSTOMERS FROM  '/Users/frederic 1/Travail/Enseignement/UNC/Cours/BD2/2013/TP/TP1/installation/data_files/cust/us_cust.csv' WITH DELIMITER   ',' 
\COPY CUSTOMERS FROM  '/Users/frederic 1/Travail/Enseignement/UNC/Cours/BD2/2013/TP/TP1/installation/data_files/cust/row_cust.csv' WITH DELIMITER  ',' 


ALTER TABLE CUSTOMERS ENABLE TRIGGER ALL;
