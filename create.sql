 # (c) pooya woodcock 2002;
 #
 # nethack sql create table script

 drop table users;
 create table users (
         username varchar(20) not null,
         password varchar(20) not null,
         index user_ind(username),
         primary key (username)
         )
         type = innodb;

 drop table playback;
 create table playback (
         playback_id int(5) not null auto_increment,
         child_username varchar(20) not null,
         playback_file varchar(32) unique not null,
         index play_ind (child_username),
         primary key (playback_id),
         foreign key (child_username) references users(username)
         on delete set null)
         type = innodb;

 drop table options;
 create table options (
         opt_id int(5) not null auto_increment,
         name varchar(20) unique not null,
         definition varchar(250),
         compound bool not null,
         index play_ind (opt_id, name),
         primary key (opt_id, name)
         ) type = innodb;

 drop table user_options;
 create table user_options (
         user_id int(10) not null auto_increment,
         username varchar(20) not null,
         name varchar(20) not null,
         value varchar(250),
         index opt_ind_01(username),
         index opt_ind_02(name),
         primary key (user_id),
         foreign key (username) references users(username)
         on delete set null,
         foreign key (name) references options(name)
         on delete set null)
         type=innodb;
