---
name: plausible
description: Access Plausible Analytics for website traffic stats. Use when checking visitor counts, pageviews, top sources, and traffic trends across sites.
---

# Plausible Analytics Skill

Privacy-focused analytics for my websites.

## Credentials

- 1Password: `op://Jarvis/Plausible Analytics API/credential`
- API Base: `https://plausible.io/api/v1`

## API Usage

### Get Aggregate Stats
```bash
curl -s "https://plausible.io/api/v1/stats/aggregate?site_id=SITE&period=30d&metrics=visitors,pageviews,bounce_rate,visit_duration" \
  -H "Authorization: Bearer API_KEY"
```

### Get Realtime Visitors
```bash
curl -s "https://plausible.io/api/v1/stats/realtime/visitors?site_id=SITE" \
  -H "Authorization: Bearer API_KEY"
```

### Get Top Sources
```bash
curl -s "https://plausible.io/api/v1/stats/breakdown?site_id=SITE&period=30d&property=visit:source&metrics=visitors" \
  -H "Authorization: Bearer API_KEY"
```

### Get Top Pages
```bash
curl -s "https://plausible.io/api/v1/stats/breakdown?site_id=SITE&period=30d&property=event:page&metrics=visitors,pageviews" \
  -H "Authorization: Bearer API_KEY"
```

## Periods

- `day` - Today
- `7d` - Last 7 days
- `30d` - Last 30 days
- `month` - This month
- `6mo` - Last 6 months
- `12mo` - Last 12 months

## Metrics

- `visitors` - Unique visitors
- `pageviews` - Total pageviews
- `bounce_rate` - Bounce rate %
- `visit_duration` - Avg visit duration (seconds)
- `visits` - Total visits/sessions

## Properties (for breakdown)

- `visit:source` - Traffic source
- `visit:referrer` - Full referrer URL
- `visit:country` - Country
- `visit:device` - Device type
- `visit:browser` - Browser
- `event:page` - Page path
- `event:goal` - Goals/conversions
