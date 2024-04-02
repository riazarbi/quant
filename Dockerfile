FROM ghcr.io/riazarbi/ib-headless:10.19.2j

LABEL maintainer="Riaz Arbi <riazarbi@gmail.com>"

USER root
WORKDIR /root

# ARGS =======================================================================

# Create same user as jupyter docker stacks so that k8s will run fine
ARG NB_USER="broker"
ARG NB_UID="1000"
ARG NB_GID="100"

# Configure environment
# Do we need this? Conflicts early locale settings
ENV SHELL=/bin/bash 
ENV NB_USER=$NB_USER
ENV NB_UID=$NB_UID 
ENV NB_GID=$NB_GID 
ENV LC_ALL=en_US.UTF-8 
ENV LANG=en_US.UTF-8 
ENV LANGUAGE=en_US.UTF-8 
ENV TZ="Africa/Johannesburg" 
ENV HOME=/home/$NB_USER 
ENV R_LIBS_SITE=/usr/local/lib/R/site-library

# RSESSION ==================================================================

RUN cat /etc/os-release

RUN apt-get update \
 && apt-get install -y locales \
 && locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales

# Add apt gpg key
RUN apt-get update -qq \
 && apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common \
 && gpg --keyserver keyserver.ubuntu.com  --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
 && gpg --armor --export '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' |  tee /etc/apt/trusted.gpg.d/cran_debian_key.asc \
 && echo "deb http://cloud.r-project.org/bin/linux/debian bookworm-cran40/" | tee /etc/apt/sources.list.d/cran.list \
 && apt-get update \
 && apt-get install -y r-base

RUN apt-get install -y gdebi-core \
 && wget --quiet http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1n-0+deb10u6_amd64.deb \
 && gdebi -n libssl1.1_1.1.1n-0+deb10u6_amd64.deb \
 && rm libssl1.1_1.1.1n-0+deb10u6_amd64.deb \
 && wget --quiet https://download2.rstudio.org/server/focal/amd64/rstudio-server-2023.12.1-402-amd64.deb \
 && gdebi -n rstudio-server-2023.12.1-402-amd64.deb \
 && rm rstudio-server-2023.12.1-402-amd64.deb

# Install system dependencies
COPY apt.txt .
RUN echo "Checking for 'apt.txt'..." \
        ; if test -f "apt.txt" ; then \
        apt-get update --fix-missing > /dev/null\
        && xargs -a apt.txt apt-get install --yes \
        && apt-get clean > /dev/null \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /tmp/* \
        ; fi

# Install R dependencies
COPY install.R .
RUN if [ -f install.R ]; then R --quiet -f install.R; fi

# Allow broker user to run rserver
COPY rserver.conf /etc/rstudio/rserver.conf

# INSTALL VSCODE ===========================================================

# Install VSCode
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install VSCode extensions
RUN code-server --install-extension ms-python.python \
 && code-server --install-extension innoverio.vscode-dbt-power-user \
 && code-server --install-extension REditorSupport.r

# INSTALL DUCKDB CLI =======================================================

RUN wget "https://github.com/duckdb/duckdb/releases/download/v0.9.2/duckdb_cli-linux-amd64.zip" -O temp.zip \
 && unzip temp.zip \
 && rm temp.zip \
 && mv duckdb /bin \
 && chmod +x /bin/duckdb 


# FIX broker HOME PERMISSIONS ==============================================

COPY exec.sh /home/broker/
COPY etc/supervisord.conf /etc/
RUN chown -R broker:broker /home/broker
RUN chown -R broker:broker /var/lib/rstudio-server/


# USER SETTINGS ============================================================
# Set NB_USER ENV vars
ENV PATH="${PATH}:/usr/lib/rstudio-server/bin" 
ENV TZ="Africa/Johannesburg"

# Run as NB_USER ============================================================
USER $NB_USER
ENV USER=broker
ENV EXEC_MODE=none
ENV R_DOC_DIR=/usr/share/R/doc
ENV R_HOME=/usr/lib/R
ENV R_INCLUDE_DIR=/usr/share/R/include
ENV R_SHARE_DIR=/usr/share/R/share
ENV RSTUDIO_DEFAULT_R_VERSION_HOME=/usr/lib/R
ENV RSTUDIO_DEFAULT_R_VERSION=4.3.2
WORKDIR /home/broker
