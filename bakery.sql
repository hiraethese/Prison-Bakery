-- SQL script for creating basic objects of the database scheme
-- Task from the IUS project - Prison's bakery
--------------------------------------------------------------------------------
-- Author: Ilia Markelov <xmarke00@stud.fit.vutbr.cz>.
-- Author: Illia Baturov <xbatur00@stud.fit.vutbr.cz>.
-------------------------------- DROP ------------------------------------------

DROP TABLE "contains_pastry";
DROP TABLE "ingredient";
DROP TABLE "type_of_pastry";
DROP TABLE "item_in_pastry";
DROP TABLE "order";
DROP TABLE "courier";
DROP TABLE "warden";
DROP TABLE "shift";
DROP TABLE "prisoner";
DROP TABLE "prison";

-------------------------------- CREATE ----------------------------------------

CREATE TABLE "prison" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "address" VARCHAR(255) NOT NULL,
    "phone_number" VARCHAR(15) NOT NULL,
    "email" VARCHAR(255) NOT NULL
		CHECK(REGEXP_LIKE(
			"email", '^[a-z]+[a-z0-9.]*@[a-z0-9.-]+\.[a-z]{2,}$', 'i'
		)),
    "number_of_cells" SMALLINT NOT NULL,
    "number_of_prisoners" INT DEFAULT 0 NOT NULL
);

CREATE TABLE "prisoner" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"cell_number" INT NOT NULL,
	"cell_type" VARCHAR(255) NOT NULL
	            CHECK("cell_type" IN ('Low Security', 'Medium Security', 'High Security')),
	"name" VARCHAR(255) NOT NULL,
	"prison_id" INT NOT NULL,
    CONSTRAINT "prisoner_prison_id_fk"
                        FOREIGN KEY ("prison_id") REFERENCES "prison" ("id")
                        ON DELETE CASCADE
);

CREATE TABLE "shift" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "start_time" TIMESTAMP NOT NULL,
    "end_time" TIMESTAMP NOT NULL,
    "prison_id" INT NOT NULL,
    CONSTRAINT "shift_prison_id_fk"
                     FOREIGN KEY ("prison_id") REFERENCES "prison" ("id")
                     ON DELETE CASCADE
);

CREATE TABLE "warden" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "phone_number" VARCHAR(15) NOT NULL,
    "email" VARCHAR(255) NOT NULL
		CHECK(REGEXP_LIKE(
			"email", '^[a-z]+[a-z0-9.]*@[a-z0-9.-]+\.[a-z]{2,}$', 'i'
		)),
	"name" VARCHAR(255) NOT NULL,
	"shift_id" INT NOT NULL,
	CONSTRAINT "warden_shift_id_fk"
                     FOREIGN KEY ("shift_id") REFERENCES "shift" ("id")
                     ON DELETE CASCADE
);

--trigger to check if the name of warden have numbers
CREATE OR REPLACE TRIGGER non_alpha
    AFTER INSERT OR UPDATE ON "warden"
    FOR EACH ROW
    BEGIN
        IF REGEXP_LIKE(:new."name", '[0-9]+') THEN
            RAISE_APPLICATION_ERROR(-20000, 'Incorrect name format');
        END IF;
    END;

CREATE TABLE "courier" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "phone_number" VARCHAR(15) NOT NULL,
    "email" VARCHAR(255) NOT NULL
		CHECK(REGEXP_LIKE(
			"email", '^[a-z]+[a-z0-9.]*@[a-z0-9.-]+\.[a-z]{2,}$', 'i'
		)),
	"name" VARCHAR(255),
	"warden_id" INT NOT NULL,
	CONSTRAINT "courier_warden_id_fk"
                     FOREIGN KEY ("warden_id") REFERENCES "warden" ("id")
                     ON DELETE CASCADE
);

