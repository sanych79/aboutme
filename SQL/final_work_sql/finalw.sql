--1
---� ����� ������� ������ ������ ���������?

--- ��������� ������� ������� ������� ���������� ���������� � ������ ������ 
--� ����� �� �������, ��� ��� ���������� ������ ������ ������� ���������� �� ������ � ���������
-- ��������� �� ������
select
	tb1.city as "�����",
	tb1.airport_name as "��������"
from
	(
	select
		distinct a.city,
		count(a.airport_code) over (partition by a.city) as ap_count,
		a.airport_name
	from
		bookings.airports a ) tb1
where
	tb1.ap_count > 1
order by
	tb1.city

---2
--� ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- ���������
	
select
--- ������ ������� ����� � �������� �������������� ���� a2.airport_name
	distinct a2.airport_name as "��������",
	a2.city as "�����",
	--a.model as "�������" -- ���������� � ���� ��������
from bookings.flights f
--- � ������� flights ������������ ������� aircrafts � airports ��� ���������� ������� � ���������� � ���������
join bookings.aircrafts a using (aircraft_code)
join bookings.airports a2 on  f.departure_airport = a2.airport_code
where
--- ��������� ���������� ��������� �� ������������ ��������� �������� ���������
	a.aircraft_code = (
--- ��������� �� ���������� ������� ��������� �� ��������� �������� � ����� ������ (������������) ��������
	select a.aircraft_code from bookings.aircrafts a
	order by a."range" desc	limit 1)
order by a2.city -- ��������� �� ������ 

--3
--������� 10 ������ � ������������ �������� �������� ������
-- �������� LIMIT

--- ��� �� ������� airports �� �������� 10 ������ � ������������ �����������  ������� ����������� ������� ����������
-- � ���������������� ������� �����������
select flight_no as "����� �����", 
--f.departure_airport as "�������� ������", 
--f.arrival_airport as "�������� ��������", 
f.scheduled_departure as "�������� ����-����� ������", 
--f.actual_departure as "����������� ����-����� ������",
(f.scheduled_departure - f.actual_departure) as delay_t 
from bookings.flights f 
order by delay_t limit 10


---4
--���� �� �����, �� ������� �� ���� �������� ���������� ������?
-- ������ ��� JOIN


select b.book_ref as "����� ������������", t.ticket_no as "����� ������", b.book_date::date "���� ������������"
from bookings.bookings b
--- � ������� ������������ ��������� ����������� �� ������� � ����� �� ���������� �������
left join bookings.tickets t using (book_ref)
left join bookings.boarding_passes bp using (ticket_no)
--- ��������� ��������� �� ���������� ���������� �������� ����� ����������� ������
where bp.boarding_no  is null
order by book_ref 

--- ����� �� ���� -127 899 ������������. ��������� ������� ����

select count("����� ������������")
from(
select distinct b.book_ref as "����� ������������", t.ticket_no as "����� ������", b.book_date::date "���� ������������"
from bookings.bookings b
--- � ������� ������������ ��������� ����������� �� ������� � ����� �� ���������� �������
left join bookings.tickets t using (book_ref)
left join bookings.boarding_passes bp using (ticket_no)
--- ��������� ��������� �� ���������� ���������� �������� ����� ����������� ������
where bp.boarding_no  is null
) tb



---5
--������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.
--- ������� �������
--- ���������� ���/� cte

--- ���������� ���� � ���� ��������.
select  distinct s.aircraft_code,	count(s.seat_no) over (partition by s.aircraft_code)
	from  bookings.seats s 

--- ������ �� ��������� ���������� ���������� ���������� �� ������� ��������� � ������ ����
select distinct f.departure_airport,
		f.scheduled_departure::date,
		count(bp.seat_no) over (partition by f.departure_airport, f.scheduled_departure::date order by f.scheduled_departure::date)
	from bookings.boarding_passes bp
	join bookings.flights f	using (flight_id)

