import os
from crypt import methods

from cs50 import SQL
from flask import Flask, flash, redirect, render_template, request, session
from sqlalchemy.testing.util import total_size
from werkzeug.exceptions import Conflict

from flask_session import Session
from werkzeug.security import check_password_hash, generate_password_hash

import logging
from helpers import apology, login_required, lookup, usd

# Configure application
app = Flask(__name__)

app.logger.setLevel(logging.DEBUG)

# Custom filter
app.jinja_env.filters["usd"] = usd

# Configure session to use filesystem (instead of signed cookies)
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

# Configure CS50 Library to use SQLite database
db = SQL("sqlite:///finance.db")


@app.after_request
def after_request(response):
    """Ensure responses aren't cached"""
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Expires"] = 0
    response.headers["Pragma"] = "no-cache"
    return response


@app.route("/")
@login_required
def index():
    """Show portfolio of stocks"""
    user_id = session["user_id"]
    user_cash = db.execute("SELECT cash FROM users WHERE id = ?", user_id)[0]["cash"]
    stocks = db.execute(
        "SELECT symbol, shares, price FROM portfolios WHERE user_id = ?", user_id
    )
    total = user_cash
    if stocks:
        for stock in stocks:
            total += stock["shares"] * stock["price"]
            stock_lookup = lookup(stock["symbol"])
            db.execute(
                "UPDATE portfolios SET price = ? WHERE symbol = ?",
                stock_lookup["price"],
                stock["symbol"],
            )
    return render_template("index.html", cash=user_cash, stocks=stocks, total=total)


@app.route("/buy", methods=["GET", "POST"])
@login_required
def buy():
    """Buy shares of stock"""
    if request.method == "POST":
        symbol = request.form.get("symbol").upper()
        shares = request.form.get("shares")
        stock = lookup(symbol)

        if not stock:
            return apology("invalid symbol", 403)
        if not shares.isdigit() or int(shares) < 1:
            return apology("invalid number of shares", 403)

        shares = int(shares)
        price = stock["price"]
        user_id = session["user_id"]
        user_cash = db.execute("SELECT cash FROM users WHERE id = ?", user_id)[0][
            "cash"
        ]
        if user_cash < price * float(shares):
            return apology("insufficient funds", 403)
        db.execute(
            "UPDATE users SET cash = ? WHERE id = ?",
            user_cash - price * float(shares),
            user_id,
        )
        existing_portfolio = db.execute(
            "SELECT id FROM portfolios " "WHERE user_id = ? AND symbol = ?",
            user_id,
            symbol,
        )
        if existing_portfolio:
            db.execute(
                "UPDATE portfolios SET shares = shares + ?, price = ? " "WHERE id = ?",
                shares,
                price,
                existing_portfolio[0]["id"],
            )
        else:
            db.execute(
                "INSERT INTO portfolios (user_id, symbol, shares, price) "
                "VALUES (?,?,?,?)",
                user_id,
                symbol,
                shares,
                price,
            )
        db.execute(
            "INSERT INTO transactions (user_id, type, symbol, shares, price, timestamp) VALUES (?,?,?,?,?, datetime('now'))",
            user_id,
            "BUY",
            symbol,
            shares,
            price,
        )
        return redirect("/")

    else:
        return render_template("buy.html")


@app.route("/history")
@login_required
def history():
    """Show history of transactions"""
    user_id = session["user_id"]
    transactions = db.execute("SELECT * FROM transactions WHERE user_id = ?", user_id)
    return render_template("history.html", transactions=transactions)


@app.route("/login", methods=["GET", "POST"])
def login():
    """Log user in"""

    # Forget any user_id
    session.clear()

    # User reached route via POST (as by submitting a form via POST)
    if request.method == "POST":
        # Ensure username was submitted
        if not request.form.get("username"):
            return apology("must provide username", 403)

        # Ensure password was submitted
        elif not request.form.get("password"):
            return apology("must provide password", 403)

        # Query database for username
        rows = db.execute(
            "SELECT * FROM users WHERE username = ?", request.form.get("username")
        )

        # Ensure username exists and password is correct
        if len(rows) != 1 or not check_password_hash(
                rows[0]["hash"], request.form.get("password")
        ):
            return apology("invalid username and/or password", 403)

        # Remember which user has logged in
        session["user_id"] = rows[0]["id"]

        # Redirect user to home page
        return redirect("/")

    # User reached route via GET (as by clicking a link or via redirect)
    else:
        return render_template("login.html")


@app.route("/logout")
def logout():
    """Log user out"""

    # Forget any user_id
    session.clear()

    # Redirect user to login form
    return redirect("/")


@app.route("/quote", methods=["GET", "POST"])
@login_required
def quote():
    """Get stock quote."""
    if request.method == "POST":
        quote = lookup(request.form.get("symbol"))
        if quote:
            return render_template("quoted.html", quote=quote)
        else:
            return apology("invalid symbol", 403)
    else:
        return render_template("quote.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    session.clear()

    if request.method == "POST":
        if not request.form.get("username"):
            return apology("must provide username", 403)
        elif not request.form.get("password"):
            return apology("must provide password", 403)
        elif request.form.get("password") != request.form.get("password-repeat"):
            return apology("passwords must match", 403)
        try:
            db.execute(
                "INSERT INTO users (username, hash) VALUES (?, ?)",
                request.form.get("username"),
                generate_password_hash(request.form.get("password")),
            )
        except ValueError:
            return apology("username already exists", 403)
        return render_template("login.html")
    else:
        return render_template("register.html")

    return apology("TODO")


@app.route("/sell", methods=["GET", "POST"])
@login_required
def sell():
    """Sell shares of stock"""
    if request.method == "POST":
        symbol = request.form.get("symbol").upper()
        shares = request.form.get("shares")
        stock = lookup(symbol)

        if not stock:
            return apology("invalid symbol", 403)
        if not shares.isdigit() or int(shares) < 1:
            return apology("invalid number of shares", 403)

        shares = int(shares)
        price = stock["price"]
        user_id = session["user_id"]

        user_stock = db.execute("SELECT * FROM portfolios WHERE user_id = ?", user_id)[
            0
        ]
        if not user_stock or user_stock["shares"] < shares:
            return apology("insufficient shares", 403)

        if user_stock["shares"] - shares == 0:
            db.execute("DELETE FROM portfolios WHERE id = ?", user_stock["id"])
        else:
            db.execute(
                "UPDATE portfolios SET shares = shares - ?, price = ? WHERE id = ?",
                shares,
                price,
                user_stock["id"],
            )

        db.execute(
            "UPDATE users SET cash = cash + ? WHERE id = ?", price * shares, user_id
        )

        db.execute(
            "INSERT INTO transactions (user_id, type, symbol, shares, price, timestamp) VALUES (?,?,?,?,?, datetime('now'))",
            user_id,
            "SELL",
            symbol,
            shares,
            price,
        )
        return redirect("/")

    else:
        return render_template("sell.html")


@app.route("/deposit", methods=["GET", "POST"])
@login_required
def deposit():
    if request.method == "POST":
        money = request.form.get("deposit")
        try:
            money = float(money)
        except ValueError:
            return apology("invalid amount", 403)
        if not float(money) > 0:
            return apology("invalid amount", 403)
        money = float(money)
        user_id = session["user_id"]
        db.execute("UPDATE users SET cash = cash + ? WHERE id = ?", money, user_id)
        return redirect("/")

    else:
        return render_template("deposit.html")
