# Power BI Dashboard

## Olist Brazilian E-Commerce Analysis

The Power BI dashboard presents the main findings from the Olist Brazilian E-Commerce analysis.

The dashboard translates the SQL analysis into interactive business-oriented visualizations covering sales, customers, products, sellers, and logistics.

---

## Dashboard Sections

### Executive Overview

Provides a high-level view of marketplace performance, including:

* Total orders
* Sales performance
* Payment value
* Average order value
* Order trends
* Order status

### Customer & Sales Analysis

Explores:

* Customer purchase frequency
* One-time vs. repeat customers
* Sales by state
* Monthly sales trends
* Customer-related KPIs

### Product & Seller Analysis

Analyzes:

* Product category performance
* Top product categories
* Seller performance
* Seller customer reach
* Product prices
* Freight costs

### Logistics & Delivery Performance

Analyzes:

* Delivery performance
* Estimated vs. actual delivery
* Delivery delays
* Freight costs
* Review scores
* Relationship between delivery performance and customer satisfaction

---

## Data Source

The dashboard is based on the Olist Brazilian E-Commerce public dataset.

Data was loaded into PostgreSQL and analyzed using SQL before being used for visualization.

---

## Analytical Process

```text
Olist Dataset
     ↓
PostgreSQL
     ↓
Data Quality Validation
     ↓
SQL Business Analysis
     ↓
KPI & Insight Development
     ↓
Power BI Dashboard
```

---

## Repository Note

The Power BI `.pbix` file is not included in this repository because of file-size considerations.

The repository contains the SQL analysis and documentation supporting the dashboard.
