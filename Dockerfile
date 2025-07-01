ARG NSO_VERSION
ARG BASE_IMAGE
FROM $BASE_IMAGE:$NSO_VERSION

ARG ADMIN_PASSWORD
ENV HOME=/home/developer \
    ADMIN_PASSWORD=$ADMIN_PASSWORD

EXPOSE 443 2024 8080

COPY config /tmp/config
COPY scripts /tmp/scripts
COPY packages /tmp/packages

RUN groupadd ncsoper \
    && useradd --create-home --home-dir /home/developer --no-user-group \
    --no-log-init --groups ncsoper  --shell /bin/bash developer \
    && echo "developer:Services4Ever" | chpasswd \
    && mkdir -p /home/developer/src \
    && mv /tmp/scripts/display_directory_tree.sh /usr/bin/tree \
    && chmod a+x /usr/bin/tree \
    && chown -Rh developer:ncsoper /home/developer \
    && chown -R developer $NCS_CONFIG_DIR/ /nso/ /log/ /defaults/* $NCS_DIR/ /tmp/ \
    && echo 'alias ll="ls -al"' >> $HOME/.bashrc \
    && echo 'alias ll="ls -al"' >> /etc/profile.d/alias.sh \
    && echo 'export PS1="developer:\W > "' >> $HOME/.bashrc \
    && echo 'export PS1="developer:\W > "' >> /etc/bash.bashrc \
    && echo 'export PS1="developer:\W > "' >> /etc/profile.d/terminal.sh \
    && echo 'export PATH="/opt/ncs/current/bin:$PATH"' >> $HOME/.bashrc \
    && echo 'export PATH="/opt/ncs/current/bin:$PATH"' >> /etc/profile.d/local.sh 

RUN mv /tmp/config/phase0/ncs.conf.xml $NCS_CONFIG_DIR/ncs.conf \
    && mv /tmp/config/phase1/authgroups.xml $NCS_RUN_DIR/cdb/ \
    && mv /tmp/scripts/10-cron-logrotate.sh $NCS_CONFIG_DIR/post-ncs-start.d/10-cron-logrotate.sh \
    && mv /tmp/scripts/setup_demo_environment.sh $NCS_CONFIG_DIR/post-ncs-start.d/setup_demo_environment.sh \
    && chmod a+x $NCS_CONFIG_DIR/post-ncs-start.d/10-cron-logrotate.sh \
    && chmod a+x $NCS_CONFIG_DIR/post-ncs-start.d/setup_demo_environment.sh \
    && ln -s $NCS_DIR/packages/neds/cisco-ios-cli-3.8 $NCS_RUN_DIR/packages/ \
    && ln -s $NCS_DIR/packages/neds/cisco-iosxr-cli-3.5 $NCS_RUN_DIR/packages/ \
    && ln -s $NCS_DIR/packages/neds/cisco-asa-cli-6.6 $NCS_RUN_DIR/packages/ \
    && ln -s $NCS_DIR/packages/neds/cisco-nx-cli-3.0 $NCS_RUN_DIR/packages/ \
    && make -C /tmp/packages/router/src clean all \
    && chown -R developer /tmp/packages/router/ \
    && ln -s /tmp/packages/router/ $NCS_RUN_DIR/packages/

WORKDIR $HOME

USER root

RUN mkdir -p /nso/etc/ssh \
    && ssh-keygen -N '' -t ed25519 -f /nso/etc/ssh/ssh_host_ed25519_key
