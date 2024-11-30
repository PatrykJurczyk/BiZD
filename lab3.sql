-- Zad 1
DECLARE number_max DEPARTMENTS.DEPARTMENT_ID % TYPE;

nowa_nazwa DEPARTMENTS.DEPARTMENT_NAME % TYPE := 'EDUCATION';

BEGIN
SELECT
    MAX(DEPARTMENT_ID) INTO number_max
FROM
    DEPARTMENTS;

dbms_output.put_line(number_max);

INSERT INTO
    DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME)
VALUES
    (number_max + 10, nowa_nazwa);

END;

-- Zad 2
DECLARE number_max DEPARTMENTS.DEPARTMENT_ID % TYPE;

nowa_nazwa DEPARTMENTS.DEPARTMENT_NAME % TYPE := 'EDUCATION';

nowa_location_id NUMBER(4) := 3000;

BEGIN
SELECT
    MAX(DEPARTMENT_ID) INTO number_max
FROM
    DEPARTMENTS;

dbms_output.put_line(number_max);

INSERT INTO
    DEPARTMENTS (
        DEPARTMENT_ID,
        DEPARTMENT_NAME,
        MANAGER_ID,
        LOCATION_ID
    )
VALUES
    (
        number_max + 10,
        nowa_nazwa,
        null,
        nowa_location_id
    );

END;

-- Zad 3
CREATE TABLE NEW_NUMBERS_TABLE (value VARCHAR(10));

DECLARE i NUMBER := 0;

BEGIN
DELETE FROM
    NEW_NUMBERS_TABLE;

LOOP IF i = 4
OR i = 6 THEN i := i + 1;

END IF;

INSERT INTO
    NEW_NUMBERS_TABLE
VALUES
    (i);

i := i + 1;

EXIT
WHEN i >= 10;

end loop;

END;

-- Zad 4
DECLARE kraj COUNTRIES % ROWTYPE;

BEGIN
SELECT
    * INTO kraj
FROM
    COUNTRIES
WHERE
    COUNTRY_ID = 'CA';

DBMS_OUTPUT.PUT_LINE('Nazwa kraju: ' || kraj.COUNTRY_NAME);

DBMS_OUTPUT.PUT_LINE('Region ID: ' || kraj.REGION_ID);

END;

-- Zad 5
DECLARE CURSOR wynagrodzenie_kursor IS
SELECT
    SALARY,
    LAST_NAME
FROM
    EMPLOYEES
WHERE
    DEPARTMENT_ID = 50;

BEGIN FOR wiersz IN wynagrodzenie_kursor LOOP IF wiersz.SALARY > 3100 THEN DBMS_OUTPUT.PUT_LINE(wiersz.LAST_NAME || ' - nie dawać podwyżki');

ELSE DBMS_OUTPUT.PUT_LINE(wiersz.LAST_NAME || ' - dać podwyżkę');

END IF;

END LOOP;

END;

-- Zad 6
DECLARE CURSOR kursor(
    min_zarobki NUMBER,
    max_zarobki NUMBER,
    imie_czesc VARCHAR2
) IS
SELECT
    SALARY,
    LAST_NAME,
    FIRST_NAME
FROM
    EMPLOYEES
WHERE
    SALARY BETWEEN min_zarobki
    AND max_zarobki
    AND LOWER(FIRST_NAME) LIKE '%' || LOWER(imie_czesc) || '%';

BEGIN DBMS_OUTPUT.PUT_LINE(
    'Pracownicy z widełkami 1000-5000 i częścią imienia "a":'
);

FOR pracownikM IN kursor(1000, 5000, 'A') LOOP DBMS_OUTPUT.PUT_LINE(
    pracownikM.FIRST_NAME || ' ' || pracownikM.LAST_NAME || ' - zarobki: ' || pracownikM.SALARY
);

END LOOP;

DBMS_OUTPUT.PUT_LINE(
    'Pracownicy z widełkami 5000-20000 i częścią imienia "u":'
);

FOR pracownikD IN kursor(5000, 20000, 'u') LOOP DBMS_OUTPUT.PUT_LINE(
    pracownikD.FIRST_NAME || ' ' || pracownikD.LAST_NAME || ' - zarobki: ' || pracownikD.SALARY
);