--- ������� ������	
with cte as (	--- cte  �������� ���������� ������� ���������� ���� ����������, ��������� ���� � �������� �� �����, �������� ������
-- �� ������ ����� ������������ ����. ������� - ������������ ������ ������
select distinct f.flight_no as fln,
f.scheduled_departure::date as sd, 
f.departure_airport as da,
tb.count as acnumber,
count (bp.boarding_no) over (partition by f.flight_no, f.scheduled_departure::date) as flnumber -- ������ ��� ���������� ���������� ���������� ������� �� ����� � ������ ���� ������
from bookings.flights f 
left join bookings.boarding_passes bp  using (flight_id) --- ��������� ������� ��������� ������ �� ���������� �������, ���� ���� �� ���
join (
select  distinct s.aircraft_code,	count(s.seat_no) over (partition by s.aircraft_code) 
	from  bookings.seats s) tb using (aircraft_code) --- �������� ������������ ������� ������� �� ���������� ���� � �������� ����������� ����
order by f.scheduled_departure::date, f.flight_no)
select cte.fln as "����� �����", 
cte.sd as "���� �����", 
cte.da as "�������� ������",
--cte.acnumber, -- ���� ���������� ������� � ��������
--cte.flnumber, -- ���������� ������� �� �����
cte.acnumber - cte.flnumber as "��������� ������ �� �����",
-- �������� ������� �� ���� � ����� % ����������, ���� ������� ������ �� �������� �� 0
case
	when cte.flnumber <> 0  then  ((cte.flnumber::numeric(10,2) / cte.acnumber::numeric(10,2)) * 100)::numeric(10,2)
	else 0 
end as "% ���������� ��������",
tb2.apn as "��������� �� ��������� �� �����"
from cte
--- ��������� ���������� �������� �������������� ���������� ���������� ���������� �� ������� ��������� � ������ ����
join (
select distinct f.departure_airport,
		f.scheduled_departure::date,
		-- ���� ��� ������� ���������� ���������� ������ � ���������� ��������� ������ �� ���������� ���� 
		count(bp.boarding_no) over (partition by f.departure_airport, f.scheduled_departure::date	order by f.scheduled_departure::date) as apn
	from bookings.boarding_passes bp
	join bookings.flights f	using (flight_id)
) tb2 on cte.da = tb2.departure_airport and cte.sd = tb2.scheduled_departure -- ������� ���������� ������ � �������� �����������
order by cte.sd, cte.da


---6
--������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
--- ��������� ��� ����
--- �������� ROUND

--���������� ��� ������� - �������� � ��������, ����� ���������� ��������� � ������ ����������� �� ������ ��������,
--- ��� �� ����������� ����� ����� ���������� ��������� 
select
	distinct a.model,
	round((count(f.flight_id)) /
		(select count (f.flight_id) from bookings.flights f)::numeric (10, 2)* 100, 2) --- ��������� �������������� ����� ���������� ���������
from bookings.flights f
join bookings.aircrafts a using(aircraft_code)
group by a.model

---7
--���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
-- CTE

--- CTE ���������� ������� ��������, � ����������� � ����� ������.
with cte as (
(select distinct f.flight_id, a.city,  tf.fare_conditions, 
--- ������ ����������� ��������� ������� � ������ ����� �������������, ������ ������� �������������,
--- ��� �� ���-��� ���� ������� (� ����� ���� � ��� ����� �� �� ��������) ���� � (��) ��� �������
--- ��� ������������ ������������� ��������� ������������ ������� ������������� ����� � ����� ������� ���� �� ������ ������� �������.
case
	when tf.fare_conditions = 'Business' then - MIN(tf.amount)
	when tf.fare_conditions = 'Economy' then MAX(tf.amount)
	else 0
end  as min_am
from bookings.flights f 
join bookings.ticket_flights tf using (flight_id)
join bookings.airports a on a.airport_code = f.arrival_airport 
group by f.flight_id , a.city, tf.fare_conditions))
select  cte.city, SUM(min_am)
from (
--- ��������� � ����� ������ ���� ������ -- ����� � ��� ������������ ������ �� ������
select distinct  tf.flight_id
from  bookings.ticket_flights tf
where tf.fare_conditions = 'Business'
order by tf.flight_id
--- ����� ��������� � ����� ������ ���� ������
) tb2 
join cte on tb2.flight_id = cte.flight_id 
group by cte.flight_id, cte.city
having SUM(min_am) > 0 -- ���������� �� ��������, ��� ����� (��������) ����� ������ - ������ ������ ����

--- ����� --- ������ ��� ������� ������ �������


---8
--����� ������ �������� ��� ������ ������?
--- ��������� ������������ � ����������� FROM
--- �������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
--- �������� EXCEPT

---�� ���� ��� �������� except "��������" �� ��� ��������� ��������� ��������-�������� (cross join �� ������� ���������� ���� � �����)
-- � ��������� ����������� ������� ��������� � ������ �������� ������-�������� �������  
create view cross_city 
as (
select
	a3.city as "����� ������",
	a4.city as "����� ��������"
from(
(
	select
		a.airport_code as ac ,
		a2.airport_code as ac2
	from
		bookings.airports a
	cross join bookings.airports a2
	order by
		a.airport_code,
		a2.airport_code)
except
(
select
	distinct f.departure_airport,
	f.arrival_airport
from
	bookings.flights f
order by
	f.departure_airport,
	f.arrival_airport)) tb
join bookings.airports a3 on tb.ac = a3.airport_code
join bookings.airports a4 on tb.ac2 = a4.airport_code
order by tb.ac,	tb.ac2
   )

  --- ������ �� ����� ������
select* from cross_city


---9
--��������� ���������� ����� �����������, ���������� ������� �������,
-- �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *
--- �������� RADIANS ��� ������������� sind/cosd
--- CASE 

--- �te ����������� ������� ������ � ���������. ������� ���������� �� ������ ������� �������������� �� ������� ������ � ������ ��������
--- � ������������� ���������� �� �� �����������. ������������ ����� �����.
with cte 
as(
select
	tb.city1,
	tb.city2,
	(acos(sind(tb.alat1)* sind(tb.alat2) + cosd(tb.alat1)* cosd(tb.alat2)* cosd(tb.alon1-tb.alon2))* 6371) as arr,
	tb.flight_no
from
	(
	select
		distinct f.flight_no,
		f.departure_airport,
		a.city as city1,
		a.longitude as alon1,
		a.latitude as alat1,
		f.arrival_airport,
		a2.city as city2,
		a2.longitude as alon2,
		a2.latitude as alat2
	from
		bookings.flights f
	join bookings.airports a on
		f.departure_airport = a.airport_code
	join bookings.airports a2 on
		f.arrival_airport = a2.airport_code
	order by
		f.departure_airport,
		f.arrival_airport
		) tb
order by
	tb.city1,
	tb.city2
  )
----
select
	concat(cte.city1, '-', tb2.daar) as "�������� ������",
	concat(cte.city2, '-', tb2.faar) as "�������� ��������" ,
	cte.arr::int as "��������� ��������",
	tb2.model as "��� ��������",
	tb2."range" as "����. ��������� ��������",
	---���� � ��������, ��� ���� ����. ��������� �������� ������ ���������� ����� ��������, �� ��� ������
	case
		when tb2."range" > cte.arr then '�������'
		else '����������'
	end as "��������� ������"
from cte
	--- � ��� ������������� ������� � ������� ����� ���������� �� ������ �����, ������������� ��������, ��� ����. ��������� � ���������� ������- �������
join (	select
		distinct f.flight_no,
		a.model,
		a."range",
		f.arrival_airport as faar,
		f.departure_airport as daar
	from
		bookings.flights f
	join bookings.aircrafts a using(aircraft_code)
	) tb2 on
	--- ������� ���������� - ������ ������
	tb2.flight_no = cte.flight_no
order by
	concat(cte.city1, '-', tb2.daar),
	concat(cte.city2, '-', tb2.faar)