CREATE TABLE "order" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "customer_name" VARCHAR(255) NOT NULL,
    "delivery_address" VARCHAR(255) NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "date_of_order" TIMESTAMP NOT NULL,
    "date_of_delivery" TIMESTAMP NOT NULL,
    "state" VARCHAR(255) NOT NULL
            CHECK ("state" IN ('Processing', 'Cooking', 'Ready to ship', 'Shipping', 'Delivered')),
    "prisoner_id" INT NOT NULL,
    CONSTRAINT "order_prisoner_id_fk"
                     FOREIGN KEY ("prisoner_id") REFERENCES "prisoner" ("id")
                     ON DELETE CASCADE,
    "courier_id" INT NOT NULL,
    CONSTRAINT "order_courier_id_fk"
                     FOREIGN KEY ("courier_id") REFERENCES "courier" ("id")
                     ON DELETE CASCADE
);

CREATE TABLE "item_in_pastry" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "mass" INT NOT NULL,
    "size" VARCHAR(255) NOT NULL
            CHECK ( REGEXP_LIKE("size", '^[0-9]+x[0-9]+ [a-zA-Z]+$', 'i') )
);

CREATE TABLE "type_of_pastry" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "name_of_type" VARCHAR(255) NOT NULL,
    "type_of_dough" VARCHAR(255) NOT NULL,
    "quantity_in_stock" INT NOT NULL,
    "quantity_of_ingredients" INT NOT NULL,
    "mass" INT NOT NULL,
    "cereal" VARCHAR2(20) DEFAULT NULL,
    -- Generalisation/specialization is implemented with the 3. variant of the
    -- structure transformation for generalisation/specialization
    "item_in_pastry_id" INT DEFAULT NULL,
    CONSTRAINT "type_of_pastry_item_in_pastry_id_fk"
                              FOREIGN KEY ("item_in_pastry_id") REFERENCES "item_in_pastry" ("id")
                              ON DELETE SET NULL
);

-- trigger for warning of low quantity in stock
CREATE OR REPLACE TRIGGER pastry_in_stock
    AFTER UPDATE OF "quantity_in_stock" ON "type_of_pastry"
    FOR EACH ROW
    BEGIN
        IF "quantity_in_stock" < 30 THEN
            DBMS_OUTPUT.PUT_LINE('Warn: the quantity of ' || "type_of_pastry"."name_of_type"
                                     || ' in stock is low.');
        END IF;
    END;

CREATE TABLE "contains_pastry" (
    "quantity" INT NOT NULL,
    "order_id" INT NOT NULL,
    CONSTRAINT "contains_pastry_order_id_fk"
                     FOREIGN KEY ("order_id") REFERENCES "order" ("id")
                     ON DELETE CASCADE,
    "type_of_pastry_id" INT NOT NULL,
    CONSTRAINT "contains_pastry_type_of_pastry_id_fk"
                     FOREIGN KEY ("type_of_pastry_id") REFERENCES "type_of_pastry" ("id")
                     ON DELETE CASCADE
);

CREATE TABLE "ingredient" (
    "id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "type" VARCHAR(255) NOT NULL,
    "quantity_in_stock" INT NOT NULL,
    "purchase_price" DECIMAL (10,2) NOT NULL,
    "allergens" VARCHAR(255) DEFAULT NULL,
    "type_of_pastry_id" INT NOT NULL,
    CONSTRAINT "ingredient_type_of_pastry_id_fk"
                     FOREIGN KEY ("type_of_pastry_id") REFERENCES "type_of_pastry" ("id")
                     ON DELETE CASCADE
);

-------------------------------- INSERT ----------------------------------------

