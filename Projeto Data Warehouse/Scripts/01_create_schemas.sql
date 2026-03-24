/*===============================================================================
  Script: 01_create_schemas.sql
  Purpose: Creates the schemas for the Data Warehouse following a simplified 
           Medallion Architecture (bronze, silver, gold).

  Description:
  This script initializes the logical structure of the Data Warehouse by creating
  three schemas:
    - bronze: raw data ingestion (CSV loads)
    - silver: cleaned and standardized data
    - gold: analytical model (dimensions and facts)
===============================================================================*/

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;