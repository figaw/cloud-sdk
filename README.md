# gcloud sdk in docker, alpine linux, as a non-privileged user

See: [https://hub.docker.com/r/google/cloud-sdk/](https://hub.docker.com/r/google/cloud-sdk/)

## Build

```shell
./build.sh
```

## Running

Login with:

```shell
docker run -ti \
    --name gcloud-container \
    figaw/cloud-sdk:277.0.0-alpine \
    gcloud auth login
```

NB: When you use it like above, _any_ container getting the `gcloud-container` volume, will have access to your credentials!

## Cleanup

```shell
docker rm gcloud-container
```

## Helpful Aliases

```shell
alias gcloud='docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    -v "$PWD":/mnt/gcloud/ \
    -w "/mnt/gcloud" \
    figaw/cloud-sdk:277.0.0-alpine gcloud'
```

```shell
alias gcloud-login="docker run -ti \
    --name gcloud-container \
    figaw/cloud-sdk:277.0.0-alpine \
    gcloud auth login"
```

See the IAQ for the `-e` flags.

NB: the `gcloud` alias mounts your current folder into the container,
in order to access your current workdirectory for e.g.
`gcloud compute scp file.txt instance-name:/some/path`.
So if you try to do something with a parent directory,
like `gcloud compute scp ../file.txt instance-name:/some/path`,
you're going to have a bad time.

### Getting a Kubeconfig volume

With the following commands you can create a volume called `kubeconfig`,
with the authorization for a cluster on the Google Kubernetes Engine.

```shell
alias gcloud-get-credentials-volume="docker run --rm -ti \
    --volumes-from gcloud-container \
    -e CLOUDSDK_CORE_PROJECT \
    -e CLOUDSDK_COMPUTE_ZONE \
    -e CLOUDSDK_COMPUTE_REGION \
    -v kubeconfig:/non-privileged/.kube \
    figaw/cloud-sdk:277.0.0-alpine \
    gcloud container clusters get-credentials"
```

Usage `$ gcloud-get-credentials <name of cluster>`

## Infrequently Asked Questions (IAQ)

### -e flags, environment variables

When you use environment flag like `-e KEY`, rather than `-e "KEY=VALUE"`,
the environment variable `KEY` is passed if it's set.

When `gcloud` is run without a configured project, it'll complain
and tell you to either configure it or set the `CLOUDSDK_CORE_PROJECT` environment variable,
which you can then do on your host, because we mount it into the container.

```shell
export CLOUDSDK_CORE_PROJECT="project key"
```

Get `project key` with `gcloud projects list`

#### Project as a gcloud-flag

`gcloud compute instances list --project your_project`

#### Project as a gcloud config

`gcloud config set project your_project`

#### Order of evaluation

`--project` takes priority over `CLOUDSDK_CORE_PROJECT` and finally it reads from the `config core/project`.

I personally prefer the env-var solution as the alias' will work out of the box, and I'll be mostly working on one project for a long time.
Also I can use `--project` if I need to do something in another project, or simply re-export the env-var for my current session.

#### Region, Zone

See: [https://cloud.google.com/compute/docs/gcloud-compute/](https://cloud.google.com/compute/docs/gcloud-compute/)

It doesn't outright _suggest_ you set these in the environment, but I'll use the same argument as above;
the alias' will work out of the box. No need for `gcloud init` or `gcloud config set ..`

```shell
export CLOUDSDK_COMPUTE_ZONE=europe-west1-b
export CLOUDSDK_COMPUTE_REGION=europe-west1
```

### Why reinvent the wheel

Well, extending the `google/cloud-sdk:alpine` with `kubectl` doesn't work,
unless you either run it with the `KUBECONFIG` environment variable, or (of course..)
add it when you run the image.

Other than that I just wanted to limit the privileges as well,
so it's not running as root;
because not running as root is awesome.
