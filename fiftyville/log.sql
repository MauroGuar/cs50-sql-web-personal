-- Find the crime scene
SELECT
    description
FROM
    crime_scene_reports
WHERE
    month = 7
    AND street = 'Humphrey Street'
    AND description LIKE '%CS50%';

-- Find the 3 witnesses who were interviewed
SELECT
    transcript
FROM
    interviews
WHERE
    transcript LIKE '%bakery%'
    AND month = 7;

-- Based on Eugene's testimony, find all the people who withdrew money from the ATM on Leggett Street on July 28th
SELECT
    name,
    phone_number,
    passport_number,
    license_plate
FROM
    people
WHERE
    id IN (
        SELECT
            person_id
        FROM
            bank_accounts
        WHERE
            account_number IN (
                SELECT
                    account_number
                FROM
                    atm_transactions
                WHERE
                    month = 7
                    AND day = 28
                    AND atm_location = 'Leggett Street'
                    AND transaction_type = 'withdraw'
            )
    );

-- Based on the license plates obtained from the ATM transactions, find the license plates of the cars that were at the bakery on July 28th witin ten minutes of crime as Eugene mentioned
SELECT
    minute,
    license_plate
FROM
    bakery_security_logs
WHERE
    month = 7
    AND day = 28
    AND hour = 10
    AND license_plate IN (
        SELECT
            license_plate
        FROM
            people
        WHERE
            id IN (
                SELECT
                    person_id
                FROM
                    bank_accounts
                WHERE
                    account_number IN (
                        SELECT
                            account_number
                        FROM
                            atm_transactions
                        WHERE
                            month = 7
                            AND day = 28
                            AND atm_location = 'Leggett Street'
                            AND transaction_type = 'withdraw'
                    )
            )
    );

-- Based on the license plates obtained before, find the names based on the phone numbers of the people who made a call which lasted less than 60 seconds on that date
-- I have two suspects now, Bruce and Diana
SELECT
    name
FROM
    people
WHERE
    phone_number IN (
        SELECT
            receiver
        FROM
            phone_calls
        WHERE
            month = 7
            AND day = 28
            AND duration < 60
            AND caller IN (
                SELECT
                    phone_number
                FROM
                    people
                WHERE
                    license_plate IN (
                        SELECT
                            license_plate
                        FROM
                            bakery_security_logs
                        WHERE
                            month = 7
                            AND day = 28
                            AND hour = 10
                            AND minute >= 15
                            AND minute <= 25
                            AND license_plate IN (
                                SELECT
                                    license_plate
                                FROM
                                    people
                                WHERE
                                    id IN (
                                        SELECT
                                            person_id
                                        FROM
                                            bank_accounts
                                        WHERE
                                            account_number IN (
                                                SELECT
                                                    account_number
                                                FROM
                                                    atm_transactions
                                                WHERE
                                                    month = 7
                                                    AND day = 28
                                                    AND atm_location = 'Leggett Street'
                                                    AND transaction_type = 'withdraw'
                                            )
                                    )
                            )
                    )
            )
    );

-- Based on the names obtained before, find the name of the person who was on the earliest flight on July 29th
-- The thief is Bruce
SELECT
    people.name
FROM
    people
    JOIN passengers ON people.passport_number = passengers.passport_number
    JOIN flights ON passengers.flight_id = flights.id
WHERE
    flights.month = 7
    AND flights.day = 29
    AND phone_number IN (
        SELECT
            caller
        FROM
            phone_calls
        WHERE
            month = 7
            AND day = 28
            AND duration < 60
            AND caller IN (
                SELECT
                    phone_number
                FROM
                    people
                WHERE
                    license_plate IN (
                        SELECT
                            license_plate
                        FROM
                            bakery_security_logs
                        WHERE
                            month = 7
                            AND day = 28
                            AND hour = 10
                            AND minute >= 15
                            AND minute <= 25
                            AND license_plate IN (
                                SELECT
                                    license_plate
                                FROM
                                    people
                                WHERE
                                    id IN (
                                        SELECT
                                            person_id
                                        FROM
                                            bank_accounts
                                        WHERE
                                            account_number IN (
                                                SELECT
                                                    account_number
                                                FROM
                                                    atm_transactions
                                                WHERE
                                                    month = 7
                                                    AND day = 28
                                                    AND atm_location = 'Leggett Street'
                                                    AND transaction_type = 'withdraw'
                                            )
                                    )
                            )
                    )
            )
    )
