CREATE TABLE
    portfolios (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        user_id INTEGER NOT NULL,
        symbol TEXT NOT NULL,
        shares INTEGER NOT NULL,
        price NUMERIC NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );