--1
---В каких городах больше одного аэропорта?

--- Используя оконную функцию находим количество аэропортов в каждом городе 
--и далее по условию, что это количество больше одного выводим информацию по городу и аэропорту
-- групируем по городу
select
	tb1.city as "Город",
	tb1.airport_name as "Аэропорт"
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
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Подзапрос
	
select
--- делаем выборку полей с условием оригинальности поля a2.airport_name
	distinct a2.airport_name as "Аэропорт",
	a2.city as "Город",
	--a.model as "Самолет" -- информация о типк самолета
from bookings.flights f
--- к таблице flights присоединяем таблицы aircrafts и airports для дополнения данными о аэропортах и самолетах
join bookings.aircrafts a using (aircraft_code)
join bookings.airports a2 on  f.departure_airport = a2.airport_code
where
--- фильтруем полученный результат по максимальной дальности перелета самолетом
	a.aircraft_code = (
--- подзапрос на сортировку таблицы самолетов по дальности перелета и берем первое (максимальное) значение
	select a.aircraft_code from bookings.aircrafts a
	order by a."range" desc	limit 1)
order by a2.city -- сортируем по городу 

--3
--Вывести 10 рейсов с максимальным временем задержки вылета
-- Оператор LIMIT

--- тут из таблицы airports мы выбираем 10 рейсов с максимальным показателем  разницы актуального времени отправлени
-- и запланированного времени отправления
select flight_no as "Номер рейса", 
--f.departure_airport as "Аэропотр вылета", 
--f.arrival_airport as "Аэропорт прибытия", 
f.scheduled_departure as "Плановая дата-время вылета", 
--f.actual_departure as "Фактическое дата-время вылета",
(f.scheduled_departure - f.actual_departure) as delay_t 
from bookings.flights f 
order by delay_t limit 10


---4
--Были ли брони, по которым не были получены посадочные талоны?
-- Верный тип JOIN


select b.book_ref as "Номер бронирования", t.ticket_no as "Номер билета", b.book_date::date "Дата бронирования"
from bookings.bookings b
--- в выборку бронирований обогащаем информацией по билетам и далее по пасадочным талонам
left join bookings.tickets t using (book_ref)
left join bookings.boarding_passes bp using (ticket_no)
--- фильтруем результат по нулевомому заполнению атрибута норем посадочного талона
where bp.boarding_no  is null
order by book_ref 

--- ответ да были -127 899 бронирований. результат расчета ниже

select count("Номер бронирования")
from(
select distinct b.book_ref as "Номер бронирования", t.ticket_no as "Номер билета", b.book_date::date "Дата бронирования"
from bookings.bookings b
--- в выборку бронирований обогащаем информацией по билетам и далее по пасадочным талонам
left join bookings.tickets t using (book_ref)
left join bookings.boarding_passes bp using (ticket_no)
--- фильтруем результат по нулевомому заполнению атрибута норем посадочного талона
where bp.boarding_no  is null
) tb



---5
--Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
--- Оконная функция
--- Подзапросы или/и cte

--- количество мест в коде самолета.
select  distinct s.aircraft_code,	count(s.seat_no) over (partition by s.aircraft_code)
	from  bookings.seats s 

--- запрос на выявление количества вывезенных пассажиров из каждого аэропорта в каждый день
select distinct f.departure_airport,
		f.scheduled_departure::date,
		count(bp.seat_no) over (partition by f.departure_airport, f.scheduled_departure::date order by f.scheduled_departure::date)
	from bookings.boarding_passes bp
	join bookings.flights f	using (flight_id)

--- решение задачи	
with cte as (	--- cte  собирает информацию сколько пассажиров было отправлено, количство мест в самолете на рейсе, аэропорт вылета
-- на каждом рейсе относительно даты. условие - уникальность номера рейчас
select distinct f.flight_no as fln,
f.scheduled_departure::date as sd, 
f.departure_airport as da,
tb.count as acnumber,
count (bp.boarding_no) over (partition by f.flight_no, f.scheduled_departure::date) as flnumber -- окошко для вычисления количества посадочных талонов на Рейсе с учетом даты вылета
from bookings.flights f 
left join bookings.boarding_passes bp  using (flight_id) --- обогощаем таблицу перелетов даннми по посадочным талонам, даже если их нет
join (
select  distinct s.aircraft_code,	count(s.seat_no) over (partition by s.aircraft_code) 
	from  bookings.seats s) tb using (aircraft_code) --- обогощем получившуюся таблицу данными по количеству мест в самолете выполняющим рейс
order by f.scheduled_departure::date, f.flight_no)
select cte.fln as "Номер рейса", 
cte.sd as "Дата рейса", 
cte.da as "Аэропорт вылета",
--cte.acnumber, -- макс количество человек в самолете
--cte.flnumber, -- количество человек на рейсе
cte.acnumber - cte.flnumber as "свободные сместа на рейсе",
-- проверка деления на ноль и вывод % заполнения, если самолет вообще не заполнен то 0
case
	when cte.flnumber <> 0  then  ((cte.flnumber::numeric(10,2) / cte.acnumber::numeric(10,2)) * 100)::numeric(10,2)
	else 0 
