# syntax=docker/dockerfile:1.4
FROM odoo:18.0

USER root

# Install helpers required by the entrypoint
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Install gosu (used to step down to the odoo user when running the app directly)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg2 dirmngr; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    gosuVersion="1.14"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${gosuVersion}/gosu-${dpkgArch}"; \
    chmod +x /usr/local/bin/gosu; \
    # verify gosu works
    /usr/local/bin/gosu --version || true; \
    rm -rf /var/lib/apt/lists/*;

# Install any extra Python dependencies here by populating requirements.txt
# This file can remain empty if no extra packages are needed.
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

# Copy custom addons and configuration template
COPY addons /mnt/extra-addons
COPY odoo.conf.template /etc/odoo/odoo.conf.template
COPY entrypoint.sh /usr/local/bin/odoo-entrypoint.sh

# Ensure correct ownership and permissions
RUN chown -R odoo:odoo /mnt/extra-addons /etc/odoo && \
    chmod +x /usr/local/bin/odoo-entrypoint.sh && \
    mkdir -p /var/lib/odoo/filestore && \
    chown -R odoo:odoo /var/lib/odoo

# Switch back to the odoo user provided by the base image
USER odoo
ENV ODOO_RC=/etc/odoo/odoo.conf

# Note: Railway volumes are configured in railway.json, not in Dockerfile
# The VOLUME keyword is banned by Railway - use Railway's native volumes instead

ENTRYPOINT ["/usr/local/bin/odoo-entrypoint.sh"]
# Set the default command to run when starting the container
CMD ["odoo"]
