#!/bin/bash
act workflow_dispatch -e $1 -j run_unity_job -v --env-file deploy.env --no-cache-server > actrun.txt
