#!/bin/bash
act workflow_dispatch -e payload.json -j run_unity_job -v --env-file deploy.env --no-cache-server > actrun.txt
