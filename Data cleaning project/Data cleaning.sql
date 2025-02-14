/* cleaning data in sql queries */
use sql_project_1;

select *
from
	sql_project_1.dbo.NashvilleHousing
order by
	ParcelID;

-- standardize SaleDate formate

select
	SaleDate,
	SaleDateConverted
from
	NashvilleHousing;


alter table NashvilleHousing
add SaleDateConverted date;

update 
	NashvilleHousing
set
	SaleDateConverted = CONVERT(Date,SaleDate);

/* populate PropertyAddress */

-- check list of rows which have a null value in PropertyAddress
select *
from
	NashvilleHousing
where
	PropertyAddress is null;

-- join two tables to populate PropertyAddress from the matching ParcelID
select
	a.UniqueID,
	a.PropertyAddress,
	ISNULL(a.PropertyAddress,b.PropertyAddress) as aPropertyAddress,
	a.ParcelID
from
	NashvilleHousing a
inner join
	NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.UniqueID  != b.UniqueID
where
	a.PropertyAddress is null;

-- update the PropertyAddress null values
update
	a
set
	a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
						from
							NashvilleHousing a
						inner join
							NashvilleHousing b
						on a.ParcelID = b.ParcelID
						and a.UniqueID  != b.UniqueID
						where
							a.PropertyAddress is null;

/* Breaking out address into individual columns */

select
	PropertyAddress
from
	NashvilleHousing; 

select
	PropertyAddress,
	LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1) AS FirstPart,
	RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress)) AS SecondPart
from
	NashvilleHousing;



alter table NashvilleHousing
add PropertySpliteAddress nvarchar(255),
	PropertySpliteCity nvarchar(255);

update 
	NashvilleHousing
set
	PropertySpliteAddress = LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1),
	PropertySpliteCity = RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress))
	from
	NashvilleHousing;

/* Breaking out OwnerAddress into individual columns */
select
	OwnerAddress
from
	NashvilleHousing;

select
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),	
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from
	NashvilleHousing;


alter table NashvilleHousing
add OwnerSpliteAddress nvarchar(255),
	OwnerSpliteCity nvarchar(255),
	OwnerSpliteState nvarchar(255);

update 
	NashvilleHousing
set
	OwnerSpliteAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSpliteCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSpliteState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	from
	NashvilleHousing;

/* change Y and N to Yes and No in SoldAsVancant*/

select
	SoldAsVacant
from
	NashvilleHousing
where
	SoldAsVacant = 'Y';


update
	NashvilleHousing
set
	SoldAsVacant =  CASE 
						WHEN SoldAsVacant = 'N' THEN 'No'
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						ELSE SoldAsVacant
					END
				FROM NashvilleHousing;


/* Remove duplicates */

with row_number_partition as(
	select *,
	row_number() over(
		partition by
			ParcelID,
			LandUse,
			PropertyAddress,
			SaleDate,
			SalePrice,
			LegalReference
	    order by
			UniqueID
		) as row_numbers
	from
		sql_project_1.dbo.NashvilleHousing)
delete
from
	row_number_partition
where row_numbers > 1;


/* delete unused columns */

alter table sql_project_1.dbo.NashvilleHousing
drop column SaleDate,PropertyAddress,OwnerAddress;


select *
from
	sql_project_1.dbo.NashvilleHousing;