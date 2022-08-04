drop database if exists hostel_alloc;

create database hostel_alloc;

use hostel_alloc;

create table hostels( hostel_id int primary key, hostel_name varchar(20));

create table wing_rooms (wing_id int primary key, hostel_id int, start_room int, end_room int, foreign key(hostel_id) references hostels(hostel_id));

create table student(first_name varchar(20), last_name varchar(20), sid int primary key);

create table hostel_rooms(room_no int, hostel_id int, sid int, wing_id int, primary key (room_no, hostel_id), foreign key(hostel_id) references hostels(hostel_id),
foreign key(wing_id) references wing_rooms(wing_id), foreign key(sid) references student(sid)); -- sid can be null, can't be made pkey

drop view if exists stu_room;
create view stu_room as
	select h.sid, s.first_name, s.last_name, h.hostel_name, h.room_no,  wing_id
	from (select w.room_no, sid, hostel_name, wing_id from hostels as h, hostel_rooms as w where h.hostel_id=w.hostel_id ) h
	join student s on h.sid=s.sid
	order by sid;

drop function if exists getHostel;

-- getHostel function checks which preference of student is available for allocation (i.e. has vacancy) and returns the corresponding hostel_id

Delimiter $$
create FUNCTION getHostel(pref1 int, pref2 int, pref3 int, pref4 int) RETURNS int
reads sql data deterministic
Begin
declare hid int;
    if (select count(*) from hostel_rooms where hostel_id = pref1) < 96
then set hid = pref1;
elseif (select count(*) from hostel_rooms where hostel_id = pref2) < 96
then set hid = pref2;
elseif (select count(*) from hostel_rooms where hostel_id = pref3) < 96
then set hid = pref3;
elseif (select count(*) from hostel_rooms where hostel_id = pref4) < 96
then set hid = pref4;
end if;
    return hid;
    end $$
delimiter ;

-- getWing is a function to randomly fetch a wing from the preferred hostel based on availability

Delimiter $$
create FUNCTION getWing(hid int) RETURNS int
reads sql data deterministic
Begin
declare wingid int;
    if((select count(*) from hostel_rooms) = 0 )
then set wingid = (select wing_id from wing_rooms where hostel_id = hid order by rand() limit 1);
else
    set wingid = (select wing_id from wing_rooms where hostel_id = hid && wing_id not in (select distinct wing_id from hostel_rooms) order by rand() limit 1);
    end if;
    return wingid;
    end $$
Delimiter ;

-- allotWing is a procedure to Allot wing to 8 students
drop procedure if exists allotWing;
Delimiter $$
create Procedure allotWing(pref1 int, pref2 int, pref3 int, pref4 int,
						   sid1 int,
                           sid2 int,
                           sid3 int,
                           sid4 int,
                           sid5 int,
                           sid6 int,
                           sid7 int,
                           sid8 int)
begin

    declare wid int;
    declare hid int;
    declare st_room int;
    
-- The statements of this procedure are wrapped in a transaction since we want all the 8 students to be allotted the same wing without a fail
-- Further if there are cases of concurrency, they will be inplicitly handled by the use of transactions.

start transaction;
    set hid = (select getHostel(pref1, pref2, pref3, pref4));
    set wid = (select getWing(hid));
    set st_room = (select start_room from wing_rooms where wing_id = wid);
    insert into hostel_rooms values (st_room, hid, sid1, wid),
									(st_room+1, hid, sid2, wid),
									(st_room+2, hid, sid3, wid),
									(st_room+3, hid, sid4, wid),
									(st_room+4, hid, sid5, wid),
									(st_room+5, hid, sid6, wid),
									(st_room+6, hid, sid7, wid),
									(st_room+7, hid, sid8, wid);
commit;
    end $$
Delimiter ;

drop procedure if exists deleteWing;

-- A procedure to delete a wing corresponding to the provided wing_id : 
Delimiter $$
create procedure deleteWing(widc int)
begin
delete from hostel_rooms where hostel_rooms.wing_id=widc;
end $$
delimiter ;


-- swapRooms procedure is provided for the functionality through which two students of the same wing can swap rooms with mutual agreement
drop procedure if exists swapRooms;

delimiter $$
create procedure swapRooms(sid1 int, sid2 int)
begin
declare wid1 int;
declare wid2 int;
declare r1 int;
declare r2 int;
start transaction;
	set wid1=(select wing_id from hostel_rooms where hostel_rooms.sid=sid1);
    set wid2=(select wing_id from hostel_rooms where hostel_rooms.sid=sid2);
    set r1=(select room_no from hostel_rooms where hostel_rooms.sid=sid1);
    set r2=(select room_no from hostel_rooms where hostel_rooms.sid=sid2);
   
    if(wid1=wid2)
then	
		update hostel_rooms set hostel_rooms.room_no=-1 where hostel_rooms.sid=sid2;
        update hostel_rooms set hostel_rooms.room_no=r2 where hostel_rooms.sid=sid1;
		update hostel_rooms set hostel_rooms.room_no=r1 where hostel_rooms.sid=sid2;
end if;
commit;
end $$
delimiter ;

-- ++++++++++++++++++++++++++++++++++++++++++END OF CREATE STATEMENTS++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- The following statements are to insert data into the tables 