ORDER BY
    flights.hour
LIMIt
    1;

-- The city where the thief escaped to is New York
SELECT
    city
FROM
    airports
WHERE
    id = (
        SELECT
            flights.destination_airport_id
        FROM
            people
            JOIN passengers ON people.passport_number = passengers.passport_number
            JOIN flights ON passengers.flight_id = flights.id
        WHERE
            flights.month = 7
            AND flights.day = 29
            AND phone_number IN (
                SELECT
                    caller
                FROM
                    phone_calls
                WHERE
                    month = 7
                    AND day = 28
                    AND duration < 60
                    AND caller IN (
                        SELECT
                            phone_number
                        FROM
                            people
                        WHERE
                            license_plate IN (
                                SELECT
                                    license_plate
                                FROM
                                    bakery_security_logs
                                WHERE
                                    month = 7
                                    AND day = 28
                                    AND hour = 10
                                    AND minute >= 15
                                    AND minute <= 25
                                    AND license_plate IN (
                                        SELECT
                                            license_plate
                                        FROM
                                            people
                                        WHERE
                                            id IN (
                                                SELECT
                                                    person_id
                                                FROM
                                                    bank_accounts
                                                WHERE
                                                    account_number IN (
                                                        SELECT
                                                            account_number
                                                        FROM
                                                            atm_transactions
                                                        WHERE
                                                            month = 7
                                                            AND day = 28
                                                            AND atm_location = 'Leggett Street'
                                                            AND transaction_type = 'withdraw'
                                                    )
                                            )
                                    )
                            )
                    )
            )
        ORDER BY
            flights.hour
        LIMIt
            1
    );

-- The accomplice is Robin
SELECT
    name
FROM
    people
WHERE
    phone_number = (
        SELECT
            receiver
        FROM
            phone_calls
        WHERE
            month = 7
            AND day = 28
            AND duration < 60
            AND caller = (
                SELECT
                    people.phone_number
                FROM
                    people
                    JOIN passengers ON people.passport_number = passengers.passport_number
                    JOIN flights ON passengers.flight_id = flights.id
                WHERE
                    flights.month = 7
                    AND flights.day = 29
                    AND phone_number IN (
                        SELECT
                            caller
                        FROM
                            phone_calls
                        WHERE
                            month = 7
                            AND day = 28
                            AND duration < 60
                            AND caller IN (
                                SELECT
                                    phone_number
                                FROM
                                    people
                                WHERE
                                    license_plate IN (
                                        SELECT
                                            license_plate
                                        FROM
                                            bakery_security_logs
                                        WHERE
                                            month = 7
                                            AND day = 28
                                            AND hour = 10
                                            AND minute >= 15
                                            AND minute <= 25
                                            AND license_plate IN (
                                                SELECT
                                                    license_plate
                                                FROM
                                                    people
                                                WHERE
                                                    id IN (
                                                        SELECT
                                                            person_id
                                                        FROM
                                                            bank_accounts
                                                        WHERE
                                                            account_number IN (
                                                                SELECT
                                                                    account_number
                                                                FROM
                                                                    atm_transactions
                                                                WHERE
                                                                    month = 7
                                                                    AND day = 28
                                                                    AND atm_location = 'Leggett Street'
                                                                    AND transaction_type = 'withdraw'
                                                            )
                                                    )
                                            )
                                    )
                            )
                    )
                ORDER BY
                    flights.hour
                LIMIt
                    1
            )
    );