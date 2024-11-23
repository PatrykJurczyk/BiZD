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

-- Zad 9
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
-- e