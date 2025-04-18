/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM NashvilleProject.dbo.Nashville_Housing_Data

-- Standardize Date Format

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM NashvilleProject.dbo.Nashville_Housing_Data

Update Nashville_Housing_Data
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE Nashville_Housing_Data
Add SaleDateConverted Date;

UPDATE Nashville_Housing_Data
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Populate Property Address Data

SELECT *
FROM NashvilleProject.dbo.Nashville_Housing_Data
-- WHERE PropertyAddress is null
ORDER BY ParcelID

--Fnd the rows where the column PropertyAddress is NULL 
--but where that same associated ParcelID does have a PropertyAddress listed in another row
--In order to populate those NULL cells correctly

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleProject.dbo.Nashville_Housing_Data a
JOIN NashvilleProject.dbo.Nashville_Housing_Data b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

--Now that the rows that are missing the correct address but have the address listed in another ParcelID somewhere else have been identified
--Add the correct address to the NULL column

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleProject.dbo.Nashville_Housing_Data a
JOIN NashvilleProject.dbo.Nashville_Housing_Data b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

-- Now run the query to check to make sure if the null cells have been populated correctly

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleProject.dbo.Nashville_Housing_Data a
JOIN NashvilleProject.dbo.Nashville_Housing_Data b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL


-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleProject.dbo.Nashville_Housing_Data
-- WHERE PropertyAddress is null
--ORDER BY ParcelID

--Use the comma in the address to separate the street address by the City

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress)) as Address

FROM NashvilleProject.dbo.Nashville_Housing_Data

-- Create two new columns and add the new address and City

ALTER TABLE Nashville_Housing_Data
Add PropertySplitAddress nvarchar(255);

UPDATE Nashville_Housing_Data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE Nashville_Housing_Data
Add PropertySplitCity nvarchar(255);

UPDATE Nashville_Housing_Data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress))


SELECT *
FROM NashvilleProject.dbo.Nashville_Housing_Data


--Now do the same with Owner Address using PARSENAME

SELECT OwnerAddress
FROM NashvilleProject.dbo.Nashville_Housing_Data

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.') ,3)
, PARSENAME(REPLACE(OwnerAddress,',','.') ,2)
, PARSENAME(REPLACE(OwnerAddress,',','.') ,1)
From NashvilleProject.dbo.Nashville_Housing_Data


ALTER TABLE Nashville_Housing_Data
Add OwnerSplitAddress nvarchar(255);

UPDATE Nashville_Housing_Data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.') ,3)

ALTER TABLE Nashville_Housing_Data
Add OwnerSplitCity nvarchar(255);

UPDATE Nashville_Housing_Data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.') ,2)

ALTER TABLE Nashville_Housing_Data
Add OwnerSplitState nvarchar(255);

UPDATE Nashville_Housing_Data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.') ,1)


SELECT *
FROM NashvilleProject.dbo.Nashville_Housing_Data


-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM NashvilleProject.dbo.Nashville_Housing_Data
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END
FROM NashvilleProject.dbo.Nashville_Housing_Data  

UPDATE Nashville_Housing_Data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                    UNIQUEID
    ) row_num
    

FROM NashvilleProject.dbo.Nashville_Housing_Data
-- order by ParcelID
)
SELECT *
FROM RowNumCTE
Where row_num > 1
Order by PropertyAddress


-- Delete Unused Columns

SELECT * 
FROM NashvilleProject.dbo.Nashville_Housing_Data

ALTER TABLE NashvilleProject.dbo.Nashville_Housing_Data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
