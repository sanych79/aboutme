--1. ��������� ������ https://supabase.com/ ����� ������� �������� ���� ������ PostgreSQL.

---host--- db.irqaqbherhklqjnfpgdl.supabase.co
---databese---postgres
---port---5432
---user---postgres
---password---NetoSQL2022


--2. ��� ������� � ������ � ���� ������ ������ ���� ������ ������������ 
--�����: netocourier
--������: NetoSQL2022
--�����: ������ ������ �� ����� public, � information_schema � pg_catalog ����� ������ �� ������, ������������� ������ � ���� ������, ���� ��� �����. 

create user netocourier with password 'NetoSQL2022'

grant connect on database postgres to netocourier

grant all privileges on schema public to netocourier

grant usage on schema information_schema to netocourier

grant usage on schema pg_catalog to netocourier

--3. ������ ���� ������� ��������� ���������:

--user: --����������
--id uuid PK
--last_name varchar(50) --������� ����������
--first_name varchar(50) --��� ����������
--dismissed boolean --������ ��� ���, �������� �� ��������� "���"

	create table public.user (
	id uuid primary key,
	last_name varchar(50) not null,
	first_name varchar(50) not null,
	dismissed boolean default false
	)

	
--account: --������ ������������
--id uuid PK
--name varchar(150) --�������� �����������
	
	create table public.account (
	id uuid primary key,
	name varchar(150) not null	
	)
	
--contact: --������ ��������� ������������
--id uuid PK
--last_name varchar(50) --������� ��������
--first_name varchar(50) --��� ��������
--account_id  FK --id �����������
	
	create table public.contact (
	id uuid primary key,
	last_name varchar(50) not null,
	first_name varchar(50) not null,
	account_id uuid references public.account(id)
	)


--courier: --������ �� ������� �� �������
--id uuid PK
--from_place varchar(150) --������
--where_place varchar(150) --����
--name varchar (150) --�������� ���������
--account_id uuid FK --id �����������
--contact_id  uuid FK --id �������� 
--description text --��������
--user_id uuid FK --id ���������� �����������
--status enum -- ������� '� �������', '�����������', '���������', '�������'. �� ��������� '� �������'
--created_date date --���� �������� ������, �������� �� ��������� now()

--�������� �5. ������� ������ (� �.3) ��� ������������ ������ �������� � �������� status ����������� create type ... as enum 
-- ������� ��� status_tp ��� ���� Status
create type status_tp as enum ('� �������', '�����������', '���������', '�������')
	
	create table public.courier (
	id uuid primary key,
	from_place varchar(150) not null,
	where_place varchar(150) not null,
	name varchar(150) not null,
	account_id uuid references public.account(id),
	contact_id uuid references public.contact(id),
	description text,
	user_id uuid references public.user(id),
	status status_tp default '� �������',
	created_date date  default now()
	)


--4. ��� ��������� uuid ���������� ������������ ���������� ������ uuid-ossp, ������� ��� ��������� � �������� ����.

-- ���������� ������� uuid

create extension uuid-ossp

select uuid_generate_v4() -- ���������� ��� ���������

--6. ��� ����������� ������������ ���������� ���������� ����������� ��������� insert_test_data(value), ������� ��������� �� ���� ������������� ��������.
--������ ��������� ������ ������:
--value * 1 ����� ��������� ������ � ��������� account.
--value * 2 ����� ��������� ������ � ��������� contact.
--value * 1 ����� ��������� ������ � ��������� user.
--value * 5 ����� ��������� ������ � ��������� courier.

----------���� ������� ������������ ��������� ������ ������, ��������� ����� ��������, ������-����, ����

--- ������� ��� ���������� ������������� �������� �� ������ status_tp
create or replace function Status_rnd(out res status_tp) as $$
	begin 
		SELECT myStatus FROM ( SELECT unnest(enum_range(NULL::status_tp)) as myStatus ) sub ORDER BY random() LIMIT 1 into res;
	end;
$$language plpgsql;


--- ������� ��� ���������� ������������� �������� varchar(x �������)
create or replace function vch_rnd(x int, out res varchar) as $$
	begin 
		SELECT left(repeat(substring('��������������������������������',1,(random()*33)::integer),(random()*10)::integer),x) into res;
	end;
$$language plpgsql;



--- ������� ��� ���������� ������������� �������� ������-����
create or replace function tf_rnd(out res boolean) as $$
	begin 
			select (round(random())::int)::boolean into res;
		end;
$$language plpgsql;


--- ������� ��� ���������� ������������� �������� ����
create or replace function date_rnd(out res date) as $$
	begin 
			select (now() - interval '1 day' * round(random() * 1000))::date  into res;
		end;
