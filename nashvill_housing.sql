--View data
SElECT *
FROM nashville_housing_data;

--Populate property address data
UPDATE nashville_housing_data 
SET property_address = COALESCE(x.property_address, y.property_address)
FROM nashville_housing_data x
INNER JOIN nashville_housing_data y
ON x.parcel_id = y.parcel_id AND x.unique_id <> y.unique_id
WHERE x.property_address IS NULL;

--Breaking out address into individual columns (Address and City)
ALTER TABLE nashville_housing_data
ADD property_split_address VARCHAR(70);

UPDATE nashville_housing_data
SET property_split_address = SUBSTRING(property_address, 1, POSITION(',' in property_address) - 1);

ALTER TABLE nashville_housing_data
ADD property_split_city VARCHAR(70);

UPDATE nashville_housing_data
SET property_split_city = SUBSTRING(property_address, POSITION(',' in property_address) + 1, LENGTH(property_address));

--Breaking owner_address into individual columns (Address, City and State)
ALTER TABLE nashville_housing_data
ADD owner_split_address VARCHAR(70);

UPDATE nashville_housing_data
SET owner_split_address = SPLIT_PART(owner_address, ',', 1);

ALTER TABLE nashville_housing_data
ADD owner_split_city VARCHAR(70);

UPDATE nashville_housing_data
SET owner_split_city = SPLIT_PART(owner_address, ',', 2);

ALTER TABLE nashville_housing_data
ADD owner_split_state VARCHAR(5);

UPDATE nashville_housing_data
SET owner_split_state = SPLIT_PART(owner_address, ',', 3);

--Change Y and N to Yes and No in "sold_as_vacant" field
UPDATE nashville_housing_data
SET sold_as_vacant = CASE sold_as_vacant
	WHEN 'Y' THEN 'Yes'
	WHEN 'N' THEN 'No'
	ELSE sold_as_vacant
END

--Remove duplicates
DELETE FROM nashville_housing_data
WHERE unique_id IN
    (SELECT unique_id
     FROM 
        (SELECT *,
         ROW_NUMBER() OVER( PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
         ORDER BY  unique_id ) AS row_num
         FROM nashville_housing_data ) t
         WHERE t.row_num > 1 );
		 
--Delete unused columns
ALTER TABLE nashville_housing_data
DROP COLUMN property_address;

ALTER TABLE nashville_housing_data
DROP COLUMN owner_address;

ALTER TABLE nashville_housing_data
DROP COLUMN tax_district;

