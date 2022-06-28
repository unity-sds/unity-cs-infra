#!/usr/bin/env bash
export AWS_ACCESS_KEY_ID="${{ github.event.inputs.AWS_ACCESS_KEY_ID }}" && export AWS_SECRET_ACCESS_KEY="${{ github.event.inputs.AWS_ACCESS_KEY_SECRET }}" && export AWS_SESSION_TOKEN="${{ github.event.inputs.AWS_SESSION_TOKEN }}"
