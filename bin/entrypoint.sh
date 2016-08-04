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
  *)
      echo $"Usage: $0 {check_account}"
      echo "check_account - Utility to check your VPC configuration and test if it is in compliance with current ITSO and Cornell best practices."
      exit 1
esac