end as "% заполнения самолета",
tb2.apn as "вывезенно из аэропорта за сутки"
from cte
--- добавляем информацию запросом которыйвыявлет количество вывезенных пассажиров из каждого аэропорта в каждый день
join (
select distinct f.departure_airport,
		f.scheduled_departure::date,
		-- окно для расчета количества посадочных талоно в конкретном аэропорту вылета на конкретную дату 
		count(bp.boarding_no) over (partition by f.departure_airport, f.scheduled_departure::date	order by f.scheduled_departure::date) as apn
	from bookings.boarding_passes bp
	join bookings.flights f	using (flight_id)
) tb2 on cte.da = tb2.departure_airport and cte.sd = tb2.scheduled_departure -- условия соединение стешки с теблицей подзапросом
order by cte.sd, cte.da


---6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--- Подзапрос или окно
--- Оператор ROUND

--объеденили две таблицы - перелеты и самолеты, нашли количество перелетов с учетом группировки по модели самолета,
--- так же подзапросом нашли общее количество перелетов 
select
	distinct a.model,
	round((count(f.flight_id)) /
		(select count (f.flight_id) from bookings.flights f)::numeric (10, 2)* 100, 2) --- подзапрос подсчитывающий общее количество перелетов
from bookings.flights f
join bookings.aircrafts a using(aircraft_code)
group by a.model

---7
--Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
-- CTE

--- CTE объединяет таблицы перелеты, с аэропортами и ценой билета.
with cte as (
(select distinct f.flight_id, a.city,  tf.fare_conditions, 
--- сделал минимальную стоимость бизнеса в каждом рейсе отрицательной, эконом оставил положительной,
--- так же кое-где есть комфорт (а может быть и еще какой то со временем) клас я (их) его занулил
--- при суммировании получившегося аргумента относительно кортежа индетификатор рейса и будет понятно есть ли бизнес дешевле эконома.
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
--- вычисляем в каких рейсах есть Бизнес -- будем к ней прикручивать данные из цтешки
select distinct  tf.flight_id
from  bookings.ticket_flights tf
where tf.fare_conditions = 'Business'
order by tf.flight_id
--- конец вычисляем в каких рейсах есть Бизнес
) tb2 
join cte on tb2.flight_id = cte.flight_id 
group by cte.flight_id, cte.city
having SUM(min_am) > 0 -- фильтрация по признаку, что сумма (разность) денег эконом - бизнес больше нуля

--- ответ --- похоже нет Бизнеса дшевле эконома


---8
--Между какими городами нет прямых рейсов?
--- Декартово произведение в предложении FROM
--- Самостоятельно созданные представления (если облачное подключение, то без представления)
--- Оператор EXCEPT

---по сути тут оператор except "вычитает" из все возможных вариантов Аэроторт-Аэропорт (cross join по таблице аэропортов само с собой)
-- и вариантов пересечений таблицы перелетов в рамках аэропорт выдета-аэропорт прилета  
create view cross_city 
as (
select
	a3.city as "Город вылета",
	a4.city as "Город прибытия"
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

  --- запрос на вызов вьюшки
select* from cross_city


---9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами,
-- сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *
--- Оператор RADIANS или использование sind/cosd
--- CASE 

--- сte объеденияет таблицы полеты и аэропорты. Выводит информацию по рейсам которые осуществляются из городов вылета в города прибытия
--- и расчитывается расстояние по их координатам. Уникальность Номер рейса.
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
	concat(cte.city1, '-', tb2.daar) as "Аэропорт вылета",
	concat(cte.city2, '-', tb2.faar) as "Аэропорт прибытия" ,
	cte.arr::int as "Дальность перелета",
	tb2.model as "Тиа самолета",
	tb2."range" as "макс. дальность самолета",
	---поле с условием, что если макс. дальность самолета больше расстояния меджу городами, то все хорошо
	case
		when tb2."range" > cte.arr then 'Долетит'
		else 'Разобьется'
	end as "результат полета"
from cte
	--- к цте приджойниваем таблицу в которой будет информация по номеру рейса, ослуживаемому самолету, его макс. дальности и аэропортах вылета- придета
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
	--- условия соединения - номера рейсов
	tb2.flight_no = cte.flight_no
order by
	concat(cte.city1, '-', tb2.daar),
	concat(cte.city2, '-', tb2.faar)