$$language plpgsql;


------�����----���� ������� ������������ ��������� ������ ������, ��������� ����� ��������, ������-����, ����

----------���� �������� ����������� �� ����� ������ ��������� ������ � ������ �� ������
create or replace procedure  user_add_rnd() as $$
DECLARE 	id1 uuid = uuid_generate_v4();
			last_name1 varchar(50) = vch_rnd(50);
			first_name1 varchar(50) = vch_rnd(50);
			dismissed1 boolean = tf_rnd();
	begin 
		insert into public."user" (	id,	last_name, first_name, dismissed) values (id1,	last_name1, first_name1, dismissed1);
	end;
$$language plpgsql;


create or replace procedure  account_add_rnd() as $$
DECLARE 
	   id1 uuid = uuid_generate_v4();
	   name1 varchar(150) = vch_rnd(150);	
	begin 
		insert into public.account (id,	name) values (id1,	name1);
	end;
$$language plpgsql;


create or replace procedure  contact_add_rnd() as $$
DECLARE 
	id1 uuid = uuid_generate_v4();
	last_name1 varchar(50) = vch_rnd(50);
	first_name1 varchar(50) = vch_rnd(50);
	account_id1  uuid = (SELECT id FROM public.account ORDER BY random() LIMIT 1 );
	begin 
		insert into public.contact (id,	last_name, first_name, account_id) values (id1,	last_name1, first_name1, account_id1);
	end;
$$language plpgsql;


create or replace procedure  courier_add_rnd() as $$
DECLARE 
	id1 uuid = uuid_generate_v4();
	from_place1 varchar(150) = vch_rnd(150);
	where_place1 varchar(150) = vch_rnd(150);
	name1 varchar(150) = vch_rnd(150);
	account_id1 uuid = (SELECT id FROM public.account  ORDER BY random() LIMIT 1);
	contact_id1 uuid = (SELECT id FROM public.contact  where public.contact.account_id = account_id1 ORDER BY random() LIMIT 1);
	description1 text = vch_rnd(150)::text;
	user_id1 uuid = (SELECT id FROM public."user"  ORDER BY random() LIMIT 1);
	status1 status_tp = status_rnd();
	created_date1 date  = date_rnd();
	begin 
		insert into public.courier (id,	from_place, where_place, name, account_id, contact_id, description, user_id, status, created_date) 
			   values (id1,	from_place1, where_place1, name1, account_id1, contact_id1, description1, user_id1, status1, created_date1);
	end;
$$language plpgsql;

------�����----���� �������� ����������� �� ����� ������ ��������� ������ � ������ �� ������

----------�������� ��������� ����������� ��� ������� ���������� ������� �� �������
--value * 1 ����� ��������� ������ � ��������� account.
--value * 2 ����� ��������� ������ � ��������� contact.
--value * 1 ����� ��������� ������ � ��������� user.
--value * 5 ����� ��������� ������ � ��������� courier

create or replace procedure  insert_test_data(value int) as $$
	begin 
		  for cnt in 1..value loop
			call account_add_rnd();
	 	   	call contact_add_rnd();
	        call contact_add_rnd();
  		    call user_add_rnd();
  		   	call courier_add_rnd();
   			call courier_add_rnd();
   		    call courier_add_rnd();
         	call courier_add_rnd();
   			call courier_add_rnd();
  		  end loop;
	end;
$$language plpgsql;


call insert_test_data(2)

select * from account

select * from contact

select * from public."user"

select * from courier

--7. ���������� ����������� ��������� erase_test_data(), ������� ����� ������� �������� ������ �� ���������.
create or replace procedure  erase_test_data() as $$
	begin 
		delete from public.courier cascade; 	
	   delete from public.user cascade;
	  	delete from public.contact cascade;
		delete from public.account cascade;
	end;
$$language plpgsql;

call erase_test_data()


--8. �� ������� ����������� ������� �� ���������� ����� ������ � ������ �� �������:
--function add($params) --���������� ����� ������

