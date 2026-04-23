FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y munin apache2 cron munin-common tzdata munin-plugins-extra python3 python3-pip wget && \
    apt-get clean

RUN groupadd -r docker && usermod -aG docker munin

RUN mkdir -p /var/log/munin /var/lib/munin /var/cache/munin /var/run/munin

RUN echo '* * * * * munin /usr/bin/munin-cron' > /etc/cron.d/munin && \
    chmod 0644 /etc/cron.d/munin

RUN a2enmod cgi auth_basic

COPY docker_ /usr/share/munin/plugins/docker_
RUN chmod +x /usr/share/munin/plugins/docker_ && \
    pip3 install docker

EXPOSE 80

CMD chown -R munin:munin /var/log/munin /var/cache/munin /var/lib/munin /var/run/munin && \
    /setup_docker_plugins.sh && \
    service cron start && \
    service apache2 start && \
    touch /var/log/munin/munin-update.log && \
    tail -F /var/log/munin/munin-update.log
