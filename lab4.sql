-- Funkcje
-- Zad 1
CREATE
OR REPLACE FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID % TYPE) RETURN JOBS.JOB_TITLE % TYPE IS v_job_name JOBS.JOB_TITLE % TYPE;

BEGIN
SELECT
    JOB_TITLE INTO v_job_name
FROM
    JOBS
WHERE
    JOB_ID = get_job_name.p_job_id;

IF v_job_name IS NULL THEN RAISE_APPLICATION_ERROR(-20001, 'Praca o podanym ID nie istnieje.');

END IF;

RETURN v_job_name;

END get_job_name;

DECLARE res JOBS.JOB_TITLE % TYPE;

BEGIN res := get_job_name('AD_VP');

DBMS_OUTPUT.PUT_LINE('Wynik: ' || res);

END;

-- Zad 2
CREATE
OR REPLACE FUNCTION get_avg_salary(p_job_id IN EMPLOYEES.EMPLOYEE_ID % TYPE) RETURN NUMBER IS v_avg_salary NUMBER;

v_salary EMPLOYEES.SALARY % TYPE;

v_commission_pct EMPLOYEES.COMMISSION_PCT % TYPE;

BEGIN
SELECT
    SALARY,
    COMMISSION_PCT INTO v_salary,
    v_commission_pct
FROM
    EMPLOYEES
WHERE
    EMPLOYEE_ID = p_job_id;

IF v_commission_pct IS NULL THEN v_avg_salary := v_salary * 12;

ELSE v_avg_salary := v_salary * 12 + (v_salary * v_commission_pct);

END IF;

IF v_salary IS NULL THEN RAISE_APPLICATION_ERROR(-20001, 'Pracownik o podanym ID nie istnieje.');

END IF;

RETURN v_avg_salary;

END get_avg_salary;

DECLARE res NUMBER;

BEGIN res := get_avg_salary(199);

DBMS_OUTPUT.PUT_LINE('Wynik: ' || res);

END;

-- Zad 3
create
or replace FUNCTION extract_area_code(p_phone_number IN EMPLOYEES.PHONE_NUMBER % TYPE) RETURN VARCHAR2 IS v_area_code VARCHAR2(10);

BEGIN v_area_code := SUBSTR(
    p_phone_number,
    1,
    INSTR(p_phone_number, '-') - 1
);

RETURN '(' || v_area_code || ')';

END extract_area_code;

DECLARE res VARCHAR2(10);

BEGIN res := extract_area_code('48-123321231');

DBMS_OUTPUT.PUT_LINE('Wynik: ' || res);

END;

-- Zad 4