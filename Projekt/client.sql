-- 1. Procedura: add_client
CREATE OR REPLACE PROCEDURE add_client(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    validate_data(p_name, p_surname, p_phone);

    INSERT INTO Client (name, surname, phone)
    VALUES (p_name, p_surname, p_phone);
    COMMIT;
END add_client;
/

-- 2. Procedura: update_client
CREATE OR REPLACE PROCEDURE update_client(
    p_client_id IN NUMBER,
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    validate_data(p_name, p_surname, p_phone);

    UPDATE Client
    SET name = p_name,
        surname = p_surname,
        phone = p_phone
    WHERE ID = p_client_id;
    COMMIT;
END update_client;
/

-- 3. Procedura: delete_client
CREATE OR REPLACE PROCEDURE delete_client(
    p_client_id IN NUMBER
) AS
BEGIN
    DELETE FROM Client WHERE ID = p_client_id;
    COMMIT;
END delete_client;
/

-- 4. Trigger: archive_client_before_delete
CREATE OR REPLACE TRIGGER archive_client_before_delete
BEFORE DELETE ON Client
FOR EACH ROW
DECLARE
    v_record_data CLOB;
BEGIN
    v_record_data := '{"ID": "' || :OLD.ID || '", "name": "' || :OLD.name || '", "surname": "' || :OLD.surname || '", "phone": "' || :OLD.phone || '"}';
    INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
    VALUES (NULL, 'client', v_record_data, 'yes');
END archive_client_before_delete;
/

-- 5. Trigger: log_client_operations
CREATE OR REPLACE TRIGGER log_client_operations
AFTER INSERT OR UPDATE OR DELETE ON Client
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(20);
    v_message VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
        v_message := 'Dodano nowego klienta.';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
        v_message := 'Zaktualizowano dane klienta.';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
        v_message := 'Usunięto klienta.';
    END IF;

    INSERT INTO Operation_Log (table_name, record_id, operation_type, operation_message)
    VALUES ('Client', NVL(:NEW.ID, :OLD.ID), v_operation_type, v_message);
END log_client_operations;
/

-- 6. Procedura: add_client_with_exceptions
create or replace PROCEDURE add_client_with_exceptions(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    IF p_name IS NULL OR p_surname IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Imię i nazwisko są wymagane.');
    END IF;

    INSERT INTO Client (name, surname, phone)
    VALUES (p_name, p_surname, p_phone);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DECLARE
            v_error_message VARCHAR2(255);
            v_row_data CLOB;
        BEGIN
            v_error_message := 'Błąd podczas dodawania klienta: ' || SQLERRM;

            v_row_data := TO_CLOB('{"name": "' || p_name || '", "surname": "' || p_surname || '", "phone": "' || p_phone || '"}');

            INSERT INTO Validation_Error (table_name, row_data, error_message)
            VALUES ('Client', v_row_data, v_error_message);
            COMMIT;
        END;

        RAISE;
END add_client_with_exceptions;
/

-- 7. Funkcja okienkowa
SELECT name, surname, phone
FROM (
    SELECT name, surname, phone,
           RANK() OVER (ORDER BY ID DESC) AS rnk
    FROM Client
) subquery
WHERE rnk = 1;

/

-- Wywołanie

EXECUTE add_client('Jan', 'Kowalski', '123456789');
EXECUTE update_client(1, 'Jan', 'Nowak', '987654321');
EXECUTE delete_client(1);
EXECUTE add_client_with_exceptions('Jan', 'Kowalski', '123456789');
