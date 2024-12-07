CREATE TABLE Worker (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    surname VARCHAR2(40) NOT NULL,
    role VARCHAR2(20) NOT NULL CHECK (role IN ('manager', 'broker')),
    phone VARCHAR2(12) NOT NULL
);

CREATE TABLE Property (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    type VARCHAR2(20) NOT NULL CHECK (type IN ('flat', 'building', 'land')),
    address VARCHAR2(255) NOT NULL,
    area FLOAT NOT NULL,
    rooms NUMBER,
    sqm_price FLOAT NOT NULL,
    description CLOB,
    add_date TIMESTAMP DEFAULT SYSDATE
);

CREATE TABLE Client (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    surname VARCHAR2(40) NOT NULL,
    phone VARCHAR2(12) NOT NULL
);

CREATE TABLE Transaction (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    property_id NUMBER NOT NULL,
    client_id NUMBER NOT NULL,
    worker_id NUMBER NOT NULL,
    transaction_date TIMESTAMP DEFAULT SYSDATE,
    final_price FLOAT NOT NULL,
    status_transakcji VARCHAR2(20) NOT NULL CHECK (status_transakcji IN ('started', 'completed', 'cancelled')),
    FOREIGN KEY (property_id) REFERENCES Property(ID),
    FOREIGN KEY (client_id) REFERENCES Client(ID),
    FOREIGN KEY (worker_id) REFERENCES Worker(ID)
);

CREATE TABLE Processed_File (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    file_name VARCHAR2(255) NOT NULL,
    load_timestamp TIMESTAMP DEFAULT SYSDATE,
    total_records NUMBER NOT NULL,
    valid_records NUMBER NOT NULL,
    invalid_records NUMBER NOT NULL
);

CREATE TABLE Processed_Data (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    processed_file_id NUMBER NOT NULL,
    data_type VARCHAR2(20) NOT NULL CHECK (data_type IN ('property', 'client', 'transaction', 'worker')),
    record_data CLOB NOT NULL,
    archived VARCHAR2(3) DEFAULT 'no' CHECK (archived IN ('yes', 'no')),
    timestamp TIMESTAMP DEFAULT SYSDATE,
    FOREIGN KEY (processed_file_id) REFERENCES Processed_File(ID)
);
