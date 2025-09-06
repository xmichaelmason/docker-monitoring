#!/bin/bash

# Create the directory structure
echo "Creating directory structure..."
mkdir -p /srv/docker-monitoring/prometheus
mkdir -p /srv/docker-monitoring/loki
mkdir -p /srv/docker-monitoring/promtail
mkdir -p /srv/docker-monitoring/grafana/provisioning/datasources
mkdir -p /srv/docker-monitoring/grafana/provisioning/dashboards

# Set proper permissions
echo "Setting permissions..."
sudo chown -R 472:472 /srv/docker-monitoring/grafana
sudo chown -R 65534:65534 /srv/docker-monitoring/prometheus
sudo chown -R 10001:10001 /srv/docker-monitoring/loki

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy the configuration files to their respective directories"
echo "2. Run 'docker-compose up -d' from /srv/docker-monitoring"
echo ""
echo "Access URLs:"
echo "- Grafana: http://localhost:3000 (admin/admin123)"
echo "- Prometheus: http://localhost:9090"
echo "- Loki: http://localhost:3100"