insert into hostels values
(0, "Vishwakarma Bhavan"), (1, "Krishna Bhawan"), (2, "Gandhi Bhawan"), (3, "Budh Bhawan");

insert into wing_rooms values
(1,0,1,8),(2,0,9,16),(3,0,17,24),(4,0,25,32),(5,0,33,40),(6,0,41,48),
(7,0,49,56),(8,0,57,64),(9,0,65,72),(10,0,73,80),(11,0,81,88),(12,0,89,96),
(13,1,1,8),(14,1,9,16),(15,1,17,24),(16,1,25,32),(17,1,33,40),(18,1,41,48),
(19,1,49,56),(20,1,57,64),(21,1,65,72),(22,1,73,80),(23,1,81,88),(24,1,89,96),
(25,2,1,8),(26,2,9,16),(27,2,17,24),(28,2,25,32),(29,2,33,40),(30,2,41,48),
(31,2,49,56),(32,2,57,64),(33,2,65,72),(34,2,73,80),(35,2,81,88),(36,2,89,96),
(37,3,1,8),(38,3,9,16),(39,3,17,24),(40,3,25,32),(41,3,33,40),(42,3,41,48),
(43,3,49,56),(44,3,57,64),(45,3,65,72),(46,3,73,80),(47,3,81,88),(48,3,89,96);

