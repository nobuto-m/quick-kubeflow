#!/bin/bash

set -e
set -x

time sudo snap remove --purge microk8s || true
juju unregister microk8s-localhost -y || true

time sudo snap install microk8s --classic --channel 1.22

time microk8s status --wait-ready
time microk8s enable dns storage ingress metallb:10.64.140.43-10.64.140.49
time microk8s kubectl wait deployment --all -A --for condition=Available=True --timeout=1h

time sudo snap install juju --classic
time juju bootstrap microk8s
juju add-model kubeflow

time juju deploy --trust kubeflow

juju config dex-auth public-url=http://10.64.140.43.nip.io
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin

time juju-wait -w
#time microk8s kubectl wait -n kubeflow deployment --all --for condition=Available=True --timeout=1h

# TODO: check this just after and 48 hours after the deployment
curl -svL -o/dev/null http://10.64.140.43.nip.io/
