#!/usr/bin/env bash
export AWS_ACCESS_KEY_ID=$INPUT_AWS_ACCESS_KEY_ID && export AWS_SECRET_ACCESS_KEY=$INPUT_AWS_ACCESS_KEY_SECRET && export AWS_SESSION_TOKEN=$INPUT_AWS_SESSION_TOKEN
eksctl create cluster -f build/eksctl/eksctl-config.yaml