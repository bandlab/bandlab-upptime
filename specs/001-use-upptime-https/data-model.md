# Data Model: BandLab Upptime Monitoring System

**Created**: 2025-10-12  
**Feature**: BandLab Upptime Monitoring System  
**Phase**: 1 (Design)

## Data Entities

### 1. Monitoring Target

Represents a URL endpoint being monitored for availability and performance.

**Attributes**:
- `name`: Human-readable identifier (e.g., "BandLab")
- `url`: Target URL to monitor (https://www.bandlab.com)
- `slug`: Unique identifier for file naming and API endpoints (auto-generated: "bandlab")
- `method`: HTTP method for monitoring (default: GET)
- `expectedStatusCodes`: Array of acceptable HTTP status codes (default: 200-399)
- `maxResponseTime`: Threshold for marking as degraded (default: 30000ms)
- `headers`: Optional custom headers for monitoring requests
- `icon`: Custom icon URL for status page display

**Configuration Example** (`.upptimerc.yml`):
```yaml
sites:
  - name: BandLab
    url: https://www.bandlab.com
    slug: bandlab
    maxResponseTime: 5000
    icon: https://www.bandlab.com/favicon.ico
```

**Relationships**:
- One-to-Many with Status Check entities
- One-to-Many with Incident entities
- One-to-One with Uptime Metrics (current)

### 2. Status Check

Individual monitoring attempt recording the health and performance of a target.

**Attributes**:
- `timestamp`: ISO 8601 timestamp of the check
- `status`: Check result (up, down, degraded)
- `responseTime`: Response time in milliseconds
- `httpStatusCode`: HTTP response status code
- `error`: Error message (if applicable)
- `target`: Reference to Monitoring Target

**Storage Format** (`history/bandlab.yml`):
```yaml
- date: "2025-10-12T10:00:00.000Z"
  status: "up"
  code: 200
  responseTime: 1234
- date: "2025-10-12T10:05:00.000Z"
  status: "down"
  code: 0
  responseTime: 0
```

**API Representation** (`api/bandlab/history.json`):
```json
[
  {
    "date": "2025-10-12T10:00:00.000Z",
    "status": "up",
    "code": 200,
    "responseTime": 1234
  }
]
```

**Validation Rules**:
- `timestamp` must be valid ISO 8601 format
- `status` must be one of: "up", "down", "degraded"
- `responseTime` must be non-negative integer
- `httpStatusCode` must be valid HTTP status code (0 for connection failures)

### 3. Incident

Period of service unavailability or degradation with start and end times.

**Attributes**:
- `incidentId`: Unique identifier (GitHub issue number)
- `target`: Reference to affected Monitoring Target
- `startTime`: ISO 8601 timestamp when incident began
- `endTime`: ISO 8601 timestamp when incident resolved (null if ongoing)
- `duration`: Total downtime duration in milliseconds
- `status`: Current incident status (investigating, resolved)
- `title`: Incident description
- `updates`: Array of incident updates/comments

**GitHub Issues Integration**:
- Each incident creates a GitHub issue automatically
- Issue title: "🚨 BandLab is down"
- Issue body: Auto-generated with incident details
- Issue labels: "status-down", "incident"
- Auto-assignment to configured team members

**Storage** (GitHub Issues API):
```json
{
  "number": 67,
  "title": "🚨 BandLab is down",
  "state": "closed",
  "created_at": "2025-10-12T10:05:00Z",
  "closed_at": "2025-10-12T10:15:00Z",
  "labels": ["status-down", "incident"]
}
```

**Lifecycle States**:
1. **Open**: Incident detected, issue created
2. **Investigating**: Team members adding updates
3. **Resolved**: Service restored, issue auto-closed
4. **Deleted**: Incidents <15 minutes auto-deleted to prevent false positives

### 4. Uptime Metrics

Calculated availability statistics and performance trends over time periods.

**Attributes**:
- `target`: Reference to Monitoring Target
- `period`: Time period (24h, 7d, 30d, 90d)
- `uptimePercentage`: Calculated uptime percentage
- `averageResponseTime`: Mean response time for period
- `totalChecks`: Number of monitoring checks in period
- `successfulChecks`: Number of successful checks
- `lastUpdated`: Timestamp of last calculation

**Storage Format** (`api/bandlab/uptime.json`):
```json
{
  "uptimeDay": 100.0,
  "uptimeWeek": 99.95,
  "uptimeMonth": 99.89,
  "uptimeYear": 99.92,
  "time": {
    "day": 1234,
    "week": 1456,
    "month": 1523,
    "year": 1445
  }
}
```

**Calculation Rules**:
- Uptime percentage = (successful checks / total checks) × 100
- Response time calculated only from successful checks
- Updates triggered daily via GitHub Actions workflow
- Historical trends generated as graphs in `/graphs/` directory

## Data Flow Architecture

### 1. Monitoring Workflow (Every 5 minutes)
```
GitHub Actions Trigger → HTTP Request to Target → Record Result → Update History → Generate API → Update Status Page
```

### 2. Incident Workflow
```
Failed Check → Validate Failure → Create GitHub Issue → Notify Assignees → Auto-close on Recovery
```

### 3. Metrics Calculation (Daily)
```
Historical Data → Calculate Statistics → Update API Endpoints → Generate Graphs → Update Status Page
```

### 4. Status Page Data Flow
```
GitHub Pages Site → GitHub API → Historical Data → Real-time Display
```

## File Structure and Storage

### Configuration
- `.upptimerc.yml`: Central configuration file

### Historical Data
- `history/bandlab.yml`: Time-series monitoring data
- `history/summary.yml`: Aggregated statistics

### API Endpoints
- `api/bandlab/history.json`: Historical check data
- `api/bandlab/uptime.json`: Current uptime metrics
- `api/summary.json`: Overall system status

### Generated Assets
- `graphs/bandlab/response-time.png`: Response time trend graphs
- `graphs/bandlab/response-time-day.png`: 24-hour detailed view
- `README.md`: Auto-generated status summary with badges

## Data Retention Policy

- **Raw Check Data**: Indefinite (stored in Git history)
- **API Endpoints**: Last 365 days of detailed data
- **Incident History**: Permanent (via GitHub Issues)
- **Response Time Graphs**: Regenerated daily, historical versions in Git
- **Summary Statistics**: Rolling calculations with configurable periods

All data persisted through Git commits ensuring immutability and audit trail compliance with constitutional transparency requirements.