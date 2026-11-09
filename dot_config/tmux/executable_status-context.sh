#!/bin/sh

parts=""

kube=$(kubectl config current-context 2>/dev/null || :)
if [ -n "$kube" ]; then
    parts="k8s: $kube"
fi

subscription=$(az account show --query name -o tsv 2>/dev/null || :)
if [ -n "$subscription" ]; then
    if [ -n "$parts" ]; then
        parts="$parts  ·  "
    fi
    parts="${parts}az: $subscription"
fi

printf '%s' "$parts"
