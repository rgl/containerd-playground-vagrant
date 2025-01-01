# About

This is a containerd on Ubuntu and Windows Server 2022 Vagrant environment for playing with Linux and Windows containers.

For Docker on Windows Server 2022 see the [rgl/docker-windows-2022-vagrant](https://github.com/rgl/docker-windows-2022-vagrant) repository.

## Usage

Install the [Base Ubuntu 22.04 UEFI Box](https://github.com/rgl/ubuntu-vagrant).

Install the [Base Windows Server 2022 UEFI Box](https://github.com/rgl/windows-vagrant).

Install the required plugins:

```bash
vagrant plugin install vagrant-reload
```

Then launch the environment:

```bash
vagrant up --provider=libvirt --no-destroy-on-error --no-tty
```

Enter the `windows` virtual machine:

```bash
vagrant ssh windows
```

Test executing a `nanoserver` container with `ctr`:

```powershell
ctr image pull mcr.microsoft.com/windows/nanoserver:ltsc2022
ctr run --cni --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 test cmd /c ver
ctr run --cni --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 test cmd /c set
ctr run --cni --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 test ipconfig /all
ctr run --cni --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 test curl https://httpbin.org/user-agent
```

Test executing a multi-platform image container with `ctr`:

```powershell
ctr image pull docker.io/ruilopes/example-docker-buildx-go:v1.12.0
ctr run --cni --rm docker.io/ruilopes/example-docker-buildx-go:v1.12.0 test
```

Test executing a nanoserver container with `nerdctl`:

```powershell
nerdctl run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c ver
nerdctl run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c set
nerdctl run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c ipconfig /all
nerdctl run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c curl https://httpbin.org/user-agent
```

Test executing a multi-platform image container with `nerdctl`:

```powershell
nerdctl run --rm ruilopes/example-docker-buildx-go:v1.12.0
```

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

Lint the source code:

```bash
./mega-linter.sh
```

## Caveats

* There is no support for building Windows containers because `buildkitd` is not available for Windows.
  * See [moby/buildkit#616](https://github.com/moby/buildkit/issues/616).
* See [all the known nerdctl Windows issues](https://github.com/containerd/nerdctl/labels/platform%2FWindows).

## Troubleshoot

* See the [Microsoft Troubleshooting guide](https://docs.microsoft.com/en-us/virtualization/windowscontainers/troubleshooting) and the [CleanupContainerHostNetworking](https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/live/windows-server-container-tools/CleanupContainerHostNetworking) page.

## References

* [Tech Community Windows Server Containers News](https://techcommunity.microsoft.com/t5/containers/bg-p/Containers)
* [Using Insider Container Images](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/using-insider-container-images)
* [Beyond \ - the path to Windows and Linux parity in Docker (DockerCon 17)](https://www.youtube.com/watch?v=4ZY_4OeyJsw)
* [The Internals Behind Bringing Docker & Containers to Windows (DockerCon 16)](https://www.youtube.com/watch?v=85nCF5S8Qok)
* [Introducing the Host Compute Service](https://blogs.technet.microsoft.com/virtualization/2017/01/27/introducing-the-host-compute-service-hcs/)
