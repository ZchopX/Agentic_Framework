import sqlite3

from flask import Flask, jsonify

app = Flask(__name__)


def db():
    return sqlite3.connect("todo.db")


@app.get("/todos")
def list_todos():
    conn = db()
    todos = conn.execute("SELECT id, title FROM todos").fetchall()
    result = []
    for todo_id, title in todos:
        tags = conn.execute("SELECT name FROM tags WHERE todo_id = ?", (todo_id,)).fetchall()
        result.append({"id": todo_id, "title": title, "tags": [t[0] for t in tags]})
    return jsonify(result)


@app.get("/health")
def health():
    return {"ok": True}
