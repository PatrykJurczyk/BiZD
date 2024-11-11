CREATE TABLE JOBS (
    job_id VARCHAR(20) NOT NULL,
    job_title VARCHAR(50),
    min_salary DECIMAL(10,2),
    max_salary DECIMAL(10,2),
    PRIMARY KEY (job_id)
);

CREATE TABLE REGIONS (
    region_id VARCHAR(20) NOT NULL,
    region_name VARCHAR(100),
    PRIMARY KEY (region_id)
);

CREATE TABLE COUNTRIES (
    country_id VARCHAR(20) NOT NULL,
    country_name VARCHAR(100),
    region_id VARCHAR(20),
    PRIMARY KEY (country_id),
    FOREIGN KEY (region_id) REFERENCES REGIONS(region_id)
);

CREATE TABLE LOCATIONS (
    location_id VARCHAR(20) NOT NULL,
    street_address VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    state_province VARCHAR(100),
    country_id VARCHAR(20),
    PRIMARY KEY (location_id),
    FOREIGN KEY (country_id) REFERENCES COUNTRIES(country_id)
);

CREATE TABLE EMPLOYEES (
    employee_id VARCHAR(20) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone_number VARCHAR(20),
    hire_date DATE,
    job_id VARCHAR(20),
    salary DECIMAL(10,2),
    commission_pct VARCHAR(255),
    manager_id VARCHAR(20),
    department_id VARCHAR(20),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (manager_id) REFERENCES EMPLOYEES(employee_id),
    FOREIGN KEY (job_id) REFERENCES JOBS(job_id)
);

CREATE TABLE DEPARTMENTS (
    department_id VARCHAR(20) NOT NULL,
    department_name VARCHAR(255),
    manager_id VARCHAR(20),
    location_id VARCHAR(20),
    PRIMARY KEY (department_id),
    FOREIGN KEY (location_id) REFERENCES LOCATIONS(location_id),
    FOREIGN KEY (manager_id) REFERENCES EMPLOYEES(employee_id)
);

ALTER TABLE EMPLOYEES ADD FOREIGN KEY (department_id) REFERENCES DEPARTMENTS(department_id);

CREATE TABLE JOB_HISTORY (
    employee_id VARCHAR(20) NOT NULL,
    start_date DATE,
    end_date DATE,
    job_id VARCHAR(20),
    department_id VARCHAR(20),
    PRIMARY KEY (employee_id, start_date),
    FOREIGN KEY (department_id) REFERENCES DEPARTMENTS(department_id),
    FOREIGN KEY (job_id) REFERENCES JOBS(job_id)
);