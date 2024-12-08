CREATE OR REPLACE FUNCTION validate_property_type(
    p_type IN VARCHAR2
) RETURN BOOLEAN AS
BEGIN
    IF p_type IN ('flat', 'building', 'land') THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_property_type;
/

CREATE OR REPLACE PROCEDURE validate_property_data(
    p_type IN VARCHAR2,
    p_area IN NUMBER,
    p_sqm_price IN NUMBER
) AS
BEGIN
    IF NOT validate_property_type(p_type) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Typ nieruchomości jest niepoprawny.');
    END IF;

    IF p_area <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Powierzchnia nieruchomości musi być większa niż zero.');
    END IF;

    IF p_sqm_price <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Cena za m² musi być większa niż zero.');
    END IF;
END validate_property_data;
/

CREATE OR REPLACE PROCEDURE add_property(
    p_type IN VARCHAR2,
    p_address IN VARCHAR2,
    p_area IN FLOAT,
    p_rooms IN NUMBER,
    p_sqm_price IN FLOAT,
    p_description IN CLOB
) AS
BEGIN
    validate_property_data(p_type, p_area, p_sqm_price);

    INSERT INTO Property (type, address, area, rooms, sqm_price, description)
    VALUES (p_type, p_address, p_area, p_rooms, p_sqm_price, p_description);
    COMMIT;
END add_property;
/

CREATE OR REPLACE PROCEDURE update_property(
    p_property_id IN NUMBER,
    p_type IN VARCHAR2,
    p_address IN VARCHAR2,
    p_area IN FLOAT,
    p_rooms IN NUMBER,
    p_sqm_price IN FLOAT,
    p_description IN CLOB
) AS
BEGIN
    validate_property_data(p_type, p_area, p_sqm_price);

    UPDATE Property
    SET type = p_type,
        address = p_address,
        area = p_area,
        rooms = p_rooms,
        sqm_price = p_sqm_price,
        description = p_description
    WHERE ID = p_property_id;
    COMMIT;
END update_property;
/

CREATE OR REPLACE PROCEDURE delete_property(
    p_property_id IN NUMBER
) AS
BEGIN
    DELETE FROM Property WHERE ID = p_property_id;
    COMMIT;
END delete_property;
/

CREATE OR REPLACE TRIGGER archive_property_before_delete
BEFORE DELETE ON Property
FOR EACH ROW
DECLARE
    v_record_data CLOB;
BEGIN
    v_record_data := '{"ID": "' || :OLD.ID || '", "type": "' || :OLD.type || '", "address": "' || :OLD.address || '", "area": "' || :OLD.area || '", "rooms": "' || :OLD.rooms || '", "sqm_price": "' || :OLD.sqm_price || '", "description": "' || :OLD.description || '"}';
    INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
    VALUES (NULL, 'property', v_record_data, 'yes');
END archive_property_before_delete;
/

CREATE OR REPLACE TRIGGER log_property_operations
AFTER INSERT OR UPDATE OR DELETE ON Property
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(20);
    v_message VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
        v_message := 'Dodano nową nieruchomość.';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
        v_message := 'Zaktualizowano dane nieruchomości.';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
        v_message := 'Usunięto nieruchomość.';
    END IF;

    INSERT INTO Operation_Log (table_name, record_id, operation_type, operation_message)
    VALUES ('Property', NVL(:NEW.ID, :OLD.ID), v_operation_type, v_message);
END log_property_operations;
/

CREATE OR REPLACE PROCEDURE add_property_with_exceptions(
    p_type IN VARCHAR2,
    p_address IN VARCHAR2,
    p_area IN FLOAT,
    p_rooms IN NUMBER,
    p_sqm_price IN FLOAT,
    p_description IN CLOB
) AS
BEGIN
    IF p_type IS NULL OR p_address IS NULL OR p_area IS NULL OR p_sqm_price IS NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'Typ, adres nieruchomości, powierzchnia, cena za metr jest wymagana.');
    END IF;

    INSERT INTO Property (type, address, area, rooms, sqm_price, description)
    VALUES (p_type, p_address, p_area, p_rooms, p_sqm_price, p_description);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DECLARE
            v_error_message VARCHAR2(255);
            v_row_data CLOB;
        BEGIN
            v_error_message := 'Błąd podczas dodawania nieruchomości: ' || SQLERRM;
            v_row_data := TO_CLOB('{"type": "' || p_type || '", "address": "' || p_address || '", "area": "' || p_area || '", "rooms": "' || p_rooms || '", "sqm_price": "' || p_sqm_price || '", "description": "' || p_description || '"}');

            INSERT INTO Validation_Error (table_name, row_data, error_message)
            VALUES ('Property', v_row_data, v_error_message);
            COMMIT;
        END;

        RAISE;
END add_property_with_exceptions;
/

-- 7. Funkcja okienkowa
SELECT type, COUNT(*) OVER (PARTITION BY type) AS properties_count
FROM Property
WHERE type = 'flat';
/

-- Wywołanie

SELECT validate_property_type('flat') FROM dual;
EXEC add_property('flat', 'Warszawa, ul. Przykładowa 1', 50, 3, 5000, 'Kawalerka w centrum miasta');
EXEC update_property(1, 'building', 'Warszawa, ul. Nowa 2', 100, 5, 4500, 'Budynek biurowy');
EXEC delete_property(1);
EXEC add_property_with_exceptions('', 'Warszawa, ul. Ziemia 3', 2000, NULL, 100, NULL);
