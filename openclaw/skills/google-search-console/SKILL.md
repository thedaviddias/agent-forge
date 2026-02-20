---
name: google-search-console
description: Access Google Search Console for SEO data - search queries, clicks, impressions, rankings, and indexing status across David's sites.
---

# Google Search Console Skill

Access SEO performance data from Google Search Console.

## Credentials

- 1Password: `op://Jarvis/Google Search Console`
- Token file: `~/.config/gsc/token.json`

## Token Refresh

Access tokens expire after 1 hour. Refresh with:

```bash
curl -s -X POST "https://oauth2.googleapis.com/token" \
  -d "client_id=CLIENT_ID" \
  -d "client_secret=CLIENT_SECRET" \
  -d "refresh_token=REFRESH_TOKEN" \
  -d "grant_type=refresh_token" | jq -r '.access_token'
```

## API Usage

### List Sites
```bash
curl -s "https://www.googleapis.com/webmasters/v3/sites" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Search Analytics (Top Queries)
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/ENCODED_SITE_URL/searchAnalytics/query" \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startDate": "2026-01-01",
    "endDate": "2026-01-31",
    "dimensions": ["query"],
    "rowLimit": 10
  }'
```

### Top Pages
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/ENCODED_SITE_URL/searchAnalytics/query" \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startDate": "2026-01-01",
    "endDate": "2026-01-31",
    "dimensions": ["page"],
    "rowLimit": 10
  }'
```

### By Country
```bash
-d '{"dimensions": ["country"], ...}'
```

### By Device
```bash
-d '{"dimensions": ["device"], ...}'
```

## URL Encoding

Site URLs must be URL-encoded:
- `https://frontendchecklist.io/` → `https%3A%2F%2Ffrontendchecklist.io%2F`
- `sc-domain:goshuinatlas.com` → `sc-domain%3Agoshuinatlas.com`

## Metrics

- `clicks` - Total clicks from search
- `impressions` - Times shown in search results
- `ctr` - Click-through rate
- `position` - Average ranking position

## Date Range

- Max range: 16 months of data
- Format: `YYYY-MM-DD`