start transaction;
insert into student (first_name, last_name, sid) values ('Mirna', 'Northam', 1);
insert into student (first_name, last_name, sid) values ('Arlana', 'Garry', 2);
insert into student (first_name, last_name, sid) values ('Redford', 'Killingback', 3);
insert into student (first_name, last_name, sid) values ('Anderson', 'Segoe', 4);
insert into student (first_name, last_name, sid) values ('Isahella', 'Banford', 5);
insert into student (first_name, last_name, sid) values ('Cletis', 'Bodicam', 6);
insert into student (first_name, last_name, sid) values ('Baxy', 'Byers', 7);
insert into student (first_name, last_name, sid) values ('Lewes', 'Staves', 8);
insert into student (first_name, last_name, sid) values ('Valli', 'Wilmington', 9);
insert into student (first_name, last_name, sid) values ('Delmor', 'Corton', 10);
insert into student (first_name, last_name, sid) values ('Kayle', 'Smullen', 11);
insert into student (first_name, last_name, sid) values ('Zacharias', 'Magauran', 12);
insert into student (first_name, last_name, sid) values ('Lucius', 'Sliney', 13);
insert into student (first_name, last_name, sid) values ('Shep', 'Richards', 14);
insert into student (first_name, last_name, sid) values ('Raul', 'Cribbin', 15);
insert into student (first_name, last_name, sid) values ('Gennifer', 'Shrimptone', 16);
insert into student (first_name, last_name, sid) values ('Devy', 'Kopps', 17);
insert into student (first_name, last_name, sid) values ('Ealasaid', 'Malinowski', 18);
insert into student (first_name, last_name, sid) values ('Katha', 'Dibbs', 19);
insert into student (first_name, last_name, sid) values ('Harbert', 'Dennidge', 20);
insert into student (first_name, last_name, sid) values ('Ambrose', 'Oliva', 21);
insert into student (first_name, last_name, sid) values ('Riva', 'Lundon', 22);
insert into student (first_name, last_name, sid) values ('Andrey', 'Sanbrooke', 23);
insert into student (first_name, last_name, sid) values ('Kristina', 'Bewicke', 24);
insert into student (first_name, last_name, sid) values ('Kliment', 'Dorricott', 25);
insert into student (first_name, last_name, sid) values ('Dorry', 'Mullin', 26);
insert into student (first_name, last_name, sid) values ('Moselle', 'Carlson', 27);
insert into student (first_name, last_name, sid) values ('Ashbey', 'Webb', 28);
insert into student (first_name, last_name, sid) values ('Augusta', 'Grigor', 29);
insert into student (first_name, last_name, sid) values ('Madelene', 'Giacopelo', 30);
insert into student (first_name, last_name, sid) values ('Wynn', 'Sarchwell', 31);
insert into student (first_name, last_name, sid) values ('Bryce', 'Iacovone', 32);
insert into student (first_name, last_name, sid) values ('Lorenzo', 'Tilson', 33);
insert into student (first_name, last_name, sid) values ('Derrik', 'Acome', 34);
insert into student (first_name, last_name, sid) values ('Noll', 'Van der Beek', 35);
insert into student (first_name, last_name, sid) values ('Husein', 'Lowrance', 36);
insert into student (first_name, last_name, sid) values ('Ara', 'Vittore', 37);
insert into student (first_name, last_name, sid) values ('Cad', 'Giroldo', 38);
insert into student (first_name, last_name, sid) values ('Jillana', 'Sarchwell', 39);
insert into student (first_name, last_name, sid) values ('Arty', 'Littlewood', 40);
insert into student (first_name, last_name, sid) values ('Michael', 'Davidovic', 41);
insert into student (first_name, last_name, sid) values ('Ferdinanda', 'Rowe', 42);
insert into student (first_name, last_name, sid) values ('Murdock', 'Izakof', 43);
insert into student (first_name, last_name, sid) values ('Bari', 'Coyett', 44);
insert into student (first_name, last_name, sid) values ('Courtney', 'Rome', 45);
insert into student (first_name, last_name, sid) values ('Bill', 'McGinley', 46);
insert into student (first_name, last_name, sid) values ('Isac', 'Tudball', 47);
insert into student (first_name, last_name, sid) values ('Loise', 'Clilverd', 48);
insert into student (first_name, last_name, sid) values ('Wiatt', 'Comiam', 49);
insert into student (first_name, last_name, sid) values ('Ashly', 'Cisar', 50);
insert into student (first_name, last_name, sid) values ('Loise', 'Ransbury', 51);
insert into student (first_name, last_name, sid) values ('Bat', 'Du Plantier', 52);
insert into student (first_name, last_name, sid) values ('Michell', 'Spragg', 53);
insert into student (first_name, last_name, sid) values ('Haley', 'Seymour', 54);
insert into student (first_name, last_name, sid) values ('Temp', 'Davidov', 55);
insert into student (first_name, last_name, sid) values ('Jerrilee', 'Seer', 56);
insert into student (first_name, last_name, sid) values ('Darb', 'Kaubisch', 57);
insert into student (first_name, last_name, sid) values ('Johny', 'Womersley', 58);
insert into student (first_name, last_name, sid) values ('Darlleen', 'Linge', 59);
insert into student (first_name, last_name, sid) values ('Berty', 'Stenhouse', 60);
insert into student (first_name, last_name, sid) values ('Florette', 'Willeman', 61);
insert into student (first_name, last_name, sid) values ('Kristos', 'O''Teague', 62);
insert into student (first_name, last_name, sid) values ('Wallis', 'Dreakin', 63);
insert into student (first_name, last_name, sid) values ('Jorrie', 'Pavlishchev', 64);
insert into student (first_name, last_name, sid) values ('Lorita', 'Batters', 65);
insert into student (first_name, last_name, sid) values ('Tedmund', 'Ogus', 66);
insert into student (first_name, last_name, sid) values ('Aurelie', 'Mellmer', 67);
insert into student (first_name, last_name, sid) values ('Fulvia', 'Helm', 68);
insert into student (first_name, last_name, sid) values ('Turner', 'Allsupp', 69);
insert into student (first_name, last_name, sid) values ('Lucinda', 'Havoc', 70);
insert into student (first_name, last_name, sid) values ('Sigismondo', 'MacFarlane', 71);
insert into student (first_name, last_name, sid) values ('Ronica', 'Dockray', 72);
insert into student (first_name, last_name, sid) values ('Dicky', 'Batiste', 73);
insert into student (first_name, last_name, sid) values ('Margret', 'Seeler', 74);
insert into student (first_name, last_name, sid) values ('Yelena', 'Lynagh', 75);
insert into student (first_name, last_name, sid) values ('Heloise', 'Crippill', 76);
insert into student (first_name, last_name, sid) values ('Tiffy', 'Howkins', 77);
insert into student (first_name, last_name, sid) values ('Trevar', 'Satch', 78);
insert into student (first_name, last_name, sid) values ('Berget', 'Hegges', 79);
insert into student (first_name, last_name, sid) values ('Lora', 'Hargie', 80);
insert into student (first_name, last_name, sid) values ('Tandie', 'Gaunt', 81);
insert into student (first_name, last_name, sid) values ('Allix', 'Matthesius', 82);
insert into student (first_name, last_name, sid) values ('Bucky', 'Klimkiewich', 83);
insert into student (first_name, last_name, sid) values ('Vanna', 'Bouda', 84);
insert into student (first_name, last_name, sid) values ('Orsa', 'Gomme', 85);
insert into student (first_name, last_name, sid) values ('Wilmer', 'Thunderchief', 86);
insert into student (first_name, last_name, sid) values ('Phaidra', 'Danilyak', 87);
insert into student (first_name, last_name, sid) values ('Errol', 'O''Hone', 88);
insert into student (first_name, last_name, sid) values ('Lynnette', 'Castelijn', 89);
insert into student (first_name, last_name, sid) values ('Jacques', 'Kleisle', 90);
insert into student (first_name, last_name, sid) values ('Alonso', 'Tegler', 91);
insert into student (first_name, last_name, sid) values ('George', 'Grevile', 92);
insert into student (first_name, last_name, sid) values ('Vivianna', 'Truter', 93);
insert into student (first_name, last_name, sid) values ('Allx', 'Bonevant', 94);
insert into student (first_name, last_name, sid) values ('Lilah', 'Fehely', 95);
insert into student (first_name, last_name, sid) values ('Blondie', 'Rowlatt', 96);
insert into student (first_name, last_name, sid) values ('Hew', 'Autin', 97);
insert into student (first_name, last_name, sid) values ('Rheta', 'Tungay', 98);
insert into student (first_name, last_name, sid) values ('Luke', 'Saxelby', 99);
insert into student (first_name, last_name, sid) values ('Kial', 'Pock', 100);
insert into student (first_name, last_name, sid) values ('Christy', 'Irnis', 101);
insert into student (first_name, last_name, sid) values ('Lockwood', 'Ruckert', 102);
insert into student (first_name, last_name, sid) values ('Simon', 'Garside', 103);
insert into student (first_name, last_name, sid) values ('Loraine', 'Ferraro', 104);
insert into student (first_name, last_name, sid) values ('Tomi', 'Peller', 105);
insert into student (first_name, last_name, sid) values ('Vilhelmina', 'Foulis', 106);
insert into student (first_name, last_name, sid) values ('Dianna', 'Murphey', 107);
insert into student (first_name, last_name, sid) values ('Antonia', 'Yurchenko', 108);
insert into student (first_name, last_name, sid) values ('Meridel', 'Pargetter', 109);
insert into student (first_name, last_name, sid) values ('Ilario', 'Mouland', 110);
insert into student (first_name, last_name, sid) values ('Lilian', 'Crumly', 111);
insert into student (first_name, last_name, sid) values ('Rachelle', 'Accum', 112);
insert into student (first_name, last_name, sid) values ('Hulda', 'Barnewall', 113);
insert into student (first_name, last_name, sid) values ('Domenico', 'Salzburg', 114);
insert into student (first_name, last_name, sid) values ('Fielding', 'Gaskal', 115);
insert into student (first_name, last_name, sid) values ('Rolando', 'Edgeley', 116);
insert into student (first_name, last_name, sid) values ('Nomi', 'Lidstone', 117);
insert into student (first_name, last_name, sid) values ('Ewen', 'Stammer', 118);
insert into student (first_name, last_name, sid) values ('Sayer', 'Ogborne', 119);
insert into student (first_name, last_name, sid) values ('Abagail', 'Grier', 120);
insert into student (first_name, last_name, sid) values ('Freeman', 'Syplus', 121);
insert into student (first_name, last_name, sid) values ('Candace', 'Shoubridge', 122);
insert into student (first_name, last_name, sid) values ('Lane', 'Klasen', 123);
insert into student (first_name, last_name, sid) values ('Torey', 'Aveyard', 124);
insert into student (first_name, last_name, sid) values ('Anthony', 'Wombwell', 125);
insert into student (first_name, last_name, sid) values ('Harley', 'Creed', 126);
insert into student (first_name, last_name, sid) values ('Krisha', 'Youster', 127);
insert into student (first_name, last_name, sid) values ('Towny', 'Schulze', 128);
insert into student (first_name, last_name, sid) values ('Marlyn', 'Scholig', 129);
insert into student (first_name, last_name, sid) values ('Sophey', 'Risborough', 130);
insert into student (first_name, last_name, sid) values ('Wilmer', 'Conrard', 131);
insert into student (first_name, last_name, sid) values ('Orren', 'Mewis', 132);
insert into student (first_name, last_name, sid) values ('Bernadina', 'Filipiak', 133);
insert into student (first_name, last_name, sid) values ('Ransom', 'Dilston', 134);
insert into student (first_name, last_name, sid) values ('Stefanie', 'Weedon', 135);
insert into student (first_name, last_name, sid) values ('Peria', 'Scholler', 136);
insert into student (first_name, last_name, sid) values ('Merry', 'Andrieux', 137);
insert into student (first_name, last_name, sid) values ('Tera', 'Tickle', 138);
insert into student (first_name, last_name, sid) values ('Price', 'Casajuana', 139);
insert into student (first_name, last_name, sid) values ('Loralee', 'Luscott', 140);
insert into student (first_name, last_name, sid) values ('Jdavie', 'Maher', 141);
insert into student (first_name, last_name, sid) values ('Luella', 'Oloshkin', 142);
insert into student (first_name, last_name, sid) values ('Batholomew', 'Wilse', 143);
insert into student (first_name, last_name, sid) values ('Abe', 'Driffield', 144);
insert into student (first_name, last_name, sid) values ('Daisie', 'Mounce', 145);
insert into student (first_name, last_name, sid) values ('Alec', 'Rubica', 146);
insert into student (first_name, last_name, sid) values ('Lawrence', 'Baroc', 147);
insert into student (first_name, last_name, sid) values ('Jacquelyn', 'Feige', 148);
insert into student (first_name, last_name, sid) values ('Anitra', 'Le Barr', 149);
insert into student (first_name, last_name, sid) values ('Martin', 'Chesshire', 150);
insert into student (first_name, last_name, sid) values ('Alejandro', 'Littleproud', 151);
insert into student (first_name, last_name, sid) values ('Darwin', 'Bore', 152);
insert into student (first_name, last_name, sid) values ('Moishe', 'Meedendorpe', 153);
insert into student (first_name, last_name, sid) values ('Nial', 'Crocroft', 154);
insert into student (first_name, last_name, sid) values ('Johnnie', 'Louedey', 155);
insert into student (first_name, last_name, sid) values ('Yehudi', 'Shalloe', 156);
insert into student (first_name, last_name, sid) values ('Minetta', 'Bonallick', 157);
insert into student (first_name, last_name, sid) values ('Alexandros', 'Martinovic', 158);
insert into student (first_name, last_name, sid) values ('Donia', 'Mewha', 159);
insert into student (first_name, last_name, sid) values ('Ashli', 'Blackwell', 160);
insert into student (first_name, last_name, sid) values ('Christian', 'Alenichev', 161);
insert into student (first_name, last_name, sid) values ('Cammi', 'Cunnane', 162);
insert into student (first_name, last_name, sid) values ('Rozanna', 'Cosh', 163);
insert into student (first_name, last_name, sid) values ('Ilka', 'Tissier', 164);
insert into student (first_name, last_name, sid) values ('Layney', 'Carhart', 165);
insert into student (first_name, last_name, sid) values ('Megan', 'Clynter', 166);
insert into student (first_name, last_name, sid) values ('Karalee', 'Kopacek', 167);
insert into student (first_name, last_name, sid) values ('Rafaela', 'Heinig', 168);
insert into student (first_name, last_name, sid) values ('Penrod', 'Langstaff', 169);
insert into student (first_name, last_name, sid) values ('Ashby', 'Allchin', 170);
insert into student (first_name, last_name, sid) values ('Tann', 'McCullouch', 171);
insert into student (first_name, last_name, sid) values ('Gabbie', 'Blewitt', 172);
insert into student (first_name, last_name, sid) values ('Eveline', 'McMearty', 173);
insert into student (first_name, last_name, sid) values ('Tybie', 'Gadault', 174);
insert into student (first_name, last_name, sid) values ('Veronica', 'Margaritelli', 175);
insert into student (first_name, last_name, sid) values ('Rafe', 'O''Neil', 176);
insert into student (first_name, last_name, sid) values ('Dyan', 'Weekley', 177);
insert into student (first_name, last_name, sid) values ('Minne', 'Cowsby', 178);
insert into student (first_name, last_name, sid) values ('Gabriele', 'Ebbett', 179);
insert into student (first_name, last_name, sid) values ('Shelagh', 'Tadman', 180);
insert into student (first_name, last_name, sid) values ('Cristiano', 'Durran', 181);
insert into student (first_name, last_name, sid) values ('Chad', 'Kwiek', 182);
insert into student (first_name, last_name, sid) values ('Filippo', 'Pyser', 183);
insert into student (first_name, last_name, sid) values ('Hailey', 'Spurrier', 184);
insert into student (first_name, last_name, sid) values ('Ari', 'Blaase', 185);
insert into student (first_name, last_name, sid) values ('Devinne', 'Shasnan', 186);
insert into student (first_name, last_name, sid) values ('Humbert', 'Burry', 187);
insert into student (first_name, last_name, sid) values ('Fanchon', 'Beetham', 188);
insert into student (first_name, last_name, sid) values ('Maude', 'Poleykett', 189);
insert into student (first_name, last_name, sid) values ('Tate', 'von Hagt', 190);
insert into student (first_name, last_name, sid) values ('Ailee', 'Mahmood', 191);
insert into student (first_name, last_name, sid) values ('Radcliffe', 'Davidde', 192);
insert into student (first_name, last_name, sid) values ('Ingamar', 'Clynman', 193);
insert into student (first_name, last_name, sid) values ('Carlynne', 'Cottey', 194);
insert into student (first_name, last_name, sid) values ('Hans', 'Poat', 195);
insert into student (first_name, last_name, sid) values ('Rafael', 'Serot', 196);
insert into student (first_name, last_name, sid) values ('Nowell', 'Killingsworth', 197);
insert into student (first_name, last_name, sid) values ('Catie', 'Trevon', 198);
insert into student (first_name, last_name, sid) values ('Ursuline', 'Tunna', 199);
insert into student (first_name, last_name, sid) values ('Emelda', 'Plaskitt', 200);
insert into student (first_name, last_name, sid) values ('Zorina', 'Rozenbaum', 201);
insert into student (first_name, last_name, sid) values ('Torrance', 'Oldroyde', 202);
insert into student (first_name, last_name, sid) values ('Kingston', 'Whall', 203);
insert into student (first_name, last_name, sid) values ('Nichols', 'Tourmell', 204);
insert into student (first_name, last_name, sid) values ('Lavena', 'Filipson', 205);
insert into student (first_name, last_name, sid) values ('Lorrayne', 'Yusupov', 206);
insert into student (first_name, last_name, sid) values ('Aleda', 'Powys', 207);
insert into student (first_name, last_name, sid) values ('Aldis', 'McGarry', 208);
insert into student (first_name, last_name, sid) values ('Lenna', 'Lettson', 209);
insert into student (first_name, last_name, sid) values ('Isacco', 'Gillam', 210);
insert into student (first_name, last_name, sid) values ('Desiri', 'Schwandermann', 211);
insert into student (first_name, last_name, sid) values ('Janeta', 'Lorraway', 212);
insert into student (first_name, last_name, sid) values ('Trixy', 'Colliss', 213);
insert into student (first_name, last_name, sid) values ('Tripp', 'Tittershill', 214);
insert into student (first_name, last_name, sid) values ('Susanetta', 'Gate', 215);
insert into student (first_name, last_name, sid) values ('Salaidh', 'O''Reagan', 216);
insert into student (first_name, last_name, sid) values ('Jemmy', 'Chree', 217);
insert into student (first_name, last_name, sid) values ('Gordie', 'Alejo', 218);
insert into student (first_name, last_name, sid) values ('Agosto', 'Ivatts', 219);
insert into student (first_name, last_name, sid) values ('Andra', 'Hartington', 220);
insert into student (first_name, last_name, sid) values ('Panchito', 'Butting', 221);
insert into student (first_name, last_name, sid) values ('Benedict', 'Ortner', 222);
insert into student (first_name, last_name, sid) values ('Inge', 'Pykerman', 223);
insert into student (first_name, last_name, sid) values ('Ad', 'Devil', 224);
insert into student (first_name, last_name, sid) values ('Shirlee', 'Boise', 225);
insert into student (first_name, last_name, sid) values ('Holmes', 'Hiddsley', 226);
insert into student (first_name, last_name, sid) values ('Dimitry', 'O''Hederscoll', 227);
insert into student (first_name, last_name, sid) values ('Anna-diane', 'Boissier', 228);
insert into student (first_name, last_name, sid) values ('Lil', 'Perrin', 229);
insert into student (first_name, last_name, sid) values ('Florida', 'Eddowes', 230);
insert into student (first_name, last_name, sid) values ('Marlow', 'Brummitt', 231);
insert into student (first_name, last_name, sid) values ('Faunie', 'Coghill', 232);
insert into student (first_name, last_name, sid) values ('Courtenay', 'Gander', 233);
insert into student (first_name, last_name, sid) values ('Flemming', 'Theis', 234);
insert into student (first_name, last_name, sid) values ('Thaddeus', 'Deackes', 235);
insert into student (first_name, last_name, sid) values ('Walt', 'De''Vere - Hunt', 236);
insert into student (first_name, last_name, sid) values ('Nancee', 'Mundford', 237);
insert into student (first_name, last_name, sid) values ('Christine', 'Hellwing', 238);
insert into student (first_name, last_name, sid) values ('Misha', 'Blinder', 239);
insert into student (first_name, last_name, sid) values ('Phyllys', 'Sommerton', 240);
insert into student (first_name, last_name, sid) values ('Moises', 'Hryniewicki', 241);
insert into student (first_name, last_name, sid) values ('Jessamyn', 'Pawlick', 242);
insert into student (first_name, last_name, sid) values ('Mirabel', 'Guilder', 243);
insert into student (first_name, last_name, sid) values ('Rosalynd', 'Barkaway', 244);
insert into student (first_name, last_name, sid) values ('Jack', 'Featherston', 245);
insert into student (first_name, last_name, sid) values ('Ken', 'Kemish', 246);
insert into student (first_name, last_name, sid) values ('Elset', 'Cathrae', 247);
insert into student (first_name, last_name, sid) values ('Weber', 'Faunt', 248);
insert into student (first_name, last_name, sid) values ('Melba', 'Meader', 249);
insert into student (first_name, last_name, sid) values ('Miranda', 'Seneschal', 250);
insert into student (first_name, last_name, sid) values ('Torrence', 'Chadwell', 251);
insert into student (first_name, last_name, sid) values ('Ellery', 'Kermode', 252);
insert into student (first_name, last_name, sid) values ('Nanete', 'Petersen', 253);
insert into student (first_name, last_name, sid) values ('Stella', 'Barrett', 254);
insert into student (first_name, last_name, sid) values ('Risa', 'Kightly', 255);
insert into student (first_name, last_name, sid) values ('Francklin', 'Ellum', 256);
insert into student (first_name, last_name, sid) values ('Herschel', 'Zellick', 257);
insert into student (first_name, last_name, sid) values ('Jacky', 'Roskeilly', 258);
insert into student (first_name, last_name, sid) values ('Nanci', 'Slingsby', 259);
insert into student (first_name, last_name, sid) values ('Anissa', 'Hullin', 260);
insert into student (first_name, last_name, sid) values ('Nye', 'Pettifer', 261);
insert into student (first_name, last_name, sid) values ('Arley', 'Simmins', 262);
insert into student (first_name, last_name, sid) values ('Hernando', 'Loffhead', 263);
insert into student (first_name, last_name, sid) values ('Zilvia', 'Aireton', 264);
insert into student (first_name, last_name, sid) values ('Andy', 'Zielinski', 265);
insert into student (first_name, last_name, sid) values ('Aaren', 'Allmark', 266);
insert into student (first_name, last_name, sid) values ('Sandor', 'Kleinplac', 267);
insert into student (first_name, last_name, sid) values ('Cissiee', 'Kitchener', 268);
insert into student (first_name, last_name, sid) values ('Liza', 'Costin', 269);
insert into student (first_name, last_name, sid) values ('Johna', 'Mucklestone', 270);
insert into student (first_name, last_name, sid) values ('Marian', 'Middlemiss', 271);
insert into student (first_name, last_name, sid) values ('Darleen', 'Estable', 272);
insert into student (first_name, last_name, sid) values ('Emilie', 'Cable', 273);
insert into student (first_name, last_name, sid) values ('Killy', 'Chugg', 274);
insert into student (first_name, last_name, sid) values ('Lianne', 'Workman', 275);
insert into student (first_name, last_name, sid) values ('Eachelle', 'Grass', 276);
insert into student (first_name, last_name, sid) values ('Maisey', 'Bouch', 277);
insert into student (first_name, last_name, sid) values ('Mirilla', 'Cardenas', 278);
insert into student (first_name, last_name, sid) values ('Paulo', 'Taw', 279);
insert into student (first_name, last_name, sid) values ('Rollie', 'Vezey', 280);
insert into student (first_name, last_name, sid) values ('Kelsey', 'Kamall', 281);
insert into student (first_name, last_name, sid) values ('Ber', 'Faich', 282);
insert into student (first_name, last_name, sid) values ('Mayne', 'Sherlock', 283);
insert into student (first_name, last_name, sid) values ('Weidar', 'Letford', 284);
insert into student (first_name, last_name, sid) values ('Pyotr', 'Pease', 285);
insert into student (first_name, last_name, sid) values ('Lyndsay', 'Dodimead', 286);
insert into student (first_name, last_name, sid) values ('Marietta', 'Winsley', 287);
insert into student (first_name, last_name, sid) values ('Marie', 'D''Alesco', 288);
insert into student (first_name, last_name, sid) values ('Vidovik', 'Ferreiro', 289);
insert into student (first_name, last_name, sid) values ('Christoph', 'Benza', 290);
insert into student (first_name, last_name, sid) values ('Irvin', 'Oneile', 291);
insert into student (first_name, last_name, sid) values ('Cami', 'Gligori', 292);
insert into student (first_name, last_name, sid) values ('Kory', 'Leser', 293);
insert into student (first_name, last_name, sid) values ('Magdalen', 'Gergely', 294);
insert into student (first_name, last_name, sid) values ('Horten', 'Eary', 295);
insert into student (first_name, last_name, sid) values ('Eachelle', 'Ladbrook', 296);
insert into student (first_name, last_name, sid) values ('Thom', 'Mockes', 297);
insert into student (first_name, last_name, sid) values ('Algernon', 'Connikie', 298);
insert into student (first_name, last_name, sid) values ('Giustina', 'Grasner', 299);
insert into student (first_name, last_name, sid) values ('Flo', 'Franzolini', 300);
insert into student (first_name, last_name, sid) values ('Kim', 'Ghiriardelli', 301);
insert into student (first_name, last_name, sid) values ('Dode', 'Maunton', 302);
insert into student (first_name, last_name, sid) values ('Alastair', 'Beavers', 303);
insert into student (first_name, last_name, sid) values ('Jarrad', 'Reaney', 304);
insert into student (first_name, last_name, sid) values ('Hanson', 'Mesias', 305);
insert into student (first_name, last_name, sid) values ('Alfonse', 'Pere', 306);
insert into student (first_name, last_name, sid) values ('Diandra', 'Hutchence', 307);
insert into student (first_name, last_name, sid) values ('Irita', 'Hanigan', 308);
insert into student (first_name, last_name, sid) values ('Maxy', 'De la Harpe', 309);
insert into student (first_name, last_name, sid) values ('Chloette', 'Gallymore', 310);
insert into student (first_name, last_name, sid) values ('Vidovic', 'Wyche', 311);
insert into student (first_name, last_name, sid) values ('Quinn', 'Novotni', 312);
insert into student (first_name, last_name, sid) values ('Deeann', 'Leal', 313);
insert into student (first_name, last_name, sid) values ('Ham', 'Skough', 314);
insert into student (first_name, last_name, sid) values ('Lew', 'Kevis', 315);
insert into student (first_name, last_name, sid) values ('Jacky', 'Reddick', 316);
insert into student (first_name, last_name, sid) values ('Courtney', 'Tremain', 317);
insert into student (first_name, last_name, sid) values ('Gearalt', 'Tretter', 318);
insert into student (first_name, last_name, sid) values ('Barbaraanne', 'Knappitt', 319);
insert into student (first_name, last_name, sid) values ('Barb', 'Oddboy', 320);
insert into student (first_name, last_name, sid) values ('Wendye', 'Horney', 321);
insert into student (first_name, last_name, sid) values ('Wilbur', 'Pothbury', 322);
insert into student (first_name, last_name, sid) values ('Vicky', 'McCarter', 323);
insert into student (first_name, last_name, sid) values ('Bunny', 'Brayshay', 324);
insert into student (first_name, last_name, sid) values ('Annetta', 'Paquet', 325);
insert into student (first_name, last_name, sid) values ('Francene', 'Bettis', 326);
insert into student (first_name, last_name, sid) values ('Marcus', 'Regenhardt', 327);
insert into student (first_name, last_name, sid) values ('Sayres', 'Shropsheir', 328);
insert into student (first_name, last_name, sid) values ('Liane', 'MacCostigan', 329);
insert into student (first_name, last_name, sid) values ('Tarrah', 'Repp', 330);
insert into student (first_name, last_name, sid) values ('Lucia', 'Ingram', 331);
insert into student (first_name, last_name, sid) values ('Emmalynn', 'Oboy', 332);
insert into student (first_name, last_name, sid) values ('Mathilde', 'Wigginton', 333);
insert into student (first_name, last_name, sid) values ('Hamil', 'Withey', 334);
insert into student (first_name, last_name, sid) values ('Quintus', 'Alcoran', 335);
insert into student (first_name, last_name, sid) values ('Levin', 'Gilardengo', 336);
insert into student (first_name, last_name, sid) values ('Juliana', 'Boydon', 337);
insert into student (first_name, last_name, sid) values ('Kelley', 'Iskowitz', 338);
insert into student (first_name, last_name, sid) values ('Gaye', 'Tart', 339);
insert into student (first_name, last_name, sid) values ('Pen', 'Mouan', 340);
insert into student (first_name, last_name, sid) values ('De witt', 'Sperring', 341);
insert into student (first_name, last_name, sid) values ('Corney', 'Wingrove', 342);
insert into student (first_name, last_name, sid) values ('Emmie', 'Dundon', 343);
insert into student (first_name, last_name, sid) values ('Nathanial', 'Dowson', 344);
insert into student (first_name, last_name, sid) values ('Robinson', 'Mundee', 345);
insert into student (first_name, last_name, sid) values ('Johnnie', 'Emanuelov', 346);
insert into student (first_name, last_name, sid) values ('Benton', 'Belmont', 347);
insert into student (first_name, last_name, sid) values ('Gayel', 'Swatridge', 348);
insert into student (first_name, last_name, sid) values ('Jerrilee', 'Dowdall', 349);
insert into student (first_name, last_name, sid) values ('Sam', 'Khidr', 350);
insert into student (first_name, last_name, sid) values ('Stacy', 'Scocroft', 351);
insert into student (first_name, last_name, sid) values ('Immanuel', 'Feldhorn', 352);
insert into student (first_name, last_name, sid) values ('Allissa', 'Fabry', 353);
insert into student (first_name, last_name, sid) values ('Gerry', 'Wharin', 354);
insert into student (first_name, last_name, sid) values ('Carmina', 'Seven', 355);
insert into student (first_name, last_name, sid) values ('Hammad', 'Gobel', 356);
insert into student (first_name, last_name, sid) values ('Marley', 'Kensington', 357);
insert into student (first_name, last_name, sid) values ('Devinne', 'Holttom', 358);
insert into student (first_name, last_name, sid) values ('Dalis', 'Woollett', 359);
insert into student (first_name, last_name, sid) values ('Valma', 'Fairlie', 360);
insert into student (first_name, last_name, sid) values ('Lorrie', 'Woliter', 361);
insert into student (first_name, last_name, sid) values ('Merridie', 'Cuthbertson', 362);
insert into student (first_name, last_name, sid) values ('Jack', 'Feasey', 363);
insert into student (first_name, last_name, sid) values ('Audre', 'Spary', 364);
insert into student (first_name, last_name, sid) values ('Noak', 'Letch', 365);
insert into student (first_name, last_name, sid) values ('Rock', 'Hakking', 366);
insert into student (first_name, last_name, sid) values ('Petrina', 'Frisch', 367);
insert into student (first_name, last_name, sid) values ('Lance', 'Songer', 368);
insert into student (first_name, last_name, sid) values ('Adore', 'Tomkowicz', 369);
insert into student (first_name, last_name, sid) values ('Teodora', 'Boice', 370);
insert into student (first_name, last_name, sid) values ('Adelice', 'Phant', 371);
insert into student (first_name, last_name, sid) values ('Stephie', 'Diwell', 372);
insert into student (first_name, last_name, sid) values ('Pollyanna', 'Barde', 373);
insert into student (first_name, last_name, sid) values ('Willyt', 'Sparkwill', 374);
insert into student (first_name, last_name, sid) values ('Link', 'Duthie', 375);
insert into student (first_name, last_name, sid) values ('Kiersten', 'Marsy', 376);
insert into student (first_name, last_name, sid) values ('Esma', 'Merman', 377);
insert into student (first_name, last_name, sid) values ('Phyllis', 'Carek', 378);
insert into student (first_name, last_name, sid) values ('Brade', 'Chazier', 379);
insert into student (first_name, last_name, sid) values ('Osbourn', 'Gullick', 380);
insert into student (first_name, last_name, sid) values ('Marybelle', 'Chilton', 381);
insert into student (first_name, last_name, sid) values ('Heriberto', 'Birtwisle', 382);
insert into student (first_name, last_name, sid) values ('Northrup', 'Castagnasso', 383);
insert into student (first_name, last_name, sid) values ('Cybil', 'Osman', 384);
commit;

-- ++++++++++++++++++++END OF INSERT STATEMENTS+++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- TEST CASES: 

call allotWing(1, 2, 0, 3, 81, 82, 83, 84, 86, 87, 88, 91);
call allotWing(2, 0, 3, 1, 85, 101, 102, 103, 104, 105, 10, 107);
call allotWing(3, 0, 1, 2, 1, 2, 45, 85, 76, 99, 106, 108);
call allotWing(0, 2, 1, 3, 200, 201, 3, 77, 78, 79, 100, 109);

select * from stu_room;

call swapRooms(78, 79);

select * from stu_room;

-- To delete a wing corresponding to the provided wing_id
-- call deleteWing(__); 
-- select * from stu_room;

-- ++++++++++++++++++++++++++ DELETE STATEMENTS ++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- To drop the entire database
-- drop database hostel_alloc