END LOOP;

END;

CREATE
OR REPLACE PACKAGE procedure_package IS PROCEDURE add_job(
    p_job_id JOBS.JOB_ID % TYPE,
    p_job_title JOBS.JOB_TITLE % TYPE
);

PROCEDURE modify_job_title(
    p_job_id JOBS.JOB_ID % TYPE,
    p_job_title JOBS.JOB_TITLE % TYPE
);

PROCEDURE delete_job_row(p_job_id JOBS.JOB_ID % TYPE);

PROCEDURE pracownik_info(
    p_employee_id EMPLOYEES.EMPLOYEE_ID % TYPE,
    v_nazwisko OUT EMPLOYEES.LAST_NAME % TYPE,
    v_zarobki OUT EMPLOYEES.SALARY % TYPE
);

PROCEDURE wyswietl_info_pracownika(p_employee_id EMPLOYEES.EMPLOYEE_ID % TYPE);

PROCEDURE dodaj_pracownika(
    p_first_name IN EMPLOYEES.FIRST_NAME % TYPE DEFAULT NULL,
    p_last_name IN EMPLOYEES.LAST_NAME % TYPE,
    p_email IN EMPLOYEES.EMAIL % TYPE,
    p_phone_number IN EMPLOYEES.PHONE_NUMBER % TYPE DEFAULT NULL,
    p_hire_date IN EMPLOYEES.HIRE_DATE % TYPE DEFAULT SYSDATE,
    p_job_id IN EMPLOYEES.JOB_ID % TYPE DEFAULT 'IT_PROG',
    p_salary IN EMPLOYEES.SALARY % TYPE DEFAULT 1000,
    p_commision_pct IN EMPLOYEES.COMMISSION_PCT % TYPE DEFAULT NULL,
    p_manager_id IN EMPLOYEES.MANAGER_ID % TYPE DEFAULT NULL,
    p_department_id IN EMPLOYEES.DEPARTMENT_ID % TYPE DEFAULT NULL
);

END procedure_package;

CREATE
OR REPLACE PACKAGE BODY procedure_package IS -- Zad 9
-- a
CREATE
OR REPLACE PROCEDURE add_job(
    p_job_id JOBS.JOB_ID % TYPE,
    p_job_title JOBS.JOB_TITLE % TYPE
) AS BEGIN
INSERT INTO
    JOBS (JOB_ID, JOB_TITLE)
VALUES
    (p_job_id, p_job_title);

DBMS_OUTPUT.PUT_LINE(
    'Wiersz został dodany pomyślnie: ' || p_job_id || ', ' || p_job_title
);

END add_job;

EXEC add_job('IT_PROG', 'Programista IT');

-- b
CREATE
OR REPLACE PROCEDURE modify_job_title(
    p_job_id JOBS.JOB_ID % TYPE,
    p_job_title JOBS.JOB_TITLE % TYPE
) AS BEGIN
UPDATE
    JOBS
SET
    JOBS.JOB_TITLE = p_job_title
WHERE
    JOBS.JOB_ID = p_job_id;

IF SQL % ROWCOUNT = 0 THEN DBMS_OUTPUT.PUT_LINE('no Jobs updated ');

ELSE DBMS_OUTPUT.PUT_LINE(
    'Wiersz został pomyślnie zmodyfikowany: ' || p_job_id || ', ' || p_job_title
);

END IF;

END modify_job_title;

-- Błąd
EXEC modify_job_title('IT_PROG12', 'Programista IT Zmodyfikowany');

-- Git
EXEC modify_job_title('IT_PROG', 'Programista IT Zmodyfikowany');

-- c
CREATE
OR REPLACE PROCEDURE delete_job_row(p_job_id JOBS.JOB_ID % TYPE) AS BEGIN
DELETE FROM
    JOBS
WHERE
    JOBS.JOB_ID = p_job_id;

IF SQL % ROWCOUNT = 0 THEN DBMS_OUTPUT.PUT_LINE('no Jobs deleted');

ELSE DBMS_OUTPUT.PUT_LINE('Wiersz został pomyślnie usunięty: ' || p_job_id);

