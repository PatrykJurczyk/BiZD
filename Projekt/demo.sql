-- Operacje na Kliencie

EXEC add_client('Jan', 'Kowalski', '123456789');
EXEC update_client(1, 'Jan', 'Nowak', '987654321');
EXEC delete_client(1);
EXEC add_client_with_exceptions('Jan', 'Kowalski', '1234567891011');
SELECT * FROM Operation_Log
SELECT * FROM Validation_Error

SELECT name, surname, phone
FROM (
    SELECT name, surname, phone,
           RANK() OVER (ORDER BY ID DESC) AS rnk
    FROM Client
) subquery
WHERE rnk = 1;

-- Operacje na Pracowniku

EXEC add_worker('Jan', 'Kowalski', 'manager', '123456789');
EXEC update_worker(1, 'Jan', 'Brzęczyszczykiewicz', 'manager', '123456789');
EXEC delete_worker(1);
EXEC add_worker_with_exceptions('Jan1', 'Kowalski', 'broker', '1234567891233');
SELECT count_workers_by_role('manager') FROM dual;
SELECT * FROM Operation_Log
SELECT * FROM Validation_Error

-- Operacje na Nieruchomości

EXEC add_property('flat', 'Warszawa, ul. Przykładowa 1', 50, 3, 5000, 'Kawalerka w centrum miasta');
EXEC update_property(1, 'building', 'Warszawa, ul. Nowa 2', 100, 5, 4500, 'Budynek biurowy');
EXEC delete_property(1);
EXEC add_property_with_exceptions('', 'Warszawa, ul. Ziemia 3', 2000, NULL, 100, NULL);
SELECT * FROM Operation_Log
SELECT * FROM Validation_Error

SELECT type, COUNT(*) OVER (PARTITION BY type) AS properties_count
FROM Property
WHERE type = 'flat';

-- Operacje na Transakcjach

EXEC add_client('Jan', 'Kowalski', '123456789');
EXEC add_worker('Jan', 'Kowalski', 'manager', '123456789');
EXEC add_property('flat', 'Warszawa, ul. Przykładowa 1', 50, 3, 5000, 'Kawalerka w centrum miasta');


EXEC add_transaction(p_property_id => 2, p_client_id => 3, p_worker_id => 3, p_status_transakcji => 'started');
EXEC update_transaction(1, 2, 3, 3, 120000, 'completed');
EXEC delete_transaction(1);
EXEC add_transaction_with_exceptions(1, 2, 3, 100000, 'completed');
SELECT * FROM Operation_Log
SELECT * FROM Validation_Error


SELECT status_transakcji, property_id, client_id, worker_id, final_price
FROM (
    SELECT status_transakcji, property_id, client_id, worker_id, final_price,
           RANK() OVER (PARTITION BY status_transakcji ORDER BY final_price DESC) AS rnk
    FROM Transaction
)
WHERE rnk = 1;

-- Zakup nieruchomości

EXEC buy_house(p_property_id => 2, p_client_id => 3, p_worker_id => 3)

SELECT * FROM Operation_Log

-- Generacja raportu

EXECUTE generate_transaction_report('month');
EXECUTE generate_transaction_report('quarter');
EXECUTE generate_transaction_report('year');

SELECT * FROM Summary_Report

-- Podsumowanie

SELECT * FROM Processed_File
SELECT * FROM Processed_Data
SELECT * FROM Validation_Error


-- Czyszczenie bazy

DELETE FROM TRANSACTION;
DELETE FROM WORKER;
DELETE FROM CLIENT;
DELETE FROM VALIDATION_ERROR;
DELETE FROM OPERATION_LOG;
DELETE FROM PROPERTY;
DELETE FROM SUMMARY_REPORT;
DELETE FROM PROCESSED_DATA;
DELETE FROM PROCESSED_FILE;