drop database if exists projectgg_db;
create database projectgg_db;

drop user if exists 'dev'@'localhost';

use projectgg_db;

-- enable foreign key checks
set foreign_key_checks = 1;

-- drop tables if they exist
drop table if exists user_login;
drop table if exists user;
drop table if exists game;
drop table if exists game_collection;
drop table if exists collection_game;
drop table if exists review;
drop table if exists login_token;
drop table if exists friend;

-- create user login table
create table user_login (
    USER_ID int auto_increment primary key,
    USERNAME varchar(255) not null unique,
    PASS varchar(255) not null
);

-- create user table: username, user_ID Primary, PFP, about, favourite game (foreign) game_ID
create table user (
    USER_ID int,
    USERNAME varchar(255) not null,
    PFP varchar(255),
    ABOUT varchar(255),
    foreign key (USERNAME) references user_login(USERNAME),
    foreign key (USER_ID) references user_login(USER_ID)
);

-- create game table: GAME_ID primary, GAMENAME, ABOUT, RATING (floating point #)
create table game (
    GAME_ID int primary key,
    GAMENAME varchar(255) not null,
    GAMEPICTURE varchar(255),
    ABOUT varchar(255),
    RATING float
);

-- create game_collection table: CREATOR(foreign user_id), game_collection_ID primary
create table game_collection (
    COLLECTION_ID int primary key,
    CREATOR int,
    foreign key (CREATOR) references user(USER_ID)
);

-- create collection_game table: collection_id, game_id
create table collection_game (
    COLLECTION_ID int,
    GAME_ID int,
    foreign key (COLLECTION_ID) references game_collection(COLLECTION_ID),
    foreign key (GAME_ID) references game(GAME_ID)
);

-- create review table: REVIEW_ID primary, REVIEWER(foreign user_id), GAME(foreign game_id), REVIEW, RATING
create table review (
    REVIEW_ID int primary key,
    REVIEWER int,
    GAME int,
    REVIEW varchar(255),
    RATING float,
    foreign key (REVIEWER) references user(USER_ID),
    foreign key (GAME) references game(GAME_ID)
);

-- create login token table for user login, expires after 3 days
create table login_token (
    TOKEN varchar(255) primary key,
    USER_ID int,
    CREATED datetime,
    foreign key (USER_ID) references user(USER_ID)
);

-- create friend table: user_id, friend_id
create table friend (
    USER_ID int,
    FRIEND_ID int,
    foreign key (USER_ID) references user(USER_ID),
    foreign key (FRIEND_ID) references user(USER_ID)
);

create user 'dev'@'localhost' identified with mysql_native_password by 'password';

grant all privileges on projectgg_db.* to 'dev'@'localhost';

-- =================================================================================================
-- Functions Start Here
-- =================================================================================================

-- function to create a new user
delimiter //
create procedure create_user_login(
    in username varchar(255),
    in pass varchar(255)
)
BEGIN

    DECLARE usernameExists INT default 0;

    CREATE temporary table if not exists response (
        RESPONSE_STATUS varchar(255),
        RESPONSE_MESSAGE varchar(255)
    );

    SELECT COUNT(*) INTO usernameExists FROM user WHERE USERNAME = username;

    IF usernameExists > 0 THEN
        INSERT INTO response VALUES ('ERROR', 'Username already exists');
    ELSE
        -- create user login
        INSERT INTO user_login (USERNAME, pass) VALUES (username, pass);
        -- create user
        INSERT INTO user (USERNAME) VALUES (username);
        INSERT INTO response VALUES ('SUCCESS', 'User created');
    END IF;
    SELECT * FROM response;
    DROP temporary table response;
END //
delimiter ;


-- function to login (validate user)
delimiter //
create procedure login_user(
    in username varchar(255),
    in pass varchar(255)
)
BEGIN

    DECLARE userExists INT default 0;
    DECLARE passMatch INT default 0;
    DECLARE user_id INT;
    -- create id for token
    DECLARE token_id varchar(255);
    SET token_id = UUID();

    CREATE temporary table if not exists response (
        RESPONSE_STATUS varchar(255),
        RESPONSE_MESSAGE varchar(255)
    );

    SELECT COUNT(*) INTO userExists FROM user_login WHERE USERNAME = username;

    IF userExists = 0 THEN
        INSERT INTO response VALUES ('ERROR', 'User does not exist');
    ELSE
        SELECT USER_ID INTO user_id FROM user_login WHERE USERNAME = username;
        SELECT COUNT(*) INTO passMatch FROM user_login WHERE USERNAME = username AND PASS = pass;
        INSERT INTO login_token (TOKEN, USER_ID, CREATED) VALUES (token_id, user_id, NOW());
        IF passMatch = 0 THEN
            INSERT INTO response VALUES ('ERROR', 'Password does not match');
        ELSE
            INSERT INTO response VALUES ('SUCCESS', 'Login successful');
        END IF;
    END IF;
    SELECT * FROM response;
    DROP temporary table response;
END //

-- function to check token against current
delimiter //
create procedure check_token(
    in token varchar(255)
)
BEGIN
    -- if token given by front matches any in back, then return userID
    DECLARE tokenExists INT default 0;
    DECLARE user_id INT;

    CREATE temporary table if not exists response (
        RESPONSE_STATUS varchar(255),
        RESPONSE_MESSAGE varchar(255)
    );

    SELECT COUNT(*) INTO tokenExists FROM login_token WHERE TOKEN = token;

    IF tokenExists = 0 THEN
        INSERT INTO response VALUES ('ERROR', 'Token does not exist');
    ELSE
        SELECT USER_ID INTO user_id FROM login_token WHERE TOKEN = token;
        INSERT INTO response VALUES ('SUCCESS', user_id);
    END IF;

    SELECT * FROM response;
    DROP temporary table response;
END //









-- =================================================================================================
--                              Default Values Start Here
-- =================================================================================================

-- create default games (GTA V, Minecraft, Baldur's Gate 3, League of Legends)
insert into game (GAME_ID, GAMENAME, GAMEPICTURE, ABOUT, RATING) values (1, 'GTA V','https://i.imgur.com/nWX7DXX.jpeg' , 'Grand Theft Auto V is a 2013 action-adventure game developed by Rockstar North and published by Rockstar Games. It is the first main entry in the Grand Theft Auto series since 2008''s Grand Theft Auto IV.', 4.5);
insert into game (GAME_ID, GAMENAME, GAMEPICTURE, ABOUT, RATING) values (2, 'Minecraft', 'https://i.imgur.com/mih2p0Q.png', 'Minecraft is a sandbox video game developed by Mojang Studios. Created by Markus "Notch" Persson in the Java programming language and released as a public alpha for personal computers in 2009.', 4);
insert into game (GAME_ID, GAMENAME, GAMEPICTURE, ABOUT, RATING) values (3, 'Baldur''s Gate 3','https://i.imgur.com/aGWjGNl.png', 'Baldur''s Gate III is an upcoming role-playing video game that is being developed and published by Larian Studios. It is the third main game in the Baldur''s Gate series.', 5);
insert into game (GAME_ID, GAMENAME, GAMEPICTURE, ABOUT, RATING) values (4, 'League of Legends', 'https://i.imgur.com/xyGRxzZ.png','League of Legends is a multiplayer online battle arena video game developed and published by Riot Games for Microsoft Windows and macOS.', 3.9);

-- create default users (sam, tom, jerry, bob)
INSERT INTO user_login (USER_ID, USERNAME, PASS) VALUES (1, 'sam', 'password1');
INSERT INTO user_login (USER_ID, USERNAME, PASS) VALUES (2, 'tom', 'password2');
INSERT INTO user_login (USER_ID, USERNAME, PASS) VALUES (3, 'jerry', 'password3');
INSERT INTO user_login (USER_ID, USERNAME, PASS) VALUES (4, 'bob', 'password4');

INSERT INTO user (USER_ID, USERNAME) VALUES (1, 'sam');
INSERT INTO user (USER_ID, USERNAME) VALUES (2, 'tom');
INSERT INTO user (USER_ID, USERNAME) VALUES (3, 'jerry');
INSERT INTO user (USER_ID, USERNAME) VALUES (4, 'bob');

-- create default reviews (each of them have reviewed each of the games)
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (1, 1, 1, 'Great game', 4.5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (2, 1, 2, 'Good game', 4);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (3, 1, 3, 'Best game', 5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (4, 1, 4, 'Decent game', 3.9);

insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (5, 2, 1, 'Great game', 4.5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (6, 2, 2, 'Good game', 4);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (7, 2, 3, 'Best game', 5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (8, 2, 4, 'Decent game', 3.9);

insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (9, 3, 1, 'Great game', 4.5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (10, 3, 2, 'Good game', 4);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (11, 3, 3, 'Best game', 5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (12, 3, 4, 'Decent game', 3.9);

insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (13, 4, 1, 'Great game', 4.5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (14, 4, 2, 'Good game', 4);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (15, 4, 3, 'Best game', 5);
insert into review (REVIEW_ID, REVIEWER, GAME, REVIEW, RATING) values (16, 4, 4, 'Decent game', 3.9);




