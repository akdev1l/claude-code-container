ARG FEDORA_RELEASE=${FEDORA_RELEASE:-44}

FROM fedora-minimal:$FEDORA_RELEASE as builder
  
RUN dnf install \
  --setopt=install_weak_deps=False \
  -y fedpkg

COPY . /ctx
WORKDIR /ctx

RUN spectool -g claude-code.spec
RUN fedpkg local

FROM fedora-minimal:$FEDORA_RELEASE
ARG FEDORA_RELEASE

RUN --mount=type=bind,from=builder,source=/ctx,target=/ctx dnf install -y \
  /ctx/$(uname -m)/claude-code-$(awk '/Version/{print $2}' /ctx/claude-code.spec)-$(rpm -E $(awk '/Release/{print $2}' /ctx/claude-code.spec)).$(uname -m).rpm
#RUN dnf install -y /ctx/$(uname -m)/claude-code.*.$(uname -m).rpm

ENTRYPOINT /usr/bin/claude
