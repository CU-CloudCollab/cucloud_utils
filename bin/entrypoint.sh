#!/bin/bash

case "$1" in
  check_account)
    bin/check_account.sh
    if [ $? -ne 0 ]
    then
      echo "Account Check failed.  Please contact cloud-support@cornell.edu about this issue."
      exit 1
    fi
    ;;
  auto_patch)
    bin/auto_patch.rb "${@:2}"
    ;;
  auto_snapshot)
    bin/auto_snapshot.rb "${@:2}"
    ;;
  clean_snapshot)
    bin/delete-ebs-snapshots-older-than.rb "${@:2}"
    ;;
  *)
    echo $"Usage: $0 {check_account, auto_snapshot}"
    echo "check_account - Utility to check your VPC configuration and test if it is in compliance with current ITSO and Cornell best practices."
    echo "auto_snapshot - Utility to backup any volumes that do not have a recent snapshot.  Accepts one integer parameter that represent how recent the snapshot must be in days.  The default is 5."
    echo "clean_snapshot - Utility to remove older snapshots.  Accepts one integer parameter that represent how old in days a snapshot can be.  The default is 15."
    exit 1
esac
