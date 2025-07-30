from flask import Flask, Response
from core.app import App
import os

app = Flask(__name__)
mvc_app = App(base_dir=os.path.dirname(os.path.abspath(__file__)))

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def handle_all(path):
    path = "/" + path
    response = mvc_app.handle_request(path)

    if response.startswith("<!DOCTYPE html>"):
        return Response(response, content_type="text/html")
    else:
        return response, 404 if "Not Found" in response else 500

if __name__ == "__main__":
    # 👇 This line is critical for accessing it from outside the VM
    app.run(host="0.0.0.0", port=5000, debug=True)
