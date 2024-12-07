import pandas as pd
import oracledb
import json

def create_db_connection():
    try:
        connection = oracledb.connect(
            user="jurczykp",
            password="Admin141368",
            dsn="213.184.8.44:1521/orcl"
        )
        print("Połączono z bazą danych.")
        return connection
    except oracledb.DatabaseError as e:
        print(f"Błąd podczas łączenia z bazą danych: {e}")
        return None


def load_csv(file_path):
    try:
        data = pd.read_csv(file_path, sep=',')
        print(f"Dane wczytane z pliku: {file_path}")
        return data
    except Exception as e:
        print(f"Błąd podczas wczytywania danych z {file_path}: {e}")
        return None


def save_to_csv(final_data, error_data, name):
    if not final_data.empty:
        final_data.to_csv(f"data/{name}/final_data_{name}.csv", index=False)
        print(f"Finalne dane zapisano w data/{name}/final_data_{name}.csv")

    if not error_data.empty:
        error_data.to_csv(f"data/{name}/errors_{name}.csv", index=False)
        print(f"Błędne dane zapisano w data/{name}/errors_{name}.csv")


def validate_property_data(data):
    errors = []
    valid_data = []

    for index, row in data.iterrows():
        try:
            if row['type'] not in ['flat', 'building', 'land']:
                raise ValueError("Niepoprawny typ nieruchomości")
            if pd.isna(row['address']) or row['address'].strip() == "":
                raise ValueError("Adres nie może być pusty")
            if row['area'] <= 0:
                raise ValueError("Powierzchnia musi być większa od zera")
            if row['sqm_price'] <= 0:
                raise ValueError("Cena za m² musi być większa od zera")

            valid_data.append(row)
        except Exception as e:
            errors.append(
                {'Index': index, 'Table': 'property', 'Error': str(e), 'Row': row.to_dict()})
    return pd.DataFrame(valid_data), pd.DataFrame(errors)


def load_and_validate_properties():
    data = load_csv("data/properties.csv")
    if data is None or data.empty:
        print("Brak danych do przetworzenia.")
        return

    property_data, property_errors = validate_property_data(
        data[['type', 'address', 'area', 'rooms', 'sqm_price', 'description']])

    save_to_csv(property_data, property_errors, 'properties')
    return property_data, property_errors


def validate_client_data(data):
    errors = []
    valid_data = []

    for index, row in data.iterrows():
        try:
            if pd.isna(row['name']) or pd.isna(row['surname']):
                raise ValueError("Imię i nazwisko nie mogą być puste")
            if pd.isna(row['phone']) or len(str(row['phone'])) > 12:
                raise ValueError("Niepoprawny numer telefonu")

            valid_data.append(row)
        except Exception as e:
            errors.append(
                {'Index': index, 'Table': 'client', 'Error': str(e), 'Row': row.to_dict()})
    return pd.DataFrame(valid_data), pd.DataFrame(errors)


def load_and_validate_clients():
    data = load_csv("data/clients.csv")
    if data is None or data.empty:
        print("Brak danych do przetworzenia.")
        return

    client_data, client_errors = validate_client_data(
        data[['name', 'surname', 'phone']])

    save_to_csv(client_data, client_errors, 'clients')
    return client_data, client_errors


def validate_worker_data(data):
    errors = []
    valid_data = []

    for index, row in data.iterrows():
        try:
            if pd.isna(row['name']) or pd.isna(row['surname']):
                raise ValueError("Imię i nazwisko nie mogą być puste")
            if row['role'] not in ['manager', 'broker']:
                raise ValueError("Niepoprawna rola")
            if pd.isna(row['phone']) or len(str(row['phone'])) > 12:
                raise ValueError("Niepoprawny numer telefonu")

            valid_data.append(row)
        except Exception as e:
            errors.append(
                {'Index': index, 'Table': 'worker', 'Error': str(e), 'Row': row.to_dict()})
    return pd.DataFrame(valid_data), pd.DataFrame(errors)


def load_and_validate_workers():
    data = load_csv("data/workers.csv")
    if data is None or data.empty:
        print("Brak danych do przetworzenia.")
        return

    worker_data, worker_errors = validate_worker_data(
        data[['name', 'surname', 'role', 'phone']])

    save_to_csv(worker_data, worker_errors, 'workers')

    return worker_data, worker_errors


