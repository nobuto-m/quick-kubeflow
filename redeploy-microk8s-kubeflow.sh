#!/bin/bash

set -e
set -x

time sudo snap remove --purge microk8s || true
juju unregister microk8s-localhost -y || true

# TODO: use 1.21/edge or something once a new revision is published to
# the snap store:
# https://github.com/canonical/microk8s/pull/3206
# https://github.com/canonical/microk8s/issues/3226
time sudo snap install microk8s --classic --channel 1.21

time microk8s status --wait-ready
time microk8s enable dns storage ingress metallb:10.64.140.43-10.64.140.49
time microk8s kubectl wait deployment --all -A --for condition=Available=True --timeout=1h

time sudo snap install juju --classic
time juju bootstrap microk8s
juju add-model kubeflow

time sudo apt-get install -y unzip
juju download kubeflow --no-progress - > quick-kubeflow.bundle
unzip -p quick-kubeflow.bundle bundle.yaml > quick-kubeflow_bundle.yaml
sed -i -e 's|/stable|/edge|' quick-kubeflow_bundle.yaml

#time juju deploy --trust kubeflow
time juju deploy --trust ./quick-kubeflow_bundle.yaml

juju config dex-auth public-url=http://10.64.140.43.nip.io
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin

# https://github.com/canonical/bundle-kubeflow/issues/459
#microk8s kubectl -n kubeflow rollout restart deployment/katib-controller
microk8s kubectl -n kubeflow delete pod -l app.kubernetes.io/name=katib-controller

time sleep 300
time microk8s kubectl wait -n kubeflow deployment --all --for condition=Available=True --timeout=1h

# TODO: check this just after and 48 hours after the deployment
curl -svL -o/dev/null http://10.64.140.43.nip.io/
