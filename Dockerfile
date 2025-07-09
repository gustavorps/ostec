FROM mambaorg/micromamba:2.3.0 AS micromamba

FROM pytorch/manylinux-cuda102:latest
# Distro: CentOS-7 
USER root

# if your image defaults to a non-root user, then you may want to make the
# next 3 ARG commands match the values in your image. You can get the values
# by running: docker run --rm -it my/image id -a
ARG MAMBA_USER=mambauser
ARG MAMBA_USER_ID=57439
ARG MAMBA_USER_GID=57439
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_entrypoint.sh /usr/local/bin/_entrypoint.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh

WORKDIR /opt/ostec

RUN git clone https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/gustavorps/ostec.git --recursive --depth 1 .

RUN pwd && ls -al && \
    echo "" && echo "# file: environment.yml" && cat environment.yml
RUN micromamba install -y -n base -f environment.yml && \
    micromamba clean --all --yes

RUN chown -R 57439:57439 /opt/ostec
#USER $MAMBA_USER

# Script which launches commands passed to "docker run"
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]

# Default command for "docker run"
CMD ["/bin/bash"]

# Script which launches RUN commands in Dockerfile
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
