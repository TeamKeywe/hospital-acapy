#!/bin/bash

aca-py start --arg-file /configs/config.yml &

PID=$!
echo "ACA-Py started with PID: $PID"

echo "Waiting for ACA-Py to be ready..."
sleep 5

echo "Running wallet initialization..."
/init_wallets.sh

echo "ACA-Py is running. Waiting for process to complete..."
wait $PID