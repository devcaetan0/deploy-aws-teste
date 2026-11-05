# Requirements Document

## Introduction

This document specifies the requirements for deploying the Capi's Rentals hash service application to Amazon Web Services (AWS). The application is a Go-based HTTP service that provides cryptographic hash calculation capabilities, storing results in DynamoDB. The deployment must be designed for a beginner AWS user (Portuguese speaker from Brazil) competing in a WorldSkills Cloud Computing challenge, operating within AWS Learner Lab constraints and a 50-credit budget.

The system comprises an EC2-based application tier with automatic scaling, an Application Load Balancer for traffic distribution, DynamoDB for data persistence, and CloudWatch for monitoring. The deployment must achieve high availability, automatic scaling based on demand, and remain within budget constraints.

## Glossary

- **ALB (Application Load Balancer)**: AWS service that distributes incoming HTTP traffic across multiple EC2 instances and performs health checks
- **ASG (Auto Scaling Group)**: AWS service that automatically adjusts the number of EC2 instances based on demand
- **Availability Zone (AZ)**: Physically separated data center within an AWS Region, providing fault isolation
- **CloudWatch**: AWS monitoring and observability service for metrics, logs, and alarms
- **CapiRentalsHash**: The DynamoDB table name for storing hash calculation results
- **EC2 Instance**: Virtual server in AWS cloud computing platform
- **DynamoDB**: Fully managed NoSQL database service provided by AWS
- **Hash Service**: The Go application that computes SHA256 hashes and persists results to DynamoDB
- **Health Endpoint**: HTTP endpoint at /health that returns service status
- **IAM Role**: AWS Identity and Access Management role providing permissions to EC2 instances
- **Launch Template**: Configuration template defining instance settings for Auto Scaling
- **Port 80**: Standard HTTP port for web traffic
- **Security Group**: Virtual firewall controlling inbound and outbound traffic for EC2 instances
- **SLA (Service Level Agreement)**: Defined performance targets for response time and availability
- **Target Group**: Logical group of EC2 instances registered with an ALB for traffic routing
- **User Data**: Script executed automatically when an EC2 instance launches
- **VPC (Virtual Private Cloud)**: Isolated virtual network in AWS for deploying resources

## Requirements

### Requirement 1: Application Hosting on EC2

**User Story:** As a cloud engineer, I want the Go application deployed on EC2 instances, so that the hash service is available to users.

#### Acceptance Criteria

1. THE System SHALL deploy the ami-bin/server binary on EC2 instances running Amazon Linux.
2. THE System SHALL configure the application to listen on port 80 for HTTP requests.
3. WHEN an EC2 instance launches, THE System SHALL execute the User Data script to install and start the application automatically.
4. THE System SHALL set environment variables DYNAMO_TABLE and PORT on each EC2 instance.

### Requirement 2: DynamoDB Database Integration

**User Story:** As a cloud engineer, I want the application connected to DynamoDB, so that hash calculations are persisted reliably.

#### Acceptance Criteria

1. THE System SHALL create a DynamoDB table named "CapiRentalsHash" with partition key "id" of type String.
2. WHEN the application receives a request to /calc endpoint, THE System SHALL persist the input text and generated hash to the CapiRentalsHash table.
3. THE System SHALL grant EC2 instances IAM permissions to perform PutItem operations on the CapiRentalsHash table.
4. THE System SHALL configure the application to use the us-east-1 AWS Region for DynamoDB connectivity.

### Requirement 3: HTTP Endpoint Availability

**User Story:** As a user, I want to access the hash service via HTTP, so that I can check health and calculate hashes.

#### Acceptance Criteria

1. THE System SHALL expose the /health endpoint returning HTTP 200 with body "Healthy!" when the service is operational.
2. WHEN a user requests /calc?input=value with a valid input parameter, THE System SHALL return HTTP 200 with a JSON response containing the base64-encoded SHA256 hash.
3. WHEN a user requests /calc without the input parameter, THE System SHALL return HTTP 400 with an error message.
4. THE System SHALL accept HTTP requests on port 80 from any internet source (0.0.0.0/0).

### Requirement 4: Traffic Distribution via Load Balancer

**User Story:** As a cloud engineer, I want an Application Load Balancer distributing traffic, so that requests are evenly distributed across instances.

#### Acceptance Criteria

1. THE System SHALL create an internet-facing Application Load Balancer configured for HTTP on port 80.
2. THE System SHALL create a Target Group with the /health endpoint configured for health checks.
3. WHEN the ALB receives an HTTP request, THE System SHALL forward the request to a healthy EC2 instance in the Target Group.
4. WHEN an EC2 instance fails health checks for 3 consecutive intervals, THE System SHALL mark the instance as unhealthy and stop routing traffic to it.
5. THE System SHALL configure health check interval of 30 seconds with a healthy threshold of 2 successful checks.

### Requirement 5: Automatic Scaling

**User Story:** As a cloud engineer, I want the system to scale automatically, so that it handles variable traffic loads without manual intervention.

#### Acceptance Criteria

