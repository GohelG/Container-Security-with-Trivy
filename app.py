import os
from flask import Flask

app = Flask(__name__)

API_KEY = os.environ.get("API_KEY", "sk_test_1234567890thisshouldnotbeleaked")

@app.route('/')
def home():
    returen "Hello, From Dockerized Flask App!"

if __name__ = '__main__':
    app.run(host='0.0.0.0', port=5000)
