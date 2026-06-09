# 📊 SQL Data Cleaning Project

This repository contains the SQL code and dataset used in a data cleaning project focused on preparing a complex HR dataset for analysis while ensuring data quality, consistency, and reliability. The project demonstrates the use of SQL for data cleaning, transformation, and preparation for visualization and analytical purposes.

## 📝 Project Highlights

During this project, the following tasks were performed:

### 1. Extensive Data Wrangling

A comprehensive data wrangling process was conducted to prepare the dataset for analysis. This included identifying and handling data quality issues, improving data consistency, removing unnecessary information, and optimizing the dataset for further analytical processes.

### 2. Data Transformation and Cleansing

Advanced SQL techniques were used to transform and clean the data efficiently. These included:

- **CASE Statements** – Used for conditional transformations and creating derived columns.
- **Views** – Created to simplify repeated analytical queries and support data visualization.
- **Common Table Expressions (CTEs)** – Utilized for cleaner and more structured query logic.
- **Data Standardization** – Corrected inconsistent values across columns.
- **Duplicate Handling** – Identified and removed duplicate records to improve data accuracy.

## ⚙️ Key Cleaning Operations Performed

- Added an **Attrition Value** column to simplify attrition-based analysis.
- Removed unnecessary columns containing irrelevant or missing data.
- Identified and removed duplicate records from the dataset.
- Standardized inconsistent categorical values for improved consistency.
- Created reusable SQL **Views** for attrition analysis based on:
  - Age
  - Department
  - Education Field
  - Job Role
  - Salary Slab
  - Years at Company
  - Gender
  - Overtime

## 📈 Outcome

The cleaned and transformed dataset is optimized for analysis and visualization tools such as Power BI, enabling more reliable insights into employee attrition trends and workforce analytics.
