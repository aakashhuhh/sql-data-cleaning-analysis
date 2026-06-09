/*
=========================================================
        CLEANING NASHVILLE HOUSING DATA USING SQL
=========================================================

Description:
This project focuses on cleaning and transforming the
Nashville Housing dataset using SQL Server (T-SQL).

Tasks Performed:
1. Populate missing property address data
2. Split address columns into individual fields
3. Standardize categorical values
4. Remove duplicate records
5. Create a clean dataset using views

=========================================================
*/

---------------------------------------------------------
-- GET TO KNOW THE DATA
---------------------------------------------------------

-- View sample data
SELECT TOP 1000
	*
FROM dbo.nashville_housing_data;

-- Count total rows
SELECT COUNT(*) AS total_rows
FROM dbo.nashville_housing_data;


---------------------------------------------------------
-- POPULATE PROPERTY ADDRESS DATA
---------------------------------------------------------

-- Find total NULL values in PropertyAddress column
SELECT COUNT(*) AS null_property_address_count
FROM dbo.nashville_housing_data
WHERE PropertyAddress IS NULL;


-- Create a backup view of original data
DROP VIEW IF EXISTS housing_data_b;
GO

CREATE VIEW housing_data_b
AS
	SELECT *
	FROM dbo.nashville_housing_data;
GO


-- Create a view to replace missing property addresses
DROP VIEW IF EXISTS new_values;
GO

CREATE VIEW new_values
AS
	WITH
		cte
		AS
		(
			SELECT
				ROW_NUMBER() OVER (
            PARTITION BY a.UniqueID
            ORDER BY a.UniqueID
        ) AS rn,

				a.UniqueID AS unique_a,
				a.ParcelID AS parcel_a,
				a.PropertyAddress AS property_a,

				b.UniqueID AS unique_b,
				b.ParcelID AS parcel_b,
				b.PropertyAddress AS property_b,

				COALESCE(
            a.PropertyAddress,
            b.PropertyAddress
        ) AS replacement

			FROM dbo.nashville_housing_data a

				LEFT JOIN dbo.housing_data_b b
				ON a.ParcelID = b.ParcelID
					AND a.UniqueID <> b.UniqueID

			WHERE a.PropertyAddress IS NULL
		)

	SELECT
		unique_a,
		parcel_a,
		property_a,
		unique_b,
		parcel_b,
		property_b,
		replacement
	FROM cte
	WHERE rn = 1;
GO


-- Alternative way to inspect replacement data
WITH
	cte
	AS
	(
		SELECT
			ROW_NUMBER() OVER (
            PARTITION BY a.UniqueID
            ORDER BY a.UniqueID
        ) AS rn,

			a.UniqueID AS unique_a,
			a.ParcelID AS parcel_a,
			a.PropertyAddress AS property_a,

			b.UniqueID AS unique_b,
			b.ParcelID AS parcel_b,
			b.PropertyAddress AS property_b,

			COALESCE(
            a.PropertyAddress,
            b.PropertyAddress
        ) AS replacement

		FROM dbo.nashville_housing_data a

			LEFT JOIN dbo.housing_data_b b
			ON a.ParcelID = b.ParcelID
				AND a.UniqueID <> b.UniqueID

		WHERE a.PropertyAddress IS NULL
	)

SELECT
	b.unique_a,
	b.parcel_a,
	b.property_a,
	b.unique_b,
	b.parcel_b,
	b.property_b,
	b.replacement,
	a.PropertyAddress

FROM dbo.nashville_housing_data a

	INNER JOIN cte b
	ON a.UniqueID = b.unique_a

WHERE rn = 1;


-- Replace missing values using the view
UPDATE a
SET a.PropertyAddress = b.replacement
FROM dbo.nashville_housing_data a
	INNER JOIN dbo.new_values b
	ON a.UniqueID = b.unique_a
WHERE a.PropertyAddress IS NULL;


