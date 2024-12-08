-- ### 2. Procedury, funkcje, wyzwalacze obsługujące tabelę Worker ###

-- #### a. Dodawanie, usuwanie, aktualizacja rekordów ####

-- 1. Procedura dodająca nowego pracownika
CREATE OR REPLACE PROCEDURE add_worker(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    INSERT INTO Worker (name, surname, role, phone)
    VALUES (p_name, p_surname, p_role, p_phone);
    COMMIT;
END add_worker;
/

-- 2. Procedura usuwająca pracownika
CREATE OR REPLACE PROCEDURE delete_worker(
    p_worker_id IN NUMBER
) AS
BEGIN
    DELETE FROM Worker WHERE ID = p_worker_id;
    COMMIT;
END delete_worker;
/

-- 3. Procedura aktualizująca dane pracownika
CREATE OR REPLACE PROCEDURE update_worker(
    p_worker_id IN NUMBER,
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    UPDATE Worker
    SET name = p_name,
        surname = p_surname,
        role = p_role,
        phone = p_phone
    WHERE ID = p_worker_id;
    COMMIT;
END update_worker;
/

-- #### b. Archiwizacja usuniętych danych ####

-- Wyzwalacz do archiwizacji danych przed usunięciem z tabeli Worker
CREATE OR REPLACE TRIGGER archive_worker_before_delete
BEFORE DELETE ON Worker
FOR EACH ROW
DECLARE
    v_record_data CLOB;
BEGIN
    -- Przygotowanie danych w formacie JSON do archiwizacji
    v_record_data := '{"ID": "' || :OLD.ID || '", "name": "' || :OLD.name || '", "surname": "' || :OLD.surname || '", "role": "' || :OLD.role || '", "phone": "' || :OLD.phone || '"}';
    INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
    VALUES (NULL, 'worker', v_record_data, 'yes');
END archive_worker_before_delete;
/

-- #### c. Logowanie informacji do tabeli ####

-- Procedura logująca operacje na danych todo to chyba do poprawy
CREATE OR REPLACE PROCEDURE log_worker_operation(
    p_operation IN VARCHAR2,
    p_worker_id IN NUMBER,
    p_message IN VARCHAR2
) AS
BEGIN
    INSERT INTO Validation_Error (table_name, row_data, error_message)
    VALUES ('Worker', '{"worker_id": "' || p_worker_id || '"}', p_message || ' (' || p_operation || ')');
    COMMIT;
END log_worker_operation;
/

-- #### d. Obsługa wyjątków ####

-- Procedura dodająca nowego pracownika z obsługą wyjątków
CREATE OR REPLACE PROCEDURE add_worker_with_exceptions(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    -- Sprawdzanie wymaganych pól
    IF p_name IS NULL OR p_surname IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Imię i nazwisko są wymagane.');
    END IF;

    -- Wstawienie rekordu
    INSERT INTO Worker (name, surname, role, phone)
    VALUES (p_name, p_surname, p_role, p_phone);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        log_worker_operation('ADD', NULL, 'Błąd podczas dodawania pracownika: ' || SQLERRM);
        RAISE;
END add_worker_with_exceptions;
/

-- #### e. Procedury, funkcje z parametrami i funkcje okienkowe ####

-- Funkcja zwracająca liczbę pracowników według roli z parametrem domyślnym
CREATE OR REPLACE FUNCTION count_workers_by_role(
    p_role IN VARCHAR2 DEFAULT 'broker'
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Worker WHERE role = p_role;
    RETURN v_count;
END count_workers_by_role;
/

-- Funkcja okienkowa: najstarszy pracownik na każdym stanowisku
CREATE OR REPLACE FUNCTION oldest_worker_by_role() RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT role, name, surname, phone
    FROM (
        SELECT role, name, surname, phone,
               RANK() OVER (PARTITION BY role ORDER BY ID ASC) AS rnk
        FROM Worker
    ) WHERE rnk = 1;
    RETURN v_cursor;
END oldest_worker_by_role;
/

-- #### f. Sprawdzanie poprawności dodawanych danych ####

-- Funkcja walidująca numer telefonu
CREATE OR REPLACE FUNCTION validate_phone_number(
    p_phone IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF LENGTH(p_phone) = 12 AND REGEXP_LIKE(p_phone, '^[0-9]{12}$') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_phone_number;
/

-- Funkcja walidująca imię i nazwisko (same litery)
CREATE OR REPLACE FUNCTION validate_name(
    p_name IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF REGEXP_LIKE(p_name, '^[A-Za-z]+$') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_name;
/

-- Procedura dodająca pracownika z walidacją
CREATE OR REPLACE PROCEDURE add_worker_with_validation(
    p_name IN VARCHAR2,
    p_surname IN VARCHAR2,
    p_role IN VARCHAR2,
    p_phone IN VARCHAR2
) AS
BEGIN
    -- Walidacja numeru telefonu
    IF NOT validate_phone_number(p_phone) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Numer telefonu jest niepoprawny.');
    END IF;

    -- Walidacja imienia i nazwiska
    IF NOT validate_name(p_name) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Imię zawiera niedozwolone znaki.');
    END IF;

    IF NOT validate_name(p_surname) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nazwisko zawiera niedozwolone znaki.');
    END IF;

    -- Dodanie rekordu po walidacji
    INSERT INTO Worker (name, surname, role, phone)
    VALUES (p_name, p_surname, p_role, p_phone);
    COMMIT;
END add_worker_with_validation;
/