1. THE System SHALL create an Auto Scaling Group with minimum 1 instance and maximum 3 instances.
2. WHEN the average CPU utilization exceeds 70% for 5 minutes, THE System SHALL launch one additional EC2 instance.
3. WHEN the average CPU utilization falls below 30% for 5 minutes, THE System SHALL terminate one EC2 instance.
4. WHILE instances are launching, THE System SHALL allow a warm-up period of 300 seconds before including them in scaling metrics.
5. THE System SHALL use a Launch Template specifying t3.micro or t2.micro instance types.

### Requirement 6: High Availability Across Availability Zones

**User Story:** As a cloud engineer, I want instances distributed across multiple Availability Zones, so that the service remains available if one zone fails.

#### Acceptance Criteria

1. THE System SHALL deploy EC2 instances across at least 2 different Availability Zones.
2. WHEN one Availability Zone becomes unavailable, THE System SHALL continue serving traffic from instances in the remaining Availability Zone.
3. THE System SHALL configure the ALB with subnets in at least 2 Availability Zones.

### Requirement 7: Security Configuration

**User Story:** As a cloud engineer, I want proper security groups configured, so that the application is accessible while maintaining security.

#### Acceptance Criteria

1. THE System SHALL create a Security Group allowing inbound HTTP traffic on port 80 from 0.0.0.0/0.
2. THE System SHALL allow all outbound traffic from EC2 instances to enable DynamoDB and CloudWatch connectivity.
3. THE System SHALL create an IAM Role with policies for DynamoDB access and CloudWatch metrics publishing.
4. THE System SHALL associate the IAM Role with EC2 instances in the Launch Template.

### Requirement 8: Response Time Performance

**User Story:** As a user, I want fast response times, so that the hash service provides a good user experience.

#### Acceptance Criteria

1. WHEN a user requests the /health endpoint, THE System SHALL respond within 200 milliseconds under normal operating conditions.
2. WHEN a user requests the /calc endpoint with a valid input, THE System SHALL respond within 500 milliseconds under normal operating conditions.
3. THE System SHALL measure response times from the ALB to the EC2 instance and back.

### Requirement 9: System Availability

**User Story:** As a user, I want the service highly available, so that I can access it when needed.

#### Acceptance Criteria

1. THE System SHALL maintain 99.9% uptime calculated monthly.
2. WHEN an EC2 instance fails health checks, THE System SHALL replace the instance automatically within 5 minutes.
3. THE System SHALL ensure at least 1 instance is running at all times through Auto Scaling Group minimum capacity.

### Requirement 10: Cost Management

**User Story:** As a competitor, I want the deployment to stay within budget, so that I do not exceed the 50 AWS Learner Lab credits.

#### Acceptance Criteria

1. THE System SHALL limit the Auto Scaling Group maximum capacity to 3 instances.
2. THE System SHALL use t3.micro or t2.micro instance types which are eligible for Learner Lab credits.
3. THE System SHALL avoid using NAT Gateways to minimize costs.
4. THE System SHALL use public subnets for EC2 instances to eliminate NAT Gateway costs.
5. WHERE DynamoDB capacity mode is configurable, THE System SHALL use on-demand capacity for simplicity and cost predictability under low traffic.

### Requirement 11: Monitoring and Observability

**User Story:** As a cloud engineer, I want CloudWatch metrics and alarms, so that I can monitor system health and performance.

#### Acceptance Criteria

1. THE System SHALL publish EC2 CPU utilization metrics to CloudWatch every 5 minutes.
2. THE System SHALL publish ALB request count and latency metrics to CloudWatch.
3. WHEN CPU utilization exceeds 80% for 5 minutes, THE System SHALL trigger a CloudWatch alarm.
4. THE System SHALL enable Auto Scaling Group metrics collection for group size and instance count visibility.
5. THE System SHALL configure the ALB to log health check status for each registered instance.

### Requirement 12: AWS Learner Lab Constraints

**User Story:** As a competitor, I want the deployment compatible with Learner Lab restrictions, so that I can successfully deploy within the competition environment.

#### Acceptance Criteria

1. WHERE AWS services are restricted, THE System SHALL use only ec2, s3, ebs, ecs, cloudwatch, systems manager, cloudtrail, config, vpc, cloudfront, and lambda.
2. THE System SHALL function within Learner Lab network constraints which may limit VPC creation options.
3. THE System SHALL use the default VPC if custom VPC creation is restricted.
4. THE System SHALL complete deployment using only the AWS Console (no CloudFormation templates).
5. THE System SHALL provide step-by-step Console instructions written in Portuguese for the Brazilian competitor.

### Requirement 13: Deployment Documentation

**User Story:** As a beginner AWS user, I want clear step-by-step instructions, so that I can deploy the system successfully.

#### Acceptance Criteria

1. THE System SHALL provide deployment instructions in Portuguese (Brazil).
2. WHERE Console steps are documented, THE System SHALL include screenshots or ASCII diagrams for visual guidance.
3. THE System SHALL explain each AWS concept in beginner-friendly language with analogies.
4. THE System SHALL include troubleshooting guidance for common deployment issues.
5. THE System SHALL provide verification steps to confirm successful deployment.
