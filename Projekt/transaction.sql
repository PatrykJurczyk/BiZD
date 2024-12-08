CREATE OR REPLACE FUNCTION validate_transaction_status(
    p_status IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF p_status IN ('started', 'completed', 'cancelled') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_transaction_status;
/

CREATE OR REPLACE PROCEDURE validate_transaction_data(
    p_status_transakcji IN VARCHAR2,
    p_final_price IN FLOAT
) AS
BEGIN
    IF NOT validate_transaction_status(p_status_transakcji) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Status transakcji jest niepoprawny.');
    END IF;

    IF p_final_price <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cena finalna musi być większa niż zero.');
    END IF;
END validate_transaction_data;
/

CREATE OR REPLACE PROCEDURE add_transaction(
    p_property_id IN NUMBER,
    p_client_id IN NUMBER,
    p_worker_id IN NUMBER,
    p_final_price IN FLOAT,
    p_status_transakcji IN VARCHAR2
) AS
BEGIN
    validate_transaction_data(p_status_transakcji, p_final_price);

    INSERT INTO Transaction (property_id, client_id, worker_id, final_price, status_transakcji)
    VALUES (p_property_id, p_client_id, p_worker_id, p_final_price, p_status_transakcji);
    COMMIT;
END add_transaction;
/

CREATE OR REPLACE PROCEDURE update_transaction(
    p_transaction_id IN NUMBER,
    p_property_id IN NUMBER,
    p_client_id IN NUMBER,
    p_worker_id IN NUMBER,
    p_final_price IN FLOAT,
    p_status_transakcji IN VARCHAR2
) AS
BEGIN
    validate_transaction_data(p_status_transakcji, p_final_price);

    UPDATE Transaction
    SET property_id = p_property_id,
        client_id = p_client_id,
        worker_id = p_worker_id,
        final_price = p_final_price,
        status_transakcji = p_status_transakcji
    WHERE ID = p_transaction_id;
    COMMIT;
END update_transaction;
/

CREATE OR REPLACE PROCEDURE delete_transaction(
    p_transaction_id IN NUMBER
) AS
BEGIN
    DELETE FROM Transaction WHERE ID = p_transaction_id;
    COMMIT;
END delete_transaction;
/

CREATE OR REPLACE TRIGGER archive_transaction_before_delete
BEFORE DELETE ON Transaction
FOR EACH ROW
DECLARE
    v_record_data CLOB;
BEGIN
    v_record_data := '{"ID": "' || :OLD.ID || '", "property_id": ' || :OLD.property_id || ', "client_id": ' || :OLD.client_id || ', "worker_id": ' || :OLD.worker_id || ', "final_price": ' || :OLD.final_price || ', "status_transakcji": "' || :OLD.status_transakcji || '"}';
    INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
    VALUES (NULL, 'transaction', v_record_data, 'yes');
END archive_transaction_before_delete;
/

CREATE OR REPLACE TRIGGER log_transaction_operations
AFTER INSERT OR UPDATE OR DELETE ON Transaction
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(20);
    v_message VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
        v_message := 'Dodano nową transakcję.';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
        v_message := 'Zaktualizowano transakcję.';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
        v_message := 'Usunięto transakcję.';
    END IF;

    INSERT INTO Operation_Log (table_name, record_id, operation_type, operation_message)
    VALUES ('Transaction', NVL(:NEW.ID, :OLD.ID), v_operation_type, v_message);
END log_transaction_operations;
/

CREATE OR REPLACE PROCEDURE add_transaction_with_exceptions(
    p_property_id IN NUMBER,
    p_client_id IN NUMBER,
    p_worker_id IN NUMBER,
    p_final_price IN FLOAT,
    p_status_transakcji IN VARCHAR2
) AS
BEGIN
    IF p_property_id IS NULL OR p_client_id IS NULL OR p_worker_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID nieruchomości, klienta i pracownika są wymagane.');
    END IF;

    INSERT INTO Transaction (property_id, client_id, worker_id, final_price, status_transakcji)
    VALUES (p_property_id, p_client_id, p_worker_id, p_final_price, p_status_transakcji);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DECLARE
            v_error_message VARCHAR2(255);
            v_row_data CLOB;
        BEGIN
            v_error_message := 'Błąd podczas dodawania transakcji: ' || SQLERRM;
            v_row_data := TO_CLOB('{"property_id": "' || p_property_id || '", "client_id": "' || p_client_id || '", "worker_id": "' || p_worker_id || '"}');

            INSERT INTO Validation_Error (table_name, row_data, error_message)
            VALUES ('Transaction', v_row_data, v_error_message);
            COMMIT;
        END;

        RAISE;
END add_transaction_with_exceptions;
/

SELECT status_transakcji, property_id, client_id, worker_id, final_price
FROM (
    SELECT status_transakcji, property_id, client_id, worker_id, final_price,
           RANK() OVER (PARTITION BY status_transakcji ORDER BY final_price DESC) AS rnk
    FROM Transaction
)
WHERE rnk = 1;

/


-- Wywołanie
EXEC add_transaction(2, 2, 2, 100000, 'completed');
EXEC update_transaction(6, 2, 2, 2, 120000, 'started');
EXEC delete_transaction(1);
EXEC add_transaction_with_exceptions(1, 2, 3, 100000, 'completed');
