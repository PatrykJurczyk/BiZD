-- Paczki
-- Zad 1
CREATE
OR REPLACE PACKAGE function_package IS FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID % TYPE) RETURN JOBS.JOB_TITLE % TYPE;

FUNCTION get_avg_salary(p_job_id IN EMPLOYEES.EMPLOYEE_ID % TYPE) RETURN NUMBER;

FUNCTION extract_area_code(p_phone_number IN EMPLOYEES.PHONE_NUMBER % TYPE) RETURN VARCHAR2;

FUNCTION capitalize_first_and_last(input_str IN VARCHAR2) RETURN VARCHAR2;

FUNCTION get_birth_date(input_str IN VARCHAR2) RETURN VARCHAR2;

FUNCTION get_employee_and_department_count(
    country_name IN VARCHAR2,
    v_department_count OUT NUMBER
) RETURN NUMBER;

END function_package;

-- Funkcje
CREATE
OR REPLACE PACKAGE BODY function_package IS -- Zad 1
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

END function_package;

-- Wyzwalacze
-- Zad 1
CREATE TABLE archiwum_departamentow (
    id NUMBER,
    nazwa VARCHAR2(100),
    data_zamknięcia DATE,
    ostatni_manager VARCHAR2(200)
);

CREATE
OR REPLACE TRIGGER after_department_delete
AFTER
    DELETE ON departments FOR EACH ROW DECLARE v_nazwa_departamentu VARCHAR2(100);

v_ostatni_manager VARCHAR2(200);

BEGIN v_nazwa_departamentu := :OLD.department_name;

SELECT
    employees.first_name || ' ' || employees.last_name INTO v_ostatni_manager
FROM
    employees
WHERE
    employees.employee_id = :OLD.manager_id;

INSERT INTO
    archiwum_departamentow (id, nazwa, data_zamknięcia, ostatni_manager)
VALUES
    (
        :OLD.department_id,
        v_nazwa_departamentu,
        SYSDATE,
        v_ostatni_manager
    );

END after_department_delete;

INSERT INTO
    DEPARTMENTS
VALUES
    (2341, 'TEST', 100, 1000);

SELECT
    *
FROM
    DEPARTMENTS
WHERE
    department_id = 2341;

SELECT
    *
FROM
    archiwum_departamentow;

DELETE FROM
    DEPARTMENTS
WHERE
    department_id = 2341;

SELECT
    *
FROM
    archiwum_departamentow;

-- Zad 2
CREATE TABLE zlodziej (
    id NUMBER,
    user_name VARCHAR2(100),
    czas_zmiany DATE
);

CREATE
OR REPLACE TRIGGER check_salary_range BEFORE
INSERT
    OR
UPDATE
    OF salary ON EMPLOYEES FOR EACH ROW DECLARE PRAGMA AUTONOMOUS_TRANSACTION;

v_employee_name VARCHAR2(200);

BEGIN IF :NEW.salary < 2000
OR :NEW.salary > 26000 THEN v_employee_name := :NEW.first_name || ' ' || :NEW.last_name;

INSERT INTO
    zlodziej (id, user_name, czas_zmiany)
VALUES
    (:NEW.EMPLOYEE_ID, v_employee_name, SYSDATE);

COMMIT;

RAISE_APPLICATION_ERROR(
    -20003,
    'Wynagrodzenie poza dozwolonym zakresem.'
);

END IF;

END check_salary_range;

UPDATE
    EMPLOYEES
SET
    SALARY = 200000
WHERE
    EMPLOYEE_ID = 103;

SELECT
    *
FROM
    zlodziej;

-- Zad 3
CREATE SEQUENCE employee_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE
OR REPLACE TRIGGER auto_increment_trigger BEFORE
INSERT
    ON employees FOR EACH ROW BEGIN IF :NEW.employee_id IS NULL THEN
SELECT
    employee_seq.NEXTVAL INTO :NEW.employee_id
FROM
    dual;

END IF;

END;

INSERT INTO
    EMPLOYEES (FIRST_NAME, LAST_NAME, EMAIL, JOB_ID, HIRE_DATE)
VALUES
    (
        'test',
        'testowo',
        'test@testowo.com',
        'AD_PRES',
        CURRENT_DATE
    );

SELECT
    *
FROM
    EMPLOYEES
where
    FIRST_NAME = 'test';

-- Zad 4
CREATE
OR REPLACE TRIGGER blokada_operacji_na_job_grades BEFORE DELETE
OR
INSERT
    OR
UPDATE
    ON JOB_GRADES BEGIN RAISE_APPLICATION_ERROR(
        -20202,
        'Operacje INSERT, UPDATE, DELETE na tabeli JOB_GRADES są zabronione.'
    );

END;

INSERT INTO
    JOB_GRADES (grade, min_salary, max_salary)
VALUES
    ('A', 2000, 4000);

-- Zad 5
CREATE
OR REPLACE TRIGGER zachowaj_stare_wartosci_salary_jobs BEFORE
UPDATE
    OF min_salary,
    max_salary ON jobs FOR EACH ROW BEGIN :NEW.min_salary := :OLD.min_salary;

:NEW.max_salary := :OLD.max_salary;

END;

UPDATE
    jobs
SET
    min_salary = 5000,
    max_salary = 20000
WHERE
    job_id = '123';

Select
    *
from
    jobs
where
    job_id = '123';