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

#### Check Account Exemptions
**IAM Key Age**: Users may be exempted from the 90 day IAM key check test by including them in a comma-delimited list passed via the `CUTILS_IAM_KEY_WHITELIST`:
```
docker run -it --rm -e CUTILS_IAM_KEY_WHITELIST="service_acct1,service_acct2" cutils check_account
```
Keys that are especially difficult to rotate can be whitelisted with this option. Note, allowing keys to age past 90 days is not a recommended practice. If it is absolutely necessary and instance roles are not an option (i.e., SES SMPT), we recommend that these keys be very tightly scoped in privilege.

### Auto Snapshot

```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot
```

Utility to snapshot volumes attached to running instances.  When run with no options specified, will snapshot attached volumes that do not have a snapshot taken within the past **five** days.  Optional parameters include:

   * **--apply-tag** Key=*keyname*,Value=*value*
      * Adds a tag key/value pair to created snapshots.
      * Note that tags specified here will **take precedence** over tags with the same key.
         * Will override values from EBS volume tags that would otherwise have been copied via the **--preserve-tags** argument.
      * May be specified multiple times to add several tags at once.
   * **--num-days** *N*
      * Take snapshots of volumes that do not have a snapshot within the last *N* days.
      * Defaults to **5** if not specified (see backwards compatibility note below).
   * **--preserve-tags** *a,b,c*
      * List of tag keys to preserve, if present, from the EBS volume.
      * May be specified multiple times to add new keys to the preservation list.

Previous versions of this utility allowed specification of *one integer parameter* to indicate snapshots should be taken of EBS volumes that did not have a snapshot within the past *N* days.  That behavior has been maintained and can be used in lieu of the extended options listed above.  If both **--num-days** and an unnamed integer option are specified, the unnamed argument will be used.

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

#### Examples
Take snapshots of all EBS volumes without a snapshot in the past 2 days:
```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot 2
```

Take snapshots of all EBS volumes without a snapshot in the past 5 days:
```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot
```

Take snapshots of all EBS volumes without a snapshot in the past 5 days, adding tag "Foo=Bar"
```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot --apply-tag Key=Foo,Value=Bar
```

Take snapshots of all EBS volumes without a snapshot in the past 5 days, adding tags "Foo=Bar", "Foo2=Bar2" *and* preserving the volumes' "Application", "Cost Center" and "Environment" tags:
```
docker run -it --rm -v ~/.aws:/root/.aws cutils auto_snapshot \
 --apply-tag Key=Foo,Value=Bar \
 --apply-tag Key=Foo2,Value=Bar2 \
 --preserve-tags Application \
 --preserve-tags "Cost Center,Environment"
```

Note the use of argument quoting to account for whitespace in key/value data.


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

Utility to clean up older EBS snapshots, by default it will remove snapshots older than 15 days.  The utility accepts one parameter that can be used to adjust how many days old the snapshot needs to be to be removed.

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

### Delete Older RDS Snapshots

```
docker run -it --rm -v ~/.aws:/root/.aws cutils delete_older_rds_snapshots
```

Utility to clean up older RDS snapshots, by default it will remove snapshots older than 15 days.  The utility accepts one parameter that can be used to adjust how many days old the snapshot needs to be to be removed.

If running as a job, we recommend using AWS credentials with minimum privileges -- the following policy example can be used:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1472066087000",
            "Effect": "Allow",
            "Action": [
              "rds:DescribeDBSnapshots",
              "rds:DeleteDBSnapshot"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
