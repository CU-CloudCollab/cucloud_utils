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

### Auto Patch

```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_patch
```

Utility to patch and reboot linux instances.  If no parameters are supplied it will look for instances tagged with auto_patch with a value of 1.  Optionally can supply the tag and the value of that tag.

If running as a job, we recommend using AWS credentials with minimum privileges -- the following policy example can be used:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1472066087000",
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeInstances",
              "ssm:SendCommand"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

### Clean Snapshots

```
docker run -it --rm -v ~/.aws:/root/.aws cutils clean_snapshot
```

Utility to clean up older snapshots, by default it will remove snapshots older than 15 days.  The utility accepts one parameter that can be used to adjust how many days old the snapshot needs to be to be removed.

If running as a job, we recommend using AWS credentials with minimum privileges -- the following policy example can be used:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1472066087000",
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeSnapshots",
              "ec2:DeleteSnapshot"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

### EC2 Scheduling Start/Stop

```
 docker run -it --rm -v ~/.aws:/root/.aws cutils ec2_scheduling --t environment --v development --a stop
```
Utility to start/stop instances based on tag name and value.  Used in conjunction with Jenkins, a good place to start to schedule start/stop of instances during business hours


### List Active API keys
```
 docker run -it --rm -v ~/.aws:/root/.aws cutils active_api_keys
```
Report of all active API keys on your account + their age in days.  Useful for quick inventory of keys and planning rotation schedule.

Minimum IAM policy requirements:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1476987642000",
            "Effect": "Allow",
            "Action": [
                "iam:ListAccessKeys",
                "iam:ListUsers"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
