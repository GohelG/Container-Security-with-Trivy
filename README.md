------------------------------
## 🎯 Docker & Trivy Security Lab
Docker isolates applications but introduces specific security attack surfaces. This document provides a quick-start laboratory workflow to install Trivy (Aqua Security), build an intentionally vulnerable Flask image, generate security audit reports, and apply production-ready remediations. 

"A practical guide to building an intentionally vulnerable Flask Docker container, scanning it for security flaws using Aqua Security Trivy, and implementing secure remediations via CI/CD pipelines."

## 📋 Table of Contents

* 🛡️ Core Concepts
* ⚡ Tool Installation
* 🛠️ Project Setup
* 📦 Build & Run
* 🔍 Vulnerability Scanning
* 🔧 Remediation & Hardening
* 🚀 CI/CD Pipeline Automation

------------------------------
## 🛡️ Core Concepts

### 🛠️ Primary Docker Security Risks

* Base Image Vulnerabilities: Outdated base operating systems containing unpatched system packages.
* Hardcoded Secrets: Plaintext API keys, passwords, or cloud credentials baked into image layers.
* Insecure Dockerfiles: Containers running as the root superuser or exposing unnecessary ports.
* Outdated Dependencies: Third-party libraries (e.g., Python packages) with published CVEs.
* Image Bloat: Unnecessary tooling inside the container that expands the total attack surface.

## Why Trivy?
Trivy is a lightweight, cloud-independent, and incredibly fast DevSecOps CLI scanner. It instantly maps out vulnerabilities in OS packages, application dependencies, infrastructure-as-code files, and plaintext secrets.

1. **CLI-based & fast**
2. **No login or cloud dependency**
3. **Great for DevSecOps pipelines**
4. **Supports multiple formats: JSON, table, HTML**

## 📂 Production-ready Folder Structure

```text
Container-Security-with-Trivy/
├── .github/
│   └── workflows/
│       └── trivy-scan.yml      # GitHub Actions automation pipeline
├── reports/
│   ├── flask-report.html       # Visual executive scan output (Generated)
│   └── flask-report.json       # Machine-readable report data (Generated)
├── app.py                      # Flask application code
├── Dockerfile                  # Intentionally vulnerable image setup
├── Dockerfile.secure           # Hardened production image setup
└── requirements.txt            # Python dependencies (vulnerable or updated)
```

------------------------------
## ⚡Tool Installation

## 1. Docker Setup
### Install Docker engine
sudo apt install docker.io -y

### Configure user permissions (avoids using sudo for docker commands)
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

## 2. Python-3 Setup
### Update local packages and install Python
sudo apt update
sudo apt install python3 -y

### Verify the installation
python3 --version

## 3. Trivy Setup

### Add official Aqua Security repository keys
sudo apt-get install wget gnupg -y
wget -qO - https://github.io | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

### Register the source repository list
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://github.io generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

### Install Trivy CLI
sudo apt-get update
sudo apt-get install trivy -y
trivy --version

------------------------------
## 🛠️ Project Setup
### Directory Structure
Execute these commands to build your application context directory:

mkdir flask-vuln-app && cd flask-vuln-app
sudo chown -R $USER:$USER $(pwd)

Create the following three application files exactly as specified below:

### app.py

from flask import Flaskapp = Flask(__name__)

@app.route('/')def home():
    return "Hello from Dockerized Flask App!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

### requirements.txt
flask
requests==2.19.1

⚠️  Note: requests v2.19.1 contains known critical CVEs that are deliberately included for Trivy to detect.

### Dockerfile

### Intentional Vulnerability: Using an outdated, bloated base OS imageFROM python:3.7
### Use an outdated Python image (intentionally vulnerable)
FROM python:3.7

### Set working directory
WORKDIR /app

### Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

### Copy source code
COPY . .

### Expose Flask default port
EXPOSE 5000

### Run the app
CMD ["python", "app.py"]

------------------------------
## 📦 Build & Run

### Assemble the Target Image
docker build -t Container-Security-with-Trivy .