INSERT INTO "prison" ("address", "phone_number", "email", "number_of_cells", "number_of_prisoners")
VALUES ('66462 Hrušovany U Brna, Václava Haňky 1833', '+420544098563', 'hrusovanyjail@jail.cz', 90, 316);
INSERT INTO "prison" ("address", "phone_number", "email", "number_of_cells", "number_of_prisoners")
VALUES ('75121 Prosenice, Československé legií 808', '+420732095161', 'prosenicejail@jail.cz', 50, 150);
INSERT INTO "prison" ("address", "phone_number", "email", "number_of_cells", "number_of_prisoners")
VALUES ('59401 Velké Mezirící, Luční 807', '+420563397960', 'meziricijail@jail.cz', 80, 239);

INSERT INTO "prisoner" ("cell_number", "cell_type", "name", "prison_id")
VALUES (106, 'Low Security', 'Dmitry Rogozhin', 1);
INSERT INTO "prisoner" ("cell_number", "cell_type", "name", "prison_id")
VALUES (212, 'Medium Security', 'Sergey Lavkov', 2);
INSERT INTO "prisoner" ("cell_number", "cell_type", "name", "prison_id")
VALUES (301, 'High Security', 'Vladimir Tutin', 3);

INSERT INTO "shift" ("start_time", "end_time", "prison_id")
VALUES (TIMESTAMP '2023-03-26 07:00:00.00', TIMESTAMP '2023-03-26 19:00:00.00', 1);
INSERT INTO "shift" ("start_time", "end_time", "prison_id")
VALUES (TIMESTAMP '2023-03-27 09:00:00.00', TIMESTAMP '2023-03-27 22:00:00.00', 2);
INSERT INTO "shift" ("start_time", "end_time", "prison_id")
VALUES (TIMESTAMP '2023-03-28 09:00:00.00', TIMESTAMP '2023-03-27 23:00:00.00', 3);

INSERT INTO "warden" ("phone_number", "email", "name", "shift_id")
VALUES ('+420772697230', 'lloyd896@gmail.com', 'Duncan Lloyd', 1);
INSERT INTO "warden" ("phone_number", "email", "name", "shift_id")
VALUES ('+420473819828', 'welshwelsh@gmail.com', 'Raymond Welsh', 2);
INSERT INTO "warden" ("phone_number", "email", "name", "shift_id")
VALUES ('+420371653057', 'grayyyooo@gmail.com', 'Troy Gray', 3);

INSERT INTO "courier" ("phone_number", "email", "name", "warden_id")
VALUES ('+420727337680', 'neonovvy2@gmail.com', 'Neo Patrick', 1);
INSERT INTO "courier" ("phone_number", "email", "name", "warden_id")
VALUES ('+420326854789', 'haneyhoney77@gmail.com', 'Ricardo Haney', 2);
INSERT INTO "courier" ("phone_number", "email", "name", "warden_id")
VALUES ('+420770835077', 'cameronii11@gmail.com', 'Aryan Cameron', 3);

INSERT INTO "order" ("customer_name", "delivery_address", "price", "date_of_order",
                     "date_of_delivery", "state","prisoner_id", "courier_id")
VALUES ('Dmitry Rogozhin', '66462 Hrušovany U Brna, Václava Haňky 1833', 180.00, TIMESTAMP '2023-03-26 08:00:00.00',
        TIMESTAMP '2023-03-27 12:00:00.00', 'Cooking', 1, 1);
INSERT INTO "order" ("customer_name", "delivery_address", "price", "date_of_order",
                     "date_of_delivery", "state", "prisoner_id", "courier_id")
VALUES ('Sergey Lavkov', '75121 Prosenice, Československé legií 808', 180.00, TIMESTAMP '2023-03-26 09:00:00.00',
        TIMESTAMP '2023-03-27 12:00:00.00', 'Ready to ship', 2, 2);
INSERT INTO "order" ("customer_name", "delivery_address", "price", "date_of_order",
                     "date_of_delivery", "state", "prisoner_id", "courier_id")
VALUES ('Vladimir Tutin', '59401 Velké Mezirící, Luční 807', 160.00, TIMESTAMP '2023-03-26 12:00:00.00',
        TIMESTAMP '2023-03-27 14:00:00.00', 'Delivered', 3, 3);

