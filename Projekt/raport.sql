CREATE OR REPLACE PROCEDURE generate_transaction_report (
    p_period_type IN VARCHAR2
) AS
    v_start_date DATE;
    v_end_date DATE;
    v_total_transactions NUMBER;
    v_total_revenue FLOAT;
BEGIN
    IF p_period_type = 'month' THEN
        v_start_date := TRUNC(SYSDATE, 'MM');
        v_end_date := LAST_DAY(SYSDATE);
    ELSIF p_period_type = 'quarter' THEN
        v_start_date := TRUNC(SYSDATE, 'Q');
        v_end_date := ADD_MONTHS(TRUNC(SYSDATE, 'Q'), 3) - 1;
    ELSIF p_period_type = 'year' THEN
        v_start_date := TRUNC(SYSDATE, 'YYYY');
        v_end_date := LAST_DAY(ADD_MONTHS(SYSDATE, 12));
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Niepoprawny parametr period_type.');
    END IF;

    SELECT COUNT(*) AS total_transactions,
           SUM(TO_NUMBER(JSON_VALUE(record_data, '$.final_price'))) AS total_revenue
    INTO v_total_transactions, v_total_revenue
    FROM Processed_Data
    WHERE data_type = 'transaction'
      AND timestamp BETWEEN v_start_date AND v_end_date;

    INSERT INTO Summary_Report (period_type, period_start, period_end, total_transactions, total_revenue)
    VALUES (p_period_type, v_start_date, v_end_date, v_total_transactions, v_total_revenue);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END generate_transaction_report;
/


-- Wywołąnie 

EXECUTE generate_transaction_report('month');
EXECUTE generate_transaction_report('quarter');
EXECUTE generate_transaction_report('year');
