FROM python:3.7-slim-buster AS openfaas-compile-image


ARG DEBIAN_FRONTEND=noninteractive

ENV PATH /usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV PYTHONDONTWRITEBYTECODE "0"
# Setup locale. This prevents Python 3 IO encoding issues.
ENV PYTHONUTF8 "1"
ENV PYTHONHASHSEED "random"

############ OPENFAAS-COMPILE-IMAGE STAGE ###########

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-suggests --no-install-recommends \
        build-essential \
        gcc \
        inetutils-ping \
        libcap2-bin \
        vim \
        python3

ENV BUILDDIR=/build/
ENV VENV=/venv/
ENV PATH="$VENV/bin:$PATH"
# Install dependencies:
COPY build/ "$BUILDDIR"
RUN    python3 -m venv $VENV \
    && pip install --no-cache-dir --upgrade setuptools pip wheel \
    && pip install --no-cache-dir -r "$BUILDDIR/requirements.txt"

WORKDIR "$BUILDDIR"
RUN make --debug

############ OPENFAAS-RUNTIME-IMAGE STAGE ###########

FROM python:3.7-slim-buster AS openfaas-runtime-image
### This RUN section only needed for getpcaps experiments
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-suggests --no-install-recommends \
        libcap2-bin \
        python3-minimal \
        time

ENV USERNAME=appuser
RUN useradd --create-home "$USERNAME"
WORKDIR "/home/$USERNAME"
USER "$USERNAME"
ENV VENV="/home/$USERNAME/venv/"
ENV PATH="$VENV/bin:$PATH"
COPY runtime/ .
RUN    python3 -m venv $VENV \
    && pip install --no-cache-dir --upgrade setuptools pip wheel \
    && pip install --no-cache-dir -r "requirements.txt"
COPY --from=openfaas-compile-image "/build/openfaas.py" "$VENV/bin/"

EXPOSE 8080
CMD ["/home/appuser/venv/bin/python", "-B", "/home/appuser/venv/bin/openfaas.py"]
