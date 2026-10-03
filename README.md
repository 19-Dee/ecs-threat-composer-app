# Production-ready AWS ECS deployment of Threat Composer

A containerised deployment of the Threat Composer application on AWS ECS Fargate using Terraform for infrastructure, GitHub Actions for CI/CD, OIDC for secure AWS authentication, and CloudWatch for application logging.

The application runs in private subnets behind an Application Load Balancer with HTTPS provided through ACM and Route 53.

> **Live environment:** Infrastructure was destroyed after validation to avoid unnecessary AWS costs.

## Tech Stack

- **Infrastructure:** AWS, Terraform, S3 remote backend
- **Compute:** ECS Fargate
- **Container Registry:** Amazon ECR
- **Networking:** VPC, ALB, public/private subnets, NAT Gateway, security groups
- **DNS / TLS:** Route 53, ACM
- **CI/CD:** GitHub Actions
- **Authentication:** GitHub OIDC → AWS IAM
- **Observability:** CloudWatch Logs
- **Containerisation:** Docker

## Live Application

<img width="2542" height="1364" alt="Screenshot 2026-10-03 at 02 11 57" src="https://github.com/user-attachments/assets/17b322c8-f0c6-4497-8663-ee59adc2fbde" />

## Architecture

<img width="2048" height="1345" alt="Threat Composer on AWS ECS Fargate Architecture (10)" src="https://github.com/user-attachments/assets/96274d2e-08bf-44bc-8a99-05cc97f5123e" />

## CI/CD

Four GitHub Actions workflows are used:

```text
.github/workflows/
├── plan.yaml
├── apply.yaml
├── docker.yaml
└── destroy.yaml
```

### Infrastructure

Terraform changes are validated through the plan workflow.

Infrastructure deployment is performed manually through the apply workflow:

```text
GitHub Actions
      |
      v
GitHub OIDC Token
      |
      v
AWS IAM Role
      |
      v
Terraform Init / Plan / Apply
      |
      v
AWS Infrastructure
```

No long-lived AWS access keys are stored in GitHub.

### Application Deployment

Application changes trigger the Docker workflow:

```text
Application Change
      |
      v
GitHub Actions
      |
      v
Build linux/amd64 Image
      |
      v
Push :latest to ECR
      |
      v
Force ECS Service Deployment
      |
      v
New Fargate Task
```

The ECS task definition runs:

```text
CPU:              1024
Memory:           4096 MB
OS:               Linux
Architecture:     X86_64
Container Port:   3000
Launch Type:      Fargate
```

## HTTPS and Load Balancing

Public traffic follows this path:

```text
Client
  |
  v
Route 53
  |
  v
ALB :443
  |
  v
Target Group
  |
  v
ECS Task :3000
```

HTTP traffic on port `80` is redirected to HTTPS on port `443`.

TLS is provided by AWS Certificate Manager.

The target group performs HTTP health checks against:

```text
/
```

A healthy deployment was validated with:

```text
Target Health: healthy
HTTP Status:   200
Response Time: ~0.14s
```

## Observability

Application logs are sent from ECS to CloudWatch using the `awslogs` log driver.

```text
/ecs/ecs-threat-composer
```

CloudWatch was used to inspect:

- container startup
- React compilation
- runtime warnings
- ECS deployment behaviour
- ALB health-check timing

## How to Reproduce

### 1. Clone the repository

```bash
git clone <repository-url>
cd ecs-threat-composer-app
```

### 2. Configure AWS authentication

Configure AWS credentials locally for the initial Terraform bootstrap.

GitHub Actions deployments use OIDC rather than stored AWS access keys.

### 3. Initialise Terraform

```bash
terraform -chdir=terraform init
```

### 4. Review the infrastructure plan

```bash
terraform -chdir=terraform plan
```

### 5. Deploy the infrastructure

```bash
terraform -chdir=terraform apply
```

### 6. Build and push the application image

The GitHub Actions Docker workflow builds the application for:

```text
linux/amd64
```

and pushes the image to Amazon ECR.

### 7. Deploy to ECS

The pipeline forces a new ECS service deployment after the image is pushed.

The Fargate task is then registered automatically with the ALB target group.

## Decisions and Trade-offs

### ECS Fargate over EC2-backed ECS

Fargate was used to avoid managing EC2 worker instances.

This keeps the project focused on container deployment, networking, IAM, and infrastructure automation rather than instance lifecycle management.

### Private ECS Tasks

The ECS tasks run without public IP addresses.

Only the Application Load Balancer can reach the application port through security-group referencing.

This reduces the public attack surface.

### GitHub OIDC over Static AWS Credentials

GitHub Actions authenticates to AWS through OpenID Connect.

This avoids storing long-lived AWS access keys as GitHub secrets and allows the workflows to receive temporary AWS credentials.

### Manual Terraform Apply

