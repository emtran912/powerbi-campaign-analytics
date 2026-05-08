# Campaign Analytics Power BI Report

Power BI report for analysing email and social media campaign performance.

> **Note**: All organisation‑specific details have been anonymised. Logic and patterns are generic.

> **Status**: The social media dashboard is currently under development. Further updates and metrics will be added soon.

## Dashboard Preview

![Campaign Analytics Dashboard](images/email_overview_dashboard.png)

## What’s Included

### Metrics
- CTR, CTOR, open, bounce and unsubscribe rates
- Unique clickers and delivery metrics
- Quarter-on-Quarter (QoQ) and Year-on-Year (YoY) % change across all measures

### Analysis
- Campaign‑level performance and trends
- Monthly, quarterly and academic‑year views
- Category breakdown (e.g. Events, Appeals, Administrative)

## Project Structure

### Power Query (`power-query/`)
- **Staging**: `stg_email_clicks.m`
- **Dimensions**: `dim_campaign.m`, `dim_person.m`, `dim_link.m`,
- **Facts**: `fact_campaign.m`, `fact_email_clicks.m`, `fact_social_media.m`
- **Utilities**: `row_count_check.m`

All `.m` files are Power Query (M) transformations.

### DAX (`dax/`)
- `Dates.dax` – Date dimension
- `measures.dax` – Core metrics, rates and time intelligence

## Data Model
- Campaign dimension with standardised naming
- Link dimension table with link categories
- Person table for demographic analysis
- Relationships built on Campaign ID
- Separate fact tables for email and social engagement
- Staging table for fact_email_clicks and dim_link, using foldable query to enable date parameters for incremental refreshes

## Key Metrics

| Metric | Description |
|------|-------------|
| CTR | % of delivered emails clicked |
| CTOR | % of openers who clicked |
| Open Rate | % of delivered emails opened |
| Bounce Rate | % of emails bounced |
| Unsubscribe Rate | % of recipients unsubscribing |
| Unique Clickers | Distinct recipients who clicked |

## Tech Stack
- Power BI Desktop
- Power Query (M)
- DAX
- SQL Server

## Configuration

Create a `Config.pq` file with:
- `ServerName`
- `DatabaseName`
- `CampaignPrefix`
- `ExcludeKeywords`
- `NewCustomerKeywords`