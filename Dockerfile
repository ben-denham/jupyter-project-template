# We will run the dev_image for local development.
FROM python:3.11 as dev_image
MAINTAINER ben@denham.nz


# Uncomment to install any dependencies (install these before
# performing steps with files that may change frequently so that
# layers may be cached). Best practice for installing apt dependencies
# without saving apt-cache:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run

# USER root
# RUN apt-get update && apt-get install -y \
#         curl \
#         && rm -rf /var/lib/apt/lists/*
# USER jovyan


# A section like the following can be useful when your base image runs
# as the root user. This will create a user with the same uid and gid
# as our host user, meaning files created in the image after this step
# and during container will be owned by our user on the host.

ARG GROUP_ID=1000
ARG USER_ID=1000
RUN groupadd --gid $GROUP_ID coder
RUN useradd --uid $USER_ID --gid coder --shell /bin/bash --create-home coder
USER coder

ENV PATH=$PATH:/home/coder/.local/bin
RUN pip install uv

RUN mkdir /home/coder/src
WORKDIR /home/coder/src

RUN mkdir -p /home/coder/src/app/voila-template
RUN mkdir -p /home/coder/.local/share/jupyter/voila/templates/
RUN ln -s /home/coder/src/app/voila-template /home/coder/.local/share/jupyter/voila/templates/customvoila


# The prod_image build step is an optional section that allows you to
# package your entire app into a self-contained Docker image that can
# be run on another machine.
FROM dev_image as prod_image
COPY --chown=coder:coder .venv /home/coder/src/.venv
COPY --chown=coder:coder pyproject.toml /home/coder/src/pyproject.toml
COPY --chown=coder:coder uv.lock /home/coder/src/uv.lock
COPY --chown=coder:coder src /home/coder/src/src
ENV VIRTUAL_ENV=/home/coder/src/.venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="/home/coder/src/.venv/bin:$PATH"
RUN uv sync --no-dev

# Mount changeable notebook and template content last.
COPY --chown=coder:coder app/voila-app.py /home/coder/src/app/voila-app.py
COPY --chown=coder:coder app/voila-template /home/coder/src/app/voila-template
COPY --chown=coder:coder notebooks/voila/*.ipynb /home/coder/src/notebooks/voila/

EXPOSE 8866
CMD ["python", "app/voila-app.py"]
