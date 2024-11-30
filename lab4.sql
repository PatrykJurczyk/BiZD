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
CREATE
OR REPLACE FUNCTION capitalize_first_and_last(input_str IN VARCHAR2) RETURN VARCHAR2 IS v_result_str VARCHAR2(100);

BEGIN v_result_str := INITCAP(SUBSTR(input_str, 1, 1));

v_result_str := v_result_str || LOWER(SUBSTR(input_str, 2, LENGTH(input_str) - 2));

v_result_str := v_result_str || INITCAP(SUBSTR(input_str, LENGTH(input_str)));

RETURN v_result_str;

END capitalize_first_and_last;

DECLARE res VARCHAR2(40);

BEGIN res := capitalize_first_and_last('jakistext');

DBMS_OUTPUT.PUT_LINE('Wynik: ' || res);

END;

-- Zad 5
CREATE
OR REPLACE FUNCTION get_birth_date(input_str IN VARCHAR2) RETURN VARCHAR2 IS year_part VARCHAR2(4);

month_part VARCHAR2(2);

day_part VARCHAR2(2);

full_date VARCHAR2(10);

BEGIN year_part := SUBSTR(input_str, 1, 2);

month_part := SUBSTR(input_str, 3, 2);

day_part := SUBSTR(input_str, 5, 2);

IF TO_NUMBER(month_part) BETWEEN 1
AND 12 THEN year_part := '19' || year_part;

-- XX wiek
ELSIF TO_NUMBER(month_part) BETWEEN 21
AND 32 THEN year_part := '20' || year_part;

-- XXI wiek
month_part := TO_CHAR(TO_NUMBER(month_part) - 20, 'FM00');

ELSIF TO_NUMBER(month_part) BETWEEN 41
AND 52 THEN year_part := '21' || year_part;

-- XXII wiek
month_part := TO_CHAR(TO_NUMBER(month_part) - 40, 'FM00');

ELSIF TO_NUMBER(month_part) BETWEEN 61
AND 72 THEN year_part := '22' || year_part;

-- XXIII wiek
month_part := TO_CHAR(TO_NUMBER(month_part) - 60, 'FM00');

ELSE RETURN NULL;

END IF;

full_date := year_part || '-' || month_part || '-' || day_part;

RETURN full_date;

END get_birth_date;

DECLARE res VARCHAR2(40);

BEGIN res := get_birth_date('01232812432');

DBMS_OUTPUT.PUT_LINE('Wynik: ' || res);

END;

-- Zad 6
create
or replace FUNCTION get_employee_and_department_count(
    country_name IN VARCHAR2,
    v_department_count OUT NUMBER
) RETURN NUMBER IS v_employee_count NUMBER;

BEGIN
SELECT
    COUNT(DISTINCT employees.employee_id),
    COUNT(DISTINCT departments.DEPARTMENT_ID) INTO v_employee_count,
    v_department_count
FROM
    employees
    LEFT JOIN departments ON employees.department_id = departments.department_id
    LEFT JOIN locations ON departments.location_id = locations.location_id
WHERE
    locations.COUNTRY_ID = (
        SELECT
            COUNTRY_ID
        FROM
            COUNTRIES
        WHERE
            COUNTRIES.COUNTRY_NAME = get_employee_and_department_count.country_name
    );

IF v_employee_count = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Brak danych dla podanego kraju.');

END IF;

RETURN v_employee_count;

END get_employee_and_department_count;

DECLARE employee_count NUMBER;

department_count NUMBER;

BEGIN employee_count := get_employee_and_department_count('Canada', department_count);

DBMS_OUTPUT.PUT_LINE('Liczba pracowników: ' || employee_count);

DBMS_OUTPUT.PUT_LINE('Liczba departamentów: ' || department_count);

END;