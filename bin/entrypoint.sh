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
  auto_snapshot)
    bin/auto_snapshot.rb "${@:2}"
    ;;
  *)
    echo $"Usage: $0 {check_account, auto_snapshot}"
    echo "check_account - Utility to check your VPC configuration and test if it is in compliance with current ITSO and Cornell best practices."
    echo "auto_snapshot - Utility to backup any volumes that do not have a recent snapshot.  Accepts one integer parameter that represent how recent the snapshot must be in days.  The default is 5."
    exit 1
esac
