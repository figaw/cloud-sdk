# Using Kubectl

In order to use Kubectl with a GKE cluster, you need to authorize against it.
It's not enough to use the `gcloud get credentials <cluster-name>` because
the `kubeconfig` will be configured to use `gcloud` as the authorer.

Your `kubeconfig` has something like:

```yaml
- name: gke_game-server-kingdom_europe-west1-b_game-cluster
  user:
    auth-provider:
      config:
        cmd-args: config config-helper --format=json
        cmd-path: /google-cloud-sdk/bin/gcloud
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp
```

We need to use the `gcloud`-container to

1. Get a `kubeconfig` that uses `APPLICATION-CREDENTIALS`
1. Create a Service Account (SA) on GCP
1. Authorize the SA
1. Download a key-file for the SA
1. Tell our kubectl environment where the key is located

> NB: There's a handy bash function in the bottom of this file,
> that takes care of the `kubeconfig` and `download of keyfile..`,
> for an already existing SA.

## Getting the Kubeconfig

TL;DR Run the `gcloud`-container interactively:

```shell
$ docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    -v kubeconfig:/non-privileged/.kube \
    figaw/cloud-sdk:277.0.0-alpine

bash-5.0$ gcloud config set container/use_application_default_credentials true
Updated property [container/use_application_default_credentials].

bash-5.0$ gcloud container clusters get-credentials <cluster-name>
```

From [gcloud container clusters get-credentials](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)

> By default, gcloud container clusters get-credentials will configure kubectl to automatically refresh its credentials using the same identity as gcloud. If you are running kubectl as part of an application, it is recommended to use application default credentials. To configure a kubeconfig file to use application default credentials, set the container/use_application_default_credentials Cloud SDK property to true before running gcloud container clusters get-credentials

## Google Cloud Platform, Service Account Magic

Still inside the interactive `gcloud`-container

```shell
# Create a Service-Account
bash-5.0$ gcloud iam service-accounts create kubectl-admin
Created service account [kubectl-admin].

# Authorize the Service-Account
bash-5.0$ gcloud projects add-iam-policy-binding game-server-kingdom --member "serviceAccount:kubectl-admin@game-server-kingdom.iam.gserviceaccount.com" --role "roles/container.developer"
Updated IAM policy for project [game-server-kingdom].
...

# Procure a key for this account
bash-5.0$ gcloud iam service-accounts keys \
    create /non-privileged/.kube/google-application-credentials.json \
    --iam-account kubectl-admin@game-server-kingdom.iam.gserviceaccount.com
created key [a6cc47140677cbb08f7ef7deb9baecb1b2b2e8e8] of type [json] as
    [/non-privileged/.kube/google-application-credentials.json]
    for [kubectl-admin@game-server-kingdom.iam.gserviceaccount.com]
```

See: [Obtaining and providing service account credentials manually](https://cloud.google.com/docs/authentication/production#obtaining_and_providing_service_account_credentials_manually)

> NB: we store the key-file inside the `/non-privileged/.kube` directory,
> as we'll be using this for the `kubeconfig` anyways.

## Make the key-file available in the environment

Export the environment variable `GOOGLE_APPLICATION_CREDENTIALS`,
e.g. for the
[figaw/kubectl-alpine](https://github.com/figaw/kubectl-alpine) image:

```shell
alias kubectl='docker run --rm -it \
    -e GOOGLE_APPLICATION_CREDENTIALS=/root/.kube/google-application-credentials.json \
    -v kubeconfig:/root/.kube \
    -v "$PWD":/mnt/kubectl \
    -w /mnt/kubectl \
    figaw/kubectl-alpine'
```

## Handy bash function for all the above

```shell
function gcloud-get-authorized-kubectl-volume {
    docker run --rm -ti \
        --volumes-from gcloud-container \
        -e CLOUDSDK_CORE_PROJECT \
        -e CLOUDSDK_COMPUTE_ZONE \
        -e CLOUDSDK_COMPUTE_REGION \
        -v kubeconfig:/non-privileged/.kube \
        figaw/cloud-sdk:277.0.0-alpine \
            gcloud config set container/use_application_default_credentials true \
            && gcloud container clusters get-credentials $1 \
            && gcloud iam service-accounts keys \
                create /non-privileged/.kube/google-application-credentials.json \
                --iam-account $2@$CLOUDSDK_CORE_PROJECT.iam.gserviceaccount.com
}
$ authorize-kubectl <cluster-name> <service-account>
```
