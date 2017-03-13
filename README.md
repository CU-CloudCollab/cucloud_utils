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

Also this container is available from docker hub in the repository cucloudcollab/cutils.  You can pull from it and add you own code.

## Available Utilities

The following utilities are currently available:

* [VPC Configuration Check](#check-account)
* [EC2 Auto-Snapshot](#auto-snapshot)
* [EC2 Cleanup Snapshots](#clean-snapshots)
* [EC2 Auto-Patch](#auto-patch)
* [EC2 Start/Stop by Tag](#ec2-scheduling-start-and-stop)
* [List Active API Keys](#list-active-api-keys)
* [Lambda Function Backup](#lambda-function-backup)

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
                "ec2:DescribeRegions",
                "ec2:DescribeVpcs"
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

### EC2 Scheduling Start and Stop

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

### Lambda Function Backup
```
docker run -it --rm -v ~/.aws:/root/.aws cutils backup_lambda BUCKET_NAME
```
Utility to backup all lambda functions in a region in an account.  The utility accepts two parameters the first is the name  of the s3 bucket to back up to.  The second parameter controls which versions are backed up.  By default the second parameter is 'YES' which will backup all version of the lambda function, any other value will backup on the version $LATEST.

Minimum IAM policy requirements:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1476987642000",
            "Effect": "Allow",
            "Action": [
              "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME/*"
            ]
        },
        {
          "Sid": "DisplayFunctionDetailsPermissions",
          "Effect": "Allow",
          "Action": [
              "lambda:ListVersionsByFunction",
              "lambda:GetFunction",
              "lambda:ListFunctions"
          ],
          "Resource": "*"
      }
    ]
}
```

### Delete/Restore RDS Database
```
docker run -it --rm -v ~/.aws:/root/.aws cutils delete_db DB_IDENTIFIER
```

```
docker run -it --rm -v ~/.aws:/root/.aws cutils restore_db --db_id DB_IDENTIFIER
```

These utilities will allow you to delete and restore RDS databases.  They are written in a way that when used together they can "hibernate" a database.  Using the delete_db function will create a final snapshot of the instance which the restore function can find.  This allows you to delete the DB at night and restore in the morning which helps to defray the cost of running many DB instances.

Minimum IAM policy requirements:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "rds:CreateDBInstance",
              "rds:DeleteDBInstance",
              "rds:AddTagsToResource",
              "rds:CreateDBSnapshot",
              "rds:RestoreDBInstanceFromDBSnapshot",
              "rds:ModifyDBInstance",
              "rds:Describe*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Deny",
            "Action": "rds:DeleteDBInstance",
            "Resource": [
                "arn:aws:rds:us-east-1:ACCOUNT:db:prod-1",
                "arn:aws:rds:us-east-1:ACCOUNT:db:prod-2",
            ]
        }
    ]
}
```
