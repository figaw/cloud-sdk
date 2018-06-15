# gcloud sdk and kubectl in docker, alpine linux, as a non-privileged user
See: https://hub.docker.com/r/google/cloud-sdk/

# Build

`docker build -t gcloud-kubectl-sdk-docker:alpine .`

# Running

Login with:
```
docker run -ti \
    --name gcloud-container \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud auth login
```

NB: When you use it like above, _any_ container getting the `gcloud-container` volume, will have access to your credentials!

## Testing (without the environment)
```
docker run -ti \
    --name gcloud-container \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud init
```
and
```
docker run --rm -ti \
    --volumes-from gcloud-container \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud --version
```

## Testing (with the environment)
```
docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud --version
```

# Cleanup

```
docker rm gcloud-container
```

# Helpful Aliases

```
alias gcloud-login="docker run -ti \
    --name gcloud-container \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud auth login"
```

```
alias gcloud="docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    -v "$PWD":/non-privileged \
    gcloud-kubectl-sdk-docker:alpine gcloud"
```

See the IAQ for the `-e` flags.

NB: the `gcloud` alias mounts your current folder into the container,
in order to access your current workdirectory for e.g.
`gcloud compute scp file.txt instance-name:/some/path`.
So if you try to do something with a parent directory,
like `gcloud compute scp ../file.txt instance-name:/some/path`,
you're going to have a bad time.

## Kubectl

```
alias gcloud-get-credentials="docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    -v $HOME/.kube:/root/.kube \
    gcloud-kubectl-sdk-docker:alpine \
    gcloud container clusters get-credentials"
```

Usage `$ gcloud-get-credentials <name of cluster>`

```
alias kubectl="docker run --rm -ti  \
    --volumes-from gcloud-container \
    -v "$PWD":/non-privileged \
    gcloud-kubectl-sdk-docker:alpine \
    kubectl"
```

Usage `$ kubectl get nodes`

NB: the `kubectl`-alias mounts the current folder into the container,
in order to access your current workdirectory,
(for `kubectl apply -f pod.yaml` etc.)
so if you try something with a parent directory,
like `kubectl apply -f ../../pod.yaml`,
you're going to have a bad time.

# Infrequently Asked Questions (IAQ)

## -e flags, environment variables
When you use environment flag like `-e KEY`, rather than `-e "KEY=VALUE"`,
the environment variable `KEY` is passed if it's set.

When `gcloud` is run without a configured project, it'll complain
and tell you to either configure it or set the `CLOUDSDK_CORE_PROJECT` environment variable,
which you can then do on your host, because we mount it into the container.

```
export CLOUDSDK_CORE_PROJECT="project key"
```
Get `project key` with `gcloud projects list`

### Project as a gcloud-flag
`gcloud compute instances list --project your_project`

### Project as a gcloud config
`gcloud config set project your_project`

### Order of evaluation
`--project` takes priority over `CLOUDSDK_CORE_PROJECT` and finally it reads from the `config core/project`.

I personally prefer the env-var solution as the alias' will work out of the box, and I'll be mostly working on one project for a long time.
Also I can use `--project` if I need to do something in another project, or simply re-export the env-var for my current session.

### Region, Zone
See: https://cloud.google.com/compute/docs/gcloud-compute/

It doesn't outright _suggest_ you set these in the environment, but I'll use the same argument as above;
the alias' will work out of the box. No need for `gcloud init` or `gcloud config set ..`
```
export CLOUDSDK_COMPUTE_ZONE=europe-west1-b
export CLOUDSDK_COMPUTE_REGION=europe-west1
```

## Why reinvent the wheel?

Well, extending the `google/cloud-sdk:alpine` with `kubectl` doesn't work,
unless you either run it with the `KUBECONFIG` environment variable, or (of course..)
add it when you run the image.

Other than that I just wanted to limit the privileges as well, so it's not running as root;
because not running as root is awesome.
