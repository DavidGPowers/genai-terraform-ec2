*genai-terraform-ec2*

# GenAI Prompt Engineering Lab: Simple vs. Advanced Terraform

## Overview
This repository contains the artifacts of a live demonstration comparing two approaches to generating Infrastructure as Code (IaC) using Generative AI. 

The goal of this lab is to demonstrate that **context matches quality**. A simple prompt yields code that requires manual toil and hides security risks, while an informed, advanced prompt produces robust, automatable, and auditable code.

## Repository Structure

```text
.
├── advanced/
│   └── main.tf               # Result of the "Advanced" prompt (Single file, dynamic lookups)
├── simple/
│   ├── main.tf               # Entry point for the "Simple" variant
│   ├── provider.tf
│   └── modules/              # The AI hallucinated/chose a module structure for the simple request
│       └── ec2-instance/
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
├── Ec2Lab.md                 # Detailed lab instructions
└── README.md
````

## The Experiment

We used a Large Language Model (LLM) to generate Terraform code for an AWS EC2 instance using two distinct prompting strategies.

### 1\. The Simple Variant (`./simple`)

  * **Prompt Strategy:** A basic, one-sentence request (e.g., *"Write Terraform code to deploy an EC2 instance"*).
  * **Outcome:**
      * **High Toil:** The generated code relied on hardcoded Resource IDs (Subnets, VPCs). This required the user to manually look up IDs in the AWS Console and paste them in before `terraform plan` would succeed.
      * **Hidden Risks:** It relied on a pre-existing Security Group. Because this SG was not managed by Terraform, it was invisible to IaC security scanners.

### 2\. The Advanced Variant (`./advanced`)

  * **Prompt Strategy:** A robust prompt specifying data sources, naming conventions, and security parameters.
  * **Outcome:**
      * **Automated:** The code used `data` blocks to dynamically retrieve Subnet and VPC IDs.
      * **Auditable:** It created its own Security Group, making the rules visible to code analysis.
      * **Speed:** The template deployed immediately with zero manual lookups.

-----

## Security Analysis (Trivy)

We ran `trivy config tfplan` against the plan files for both variants.

### Simple Variant Findings

  * ❌ **IMDSv2 Missing:** The AI did not default to the secure Instance Metadata Service v2.
  * ❌ **Unencrypted Root Volume:** The EBS volume was left unencrypted.
  * ⚠️ **The Hidden Risk:** The findings **did not** flag the open `0.0.0.0/0` egress rules because the Security Group was unmanaged (pre-existing) and therefore outside the scope of the Terraform plan.

### Advanced Variant Findings

  * ✅ **Infrastructure Visibility:** Trivy correctly flagged the Security Group for having `0.0.0.0/0` egress.
  * *Note:* While open egress is a finding, the fact that it was *visible* in the scan proves the Advanced variant is more auditable than the Simple variant.

-----

## 🧪 Lab Challenge: The "Model du Jour"

**Do not rely solely on the code in this repository.** Generative AI is a rapidly advancing field. The "best" model today may be outperformed tomorrow. The code included here is just one iteration.

### Your Task:

1.  **Choose your fighter:** Select a current LLM (ChatGPT, Claude, Gemini, etc.).
2.  **Replicate the experiment:**
      * Issue a **Simple Prompt** and attempt to deploy the result. Note the manual changes required.
      * Issue an **Advanced Prompt** asking for dynamic data lookups and specific constraints.
3.  **Analyze:** Run `trivy config` on your results.
4.  **Compare:** Does the newest model handle IMDSv2 by default? Does it still hallucinate hardcoded IDs?

*Experience the difference between "getting code" and "getting a solution."*

```

### Prerequisites for Analysis
* [Terraform](https://www.terraform.io/)
* [AWS CLI](https://aws.amazon.com/cli/)
* [Trivy](https://trivy.dev/)

