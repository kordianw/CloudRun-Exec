import os
import subprocess
from flask import Flask, request, make_response

# config: how many seconds to timeout?
timeout_secs = 30

print("Started Flask app...")
app = Flask(__name__)

@app.route('/')
def func_root():
    print("Running: /")
    return "Hello, world!"

@app.route('/exec', methods=['POST'])
def func_exec():
    command = request.data.decode('utf-8')
    try:
        completedProcess = subprocess.run(
            command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=timeout_secs, universal_newlines=True
        )
        print(completedProcess.stdout)  # debug

        # 200 OK
        response = make_response(completedProcess.stdout, 200)
        response.mimetype = "text/plain"

        return response
    except subprocess.TimeoutExpired:
        print("Timed Out after secs " + timeout_secs)  # debug

        # 400 Timeout
        response = make_response("Timed out after secs " + timeout_secs, 400)
        response.mimetype = "text/plain"

        return response
    return "/exec"

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get('PORT', 8080)))

# EOF
