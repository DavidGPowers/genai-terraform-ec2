# The "Advanced" Prompt

Copy and paste the text below into your LLM of choice:

***

Act as a Senior DevOps Engineer. Write a complete Terraform configuration to deploy an AWS EC2 instance with the following strict requirements:

1.  **Dynamic Data:** Do NOT hardcode any VPC IDs, Subnet IDs, or AMI IDs. Use `data` blocks to dynamically look up the default VPC, the default Subnet in that VPC, and the latest "Amazon Linux 2023" AMI.

2.  **Modern Access (No SSH):** * Do NOT configure an SSH Key Pair.
    * Do NOT open port 22 in the Security Group.
    * Instead, configure the instance for **AWS Systems Manager (SSM) Session Manager** access.
    * Create an IAM Role with the managed policy `AmazonSSMManagedInstanceCore` attached.
    * Create an Instance Profile for this role and attach it to the EC2 instance.

3.  **Networking:** Create a NEW Security Group. Since we are using SSM, strictly allow **no inbound traffic** (egress only).

4.  **Resources:** Deploy a `t3.micro` instance using the dynamic data, the IAM instance profile, and the new security group.

5.  **Best Practices:** Tag all resources with `Name = "GenAI-Lab-Advanced"`.

6.  **Outputs:** Output the Instance ID (required to connect via SSM Console).

***