--����� ����������� ��������� add_courier(from_place, where_place, name, account_id, contact_id, description, user_id), 
--������� ��������� �� ���� ������������� ��������� � ������ ������ � ������� courier
--�����! ������������������ �������� ������ ���� ������ ���������, ����� ���������� �������� �� �����.

 create or replace procedure  add_courier(from_place1 varchar(150), where_place1 varchar(150), name1 varchar(150), account_id1 uuid, contact_id1 uuid, description1 text, user_id1 uuid) as $$
	declare 
	 id1 uuid =  uuid_generate_v4();
 	 created_date1 date = now();
 	 status1 status_tp = '� �������';
 	 user_chek int = (select case  when (select id from public."user" u where u.id = user_id1) is null then 0 else 1 end );
 	 account_chek int = (select case  when (select id from public.account a where a.id = account_id1) is null then 0 else 1 end );
 	 contact_chek int = (select case  when (select id from public.contact c where c.id = contact_id1 and c.account_id = account_id1) is null then 0 else 1 end ); 	
    begin 
	    if user_chek = 0 then
	    	RAISE EXCEPTION 'Nonexistent ID --> %', user_id1  USING HINT = 'Please check your user ID';	    	
	    elsif account_chek = 0 then
	    	RAISE EXCEPTION 'Nonexistent ID --> %', account_id1  USING HINT = 'Please check your account ID';	    	
	    elsif contact_chek = 0 then
	   		RAISE EXCEPTION 'Nonexistent ID --> %', contact_id1  USING HINT = 'Please check your contact ID';
	    else
			insert into public.courier (id,	from_place, where_place, name, account_id, contact_id, description, user_id, status, created_date) 
			   values (id1,	from_place1, where_place1, name1, account_id1, contact_id1, description1, user_id1, status1, created_date1);
		end if;
	end;
$$language plpgsql;

call add_courier('qwe123', 'qwe456', 'passport','a42d3904-8308-4c66-a32d-35ec53450d27','e6685feb-b898-411c-b54a-6c388e1ce662','passport get to user','2a4aa83c-6dd6-46c5-92f0-e4b00a862f6b')

select * from public.courier c


--9. �� ������� ����������� ������� �� ��������� ������� � ������� �� �������: 

--����� ����������� ������� get_courier(), ������� ���������� ������� �������� ��������� ���������:
-- id --������������� ������
--from_place --������
--where_place --����
--name --�������� ���������
--account_id --������������� �����������
--account --�������� �����������
--contact_id --������������� ��������
--contact --������� � ��� �������� ����� ������
--description --��������
--user_id --������������� ����������
--user --������� � ��� ���������� ����� ������
--status --������ ������
--created_date --���� �������� ������
--���������� ���������� ������ ���� ������ �� �������, ����� �� ���� �� �������� � ��������.
--�����! ���� �������� �������� ������������ �������� ������� ����� ���������� �� ��������� ����, �� ���������� �������� �� �����.



CREATE OR REPLACE FUNCTION get_courier() RETURNS TABLE(id uuid, from_place varchar(150), where_place varchar(150), name varchar(150), account_id uuid, account varchar(150), contact_id uuid, contact varchar, description text,
			user_id uuid, "user" varchar, status status_tp, created_date date) AS $$
    BEGIN
         RETURN QUERY
            select c.id, c.from_place, c.where_place, c."name", c.account_id, a."name" as account, c.contact_id, concat(c2.last_name,' ',c2.first_name)::varchar as contact, c.description,
			c.user_id, concat(u.last_name, ' ', u.first_name)::varchar as  "user", c.status, c.created_date 
			from 
			public.courier c 
			join public.account a on a.id = c.account_id 
			join public.contact c2 on c.contact_id = c2.id 
			join public."user" u on u.id = c.user_id 
			order by 12, 13 desc;
    END;
$$ LANGUAGE plpgsql;

select * from get_courier()

--10. �� ������� ����������� ������� �� ��������� ������� ������.
--����� ����������� ��������� change_status(status, id), ������� ����� �������� ������ ������. �� ���� ��������� ��������� ����� �������� ������� � �������� �������������� ������.

create or replace procedure  change_status(status1 status_tp, id1 uuid) as $$
	declare 
 	  courier_chek int = (select case  when (select id from public.courier c where c.id = id1) is null then 0 else 1 end );
    begin 
	    if courier_chek = 0 then
	    	RAISE EXCEPTION 'Nonexistent ID --> %', id1  USING HINT = 'Please check your courier ID';	    	
	    else
			UPDATE public.courier c SET status = status1 WHERE id  = id1;
		end if;
	end;
$$language plpgsql;


--11. �� ������� ����������� ������� ��������� ������ ����������� ��������.
--static function get_users() --��������� ������ �������������
--����� ����������� ������� get_users(), ������� ���������� ������� �������� ��������� ���������:
--user --������� � ��� ���������� ����� ������ 
--��������� ������ ���� �����������! ���������� ������ ���� �� ������� ����������.


CREATE OR REPLACE FUNCTION get_users() RETURNS TABLE("user" varchar) AS $$
    BEGIN
         RETURN QUERY
         select concat(u.last_name,' ', u.first_name)::varchar as "user"  from public."user" u where u.dismissed = false order by 1;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_users()

