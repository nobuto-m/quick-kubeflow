#!/bin/bash

set -e
set -x

time sudo snap remove --purge microk8s || true
juju unregister microk8s-localhost -y || true

time sudo snap install microk8s --classic --channel 1.21
sudo adduser "$USER" microk8s
newgrp microk8s

time microk8s status --wait-ready
time microk8s enable dns storage ingress metallb:10.64.140.43-10.64.140.49
time microk8s kubectl wait deployment --all -A --for condition=Available=True --timeout=1h

time juju bootstrap microk8s
juju add-model kubeflow
time juju deploy --trust kubeflow
time sleep 300
time microk8s kubectl wait -n kubeflow deployment --all --for condition=Available=True --timeout=1h

juju config dex-auth public-url=http://10.64.140.43.nip.io
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin

# https://github.com/canonical/kfp-operators/pull/49
juju refresh kfp-profile-controller --channel edge

# https://github.com/canonical/bundle-kubeflow/issues/459
microk8s kubectl patch Deployment katib-controller -n kubeflow --type=json \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--trial-resources=Workflow.v1alpha1.argoproj.io"}]'

time sleep 60
time microk8s kubectl wait -n kubeflow deployment --all --for condition=Available=True --timeout=1h
