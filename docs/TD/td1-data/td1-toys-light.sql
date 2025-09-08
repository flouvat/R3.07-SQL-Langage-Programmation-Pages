-- Drop tables if they exist
DROP TABLE IF EXISTS buy;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS manufacturer;
DROP TABLE IF EXISTS manufactures;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS supplies;

-- Create tables
CREATE TABLE product (
    pid integer NOT NULL,
    name text,
    min_age integer,
    price integer
);

CREATE TABLE inventory (
    pid integer,
    stock integer
);

CREATE TABLE supplier (
    sid integer,
    name character varying(150),
    address character varying(150)
);

CREATE TABLE supplies (
    sid integer,
    pid integer,
    prices integer
);

CREATE TABLE client (
    cid integer,
    name character varying(50)
);

CREATE TABLE manufacturer (
    mid integer,
    name character varying(30),
    address character varying(50)
);

CREATE TABLE manufactures (
    mid integer,
    pid integer
);

CREATE TABLE buy (
    pid integer,
    sid integer,
    cid integer,
    deleveryadress character varying(150),
    qty integer,
    datecde date
);

-- Insert data
INSERT INTO product (pid, name, min_age, price) VALUES
(1, 'Toy Car', 3, 20),
(2, 'Doll', 4, 15),
(3, 'Puzzle', 5, 25),
(4, 'Lego Set', 6, 50),
(5, 'Action Figure', 7, 30),
(6, 'Board Game', 8, 40),
(7, 'Stuffed Animal', 3, 10),
(8, 'Art Kit', 5, 35),
(9, 'Building Blocks', 4, 20),
(10, 'Remote Control Car', 6, 60),
(11, 'Educational Toy', 5, 45),
(12, 'Outdoor Game', 7, 55);

INSERT INTO inventory (pid, stock) VALUES
(1, 25),
(2, 30),
(3, 15),
(4, 40),
(5, 20),
(6, 50),
(7, 10),
(8, 35),
(9, 25),
(10, 60),
(11, 45),
(12, 55);

INSERT INTO supplier (sid, name, address) VALUES
(101, 'Supplier A', '123 Main St'),
(102, 'Supplier B', '456 Oak Ave'),
(103, 'Supplier C', '789 Pine Rd'),
(104, 'Supplier D', '321 Elm Blvd'),
(105, 'Supplier E', '654 Maple Ln'),
(106, 'Supplier F', '987 Cedar Dr'),
(107, 'Supplier G', '000 Tree St');

INSERT INTO supplies (sid, pid, prices) VALUES
(101, 1, 15),
(102, 2, 10),
(103, 3, 20),
(104, 4, 45),
(105, 5, 25),
(106, 6, 35),
(101, 7, 8),
(102, 8, 30),
(103, 9, 18),
(104, 10, 55),
(105, 11, 40),
(106, 12, 50);

INSERT INTO client (cid, name) VALUES
(1, 'Client A'),
(2, 'Client B'),
(3, 'Client C'),
(4, 'Client D'),
(5, 'Client E'),
(6, 'Client F'),
(7, 'Client G'),
(8, 'Client H'),
(9, 'Client I'),
(10, 'Client J');

INSERT INTO manufacturer (mid, name, address) VALUES
(1, 'Manufacturer X', '100 Factory Rd'),
(2, 'Manufacturer Y', '200 Industry Blvd'),
(3, 'Manufacturer Z', '300 Production Ave');

INSERT INTO manufactures (mid, pid) VALUES
(1, 1),
(1, 2),
(2, 3),
(2, 4),
(3, 5),
(3, 6),
(1, 7),
(2, 8),
(3, 9),
(1, 10),
(2, 11),
(3, 12);

INSERT INTO buy (pid, sid, cid, deleveryadress, qty, datecde) VALUES
(1, 101, 1, '123 Paris St', 2, '2023-01-15'),
(2, 102, 2, '456 Lyon Ave', 3, '2023-02-20'),
(3, 103, 3, '789 Marseille Rd', 1, '2023-03-10'),
(4, 104, 4, '321 Bordeaux Blvd', 4, '2023-04-05'),
(5, 105, 5, '654 Toulouse Ln', 2, '2023-05-12'),
(6, 106, 6, '987 Nice Dr', 5, '2023-06-18'),
(7, 101, 7, '123 Paris St', 1, '2023-07-22'),
(8, 102, 8, '456 Lyon Ave', 3, '2023-08-30'),
(9, 103, 9, '789 Marseille Rd', 2, '2023-09-14'),
(10, 104, 10, '321 Bordeaux Blvd', 4, '2023-10-25'),
(1, 105, 1, '654 Toulouse Ln', 2, '2023-11-08'),
(2, 106, 2, '987 Nice Dr', 3, '2023-12-19');
