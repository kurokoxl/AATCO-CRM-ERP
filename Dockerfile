# syntax=docker/dockerfile:1.4
FROM odoo:18.0

USER root

# Install helpers required by the entrypoint
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    rm -rf /var/lib/apt/lists/*

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
    chmod +x /usr/local/bin/odoo-entrypoint.sh

# Switch back to the odoo user provided by the base image
USER odoo
ENV ODOO_RC=/etc/odoo/odoo.conf

ENTRYPOINT ["/usr/local/bin/odoo-entrypoint.sh"]
CMD ["odoo"]
