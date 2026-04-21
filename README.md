# Campaign Analytics Power BI Report

## Overview
Power BI report for analysing campaign performance across email and social media channels.

> **Note**: This is a personal learning project. All institutional-specific details 
> have been anonymized. Code patterns and logic are generic and applicable to 
> any email campaign analytics workflow.

## About
Power Query (M) and DAX transformations for cleaning and modeling email campaign data 
in Power BI. Created to practice Git/GitHub workflow and demonstrate data transformation skills.

## Data Model Changes
- Created dim_Campaign dimension table
- Standardized campaign names using key matching
- Established relationships via Campaign ID

## Queries

**Dimension Tables:**
- `dim_campaign.m` - Campaign dimension with standardized keys and categories
- `dim_person.m` - Person dimension
- `Dates.dax` - Date dimension (DAX calculated table)

**Fact Tables:**
- `fact_campaign.m` - Campaign-level performance metrics
- `fact_email_clicks.m` - Individual click-level tracking
- `fact_social_media.m` - Social media engagement data

**Staging & Utilities:**
- `stg_email_clicks.m` - Email clicks staging transformation
- `row_count_check.m` - Data validation checks

*All `.m` files are Power Query (M language) transformations located in the `power-query/` folder.*

## Setup
1. Open the.pbix file in Power BI Desktop
2. Refresh data sources
3. Update data source credentials if needed

## Configuration Required

Before running, create a `Config.pq` file with:
- `ServerName`: Your SQL Server address
- `DatabaseName`: Target database name
- `ExcludeKeywords`: List of campaign keywords to filter out
- `NewCustomerKeywords`: Keywords identifying new customer campaigns
- `CampaignPrefix`: Campaign naming prefix