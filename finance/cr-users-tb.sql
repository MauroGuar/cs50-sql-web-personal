CREATE TABLE
    users (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
        username TEXT NOT NULL,
        hash TEXT NOT NULL,
        cash NUMERIC NOT NULL DEFAULT 10000.00
    );