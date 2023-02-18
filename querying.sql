drop table if exists housing;
create table if not exists housing
(
	UniqueID int,
	ParcelID varchar,
	LandUSe varchar,
	PropertyAddress varchar,
	SaleDate varchar,
	SalePrice varchar,
	LegalReference varchar,
	SoldAsVacant varchar,
	OwnerName varchar,
	OwnerAddress varchar,
	Acreage numeric,
	TaxDistrict varchar,
	LandValue int,
	BuildingValue int,
	TotalValue int,
	YearBuilt int,
	Bedrooms int,
	FullBath int,
	HalfBath int
);


select * 
from housing;

----------------------------------------------------------------------------------

-- standardize the date format

select saledate,to_char(to_date(saledate, 'Month DD, YYYY'), 'YYYY-MM-DD')
from housing;


ALTER TABLE housing ALTER COLUMN saledate TYPE date USING saledate::date;



------------------------------------------------------------------------------

-- populate property address data

select propertyaddress
from housing
where propertyaddress is null;


select a.parcelid,a.propertyaddress, b.parcelid,b.propertyaddress,coalesce(a.propertyaddress,b.propertyaddress)
from housing a
join housing b
	on a.parcelid=b.parcelid
	and a.uniqueid <> b.uniqueid
where a.propertyaddress is null;


update housing 
set propertyaddress = coalesce(a.propertyaddress,b.propertyaddress)
from housing a
join housing b
	on a.parcelid=b.parcelid
	and a.uniqueid <> b.uniqueid
where a.propertyaddress is null; 


---------------------------------------------------------------------------

-- split address into separate columns (address,city,state)

-----propery address-----------

select split_part(propertyaddress,',',1) as p_address,
	   split_part(propertyaddress,',',2) as p_city
from housing;

alter table housing 
add column p_address varchar,
add column p_city varchar;

update housing
set p_address = split_part(propertyaddress,',',1),
	p_city = split_part(propertyaddress,',',2);


select p_address,p_city
from housing;

-------owner address----

select split_part(owneraddress,',',1) as o_address,
	   split_part(owneraddress,',',2) as o_city,
	   split_part(owneraddress,',',3) as o_state
from housing;

alter table housing 
add column o_address varchar,
add column o_city varchar,
add column o_state varchar;

update housing
set o_address = split_part(owneraddress,',',1),
	o_city = split_part(owneraddress,',',2),
	o_state = split_part(owneraddress,',',3);

-----------------------------------------------------------------------------------

-- convert Y and N to Yes and No in "sold as vacant" column


update housing
set soldasvacant = case 
			when soldasvacant = 'Y' then 'Yes'
			when soldasvacant = 'N' then 'No'
			else soldasvacant
			end;


select count(soldasvacant),soldasvacant
from housing
group by soldasvacant;

--------------------------------------------------------------------------------

-- remove duplicate rows


with duplicateCTE1 as(
	select * from(
		select h.*,
		row_number() over(
			partition by 
			parcelid,
			propertyaddress,
			saleprice,
			saledate,
			legalreference
			order by parcelid
		   )row_num 
		from housing h) x
	where x.row_num > 1)

delete from housing
where uniqueid in (select uniqueid
				   from duplicateCTE1)

-- with duplicateCTE as (
-- select *,
-- 	row_number() over(
-- 	partition by 
-- 		parcelid,
-- 		propertyaddress,
-- 		saleprice,
-- 		saledate,
-- 		legalreference
-- 		order by parcelid
-- 	   ) row_num 
-- 	from housing
-- )

-- other method
delete from housing
where uniqueid in	(select  parcelid,
				propertyaddress,
				saleprice,
				saledate,
				legalreference,
				max(uniqueid)
			from housing
			group by parcelid,propertyaddress,saleprice,saledate,legalreference
			having count(*) > 1)


select *
from housing

------------------------------------------------------------------------------

-- delete unused columns

alter table housing
drop column owneraddress,
drop column propertyaddress;

-------------------------------------------------------

----renaming columns

alter table housing rename column p_address to property_address;

alter table housing rename column p_city to property_city;

alter table housing rename column o_address to owner_address;
alter table housing rename column o_city to owner_city;
alter table housing rename column o_state to owner_state;

----------------------------------------------------------

