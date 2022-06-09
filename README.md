## Prerequisites

1. Create a group, and add the current user to the group.

       sudo addgroup --system microk8s
       sudo adduser $USER microk8s

1. Logout from the session and login.

## Run

Based on: https://charmed-kubeflow.io/docs/quickstart

    time ./redeploy-microk8s-kubeflow.sh

-> 35 minutes