INSERT INTO "item_in_pastry" ("mass", "size")
VALUES (500, '5x10 cm');
INSERT INTO "item_in_pastry" ("mass", "size")
VALUES (800, '10x20 cm');
INSERT INTO "item_in_pastry" ("mass", "size")
VALUES (700, '10x10 cm');

INSERT INTO "type_of_pastry" ("name_of_type", "type_of_dough", "quantity_in_stock",
                              "quantity_of_ingredients", "mass", "cereal")
VALUES ('Сake', 'shortbread dough', 42, 16, 800, 'wheat');
INSERT INTO "type_of_pastry" ("name_of_type", "type_of_dough", "quantity_in_stock",
                              "quantity_of_ingredients", "mass", "cereal")
VALUES ('Loaf', 'yeast dough', 180, 8, 400, 'wheat');
INSERT INTO "type_of_pastry" ("name_of_type", "type_of_dough", "quantity_in_stock",
                              "quantity_of_ingredients", "mass", "cereal", "item_in_pastry_id")
VALUES ('Hot Dog', 'yeast dough', 58, 12, 500, 'wheat', 2);

INSERT INTO "contains_pastry" ("quantity", "order_id", "type_of_pastry_id")
VALUES (10, 1, 1);
INSERT INTO "contains_pastry" ("quantity", "order_id", "type_of_pastry_id")
VALUES (20, 2, 2);
INSERT INTO "contains_pastry" ("quantity", "order_id", "type_of_pastry_id")
VALUES (30, 3, 3);

INSERT INTO "ingredient" ("type", "quantity_in_stock", "purchase_price", "allergens", "type_of_pastry_id")
VALUES ('wheat flour', 80, 30, 'gluten', 2);
INSERT INTO "ingredient" ("type", "quantity_in_stock", "purchase_price", "allergens", "type_of_pastry_id")
VALUES ('butter', 40, 50, NULL, 1);
INSERT INTO "ingredient" ("type", "quantity_in_stock", "purchase_price", "allergens", "type_of_pastry_id")
VALUES ('egg', 160, 20, NULL, 1);

-------------------------------- SELECT ----------------------------------------

-- Write all prisoners from the prison in Hrusovany U Brna
-- Joining two tables (1)
SELECT "prisoner"."name" as "prisoner_name"
FROM "prisoner"
JOIN "prison" on "prison"."id" = "prisoner"."prison_id"
WHERE "prison"."address" = '66462 Hrušovany U Brna, Václava Haňky 1833'
ORDER BY "prisoner_name";

-- Write names and phone numbers of all wardens who work after 20:00, 3/27/2023
-- Joining two tables (2)
SELECT
        "warden"."name" AS "warden_name",
        "warden"."phone_number" AS "warden_phone"
FROM "warden"
JOIN "shift" ON "shift"."id" = "warden"."shift_id"
WHERE "shift"."end_time" > TIMESTAMP '2023-03-27 20:00:00.00'
ORDER BY "warden_name";

-- Write all items in pastry which has egg as an ingredient
-- Joining three tables (1)
SELECT
        "item_in_pastry"."id" as "item_id",
        "item_in_pastry"."mass" as "item_mass",
        "item_in_pastry"."size" as "item_size"
FROM "item_in_pastry"
JOIN "type_of_pastry" ON "item_in_pastry"."id" = "type_of_pastry"."item_in_pastry_id"
JOIN "ingredient" ON "type_of_pastry"."id" = "ingredient"."type_of_pastry_id"
WHERE "ingredient"."type" = 'egg'
ORDER BY "item_id";

-- Show the count of orders for each prisoner
-- Group by (1)
SELECT
        "prisoner"."name" as "prisoner_name",
        COUNT("order"."id") as "number_of_orders"
FROM "order", "prisoner"
WHERE "order"."prisoner_id" = "prisoner"."id"
GROUP BY "prisoner"."id", "prisoner"."name"
ORDER BY "prisoner_name";

