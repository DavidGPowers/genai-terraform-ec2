# Lab: Secure EC2 Deployment with GenAI and Terraform

## Objective

In this lab, you will explore how the quality of your Generative AI prompt affects the security and operational readiness of your infrastructure. You will:

1.  Configure AWS CLI with temporary credentials.
2.  Generate a "naive" Terraform configuration using a basic prompt.
3.  Scan the code for security vulnerabilities using **Trivy**.
4.  Generate a "best practice" configuration using a detailed prompt (IMDSv2, SSM, Encryption).
5.  Deploy the resources and verify runtime security with **AWS Inspector**.

-----

## Part 1: Prerequisites & Setup

### 1\. Install Terraform

  * **Windows:** `choco install terraform` (via Chocolatey)
  * **macOS:** `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
  * **Linux:** Follow the [official HashiCorp guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

### 2\. Install AWS CLI

  * **Windows:** Download and run the [AWS CLI MSI installer](https://aws.amazon.com/cli/).
  * **macOS:** `brew install awscli`
  * **Linux:** `sudo apt-get install awscli` (or similar for your distro).

### 3\. Configure Temporary Credentials

Since you are using temporary access keys (common in AWS Academy or SSO environments), you must configure the `aws_session_token`.

1.  Open your terminal.
2.  Run `aws configure`.
3.  Enter your **Access Key ID** and **Secret Access Key**.
4.  For **Region**, enter `us-east-1` (or your assigned region).
5.  For **Output**, enter `json`.
6.  **Crucial Step:** `aws configure` does not ask for the session token. You must add it manually.
      * Open the credentials file ( `~/.aws/credentials` on Mac/Linux or `%USERPROFILE%\.aws\credentials` on Windows).
      * Add `aws_session_token = <YOUR_TOKEN>` to the `[default]` profile.

**Verification:**
Run `aws sts get-caller-identity`. You should see your Account and ARN.

-----

## Part 2: Scenario \#1 - The "Naive" Prompt

We will start by asking an AI to do the bare minimum. This simulates a developer rushing to get a resource running.

### 1\. The Prompt

Open your preferred LLM (ChatGPT, Gemini, Claude) and enter:

> "Write a terraform module to create an aws ec2 instance."

### 2\. The Output (Example)

Save the following code into a file named `main.tf` inside a folder named `lab-scenario-1`. (If your AI gave you something different, you may use that, but ensure it looks similar to this basic structure).

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0c7217cdde317cfec" # Example Ubuntu AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Scenario1-Instance"
  }
}
```

### 3\. Security Scan with Trivy

We will use **Trivy** to check this code for misconfigurations before we deploy.

**Install Trivy:**

  * **macOS/Linux (Homebrew):** `brew install trivy`
  * **Windows (Chocolatey):** `choco install trivy`
  * **Binary:** [Download from GitHub](https://github.com/aquasecurity/trivy/releases)

**Run the Scan:**
Navigate to your `lab-scenario-1` folder and run:

```bash
trivy config .
```

**Analysis:**
Look at the "High" and "Critical" failures. You will likely see:

  * **AVD-AWS-0131:** Instance does not require IMDSv2 (Metadata service vulnerability).
  * **AVD-AWS-0008:** EBS volume is not encrypted.
  * **AVD-AWS-0028:** No check for monitoring (Detailed Monitoring disabled).

-----

## Part 3: Scenario \#2 - The "Best Practice" Prompt

Now we will apply **Prompt Engineering** to force the AI to generate secure, production-ready code.

### 1\. The Prompt

Enter the following detailed prompt into your LLM:

> "Generate a Terraform configuration to create a secure AWS EC2 instance.
> Requirements:
>
> 1.  Retrieve the latest Amazon Linux 2023 AMI ID dynamically using the SSM Parameter Store.
> 2.  Create and attach an IAM Instance Profile that allows AWS Systems Manager (SSM) core functionality (AmazonSSMManagedInstanceCore).
> 3.  Enforce IMDSv2 (HttpTokens required).
> 4.  Ensure the root EBS volume is encrypted.
> 5.  Create a Security Group that allows no inbound traffic (we will use SSM to connect) and allows all outbound traffic."

### 2\. The Output (Example)

Save this code into a new folder `lab-scenario-2/main.tf`.

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Get Latest AL2023 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-2023/amd64/standard/regional/image_id"
}

# 2. IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ec2_ssm_role_lab"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2_ssm_profile_lab"
  role = aws_iam_role.ssm_role.name
}

# Security Group (No Inbound)
resource "aws_security_group" "no_inbound" {
  name        = "allow_ssm_only"
  description = "Allow outbound only"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Instance
resource "aws_instance" "secure_server" {
  ami                  = data.aws_ssm_parameter.al2023.value
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.no_inbound.id]

  # 3. Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # 4. Encrypt Root Volume
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "Scenario2-SecureInstance"
  }
}
```

### 3\. Re-Scan with Trivy

Run the scan in the new folder:

```bash
trivy config .
```

**Analysis:** You should see significantly fewer security issues. The Critical/High issues regarding encryption and IMDSv2 should be resolved.

-----

## Part 4: Deployment & Verification

Now we deploy the **Scenario 2** instance.

### 1\. Initialize and Apply

Inside the `lab-scenario-2` folder:

```bash
# Download provider plugins
terraform init

# View the deployment plan
terraform plan

# Create the infrastructure (Type 'yes' when prompted)
terraform apply
```

### 2\. Enable AWS Inspector (Runtime Security)

Infrastructure as Code scanning (Trivy) checks the *blueprint*. AWS Inspector checks the *running server* for software vulnerabilities (CVEs).

1.  Log into the AWS Console.
2.  Search for **Inspector**.
3.  If not already active, click **Activate Inspector**.
4.  Go to **Account Management** in the Inspector sidebar and ensure "EC2 Scanning" is Enabled.

### 3\. Verify the Instance

Because we used the **SSM Agent** and an **IAM Role**, Inspector can automatically scan the instance without needing SSH keys or open ports.

1.  Wait 5-10 minutes after deployment.
2.  In the Inspector Console, click **Dashboard**.
3.  Look at **Environment Coverage**. You should see your EC2 instance listed as "100% covered."
4.  Click **Findings**. If the Amazon Linux 2023 AMI has any brand-new vulnerabilities, they will appear here.

### 4\. Connect via SSM (Bonus)

Since we blocked port 22 (SSH), verify you can still access the server:

1.  Go to the EC2 Console.
2.  Select `Scenario2-SecureInstance`.
3.  Click **Connect**.
4.  Select the **Session Manager** tab and click **Connect**.
5.  You now have a secure shell without opening ports to the internet\!

-----

## Cleanup

To avoid unexpected charges, destroy the resources when finished.

```bash
terraform destroy
# Type 'yes' to confirm
```