---------------------------------------------------------
-- SPLIT ADDRESS COLUMNS
---------------------------------------------------------

-- View existing address columns
SELECT
	PropertyAddress,
	OwnerAddress
FROM dbo.nashville_housing_data;


-- Check NULL values in OwnerAddress
SELECT COUNT(*) AS null_owner_address_count
FROM dbo.nashville_housing_data
WHERE OwnerAddress IS NULL;


---------------------------------------------------------
-- SPLIT PROPERTY ADDRESS
---------------------------------------------------------

SELECT
	LTRIM(RTRIM(
        SUBSTRING(
            PropertyAddress,
            1,
            CHARINDEX(',', PropertyAddress) - 1
        )
    )) AS address,

	LTRIM(RTRIM(
        SUBSTRING(
            PropertyAddress,
            CHARINDEX(',', PropertyAddress) + 1,
            LEN(PropertyAddress)
        )
    )) AS city

FROM dbo.nashville_housing_data;


-- Add new columns
ALTER TABLE dbo.nashville_housing_data
ADD short_address VARCHAR(255);

ALTER TABLE dbo.nashville_housing_data
ADD property_city VARCHAR(255);


-- Populate short address
UPDATE dbo.nashville_housing_data
SET short_address =
    LTRIM(RTRIM(
        SUBSTRING(
            PropertyAddress,
            1,
            CHARINDEX(',', PropertyAddress) - 1
        )
    ));


-- Populate property city
UPDATE dbo.nashville_housing_data
SET property_city =
    LTRIM(RTRIM(
        SUBSTRING(
            PropertyAddress,
            CHARINDEX(',', PropertyAddress) + 1,
            LEN(PropertyAddress)
        )
    ));


-- Validate results
SELECT
	PropertyAddress,
	short_address,
	property_city
FROM dbo.nashville_housing_data;


---------------------------------------------------------
-- SPLIT OWNER ADDRESS
---------------------------------------------------------

SELECT
	OwnerAddress,

	LTRIM(RTRIM(
        SUBSTRING(
            OwnerAddress,
            1,
            CHARINDEX(',', OwnerAddress) - 1
        )
    )) AS address,

	LTRIM(RTRIM(
        SUBSTRING(
            OwnerAddress,
            CHARINDEX(',', OwnerAddress) + 1,
            LEN(OwnerAddress)
                - CHARINDEX(',', OwnerAddress)
                - 4
        )
    )) AS city,

	LTRIM(RTRIM(
        RIGHT(OwnerAddress, 2)
    )) AS state

FROM dbo.nashville_housing_data;


-- Add new columns
ALTER TABLE dbo.nashville_housing_data
ADD owner_address_short VARCHAR(255);

ALTER TABLE dbo.nashville_housing_data
ADD owner_city VARCHAR(255);

ALTER TABLE dbo.nashville_housing_data
ADD owner_state VARCHAR(255);


-- Populate owner address
UPDATE dbo.nashville_housing_data
SET owner_address_short =
    LTRIM(RTRIM(
        SUBSTRING(
            OwnerAddress,
            1,
            CHARINDEX(',', OwnerAddress) - 1
        )
    ));


-- Populate owner city
UPDATE dbo.nashville_housing_data
SET owner_city =
    LTRIM(RTRIM(
        SUBSTRING(
            OwnerAddress,
            CHARINDEX(',', OwnerAddress) + 1,
            LEN(OwnerAddress)
                - CHARINDEX(',', OwnerAddress)
                - 4
        )
    ));


-- Populate owner state
UPDATE dbo.nashville_housing_data
SET owner_state =
    LTRIM(RTRIM(
        RIGHT(OwnerAddress, 2)
    ));


-- Validate results
SELECT
	OwnerAddress,
	owner_address_short,
	owner_city,
	owner_state
FROM dbo.nashville_housing_data;


---------------------------------------------------------
-- STANDARDIZE SoldAsVacant VALUES
---------------------------------------------------------

