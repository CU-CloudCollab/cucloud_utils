# CU Cloud Utilities Package

A package of ready-to-use utilities for managing AWS services and infrastructure.  Delivered in a portable Docker container.

## Installation

First, build the container:

```
docker build -t cutils .
```

Then run for instructions on what commands/utilities are available:
```
docker run -it --rm -v ~/.aws:/root/.aws cutils
```

Note - this command passes in your .aws folder so that commands can use your credential sets.  You can also pass in credentials as environment variables:

```
docker run -it -e AWS_ACCESS_KEY_ID=[ID] -e AWS_SECRET_ACCESS_KEY=[KEY] cutils
```

## Available Utilities

The following utilities are currently available:

### Check Account

```
docker run -it --rm -v ~/.aws:/root/.aws cutils check_account
```

Utility to check your VPC configuration and test if it is in compliance with current ITSO and Cornell best practices.  The utility runs as a set of rspec tests and will return a proper exit code on pass/fail (ideal for a jenkins job).

If running as a job, we recommend using AWS credentials with minimum privileges -- the following policy example can be used:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1470184545000",
            "Effect": "Allow",
            "Action": [
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetTrailStatus"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1470184577000",
            "Effect": "Allow",
            "Action": [
                "config:DescribeConfigRuleEvaluationStatus",
                "config:DescribeConfigRules",
                "config:DescribeConfigurationRecorderStatus",
                "config:GetComplianceDetailsByConfigRule"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1470184684000",
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy",
                "iam:GetAccountSummary",
                "iam:GetLoginProfile",
                "iam:GetSAMLProvider",
                "iam:ListAccessKeys",
                "iam:ListAccountAliases",
                "iam:ListSAMLProviders",
                "iam:ListUsers"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1470184814000",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeFlowLogs",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRegions"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

### Auto Snapshot

```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot
```

Utility to snapshot volumes attached to running instances.  The utility takes one integer parameter, the default if nothing is passed is 5.  The utility will create an EBS snapshot of all volumes that do not have a snapshot within the last x days, where x is the parameter passed to the utility.

If running as a job, we recommend using AWS credentials with minimum privileges -- the following policy example can be used:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1472066087000",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstances",
                "ec2:CreateTags"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
