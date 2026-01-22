# API Contracts: BandLab Upptime Monitoring System

**Created**: 2025-10-12  
**Feature**: BandLab Upptime Monitoring System  
**Type**: RESTful JSON API (Read-only)

## Overview

The Upptime system auto-generates RESTful JSON API endpoints from monitoring data stored in the Git repository. All APIs are read-only and publicly accessible via GitHub Pages hosting.

**Base URL**: `https://{username}.github.io/{repository-name}/api/`
**Content-Type**: `application/json`
**Authentication**: None (public read-only access)

## Endpoint Specifications

### 1. Site Status API

#### GET /api/{site-slug}/uptime.json

Returns current uptime statistics for a specific monitored site.

**Parameters**:
- `site-slug`: URL slug for the monitored site (e.g., "bandlab")

**Response Schema**:
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

**Field Descriptions**:
- `uptimeDay`: Uptime percentage for last 24 hours (0-100)
- `uptimeWeek`: Uptime percentage for last 7 days (0-100)
- `uptimeMonth`: Uptime percentage for last 30 days (0-100)
- `uptimeYear`: Uptime percentage for last 365 days (0-100)
- `time.day`: Average response time for last 24 hours (milliseconds)
- `time.week`: Average response time for last 7 days (milliseconds)
- `time.month`: Average response time for last 30 days (milliseconds)
- `time.year`: Average response time for last 365 days (milliseconds)

**Example Request**:
```http
GET /api/bandlab/uptime.json HTTP/1.1
Host: bandlab.github.io
```

**Example Response**:
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

### 2. Site History API

#### GET /api/{site-slug}/history.json

Returns historical monitoring check data for a specific site.

**Parameters**:
- `site-slug`: URL slug for the monitored site (e.g., "bandlab")

**Response Schema**:
```json
[
  {
    "date": "2025-10-12T10:00:00.000Z",
    "status": "up",
    "code": 200,
    "responseTime": 1234
  },
  {
    "date": "2025-10-12T10:05:00.000Z",
    "status": "down",
    "code": 0,
    "responseTime": 0
  }
]
```

**Field Descriptions**:
- `date`: ISO 8601 timestamp of the monitoring check
- `status`: Check result ("up", "down", "degraded")
- `code`: HTTP response status code (0 for connection failures)
- `responseTime`: Response time in milliseconds

**Data Ordering**: Chronological, most recent first
**Data Retention**: Last 365 days of check data

### 3. Overall Summary API

#### GET /api/summary.json

Returns aggregated status information for all monitored sites.

**Response Schema**:
```json
{
  "status": "up",
  "message": "All systems operational",
  "count": {
    "up": 1,
    "down": 0,
    "degraded": 0
  },
  "sites": [
    {
      "name": "BandLab",
      "slug": "bandlab",
      "status": "up",
      "uptime": "99.95%",
      "time": 1234,
      "url": "https://www.bandlab.com",
      "icon": "https://www.bandlab.com/favicon.ico"
    }
  ]
}
```

**Field Descriptions**:
- `status`: Overall system status ("up", "degraded", "down")
- `message`: Human-readable status message
- `count.up`: Number of sites currently up
- `count.down`: Number of sites currently down
- `count.degraded`: Number of sites currently degraded
- `sites[].name`: Display name for the site
- `sites[].slug`: URL slug identifier
- `sites[].status`: Current site status
- `sites[].uptime`: Human-readable uptime percentage
- `sites[].time`: Current average response time (milliseconds)
- `sites[].url`: Monitored URL
- `sites[].icon`: Site icon URL

### 4. Incident History API

#### GET /api/{site-slug}/incidents.json

Returns incident history for a specific site (derived from GitHub Issues).

**Parameters**:
- `site-slug`: URL slug for the monitored site (e.g., "bandlab")

**Response Schema**:
```json
[
  {
    "id": 67,
    "title": "🚨 BandLab is down",
    "start": "2025-10-12T10:05:00Z",
    "end": "2025-10-12T10:15:00Z",
    "duration": 600000,
    "status": "resolved",
    "updates": [
      {
        "timestamp": "2025-10-12T10:07:00Z",
        "message": "Investigating: We're currently investigating the cause of this outage."
      }
    ]
  }
]
```

**Field Descriptions**:
- `id`: GitHub issue number
- `title`: Incident title
- `start`: Incident start timestamp (ISO 8601)
- `end`: Incident end timestamp (ISO 8601, null if ongoing)
- `duration`: Total incident duration in milliseconds
- `status`: Incident status ("investigating", "resolved")
- `updates`: Array of incident updates with timestamps

## Error Responses

All APIs return standard HTTP status codes:

- `200 OK`: Successful request
- `404 Not Found`: Site slug not found or endpoint doesn't exist
- `500 Internal Server Error`: Server-side error (rare with static hosting)

**Error Response Schema**:
```json
{
  "error": {
    "code": 404,
    "message": "Site not found"
  }
}
```

## Rate Limiting

No explicit rate limiting as APIs are served via GitHub Pages CDN. Standard CDN and browser caching applies.

**Cache Headers**:
- API endpoints: `Cache-Control: max-age=300` (5 minutes)
- Historical data: `Cache-Control: max-age=3600` (1 hour)

## CORS Policy

All APIs support Cross-Origin Resource Sharing (CORS) for browser-based applications:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

## Webhooks and Real-time Updates

Upptime does not provide webhooks or real-time push notifications. For real-time updates:

1. **Polling**: Client applications should poll relevant endpoints at appropriate intervals
2. **GitHub Webhooks**: Advanced users can set up GitHub webhooks on the repository for commit events
3. **Status Page**: The web interface provides real-time updates via GitHub API integration

## Integration Examples

### JavaScript/Node.js
```javascript
const response = await fetch('https://bandlab.github.io/upptime/api/bandlab/uptime.json');
const uptimeData = await response.json();
console.log(`BandLab uptime: ${uptimeData.uptimeDay}%`);
```

### Python
```python
import requests

response = requests.get('https://bandlab.github.io/upptime/api/summary.json')
data = response.json()
print(f"System status: {data['status']}")
```

### curl
```bash
curl -H "Accept: application/json" \
     https://bandlab.github.io/upptime/api/bandlab/uptime.json
```

All API endpoints are automatically generated and maintained by Upptime's GitHub Actions workflows, ensuring consistency and reliability without manual intervention.