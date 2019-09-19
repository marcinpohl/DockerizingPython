# Dockerizing Python
A flexible structure and strategy for building and deploying small, secure, Python 3.5+ software inside Docker containers.

## Problems you did not know you have:
### Unpredictable, potentially old images or packages.
`FROM python:3.5` is far from optimal.  It's built on top of Debian 8 or 9, depends which docker tag for version of Python you chose.

### Unmaintained
The base OS itself was NOT maintained.  When you try to update it, it showed 60+ packages that could use an update.  Some of the newer images are better about it, but there's always a window of time where critical patches have not been applied.

### Unoptimized and unsecured builds
The Python build itself is not optimized, comparatively to [GCP's python-runtime](https://github.com/GoogleCloudPlatform/python-runtime).  The flags the software is built with is also unknown.

Similarly, the hardening flags vary greatly, depending on versions of GCC, LibC, and default settings.

### Cluttered
`FROM Python:3.5` Base OS comes with Python 3.5. As time passed, the authors evolved the base OS accordingly, from Debian 8, to 9, to now 10. It is not very well documented, unless you look at the Dockerfile on [DockerHub](http://dockerhub.com)

The Python build intended to be used is a custom one, not the one coming from the base OS.  To not clash with the the base OS installation, it was installed as a bunch of files somewhere in the tree, not a proper Debian package.
There is nothing pointing to or indicating that there's a new Python installation on the system.

To make it more confusing, the version of Python you get depends on the ordering and contents of `$PATH` environment variable.  When auditing  software versioning, and query the main package system to report software and their versions, what it will tell you will most likely be different from what you're actually using to run your software.  That's confusing.

What about headers/libraries to compile software with?  If you're building any Python package with a C component, is it going to pick up system's Python or the custom one? What is the chance the build process is going to use the wrong one, or assume the wrong path/location/name/distribution?

Python has an extensive list of default locations to look for modules in. With all this clutter, do you know where is your package coming from?  Which version got used? Some software might be hardcoded or configured to use the standard system locations for libraries or modules, and it will use those, instead of the ones custom build. That is not what was intended.

The clutter is confusing at best, and deadly at worst.  `Python:3.5` is not a good base Python image to use.

### Bloated Image:
A nearly blank Dockerfile with `FROM Python:3.5` is going to install over 360 Debian packages. Do you need them all? How many of them are going to be old, vulnerable, misconfigured, or unpatched? Then there's the size that comes with all these packages: the usual Python container resulted in over 950 MB image.

### Too generic
The settings seem to be the same for all the different tags of Python Docker images.  These images do NOT take advantage of the new settings, and modern features. `PYTHONHASHSEED`, and `venv` module can be useful in nearly all modern deployments, but for backwards compatiblity, the 'safe' settings are used, or the new settings are simply not used.

What about Unicode?  Python3 might be Unicode from ground up, but is the shell?
If your Python script ever produces or consumes a Unicode pathname with a  filesystem not configured to do it, filenames will get mangled.

What about localization? Dates and times from the OS are localized.  same goes for floating point numbers, or currency.

If you do not use any of these, you are relying on the settings from the OS.  And from previous points, we know these change along with the changes in the base OS.  Which the `Python:` family of images does without announcements.
Most of these changes also frequently implicit, or buried deep in `/etc`.

Debian is a generic distribution.  Some of it utils, when facing a problem, will attempt to do an interactive prompt, asking user for a clarification.
Inside of a fully automated CD/CI pipeline, the interactive process will fail, as it will not be able to get a TTY, or hang indefinitely for a prompt. Nither one of these is a desirable situation.

## Solutions to all of the above.

### Unpredictable, potentially old images or packages.
1. Use `debian:slim-buster` as the base image. It's small (70MB and 89 pkgs bare, `python3-minimal` grows it to 129MB and 101 pkgs.  With `python3` and `python3-dev` installed the installation grows to  244MB and 117 pkgs.  With `python3`, `python3-dev` and `build-essential` the sides goes up to 433MB and 180 pkgs.
2. `debian:slim-buster` comes with Python 3.7.3, GCC 8.3.0 and GlibC 2.28

### Unmaintained
1. It seems to be frequently updated, when checked, it had ONE outstanding patch.
2. Debian 10 (Buster) was released 2019-07-06.

### Unoptimized and unsecured builds
1. Installed `hardening-runtime`
2. Implementing portions of [Securing Debian Howto][https://www.debian.org/doc/manuals/securing-debian-howto/]
3. Update packages upon image build.  If there are running daemons using libraries that got updated, they should be restarted.
4. [Debian buster has AppArmor enabled per default](https://www.debian.org/releases/buster/amd64/release-notes/ch-whats-new.en.html#apparmor)
5. [OpenSSL's settings have been made stricter](https://www.debian.org/releases/buster/amd64/release-notes/ch-information.en.html#openssl-defaults)
6. [Hardening builds](https://wiki.debian.org/Hardening) and (https://wiki.debian.org/HardeningWalkthrough)
7. [Validating builds](https://wiki.debian.org/Hardening#Validation) or `checksec.sh`

[https://www.youtube.com/watch?v=N-pvLMHtRSA]


dpkg-reconfigure locales
