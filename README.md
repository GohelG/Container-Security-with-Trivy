## 🎯 Docker & Trivy Security Lab

Docker provides application isolation and portability, but insecure container images can expose vulnerabilities such as outdated operating system packages, vulnerable dependencies, hardcoded secrets, and excessive privileges.

This hands-on project demonstrates how to:

- Build an intentionally vulnerable Flask Docker image
- Scan the image using **Aqua Security Trivy**
- Generate JSON and HTML vulnerability reports
- Harden the container using Docker security best practices
- Automate security scanning using GitHub Actions

This project is ideal for learning **Container Security**, **DevSecOps**, and **CI/CD Security Automation**.
```

---

# Tool Installation

```bash
sudo apt update
sudo apt install docker.io -y
```
---

# Trivy Installation

```bash
wget -qO - https://github.io
```

```bash
sudo apt-get update
sudo apt-get install wget gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb \
$(lsb_release -sc) main" \
| sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update
sudo apt-get install trivy -y

trivy --version
```
````

---

# app.py

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Dockerized Flask App!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

---

# requirements.txt

```text
Flask==2.2.5
requests==2.19.1
```

---

# Dockerfile

```dockerfile
FROM python:3.7

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

---

# Secure Dockerfile

```dockerfile
FROM python:3.11-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
```

---

# Build Commands

```bash
docker build -t flask-vuln-app .
```

```bash
docker run -d -p 5000:5000 --name flask-container flask-vuln-app
```

```bash
docker ps
```

```bash
docker stop flask-container
docker rm flask-container
```

---

# Trivy Scan

Use the same image name everywhere.

```bash
trivy image flask-vuln-app
```

```bash
trivy image --severity HIGH,CRITICAL flask-vuln-app
```

```bash
mkdir -p reports
```

```bash
trivy image \
-f json \
-o reports/flask-report.json \
flask-vuln-app
```

```bash
sudo apt install jq -y
jq . reports/flask-report.json
```

```bash
trivy image \
--format template \
--template "@contrib/html.tpl" \
-o reports/flask-report.html \
flask-vuln-app
```

---

# GitHub Actions

```yaml
# .github/workflows/trivy-scan.yml
name: 🚀 DevSecOps CI/CD Security Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

permissions:
  contents: read
  security-events: write  # 🔒 Required to publish Trivy SARIF reports to GitHub Security tab

jobs:
  devsecops-audit:
    name: 🛡️ Code & Container Security Verification
    runs-on: ubuntu-latest

    steps:
      - name: 📋 Checkout Source Infrastructure Code
        uses: actions/checkout@v4

      - name: 🔍 Run Trivy Source Code Analyzer (Config & Secrets)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'table'
          severity: 'CRITICAL,HIGH'
          exit-code: '1' # 🛑 Fails the pipeline if vulnerabilities or secrets are found

      - name: 📦 Assemble Hardened Production Container
        run: |
          docker build -f Dockerfile.secure -t production-app:latest .

      - name: 🧪 Execute Trivy Artifact Scan (Target Container Image)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'production-app:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: 📊 Publish Security Metrics to GitHub Alerts Dashboard
        uses: github/codeql-action/upload-sarif@v3
        if: always() # ⚙️ Always runs to ensure data uploads even if previous steps fail
        with:
          sarif_file: 'trivy-results.sarif'
```

---

# 📂 Folder Structure

```text
Container-Security-with-Trivy/
│
├── .github/
│   └── workflows/
│       └── trivy-scan.yml
│
├── reports/
│   ├── flask-report.html
│   └── flask-report.json
│
├── app.py
├── requirements.txt
├── Dockerfile
├── Dockerfile.secure
└── README.md
```

---

## 📊 Expected Results

After scanning the vulnerable image, Trivy should detect:

- High and Critical OS package vulnerabilities
- Vulnerable Python dependencies
- CVEs associated with Requests 2.19.1

After rebuilding using **Dockerfile.secure**, the number of High and Critical vulnerabilities should be significantly reduced.
```

---

## 🎓 Learning Outcomes

By completing this project, you will learn:

- Docker image security fundamentals
- Vulnerability scanning using Trivy
- Container hardening best practices
- Least Privilege Principle
- Secure Dockerfile design
- DevSecOps automation using GitHub Actions
- Generating JSON, HTML, and SARIF security reports
```

---

## 👨‍💻 Author

**Gautam Gohel**

**System Administrator | SRE Engineer | Cloud Engineer | DevSecOps Enthusiast**

### Connect with Me

- GitHub: https://github.com/GohelG
- LinkedIn: *(https://www.linkedin.com/in/gautam-gohel-83875593/)*

---

⭐ If you found this project useful, consider giving it a star!
```
