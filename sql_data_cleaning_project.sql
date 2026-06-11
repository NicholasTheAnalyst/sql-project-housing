-- Выбрать БД для работы

USE portfolio_project;

-- Ознакомиться с данными

SELECT *
FROM nashville_housing; 

-- Изменить тип данных в столбце saledate

ALTER TABLE nashville_housing 
ADD COLUMN new_sale_date DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_housing 
SET new_sale_date = STR_TO_DATE(saledate, '%M %d, %Y');

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE nashville_housing 
DROP COLUMN saledate;

ALTER TABLE nashville_housing 
RENAME COLUMN new_sale_date TO sale_date;

SELECT *
FROM nashville_housing; 

-- Заполнить пропущенные адреса (PropertyAddress)

SELECT *
FROM nashville_housing 
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT 
	a.ParcelID, 
	a.PropertyAddress,
	b.ParcelID, 
	b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing AS a
JOIN nashville_housing AS b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_housing AS a
JOIN nashville_housing AS b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

SET SQL_SAFE_UPDATES = 1;

-- Разделить адрес на отдельные столбцы (адрес, город)

SELECT 
	PropertyAddress
FROM nashville_housing;

SELECT 
	PropertyAddress,
    SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS address,
	SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1, LENGTH(PropertyAddress)) AS city
FROM nashville_housing;

ALTER TABLE nashville_housing 
ADD COLUMN property_split_address VARCHAR(50);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_housing 
SET property_split_address = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1);

ALTER TABLE nashville_housing 
ADD COLUMN property_split_city VARCHAR(50);

UPDATE nashville_housing 
SET property_split_city = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1, LENGTH(PropertyAddress));

SET SQL_SAFE_UPDATES = 1;

SELECT
	PropertyAddress,
	property_split_address,
	property_split_city
FROM nashville_housing;

-- Заменить значения Y и N на Yes и No в столбце SoldAsVacant

SELECT 
	DISTINCT SoldAsVacant,
    COUNT(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT
	SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END 
FROM nashville_housing;

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_housing 
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END ;

SET SQL_SAFE_UPDATES = 1;

-- Удалить дубликаты

SET SQL_SAFE_UPDATES = 0;

DELETE FROM nashville_housing
WHERE UniqueID IN (
    SELECT UniqueID FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER(
                   PARTITION BY ParcelID, PropertyAddress, SalePrice, sale_date, LegalReference
                   ORDER BY UniqueID
               ) AS row_numb
        FROM nashville_housing
    ) t
    WHERE row_numb > 1
);

SET SQL_SAFE_UPDATES = 1;

-- Удалить неиспользуемые столбцы

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;