def save_to_db(data, table_name, connection):
    try:
        cursor = connection.cursor()
        for i, row in data.iterrows():
            columns = ', '.join(data.columns)
            values = ', '.join([f"'{str(val)}'" if isinstance(
                val, str) else str(val) for val in row])
            sql = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
            cursor.execute(sql)
        connection.commit()
        print(f"Dane zapisane do tabeli: {table_name}")
    except oracledb.DatabaseError as e:
        print(f"Błąd podczas zapisywania danych do bazy: {e}")
        connection.rollback()


def save_processed_file(file_name, total_records, valid_records, invalid_records, connection):
    try:
        cursor = connection.cursor()
        sql = """
            INSERT INTO Processed_File (file_name, total_records, valid_records, invalid_records)
            VALUES (:file_name, :total_records, :valid_records, :invalid_records)
        """
        cursor.execute(sql, file_name=file_name, total_records=total_records,
                       valid_records=valid_records, invalid_records=invalid_records)
        connection.commit()
        print(f"Informacje o przetworzonym pliku zapisano do Processed_File.")
    except oracledb.DatabaseError as e:
        print(f"Błąd podczas zapisywania danych o przetworzonym pliku: {e}")
        connection.rollback()


def save_processed_data(processed_file_id, data_type, record_data, archived, connection):
    try:
        cursor = connection.cursor()

        if isinstance(record_data, str):
            lob_record_data = connection.createlob(oracledb.DB_TYPE_CLOB)
            lob_record_data.write(record_data)
            record_data = lob_record_data

        sql = """
            INSERT INTO Processed_Data (processed_file_id, data_type, record_data, archived)
            VALUES (:processed_file_id, :data_type, :record_data, :archived)
        """
        cursor.execute(sql, processed_file_id=processed_file_id,
                       data_type=data_type, record_data=record_data, archived=archived)

        connection.commit()
        print(f"Informacje o przetworzonych danych zapisano do Processed_Data.")
    except oracledb.DatabaseError as e:
        print(f"Błąd podczas zapisywania danych o przetworzonych danych: {e}")
        connection.rollback()


def save_errors_to_db(errors, connection):
    try:
        cursor = connection.cursor()

        for _, row in errors.iterrows():
            if isinstance(row['Row'], str):
                try:
                    row['Row'] = json.loads(row['Row'])
                except Exception as e:
                    print(f"Błąd podczas konwersji Row na słownik: {e}")
                    continue

            error_message = row['Error']
            row_data = json.dumps(row['Row'])

            sql = """
                INSERT INTO Validation_Error (table_name, row_data, error_message)
                VALUES (:table_name, :row_data, :error_message)
            """
            cursor.execute(
                sql, table_name=row['Table'], row_data=row_data, error_message=error_message)

        connection.commit()
        print(f"Błędy zapisane do tabeli Validation_Error.")
    except oracledb.DatabaseError as e:
        print(f"Błąd podczas zapisywania błędów do bazy: {e}")
        connection.rollback()


def main():
    worker_data, worker_errors = load_and_validate_workers()
    client_data, client_errors = load_and_validate_clients()
    property_data, property_errors = load_and_validate_properties()

    connection = create_db_connection()
    if connection is None:
        print("Brak połączenia z bazą danych.")
        return

    if not worker_data.empty:
        save_to_db(worker_data, 'Worker', connection)
        save_processed_data(1, 'worker', json.dumps(
            worker_data.to_dict(orient='records')), 'no', connection)
    if not property_data.empty:
        save_to_db(property_data, 'Property', connection)
        save_processed_data(1, 'property', json.dumps(
            property_data.to_dict(orient='records')), 'no', connection)
    if not client_data.empty:
        save_to_db(client_data, 'Client', connection)
        save_processed_data(1, 'client', json.dumps(
            client_data.to_dict(orient='records')), 'no', connection)

    if not worker_errors.empty:
        save_errors_to_db(worker_errors, connection)
    if not client_errors.empty:
        save_errors_to_db(client_errors, connection)
    if not property_errors.empty:
        save_errors_to_db(property_errors, connection)

    valid_records = len(property_data) + len(worker_data) + len(client_data)
    invalid_records = len(property_errors) + \
        len(worker_errors) + len(client_errors)
    total_records = valid_records + invalid_records

    save_processed_file('All Files', total_records,
                        valid_records, invalid_records, connection)

    connection.close()


if __name__ == "__main__":
    main()
