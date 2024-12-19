CREATE TABLE
    transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        symbol TEXT NOT NULL,
        shares INTEGER NOT NULL,
        price NUMERIC NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );