# Lab Setup & Tool Configuration

This document outlines the prerequisites and specific workflows required to complete the GenAI Prompt Engineering Lab.

## 1. Tool Installation

You will need the following three tools installed on your workstation.

### A. AWS CLI (Command Line Interface)
Required to authenticate your terminal with your AWS account.

* **Windows:** [Download 64-bit MSI installer](https://awscli.amazonaws.com/AWSCLIV2.msi)
* **macOS:** [Download GUI Installer](https://awscli.amazonaws.com/AWSCLIV2.pkg)
* **Linux:**
    ```bash
    curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```

### B. Terraform
Required to deploy Infrastructure as Code.

* **Windows (Chocolatey):** `choco install terraform`
* **macOS (Homebrew):** `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
* **Manual Binary:** [Download from HashiCorp](https://developer.hashicorp.com/terraform/install)

### C. Trivy (Security Scanner)
Required to scan your infrastructure code for vulnerabilities before deployment.

* **Windows (Chocolatey):** `choco install trivy`
* **macOS (Homebrew):** `brew install aquasecurity/trivy/trivy`
* **Linux (apt/deb):**
    ```bash
    sudo apt-get install wget apt-transport-https gnupg lsb-release
    wget -qO - [https://aquasecurity.github.io/trivy-repo/deb/public.key](https://aquasecurity.github.io/trivy-repo/deb/public.key) | sudo apt-key add -
    echo deb [https://aquasecurity.github.io/trivy-repo/deb](https://aquasecurity.github.io/trivy-repo/deb) $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install trivy
    ```

---

## 2. AWS Authentication

Before running Terraform, your terminal must be authenticated.

### For Standard AWS Accounts
Run the configure command and enter your credentials:
```bash
aws configure
# Enter Access Key ID, Secret Access Key, Default Region (e.g., us-west-2), and Output Format (json)
````

### ⚠️ For AWS Academy / Vocareum / Learner Labs

If you are using a temporary Learner Lab environment, `aws configure` is **insufficient** because it does not handle the Session Token.

1.  In the Vocareum AWS Details panel, click **AWS CLI**.
2.  Copy the block of export commands (Mac/Linux) or `$Env` commands (PowerShell).
3.  Paste them directly into your terminal. It should look like this:
    ```bash
    export AWS_ACCESS_KEY_ID="ASIA..."
    export AWS_SECRET_ACCESS_KEY="wJalr..."
    export AWS_SESSION_TOKEN="FQoGZ..."
    ```
4.  **Verify:** Run `aws sts get-caller-identity` to confirm you are logged in.

-----

## 3\. Lab Workflow: The "Plan & Scan" Cycle

The core learning objective of this lab is comparing the security posture of different GenAI outputs. Follow this exact sequence for every iteration (Simple vs. Advanced).

### Step 1: Initialize

Prepare the directory and download the AWS providers.

```bash
terraform init
```

### Step 2: Plan to Output File

Instead of just running `terraform plan`, we output the plan to a binary file (`tfplan`). This creates a static artifact of *exactly* what Terraform intends to build.

```bash
terraform plan -out tfplan
```

### Step 3: Security Analysis with Trivy

This is the critical step. We use Trivy to analyze the `tfplan` file. Trivy treats the Terraform plan as a configuration file and checks it against known CVEs and AWS security best practices (CIS benchmarks).

**Run the scan:**

```bash
trivy config tfplan
```

**How to interpret the results:**

  * **Misconfiguration:** The specific rule violated (e.g., `AVD-AWS-0053`).
  * **Severity:** `LOW`, `MEDIUM`, `HIGH`, or `CRITICAL`.
  * **Message:** A description of the issue (e.g., "Instance does not require IMDSv2" or "EBS Volume is not encrypted").
  * **Context:** Trivy will show the exact lines of code in your `main.tf` causing the violation.

> **Lab Tip:** If your "Simple" prompt uses an unmanaged (pre-existing) Security Group, Trivy may yield **fewer** findings than the "Advanced" prompt. This is a "false negative" because Trivy cannot scan resources it does not manage.

### Step 4: Deploy (Optional)

If you wish to verify the deployment works:

```bash
terraform apply tfplan
```

### Step 5: Cleanup (Mandatory)

To prevent cost overruns, always destroy resources when finished.

```bash
terraform destroy -auto-approve
```

-----

## 4\. Troubleshooting

**Error: `Error acquiring the state lock`**

  * **Cause:** A previous command crashed or is still running.
  * **Fix:** `terraform force-unlock <LOCK_ID>` (The Lock ID will be in the error message).

**Error: `ExpiredToken`**

  * **Cause:** Your AWS Academy/Vocareum session has timed out.
  * **Fix:** Refresh the Vocareum page, copy the new CLI credentials, and paste them into your terminal again.

**Trivy shows "No issues found" on a bad template**

  * **Cause:** You might be referencing resources that don't exist in the TF code (like hardcoded Security Group IDs).
  * **Fix:** This is a teaching moment\! It demonstrates that IaC scanning only works on the *Code*, not the existing environment.