-- View distinct values
SELECT
	SoldAsVacant,
	COUNT(*) AS count_value
FROM dbo.nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY count_value;


-- Convert Y/N to Yes/No
SELECT
	SoldAsVacant,

	CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS yes_no

FROM dbo.nashville_housing_data;


-- Update values
UPDATE dbo.nashville_housing_data
SET SoldAsVacant =
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


-- Validate updates
SELECT
	SoldAsVacant,
	COUNT(*) AS count_value
FROM dbo.nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY count_value;


---------------------------------------------------------
-- CHECK NULL VALUES IN SALE PRICE
---------------------------------------------------------

SELECT SalePrice
FROM dbo.nashville_housing_data
WHERE SalePrice IS NULL;

-- No NULL values found


---------------------------------------------------------
-- CHECK FOR DUPLICATES
---------------------------------------------------------

WITH
	cte
	AS
	(
		SELECT *,
			ROW_NUMBER() OVER
           (
               PARTITION BY
                   ParcelID,
                   LandUse,
                   PropertyAddress,
                   SaleDate,
                   SalePrice,
                   LegalReference,
                   SoldAsVacant,
                   OwnerName,
                   OwnerAddress,
                   Acreage,
                   TaxDistrict,
                   LandValue,
                   BuildingValue,
                   TotalValue,
                   YearBuilt,
                   Bedrooms,
                   FullBath,
                   HalfBath

               ORDER BY UniqueID
           ) AS rn

		FROM dbo.nashville_housing_data
	)

SELECT *
FROM cte
WHERE rn > 1;


---------------------------------------------------------
-- CREATE CLEAN DATASET VIEW
---------------------------------------------------------

DROP VIEW IF EXISTS clean_nashville_data;
GO

CREATE VIEW clean_nashville_data
AS

	WITH
		cte
		AS
		(
			SELECT *,
				ROW_NUMBER() OVER
           (
               PARTITION BY
                   ParcelID,
                   LandUse,
                   PropertyAddress,
                   SaleDate,
                   SalePrice,
                   LegalReference,
                   SoldAsVacant,
                   OwnerName,
                   OwnerAddress,
                   Acreage,
                   TaxDistrict,
                   LandValue,
                   BuildingValue,
                   TotalValue,
                   YearBuilt,
                   Bedrooms,
                   FullBath,
                   HalfBath

               ORDER BY UniqueID
           ) AS rn

			FROM dbo.nashville_housing_data
		)

	SELECT
		UniqueID,
		ParcelID,
		LandUse,
		PropertyAddress,
		SaleDate,
		SalePrice,
		LegalReference,
		SoldAsVacant,
		OwnerName,
		Acreage,
		LandValue,
		BuildingValue,
		TotalValue,
		YearBuilt,
		Bedrooms,
		FullBath,
		HalfBath,
		short_address AS property_address_short,
		property_city,
		owner_address_short,
		owner_city,
		owner_state

	FROM cte
	WHERE rn = 1;
GO


---------------------------------------------------------
-- VALIDATE CLEAN DATASET
---------------------------------------------------------

WITH
	cte
	AS
	(
		SELECT *,
			ROW_NUMBER() OVER
           (
               PARTITION BY
                   ParcelID,
                   LandUse,
                   PropertyAddress,
                   SaleDate,
                   SalePrice,
                   LegalReference,
                   SoldAsVacant,
                   OwnerName,
                   Acreage,
                   LandValue,
                   BuildingValue,
                   TotalValue,
                   YearBuilt,
                   Bedrooms,
                   FullBath,
                   HalfBath

               ORDER BY UniqueID
           ) AS row_number

		FROM dbo.clean_nashville_data
	)

SELECT *
FROM cte
WHERE row_number > 1;


---------------------------------------------------------
-- VIEW CLEAN DATASET
---------------------------------------------------------

SELECT *
FROM dbo.clean_nashville_data;