--12. �� ������� ����������� ������� ��������� ������ ������������.
--static function get_accounts() --��������� ������ ������������
--����� ����������� ������� get_accounts(), ������� ���������� ������� �������� ��������� ���������:
--account --�������� ����������� 
--���������� ������ ���� �� �������� �����������.

CREATE OR REPLACE FUNCTION get_accounts() RETURNS TABLE(account varchar) AS $$
    BEGIN
         RETURN QUERY
           select a."name"  from public.account a order by 1;
    END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_accounts()

--13. �� ������� ����������� ������� ��������� ������ ���������.
--function get_contacts($params) --��������� ������ ���������
--����� ����������� ������� get_contacts(account_id), ������� ��������� �� ���� ������������� ����������� � ���������� ������� � ���������� ����������� ����������� �������� ��������� ���������:
--contact --������� � ��� �������� ����� ������ 
--���������� ������ ���� �� ������� ��������. ���� � ������� ������ �������������� ����������� ������� null, ����� ������� ������ '�������� �����������'.


CREATE OR REPLACE FUNCTION get_contacts(account_id1 uuid) RETURNS TABLE(contact varchar) AS $$
	declare
		contact_chek int = (select case  when (select id from public.contact c where c.account_id = account_id1) is null then 0 else 1 end );
    begin
	    if account_id1 is null then
	    	RAISE EXCEPTION 'Please choose your account';	    	
	    elsif contact_chek = 0 then
	    	RAISE EXCEPTION 'Nonexistent ID --> %', account_id1  USING HINT = 'Please check your account ID';
	    else
         RETURN QUERY
          select concat(c.last_name,' ', c.first_name)::varchar as contact  from contact c where c.account_id = account_id1;
         end if;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_contacts(null)


--14. �� ������� ����������� ������� �� ��������� ���������� � ������� �� �������: 
--����� ����������� ������������� courier_statistic, �� ��������� ����������:
--account_id --������������� �����������
--account --�������� �����������
--count_courier --���������� ������� �� ������� ��� ������� �����������
--count_complete --���������� ����������� ������� ��� ������� �����������
--count_canceled --���������� ���������� ������� ��� ������� �����������
--percent_relative_prev_month -- ���������� ��������� ���������� ������� �������� ������ � ����������� ������ ��� ������� �����������, ���� ��������� ������� �� 0, �� � ��������� ������� 0.
--count_where_place --���������� ���� �������� ��� ������� �����������
--count_contact --���������� ��������� �� �����������, ������� ������������ ���������
--cansel_user_array --������ � ���������������� �����������, �� ������� ���� ������ �� �������� "�������" ��� ������� �����������



create view courier_statistic as
select t4.id, t4.name, count_courier, count_complete, count_canceled, 
case 
	when now_m_c > 0 then now_m_c/last_m_c*100 else 0
end as percent_relative_prev_month, count_where_place, count_contact, cansel_user_array 
from(
select *  from account) t4
full join 
(select t1.account_id, last_m_c, now_m_c
from(
select c.account_id, date_trunc('month', c.created_date), count(c.id) as last_m_c
from courier c 
group by c.account_id, c.created_date
having date_trunc('month', c.created_date) = date_trunc('month',now() - interval '1 month')) t1
join(
select c.account_id, date_trunc('month', c.created_date), count(c.id) as now_m_c
from courier c 
group by c.account_id, c.created_date
having date_trunc('month', c.created_date) = date_trunc('month', now())) t2 on t1.account_id = t2.account_id) t3 on t4.id = t3.account_id
full join (
--count_complete --���������� ����������� ������� ��� ������� �����������
select account_id, count(id) as count_complete   
from courier c 
group by account_id, status
having  status = '���������') t5 on t4.id = t5.account_id
full join(
--count_where_place --���������� ���� �������� ��� ������� �����������
select account_id, count(id) as count_where_place
from contact c 
group by c.account_id) t6 on t4.id = t6.account_id
full join(
--count_contact --���������� ��������� �� �����������, ������� ������������ ���������
select account_id, count(id) as count_contact   
from courier c 
group by account_id, status
having  status = '�����������') t7 on  t4.id = t7.account_id
full join(
--cansel_user_array --������ � ���������������� �����������, �� ������� ���� ������ �� �������� "�������" ��� ������� �����������
--count_canceled --���������� ���������� ������� ��� ������� �����������
select account_id, array_agg(distinct c.user_id) as  cansel_user_array, count(id) as count_canceled 
from courier c 
group by account_id, status
having  status = '�������') t8 on t4.id = t8.account_id
full join (select  account_id, count(id) / count(distinct user_id) as count_courier    from courier c 
group by account_id) t9 on t4.id = t9.account_id

SELECT * FROM courier_statistic




