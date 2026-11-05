# Workshop Worldskills Brasil
#53 Cloud Computing - 2024

## Capi's Rentals Runbook

<p align="center" width="100%">
    <img width="50%" src="imgs/logo.png">
</p>

### Introduction

The Capi's Rentals website provides cryptographically strong hashes as a service. The
system is comprised of a client application and a standalone server. The system builds the hash based on a proprietary, computationally expensive hashing algorithm.

The server is currently not deployed, There is no session state to track or external calls to make so the server architecture should respond well to simple horizontal scaling. As there is expected to be a constrained set of client keys.

That's it for hints.
 

### Scope

This runbook describes the operational theory and practice for the production system
powering the Capi's Rentals website. The primary audience is the DevOps team running
the site. The DevOps team is responsible for deploying code, scaling the site in response
to load, maintaining our published SLA's (including response time and uptime), disaster
recovery, troubleshooting activities and any monitoring and alerting activities required
to meet these objectives.

### References

The server application is deployed,as a 'go' binary compiled from source rumored to be stored in a github repository. However, the name of of this repository is unknown to the current operations and development staff.

The server application is an x86 statically linked, unstripped ELF executable found here: https://github.com/thiagodavala/workshop-wsc-2024/blob/main/ami-bin/server

The base OS we have chosen is Amazon Linux. This distribution was selected for it's broad industry support, stability, availability of support and excellent integration with AWS. This distributions was selected by SecOps based on their requirements for platform hardening.

Architecture was moved to AWS as part of go-to-market plan. Operating the AWS CLI (http://docs.aws.amazon.com/cli/latest/userguide/installing.html) might be helpful.

When working with AWS, only the following roles are allowed by SecOps... and finance:
- ec2
- s3
- ebs
- ecs
- cloudwatch
- systems manager
- cloudtrail
- config
- vpc
- cloudfront
- lambda

Getting bored of writing this silly thing. Who needs it?

Binary file is in ami-bin folder.

#### Tasks

1. Please read the documentation carefully, it will be very helpful
2. Access AWS Academy Leaner Lab, start a Lab.
3. Check the existing configuration in EC2 (Elastic Cloud Computer Server)
4. Check the existing configuration in VPC (VPC, Subnet)
5. Configure the application to automatically scale to handle the increasing load (Auto Scaling Groups, with Launch Configuration)
6. Configure the relevant server dependencies as described in the technical details
7. Your most important task is to launch and ensure that the Server application is available and scalable
8. Configure the necessary application monitoring, metrics and alarms in CloudWatch
9. Monitor costs and do not overscale the infrastructure to minimize penalty points
10. The amount of traffic changes over time and occurs continuously

### Troubleshooting Procedures

If you need help, try:

```
./server --help
```

New application test utility!

```
export BASE_URL=localhost:80
./test_requests.sh
```


> [!CAUTION]
> If you are limited in creating certain resources because of using AWS Leaner Lab (e.g. create new VPC, Cloudformation and etc.), it is not my fault, turn around and try to make our application available!

## Change Management

HAH!

## System Monitoring

How to check ELB metrics?
http://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/policy_creating.html

http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elb-cloudwatch-metrics.html


## To Do

- How to test HA? Automate DR.
- Refactor infrastructure using container architecture


<hr/>
Feito com :hearts: por Thiago Geremias
