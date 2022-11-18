#!/usr/bin/python3
import subprocess

version = (
    subprocess.check_output(["git", "rev-parse", "--verify", "--short", "HEAD"])
    .strip()
    .decode("utf-8")
)
print("-DCFORTH_VERSION='\"%s\"'" % version)

# todo; append -dirty

date = (
    subprocess.check_output(["date", "--utc", "+%F %R"])
    .strip()
    .decode("utf-8")
)
print("-DCFORTH_DATE='\"%s\"'" % date)
