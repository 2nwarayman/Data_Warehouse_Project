# Data Warehouse and Analytics Project

Welcome to my **Data Warehouse and Analytics Project**! 🚀

This project demonstrates the development of a modern data warehouse using **SQL Server**, following the **Medallion Architecture** with Bronze, Silver, and Gold layers.

The project covers the complete data workflow, starting from raw data ingestion and data cleansing to data transformation, data modeling, and analytical reporting.

---

## 🏗️ Data Architecture

<img width="1442" height="1004" alt="Architecture" src="https://github.com/user-attachments/assets/b38377db-cc01-4df9-9b3c-ab157d65dc9a" />

The project follows the **Medallion Architecture**, consisting of three layers:

1. **Bronze Layer**: Stores raw data as-is from the source systems. Data is loaded from CSV files into SQL Server with minimal transformation.

2. **Silver Layer**: Contains cleaned, standardized, and transformed data. Data quality issues are handled and the data is prepared for analytical use.

3. **Gold Layer**: Contains business-ready data modeled into a **Star Schema**, consisting of fact and dimension views for reporting and analytics.

---

## 📖 Project Overview

This project includes:

1. **Data Architecture**  
   Designing a modern data warehouse using the Bronze, Silver, and Gold architecture.

2. **ETL Pipelines**  
   Extracting data from CRM and ERP source systems, loading it into the Bronze layer, and transforming it through the Silver layer.

3. **Data Quality & Transformation**  
   Cleaning, standardizing, validating, and integrating data from multiple source systems.

4. **Data Modeling**  
   Building a business-ready Star Schema using fact and dimension views in the Gold layer.

5. **Analytics & Reporting**  
   Preparing the Gold layer for analytical queries, dashboards, and business insights.

---

## 🎯 Project Objectives

The main objectives of this project are to:

- Build a modern SQL Server Data Warehouse.
- Integrate data from CRM and ERP systems.
- Apply data cleansing and transformation techniques.
- Implement a Medallion Architecture.
- Build a Star Schema for analytical workloads.
- Create reusable SQL scripts for ETL processes.
- Prepare clean and structured data for BI and reporting.

---

## 🛠️ Technologies & Tools

- **SQL Server**
- **SQL Server Management Studio (SSMS)**
- **T-SQL**
- **SQL Server BULK INSERT**
- **ETL Pipelines**
- **Medallion Architecture**
- **Star Schema**
- **Draw.io**
- **Git & GitHub**

---

## 📂 Data Sources

The project uses data from two source systems:

### CRM

Customer Relationship Management data including:

- Customer information
- Product information
- Sales transactions

### ERP

Enterprise Resource Planning data including:

- Customer demographic information
- Customer location information
- Product category information

The source data is provided as CSV files and loaded into the Bronze layer before being transformed.

---

## 🔄 ETL Process

The data flows through the following process:

```text
CRM CSV Files ──────┐
                    ├──> Bronze ──> Silver ──> Gold ──> Analytics
ERP CSV Files ──────┘