-- Show the number of couriers who deal with each warden
-- Group by (2)
SELECT
        "warden"."name" as "warden_name",
        COUNT("courier"."id") as "number_of_couriers"
FROM "courier", "warden"
WHERE "courier"."warden_id" = "warden"."id"
GROUP BY "warden"."id", "warden"."name"
ORDER BY "warden_name";

-- Write all names of customers who ordered pastry that contain the item,
-- as well as the type and quantity of baked goods
-- Exists (1)
SELECT
        "order"."customer_name" as "customer",
        "type_of_pastry"."name_of_type" as "pastry",
        "contains_pastry"."quantity" as "amount"
FROM "order", "type_of_pastry", "contains_pastry"
WHERE "contains_pastry"."order_id" = "order"."id"
AND "contains_pastry"."type_of_pastry_id" = "type_of_pastry"."id"
AND EXISTS (
        SELECT *
        FROM "item_in_pastry"
        WHERE "type_of_pastry"."item_in_pastry_id" = "item_in_pastry"."id"
)
ORDER BY "customer";

-- Write all ingredients for wheat baking,
-- where each ingredient contains allergens
-- In (1)
SELECT
    "ingredient"."type" as "ingredient",
    "ingredient"."allergens" as "allergens",
    "type_of_pastry"."name_of_type" as "pastry"
FROM "ingredient", "type_of_pastry"
WHERE "type_of_pastry"."cereal" = 'wheat'
AND "ingredient"."type_of_pastry_id" = "type_of_pastry"."id"
AND "ingredient"."id" IN (
        SELECT "ingredient"."id"
        FROM "ingredient"
        WHERE "ingredient"."allergens" IS NOT NULL
)
ORDER BY "pastry";


------------------------------ WITH AND SELECT ---------------------------------------

-- WITH creates a table called order_summary that aggregates the total mass of all pastries in each order.
-- Then, SELECT selects the order id, customer name and delivery date from created table,
-- along with a calculated column order_size that uses the CASE operator
-- to categorize each order based on its total mass.

-- With and select
WITH "order_summary" AS (
    SELECT o."id", o."customer_name", o."date_of_delivery", SUM(tp."mass" * cp."quantity") AS "total_mass"
    FROM "order" o
    JOIN "contains_pastry" cp ON o."id" = cp."order_id"
    JOIN "type_of_pastry" tp ON cp."type_of_pastry_id" = tp."id"
    GROUP BY o."id", o."customer_name", o."date_of_delivery"
)
SELECT os."id", os."customer_name", os."date_of_delivery",
    CASE
        WHEN os."total_mass" >= 10000 THEN 'Large Order'
        WHEN os."total_mass" >= 5000 THEN 'Medium Order'
        ELSE 'Small Order'
    END AS "order_size"
FROM "order_summary" os
ORDER BY os."id"


----------------------------- EXPLAIN PLANS -----------------------------------

-- without indexes
-- number of orders each prisoner
EXPLAIN PLAN FOR
    SELECT "prisoner"."id", COUNT("order"."id") AS order_count
    FROM "prisoner"
    JOIN "order" ON "prisoner"."id" = "order"."prisoner_id"
    GROUP BY "prisoner"."id";

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

--with indexes
CREATE INDEX i_prisoner ON "prisoner"("id", "name");

EXPLAIN PLAN FOR
    SELECT "prisoner"."id", COUNT("order"."id") AS order_count
    FROM "prisoner"
    JOIN "order" ON "prisoner"."id" = "order"."prisoner_id"
    GROUP BY "prisoner"."id";

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

DROP INDEX i_prisoner;

--------------------------------------------------------------------------------
-------------------- TRIGGERS ARE ON LINES 70 AND 136 --------------------------
--------------------------------------------------------------------------------

------------------------------ PROCEDURE ---------------------------------------