Terraform planning is automated while infrastructure application is manually triggered.

This separates infrastructure review from infrastructure modification and avoids automatically applying every Terraform change.

### Mutable `latest` Image Tag

The application deployment workflow pushes the `latest` image tag to ECR and forces a new ECS deployment.

This keeps the deployment mechanism intentionally simple for the scope of the project.

A production system could instead deploy immutable image digests or versioned tags.

### Single NAT Gateway

A single NAT Gateway was used for outbound connectivity from the private subnets.

This reduces project cost and complexity but introduces a single-AZ dependency for outbound traffic.

A production architecture requiring higher availability could deploy one NAT Gateway per Availability Zone.

## Troubleshooting

### GitHub OIDC Trust Failure

The GitHub Actions workflow initially failed to assume the AWS deployment role.

The IAM trust policy did not match the actual OIDC subject sent by GitHub.

The authentication event was inspected to identify the exact subject value, after which the trust relationship was corrected.

### IAM Inline Policy Size Limit

The GitHub Actions role originally exceeded the AWS inline policy size limit.

The permissions were split into:

```text
ecs-threat-composer-deploy
ecs-threat-composer-iam
```

This retained the required permissions while staying within the IAM policy size limit.

### ECS Task Definition Permissions

Terraform successfully registered an ECS task definition but failed when attempting to read it afterwards.

The issue was IAM resource scoping.

The following actions required wildcard resource scope:

```text
ecs:DescribeTaskDefinition
ecs:DeregisterTaskDefinition
```

Moving them to the wildcard-scoped discovery statement resolved the problem.

### Missing ECR Image

After the infrastructure was first deployed, ECS attempted to start the task before an image tagged `latest` existed in ECR.

The task failed with:

```text
CannotPullContainerError
```

The Docker workflow then:

```text
Built Image
    |
    v
Pushed :latest to ECR
    |
    v
Forced ECS Deployment
    |
    v
Task Started Successfully
```

### ALB Health Check Timing

The target initially reported:

```text
Target.Timeout
```

CloudWatch showed that the React development server was still compiling.

Once compilation completed, the application responded successfully and the target transitioned to:

```text
healthy
```

No infrastructure change was required.

## Validation

The completed deployment was validated through:

- successful Terraform GitHub Actions workflow
- successful Docker deployment workflow
- running ECS Fargate task
- healthy ALB target
- ECR image deployment
- CloudWatch application logs
- Route 53 DNS resolution
- ACM HTTPS certificate
- successful HTTPS response

```text
HTTP 200 | total ~0.14s
```

## Evidence

### Terraform Deployment

<img width="2580" height="816" alt="Screenshot 2026-10-03 at 02 09 08" src="https://github.com/user-attachments/assets/1f0abd72-b5f5-4dd4-be30-6e392b7a1ad7" />

### Application Deployment

<img width="2554" height="593" alt="Screenshot 2026-10-03 at 02 09 21" src="https://github.com/user-attachments/assets/4c46775a-f91a-4242-acd5-0b74afc3b242" />

### ECS Service

<img width="2560" height="617" alt="Screenshot 2026-10-03 at 02 10 35" src="https://github.com/user-attachments/assets/c6ec6711-dfd4-42e4-bf9c-4bcec12a0980" />

### Healthy Target

<img width="2557" height="1050" alt="Screenshot 2026-10-03 at 02 11 00" src="https://github.com/user-attachments/assets/2eebf979-3281-4a8e-b21b-07c89c58ad8e" />

### ECR Image

<img width="2559" height="519" alt="Screenshot 2026-10-03 at 02 11 41" src="https://github.com/user-attachments/assets/36ba13e8-4544-43e3-a7cd-fbfe87d6aa19" />

### CloudWatch Logs

<img width="2558" height="986" alt="Screenshot 2026-10-03 at 02 13 18" src="https://github.com/user-attachments/assets/2dc253ad-08f1-44f4-a813-21e817e90941" />

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       ├── apply.yaml
│       ├── destroy.yaml
│       ├── docker.yaml
│       └── plan.yaml
│
├── app/
│
├── terraform/
│   ├── modules/
│   │   ├── alb/
│   │   ├── ecs/
│   │   ├── route53/
│   │   └── vpc/
│   │
│   ├── ecr.tf
│   ├── iam.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── providers.tf
│
├── docs/
│   ├── architecture.png
│   └── screenshots/
│
└── README.md
```

## Cleanup

The AWS infrastructure was destroyed after validation to prevent unnecessary cloud costs.

The account was checked for remaining project resources including:

- ECS and EKS clusters
- EC2 instances
- NAT Gateways
- Application Load Balancers
- Elastic IP addresses
- EBS volumes
- ECR repositories
- RDS instances
- ElastiCache clusters
- ACM certificates

No active compute, networking, database, or load-balancing resources remained after cleanup.
