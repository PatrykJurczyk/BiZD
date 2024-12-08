CREATE OR REPLACE PROCEDURE buy_house(
    p_property_id IN NUMBER,
    p_client_id IN NUMBER,
    p_worker_id IN NUMBER,
    p_final_price IN FLOAT
) AS
    v_status_transakcji VARCHAR2(20) := 'completed';
    v_property_exists NUMBER;
    v_client_exists NUMBER;
    v_worker_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_property_exists
    FROM Property
    WHERE ID = p_property_id;

    IF v_property_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nieruchomość o podanym ID nie istnieje.');
    END IF;

    SELECT COUNT(*) INTO v_client_exists
    FROM Client
    WHERE ID = p_client_id;

    IF v_client_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Klient o podanym ID nie istnieje.');
    END IF;

    SELECT COUNT(*) INTO v_worker_exists
    FROM Worker
    WHERE ID = p_worker_id;

    IF v_worker_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Pracownik o podanym ID nie istnieje.');
    END IF;

    INSERT INTO Transaction (property_id, client_id, worker_id, final_price, status_transakcji)
    VALUES (p_property_id, p_client_id, p_worker_id, p_final_price, v_status_transakcji);
    COMMIT;

    DELETE FROM Property WHERE ID = p_property_id;
    COMMIT;

    INSERT INTO Operation_Log (table_name, record_id, operation_type, operation_message)
    VALUES ('Transaction', p_property_id, 'INSERT', 'Zakończono zakup nieruchomości.');
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END buy_house;

/
