-- 1. Funkcja validate_phone_number
CREATE OR REPLACE FUNCTION validate_phone_number(
    p_phone IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF REGEXP_LIKE(p_phone, '^[0-9]{9,12}$') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_phone_number;
/

-- 2. Funkcja validate_name_surname
CREATE OR REPLACE FUNCTION validate_name_surname(
    p_name IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF REGEXP_LIKE(p_name, '^[A-Za-z]+$') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_name_surname;
/

-- 3. Procedura validate_data
CREATE OR REPLACE PROCEDURE validate_data(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    IF NOT validate_phone_number(p_phone) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Numer telefonu jest niepoprawny.');
    END IF;

    IF NOT validate_name_surname(p_name) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Imię zawiera niedozwolone znaki.');
    END IF;

    IF NOT validate_name_surname(p_surname) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nazwisko zawiera niedozwolone znaki.');
    END IF;
END validate_data;
/

-- 4. Procedura add_worker
CREATE OR REPLACE PROCEDURE add_worker(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    validate_data(p_name, p_surname, p_phone);

    INSERT INTO Worker (name, surname, role, phone)
    VALUES (p_name, p_surname, p_role, p_phone);
    COMMIT;
END add_worker;
/

-- 5. Procedura update_worker
CREATE OR REPLACE PROCEDURE update_worker(
    p_worker_id IN NUMBER,
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    validate_data(p_name, p_surname, p_phone);

    UPDATE Worker
    SET name = p_name,
        surname = p_surname,
        role = p_role,
        phone = p_phone
    WHERE ID = p_worker_id;
    COMMIT;
END update_worker;
/

-- 6. Procedura delete_worker
CREATE OR REPLACE PROCEDURE delete_worker(
    p_worker_id IN NUMBER
) AS
BEGIN
    DELETE FROM Worker WHERE ID = p_worker_id;
    COMMIT;
END delete_worker;
/

-- 7. Wyzwalacz archive_worker_before_delete
CREATE OR REPLACE TRIGGER archive_worker_before_delete
BEFORE DELETE ON Worker
FOR EACH ROW
DECLARE
    v_record_data CLOB;
BEGIN
    v_record_data := '{"ID": "' || :OLD.ID || '", "name": "' || :OLD.name || '", "surname": "' || :OLD.surname || '", "role": "' || :OLD.role || '", "phone": "' || :OLD.phone || '"}';
    INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
    VALUES (NULL, 'worker', v_record_data, 'yes');
END archive_worker_before_delete;
/

-- 8. Wyzwalacz log_worker_operations
CREATE OR REPLACE TRIGGER log_worker_operations
AFTER INSERT OR UPDATE OR DELETE ON Worker
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(20);
    v_message VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
        v_message := 'Dodano nowego pracownika.';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
        v_message := 'Zaktualizowano dane pracownika.';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
        v_message := 'Usunięto pracownika.';
    END IF;

    INSERT INTO Operation_Log (table_name, record_id, operation_type, operation_message)
    VALUES ('Worker', NVL(:NEW.ID, :OLD.ID), v_operation_type, v_message);
END log_worker_operations;
/

-- 9. Procedura add_worker_with_exceptions
create or replace PROCEDURE add_worker_with_exceptions(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    IF p_name IS NULL OR p_surname IS NULL OR p_role IS NULL OR p_phone IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Imię, nazwisko, rola, telefon są wymagane.');
    END IF;

    INSERT INTO Worker (name, surname, role, phone)
    VALUES (p_name, p_surname, p_role, p_phone);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DECLARE
            v_error_message VARCHAR2(255);
            v_row_data CLOB;
        BEGIN
            v_error_message := 'Błąd podczas dodawania pracownika: ' || SQLERRM;

            v_row_data := TO_CLOB('{"name": "' || p_name || '", "surname": "' || p_surname || '", "role": "' || p_role || '", "phone": "' || p_phone || '"}');

            INSERT INTO Validation_Error (table_name, row_data, error_message)
            VALUES ('Worker', v_row_data, v_error_message);
            COMMIT;
        END;

        RAISE;
END add_worker_with_exceptions;
/

-- 10. Funkcja count_workers_by_role
CREATE OR REPLACE FUNCTION count_workers_by_role(
    p_role IN VARCHAR2 DEFAULT 'broker'
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Worker WHERE role = p_role;
    RETURN v_count;
END count_workers_by_role;
/

-- Wywołanie 

SELECT validate_phone_number('123456789') FROM dual;
SELECT validate_name_surname('Jan') FROM dual;
EXEC validate_data('Jan', 'Kowalski', '123456789');
EXEC add_worker('Jan', 'Kowalski', 'manager', '123456789');
EXEC update_worker(1, 'Jan', 'Brzęczyszczykiewicz', 'manager', '123456789');
EXEC delete_worker(1);
EXEC add_worker_with_exceptions('Jan1', 'Kowalski', 'broker', '123456789');
SELECT count_workers_by_role('manager') FROM dual;
