#!/bin/bash

aws ssm get-parameter --name $1 | jq -r .Parameter.Value