### Launch the Application Container
docker run -d -p 5000:5000 Container-Security-with-Trivy

### List all running instances to locate your Container ID
docker ps -a

### Stop the running container
docker stop <container_id>

------------------------------
## 🔍 Vulnerability Scanning
Prepare a directory to house all safety metrics before executing scans:

mkdir -p reports

### Option A: Standard Terminal Output (Table)

### Run a full scan and display directly in the console
trivy image flask-vuln-app

### Filter the output down to urgent issues only
trivy image --severity CRITICAL,HIGH flask-vuln-app

### Option B: Machine-Readable Report (JSON)

### Generate the raw JSON log file
trivy image -f json -o reports/flask-report.json flask-vuln-app

### Optional: Install jq to pretty-print and query the JSON file
sudo apt install jq -y
cat reports/flask-report.json | jq .

### Option C: Executive Summary (HTML)

### Compile a human-friendly interactive visual web report
trivy image --format template --template "@contrib/html.tpl" -o reports/flask-report.html flask-vuln-app

------------------------------
### Remediation & Hardening
To mitigate the architectural flaws flagged during the Trivy scan, apply a two-step hardening strategy covering dependency management and image restructuring.

### 1. Update Python Dependencies (requirements.txt)
Replace the contents of your existing dependency file with stable, secure versions:

flask>=3.0.0
requests>=2.31.0

### 2. Build the Secured Dockerfile (Dockerfile.secure)
Create a new file named Dockerfile.secure in your root directory. This configuration enforces standard industry hardening procedures:

* Minimal Base Image: Shifts from a heavy development system to a stripped-down Alpine Linux core.
* Least-Privilege User Principle: Drops root execution privileges by creating and utilizing a non-root system user.
* Reduced Multi-Layer Attack Surface: Aggregates installation actions and forces deterministic cache cleaning.

### Use a minimal, highly secure Python runtime environmentFROM python:3.11-alpine

### Set system environment adjustmentsENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/app
WORKDIR /app

### Enforce least-privilege by initializing a locked non-root userRUN addgroup -S appgroup && adduser -S appuser -G appgroup

### Install and build dependencies securelyCOPY requirements.txt .RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

### Bring app resources into container file boundariesCOPY app.py .

### Reassign absolute ownership of the application path to the new userRUN chown -R appuser:appgroup /app

### Relinquish superuser access rightsUSER appuser
EXPOSE 5000
CMD ["python", "app.py"]

## 3. Re-verify Vulnerability Reductions
Build and execute a differential scan against your newly hardened configuration:

### Build the secure image layer stack
docker build -f Dockerfile.secure -t flask-secure-app .

### Run Trivy scan to verify clean execution
trivy image --severity CRITICAL,HIGH flask-secure-app

------------------------------
## 🚀 CI/CD Pipeline Automation
Automate container security auditing by embedding Trivy checks directly within source control platforms.

### GitHub Actions Workflow
Create a configuration file at the following path in your repository: .github/workflows/trivy-scan.yml. This script triggers automated validation policies on every mainline code push or pull request transaction.

```groovy
name: Security Scan & Build Verification
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
permissions:
  contents: read
  security-events: write 
jobs:
  audit-and-build:
    name: DevSecOps Code and Container Evaluation
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Source Infrastructure Code
      uses: actions/checkout@v4

    - name: Run Trivy Source Code Analyzer (Config & Secrets)
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'table'
        severity: 'CRITICAL,HIGH'
        exit-code: '1' 

    - name: Assemble Hardened Production Container
      run: |
        docker build -f Dockerfile.secure -t production-app:latest .
    - name: Execute Trivy Artifact Scan (Target Container Image)
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'production-app:latest'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Publish Security Metrics to GitHub Alerts Dashboard
      uses: github/codeql-action/upload-sarif@v3
      if: always() 
      with:
        sarif_file: 'trivy-results.sarif'
```

## 👨‍💻 Author

**Gautam Gohel**

System Administrator | SRE Engineer | Cloud & DevOps Enthusiast 🚀

---
---