--- First procedure ---

-- This procedure writes out the total number of items in pastry,
-- and also calculates the average weight of the item in pastry
-- and rounds it up to three decimal places.

CREATE OR REPLACE PROCEDURE "number_of_items_and_average_weight"
AS
    "num_items" NUMBER;
    "items_sum_weight" NUMBER;
  "item_average_weight" NUMBER;
BEGIN
  SELECT SUM("mass") INTO "items_sum_weight" FROM "item_in_pastry";
  SELECT COUNT(*) INTO "num_items" FROM "item_in_pastry";
  "item_average_weight" := "items_sum_weight" / "num_items";
  DBMS_OUTPUT.PUT_LINE('Amount of items in pastry: ' || "num_items" ||
                       ', average mass of item in pastry: ' || TO_CHAR("item_average_weight", 'FM999999999.999'));
  EXCEPTION WHEN ZERO_DIVIDE THEN
  BEGIN
    IF "num_items" = 0 THEN
      DBMS_OUTPUT.put_line('There are no items!');
    END IF;
  END;
END;

--- Second procedure ---

-- This procedure writes out the list of wardens assigned to a specific prison by their email address,
-- it uses a cursor to loop over the wardens and a variable with the "warden"%ROWTYPE data type
-- to store the current warden's record.

CREATE OR REPLACE PROCEDURE "get_wardens_by_prison_email"(p_email IN VARCHAR2) AS
    w_cursor SYS_REFCURSOR;
    w_record "warden"%ROWTYPE;
BEGIN
    OPEN w_cursor FOR
        SELECT w.*
        FROM "warden" w
        INNER JOIN "shift" s ON w."shift_id" = s."id"
        INNER JOIN "prison" p ON s."prison_id" = p."id"
        WHERE p."email" = p_email;
    LOOP
        FETCH w_cursor INTO w_record;
        EXIT WHEN w_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Warden name: ' || w_record."name" ||
                             ', email: ' || w_record."email");
    END LOOP;
    CLOSE w_cursor;
END;

--- Start first procedure
BEGIN
    "number_of_items_and_average_weight";
END;

--- Start second procedure
BEGIN
    "get_wardens_by_prison_email"('hrusovanyjail@jail.cz');
END;


------------------------------ MATERIALIZED VIEWS ------------------------------

CREATE MATERIALIZED VIEW LOG ON "warden" WITH PRIMARY KEY, ROWID;
CREATE MATERIALIZED VIEW LOG ON "courier" WITH PRIMARY KEY, ROWID;

DROP MATERIALIZED VIEW ingredients_in_pastry;

--How many ingredients are in each type of pastry
CREATE MATERIALIZED VIEW ingredients_in_pastry
NOLOGGING
CACHE
BUILD IMMEDIATE
AS SELECT "ingredient"."id" as ingredient_id, COUNT(*)
    FROM "ingredient" JOIN "type_of_pastry" on "ingredient"."type_of_pastry_id" = "type_of_pastry"."id"
    GROUP BY "ingredient"."id"

SELECT * FROM ingredients_in_pastry;


----------------------------- ACCESS RIGHTS -----------------------------------

GRANT ALL ON "prison" TO xbatur00;
GRANT ALL ON "prisoner" TO xbatur00;
GRANT ALL ON "shift" TO xbatur00;
GRANT ALL ON "warden" TO xbatur00;
GRANT ALL ON "courier" TO xbatur00;
GRANT ALL ON "order" TO xbatur00;
GRANT ALL ON "item_in_pastry" TO xbatur00;
GRANT ALL ON "contains_pastry" TO xbatur00;
GRANT ALL ON "ingredient" TO xbatur00;

GRANT ALL ON ingredients_in_pastry TO xbatur00;
GRANT EXECUTE ON "number_of_items_and_average_weight" TO xbatur00;
GRANT EXECUTE ON "get_wardens_by_prison_email" TO xbatur00;
