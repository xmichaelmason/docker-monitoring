# Docker Monitoring Stack

A complete monitoring solution using Grafana, Loki, Promtail, and Prometheus for comprehensive system and container monitoring.

## Overview

This stack provides:
- **System Log Monitoring**: Collects logs from `/var` via systemd journal
- **Container Log Monitoring**: Monitors Docker container logs
- **Metrics Collection**: System and application metrics via Prometheus
- **Visualization**: Beautiful dashboards in Grafana

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   System Logs   │───▶│   Promtail   │───▶│    Loki     │
│ (systemd journal)│    │              │    │             │
└─────────────────┘    └──────────────┘    └─────────────┘
                                                   │
┌─────────────────┐    ┌──────────────┐           │
│ Container Logs  │───▶│   Promtail   │───────────┘
│ (/var/lib/docker)│   │              │           
└─────────────────┘    └──────────────┘           
                                                   │
┌─────────────────┐    ┌──────────────┐           ▼
│    Metrics      │───▶│  Prometheus  │    ┌─────────────┐
│   (node_exporter)│   │              │───▶│   Grafana   │
└─────────────────┘    └──────────────┘    │             │
                                           └─────────────┘
```

## Services

### Grafana (Port 3000)
- **Purpose**: Visualization and dashboards
- **Access**: http://your-server:3000
- **Credentials**: admin / admin123
- **Dashboards**:
  - System Logs Dashboard: Monitor systemd journal logs
  - Monitoring Stack Dashboard: Monitor the monitoring infrastructure itself

### Loki (Port 3100)
- **Purpose**: Log aggregation and storage
- **API**: http://your-server:3100
- **Storage**: Stores logs from systemd journal and Docker containers

### Promtail
- **Purpose**: Log collection agent
- **Sources**:
  - Systemd journal (`/var/log/journal/`)
  - Docker container logs (`/var/lib/docker/containers/`)
  - Traditional log files (`/var/log/syslog`, `/var/log/auth.log` if they exist)

### Prometheus (Port 9090)
- **Purpose**: Metrics collection and storage
- **Access**: http://your-server:9090
- **Targets**: Self-monitoring of the stack components

## Quick Start

### 1. Deploy the Stack

```bash
# Clone and navigate to the project
cd /srv/docker-monitoring

# Start all services
sudo docker compose up -d

# Check status
sudo docker compose ps
```

### 2. Access Grafana

1. Open http://your-server:3000
2. Login with `admin` / `admin123`
3. Navigate to Dashboards → Browse
4. Open "System Logs Dashboard" or "Monitoring Stack Dashboard"

### 3. Query Logs Directly (Optional)

You can also query Loki directly:

```bash
# Check available log sources
curl "http://localhost:3100/loki/api/v1/label/job/values"

# Query recent systemd logs
curl "http://localhost:3100/loki/api/v1/query_range?query=%7Bjob%3D%22systemd-journal%22%7D&start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000&limit=10"
```

## Log Sources

### System Logs (systemd-journal)
- **Source**: `/var/log/journal/`
- **Content**: All system logs on modern Debian/Ubuntu systems
- **Includes**: Authentication, kernel messages, service logs, etc.
- **Query**: `{job="systemd-journal"}`

### Docker Logs
- **Source**: `/var/lib/docker/containers/`
- **Content**: All container stdout/stderr
- **Query**: `{job="docker"}`

### Traditional Logs (if available)
- **Source**: `/var/log/syslog`, `/var/log/auth.log`
- **Content**: Traditional syslog format logs
- **Query**: `{job="syslog"}` or `{job="auth"}`

## Useful Queries

### Filter by Log Level
```logql
# Errors only
{job="systemd-journal"} |~ "(?i)(error|err|fail|fatal)"

# Warnings
{job="systemd-journal"} |~ "(?i)(warn|warning)"
```

### Filter by Service
```logql
# SSH authentication logs
{job="systemd-journal"} |~ "sshd"

# Docker service logs
{job="systemd-journal"} |~ "docker"
```

### Container-specific Logs
```logql
# Specific container
{job="docker", container_name="grafana"}

# All containers
{job="docker"}
```

## Configuration Files

### Key Files
- `docker-compose.yml`: Service definitions
- `promtail/promtail-config.yml`: Log collection configuration
- `loki/loki-config.yml`: Loki storage and retention settings
- `prometheus/prometheus.yml`: Metrics collection targets
- `grafana/provisioning/`: Auto-provisioned datasources and dashboards

### Volumes
- `grafana-data`: Grafana configuration and data
- `prometheus-data`: Prometheus metrics storage
- `loki-data`: Loki log storage

## Troubleshooting

### Check Service Status
```bash
sudo docker compose ps
sudo docker compose logs [service-name]
```

### Common Issues

1. **No logs appearing**: 
   - Check if systemd journal is readable: `sudo journalctl --disk-usage`
   - Verify Promtail is running: `sudo docker compose logs promtail`

2. **Grafana dashboards empty**:
   - Check datasource connectivity in Grafana UI
   - Verify Loki has data: `curl "http://localhost:3100/loki/api/v1/label/job/values"`

3. **Permission issues**:
   - Ensure Docker has access to log directories
   - Check volume mounts in docker-compose.yml

### View Available Data
```bash
# Check what log jobs are available
curl -s "http://localhost:3100/loki/api/v1/label/job/values"

# Check if logs are being ingested
curl -s "http://localhost:3100/loki/api/v1/query_range?query=%7Bjob%3D%22systemd-journal%22%7D&start=$(date -d '10 minutes ago' +%s)000000000&end=$(date +%s)000000000&limit=5"
```

## Maintenance

### Log Retention
- Loki retention: 168h (7 days) - configurable in `loki/loki-config.yml`
- Prometheus retention: Default 15 days

### Backup Important Data
```bash
# Backup Grafana dashboards and settings
sudo docker compose exec grafana tar czf - /var/lib/grafana | gzip > grafana-backup.tar.gz

# Backup configurations
tar czf monitoring-config-backup.tar.gz grafana/ loki/ prometheus/ promtail/ docker-compose.yml
```

### Updates
```bash
# Pull latest images
sudo docker compose pull

# Restart with new images
sudo docker compose up -d
```

## Security Notes

- **Default credentials**: Change the default Grafana password (`admin`/`admin123`)
- **Network access**: Consider firewall rules for ports 3000, 3100, 9090
- **Log sensitivity**: System logs may contain sensitive information

## Customization

### Adding New Log Sources
Edit `promtail/promtail-config.yml` and add new `scrape_configs` entries.

### Creating Custom Dashboards
1. Access Grafana UI
2. Create new dashboard
3. Use Loki queries like `{job="systemd-journal"}`
4. Export JSON and save to `grafana/provisioning/dashboards/`

### Modifying Retention
Edit `loki/loki-config.yml` and adjust `reject_old_samples_max_age` value.

---

## Support

This monitoring stack captures all logs from `/var` through the systemd journal, which is the modern standard for Linux logging. Your system logs are being monitored and visualized effectively!