END IF;

END delete_job_row;

EXEC delete_job_row('IT_PROG');

-- d
create
or replace PROCEDURE pracownik_info(
    p_employee_id EMPLOYEES.EMPLOYEE_ID % TYPE,
    v_nazwisko OUT EMPLOYEES.LAST_NAME % TYPE,
    v_zarobki OUT EMPLOYEES.SALARY % TYPE
) AS BEGIN
SELECT
    EMPLOYEES.LAST_NAME,
    EMPLOYEES.SALARY INTO v_nazwisko,
    v_zarobki
FROM
    EMPLOYEES
WHERE
    EMPLOYEES.EMPLOYEE_ID = p_employee_id;

EXCEPTION
WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Brak pracownika o podanym ID.');

WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(
    'B³¹d podczas pobierania danych pracownika: ' || SQLERRM
);

END pracownik_info;

CREATE
OR REPLACE PROCEDURE wyswietl_info_pracownika(p_employee_id EMPLOYEES.EMPLOYEE_ID % TYPE) AS v_zarobki EMPLOYEES.SALARY % TYPE;

v_nazwisko EMPLOYEES.LAST_NAME % TYPE;

BEGIN pracownik_info(p_employee_id, v_nazwisko, v_zarobki);

IF v_zarobki IS NOT NULL THEN DBMS_OUTPUT.PUT_LINE(
    'Pracownik: ' || v_nazwisko || ', Zarobki: ' || TO_CHAR(v_zarobki)
);

ELSE DBMS_OUTPUT.PUT_LINE(
    'Nie znaleziono danych dla pracownika o ID ' || TO_CHAR(p_employee_id)
);

END IF;

END wyswietl_info_pracownika;

BEGIN wyswietl_info_pracownika(200);

END;

-- e
CREATE
OR REPLACE PROCEDURE dodaj_pracownika(
    p_first_name IN EMPLOYEES.FIRST_NAME % TYPE DEFAULT NULL,
    p_last_name IN EMPLOYEES.LAST_NAME % TYPE,
    p_email IN EMPLOYEES.EMAIL % TYPE,
    p_phone_number IN EMPLOYEES.PHONE_NUMBER % TYPE DEFAULT NULL,
    p_hire_date IN EMPLOYEES.HIRE_DATE % TYPE DEFAULT SYSDATE,
    p_job_id IN EMPLOYEES.JOB_ID % TYPE DEFAULT 'IT_PROG',
    p_salary IN EMPLOYEES.SALARY % TYPE DEFAULT 1000,
    p_commision_pct IN EMPLOYEES.COMMISSION_PCT % TYPE DEFAULT NULL,
    p_manager_id IN EMPLOYEES.MANAGER_ID % TYPE DEFAULT NULL,
    p_department_id IN EMPLOYEES.DEPARTMENT_ID % TYPE DEFAULT NULL
) AS v_pracownik_id EMPLOYEES.EMPLOYEE_ID % TYPE;

BEGIN
SELECT
    (MAX(employee_id) + 1) INTO v_pracownik_id
FROM
    employees;

IF p_salary > 20000 THEN DBMS_OUTPUT.PUT_LINE('Zbyt wysokie zarobki');

RETURN;

END IF;

INSERT INTO
    EMPLOYEES (
        EMPLOYEE_ID,
        FIRST_NAME,
        LAST_NAME,
        EMAIL,
        PHONE_NUMBER,
        HIRE_DATE,
        JOB_ID,
        SALARY,
        COMMISSION_PCT,
        MANAGER_ID,
        DEPARTMENT_ID
    )
VALUES
    (
        v_pracownik_id,
        p_first_name,
        p_last_name,
        p_email,
        p_phone_number,
        p_hire_date,
        p_job_id,
        p_salary,
        p_commision_pct,
        p_manager_id,
        p_department_id
    );

DBMS_OUTPUT.PUT_LINE('Pracownik ' || p_last_name || ' został dodany.');

END dodaj_pracownika;

DECLARE BEGIN dodaj_pracownika('Patryk', 'Kozak', 'kozak@email.com');

END;

END procedure_package;