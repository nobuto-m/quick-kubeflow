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
#sed -i -e 's|/stable|/edge|' quick-kubeflow_bundle.yaml
sed -i -e 's|\(charm: seldon-core,.*channel: latest\)/stable|\1/edge|' quick-kubeflow_bundle.yaml

time juju deploy --trust ./quick-kubeflow_bundle.yaml

juju config dex-auth public-url=http://10.64.140.43.nip.io
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin

# https://github.com/canonical/kfp-operators/pull/49
juju refresh kfp-profile-controller --channel edge

# https://github.com/canonical/bundle-kubeflow/issues/459
#microk8s kubectl -n kubeflow rollout restart deployment/katib-controller

time sleep 300
time microk8s kubectl wait -n kubeflow deployment --all --for condition=Available=True --timeout=1h

# Error from server (InternalError): error when creating "STDIN":
# Internal error occurred: failed calling webhook
# "v1.vseldondeployment.kb.io": Post
# "https://seldon-webhook-service.kubeflow.svc:4443/validate-machinelearning-seldon-io-v1-seldondeployment?timeout=30s":
# dial tcp 10.152.183.249:4443: connect: connection refused
#microk8s kubectl patch ns admin \
#    -p '{"metadata":{"labels":{"serving.kubeflow.org/inferenceservice":"disabled"}}}'

# TODO: check this just after and 48 hours after the deployment
#curl -svL -o/dev/null http://10.64.140.43.nip.io/
