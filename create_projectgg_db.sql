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
            INSERT INTO response VALUES ('TOKEN', token_id);
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
