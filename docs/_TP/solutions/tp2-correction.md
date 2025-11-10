---
layout: post
title: "TP 2 -- Solutions"
categories: jekyll update

mathjax: true
---

# TP 2 -- Contraindre les données et automatiser des traitements

### Analyse de la base de données 

```sql
-- Informations sur les colonnes
SELECT table_name, column_name, column_default, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name IN ('products', 'customers', 'categories', 'inventory', 'orderlines', 'orders', 'reorder');

-- Clés étrangères existantes
SELECT tc.constraint_name, tc.table_name, kcu.column_name, 
       ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name 
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name 
WHERE constraint_type = 'FOREIGN KEY';

```

### Définition de contraintes et de triggers


#### 1.	"Une même commande ne peut être constituée de deux lignes associées au même produit."

```sql
-- Nettoyer les doublons existants
DELETE o1 FROM orderlines o1
INNER JOIN orderlines o2 
WHERE o1.ctid > o2.ctid 
  AND o1.orderid = o2.orderid 
  AND o1.prodid = o2.prodid;


-- Ajouter la contrainte d'unicité
ALTER TABLE orderlines 
ADD CONSTRAINT orderlines_unique_produit UNIQUE (orderid, prodid);
```

Test de la contrainte :
```sql
-- Test positif (OK) : insertion de deux lignes de commande pour des produits différents et une même commande
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (1, 3001, 2, NOW());
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (1, 3002, 1, NOW());

-- Test négatif (ERREUR attendue) : même commande, même produit
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (1, 3001, 4, NOW());
-- Erreur : duplicate key value violates unique constraint "orderlines_unique_produit"
```

####  2.	"Une commande est nécessairement associée à un client. Si le client est supprimé, toutes ses commandes sont supprimées (et par extension toutes les lignes de ces commandes aussi)". Que se passe-t-il si une commande est insérée avec un mauvais numéro de client ?

```sql
ALTER TABLE orders 
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customerid) REFERENCES customers(customerid) 
ON DELETE CASCADE;

ALTER TABLE orderlines 
ADD CONSTRAINT fk_orderlines_order 
FOREIGN KEY (orderid) REFERENCES orders(orderid) 
ON DELETE CASCADE;
```

Test de la contrainte :
```sql
-- Test négatif : insertion d'une commande avec un client inexistant
INSERT INTO orders (orderid, orderdate, customerid, tax, netamount, totalamount) VALUES (9999, NOW(), 123456, 10, 50, 55);
-- ERREUR : violation de la contrainte de clé étrangère

-- Test positif : suppression d'un client supprime ses commandes et leurs lignes
INSERT INTO customers (customerid, firstname, lastname, age, email, creditcard) VALUES (8888, 'Doe', 'Jane', 45, 'jane@doe.com', '1111222233334444');
INSERT INTO orders (orderid, orderdate, customerid, tax, netamount, totalamount) VALUES (8800, NOW(), 8888, 10, 100, 110);
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (8800, 3003, 2, NOW());
DELETE FROM customers WHERE customerid = 8888;
-- Les lignes dans orders et orderlines associées à ce client sont effacées automatiquement
```


#### 3.	"L'identifiant d'une ligne d'une commande est unique et non null."

```sql

-- Ajouter la contrainte de clé primaire (qui garantit l'unicité)
ALTER TABLE orderlines ADD PRIMARY KEY (orderlineid);

-- Optionnel : créer une séquence pour l'auto-incrémentation si elle n'existe pas
CREATE SEQUENCE IF NOT EXISTS orderlines_seq START 1;
ALTER TABLE orderlines ALTER COLUMN orderlineid SET DEFAULT nextval('orderlines_seq');
```

Test de la contrainte :
```sql
-- Test négatif 1 : tentative d'insertion avec orderlineid NULL
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate) 
VALUES (NULL, 2, 3003, 1, NOW());
-- ERREUR attendue : violation de contrainte NOT NULL

-- Test négatif 2 : tentative d'insertion avec orderlineid en doublon
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate) 
VALUES (1, 2, 3004, 1, NOW());
-- ERREUR attendue : violation de contrainte de clé primaire

-- Test positif 1 : insertion sans spécifier orderlineid (utilise la valeur par défaut)
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) 
VALUES (2, 3005, 2, NOW());
-- OK : orderlineid généré automatiquement

-- Test positif 2 : insertion avec orderlineid explicite et unique
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate) 
VALUES ((SELECT MAX(orderlineid) + 1 FROM orderlines), 2, 3006, 1, NOW());
-- OK : orderlineid explicite et unique

-- Vérification : aucun doublon dans orderlineid
SELECT orderlineid, COUNT(*) 
FROM orderlines 
GROUP BY orderlineid 
HAVING COUNT(*) > 1;
-- Résultat attendu : aucune ligne (pas de doublons)
```

####  4. "Une demande de réapprovisionnement est nécessairement associée à un produit référencé (dans products). Il est impossible de supprimer un produit si celui-ci est en cours de réapprovisionnement."

```sql
ALTER TABLE reorder 
ADD CONSTRAINT fk_reorder_product 
FOREIGN KEY (prodid) REFERENCES products(prodid) 
ON DELETE RESTRICT;
```

Test de la contrainte :
```sql
-- Test positif : insertion avec un produit qui existe
INSERT INTO reorder (prodid, datelow, quanlow) VALUES (3001, NOW(), 10);

-- Test négatif : suppression d'un produit en cours de réapprovisionnement
DELETE FROM products WHERE prodid = 3001;
-- ERREUR : violation de la contrainte de clé étrangère
```

#### 5. "L'âge des clients est nécessairement supérieur à zéro. Leur adresse mail est composée d'un "@" et d'un point. Leur numéro de carte de crédit est composé de 16 chiffres."

```sql
ALTER TABLE customers 
ADD CONSTRAINT chk_age CHECK (age > 0);

ALTER TABLE customers 
ADD CONSTRAINT chk_email CHECK (email LIKE '%@%.%');

ALTER TABLE customers 
ADD CONSTRAINT chk_creditcard CHECK (char_length(creditcard) = 16 AND creditcard ~ '^[0-9]{16}$');
```

Test des contraintes :
```sql
-- Tests négatifs
INSERT INTO customers (customerid, firstname, lastname, age, email, creditcard) VALUES (9001, 'Test', 'Zero', 0, 'test@email.com', '1234567890123456');          -- ERREUR : âge
INSERT INTO customers (customerid, firstname, lastname, age, email, creditcard) VALUES (9002, 'Test', 'Mail', 30, 'testemail.com', '1234567890123456');         -- ERREUR : email
INSERT INTO customers (customerid, firstname, lastname, age, email, creditcard) VALUES (9003, 'Test', 'Card', 30, 'mail@test.com', '123456789012345');         -- ERREUR : carte (15 chiffres)

-- Test positif
INSERT INTO customers (customerid, firstname, lastname, age, email, creditcard) VALUES (9004, 'Valid', 'User', 28, 'valid@mail.com', '1234567890123456');      -- OK
```

#### 6. "Pour chaque nouvelle commande, l'historique des commandes (cust_hist) doit être automatiquement mis à jour."

```sql
CREATE OR REPLACE FUNCTION update_cust_hist() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO cust_hist (customerid, orderid, prodid)
    SELECT o.customerid, n.orderid, n.prodid
    FROM orders o, (SELECT NEW.*) n
    WHERE o.orderid = n.orderid;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_cust_hist
    AFTER INSERT ON orderlines
    FOR EACH ROW EXECUTE PROCEDURE update_cust_hist();
```

Test du mécanisme :
```sql
-- Test positif : insertion d'une nouvelle ligne de commande, vérification dans cust_hist
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (2, 3003, 2, NOW());

SELECT * FROM cust_hist WHERE orderid = 2 AND prodid = 3003;
```

#### 7. "Pour chaque nouvelle commande, le montant total net (netamount) de la commande, et le montant avec les taxes (totalamount), devront être automatiquement renseignés (si ces informations ne sont pas précisées au moment de l'enregistrement de la commande)."

```sql
CREATE OR REPLACE FUNCTION calculate_order_amounts() RETURNS TRIGGER AS $$
DECLARE
    total_price NUMERIC;
    tax_rate NUMERIC := 0.0825;
BEGIN
    SELECT SUM(ol.quantity * p.price) INTO total_price
    FROM orderlines ol, products p
    WHERE ol.prodid = p.prodid AND ol.orderid = NEW.orderid;
    
    UPDATE orders 
    SET netamount = COALESCE(total_price, 0),
        totalamount = COALESCE(total_price, 0) * (1 + tax_rate)
    WHERE orderid = NEW.orderid
    AND (netamount IS NULL OR totalamount IS NULL);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_amounts
    AFTER INSERT ON orderlines
    FOR EACH ROW EXECUTE PROCEDURE calculate_order_amounts();
```

Test du mécanisme :
```sql
-- Test positif : Insérer nouvelle orderline, vérifier calcul
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (3, 3002, 2, NOW());

SELECT netamount, totalamount FROM orders WHERE orderid = 3;

-- Test négatif : commande sans orderline (montants non calculés)
INSERT INTO orders (orderid, orderdate, customerid, tax) VALUES (33, NOW(), 1, 8.25);

SELECT netamount, totalamount FROM orders WHERE orderid = 33; -- NULL attendu
```

#### 8. "Pour chaque produit commandé, il faudra mettre à jour le nombre total de ventes associées à ce produit (champ sales de inventory)."

```sql
CREATE OR REPLACE FUNCTION update_product_sales() RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory 
    SET sales = sales + NEW.quantity
    WHERE prodid = NEW.prodid;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_sales
    AFTER INSERT ON orderlines
    FOR EACH ROW EXECUTE PROCEDURE update_product_sales();
```

Test du mécanisme :
```sql
-- Test positif : vérifier l'évolution de sales
SELECT sales FROM inventory WHERE prodid = 3001;

INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (4, 3001, 2, NOW());

SELECT sales FROM inventory WHERE prodid = 3001; -- Doit avoir augmenté de 2
```

#### 9. "Il est impossible de commander un produit si la quantité en stock est insuffisante (prendre aussi en compte les commandes en cours des autres clients)."

```sql
CREATE OR REPLACE FUNCTION check_stock_availability() RETURNS TRIGGER AS $$
DECLARE
    stock_disponible INTEGER;
    commandes_en_cours INTEGER;
BEGIN
    SELECT quan_in_stock INTO stock_disponible FROM inventory WHERE prodid = NEW.prodid;
    SELECT COALESCE(SUM(quantity), 0) INTO commandes_en_cours FROM orderlines WHERE prodid = NEW.prodid;
    IF stock_disponible < (commandes_en_cours + NEW.quantity) THEN
        RAISE EXCEPTION 'Stock insuffisant pour le produit %!', NEW.prodid;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_stock
    BEFORE INSERT ON orderlines
    FOR EACH ROW EXECUTE PROCEDURE check_stock_availability();
```

Test de la contrainte :
```sql
-- Test positif : commande possible si stock suffisant
-- (suppose que le stock de prodid=3001 est au moins 1)
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (5, 3001, 1, NOW());

-- Test négatif : commande impossible si stock dépassé
INSERT INTO orderlines (orderid, prodid, quantity, orderdate) VALUES (5, 3001, 100000, NOW());
-- ERREUR attendue
```

10. "Un client ne peut pas avoir la même adresse email qu'un autre client."

```sql
ALTER TABLE customers
ADD CONSTRAINT unique_email UNIQUE (email);
```

Test de la contrainte :
```sql
-- Insertion valide
INSERT INTO customers (firstname, lastname, email, phone, username, password, address1, city, state, zip, country, region, creditcardtype, creditcard, creditcardexpiration, age, income, gender)
VALUES ('Alice', 'Martin', 'alice@example.com', '0102030405', 'alicem', 'pass', '1 rue A', 'Paris', 'IDF', '75000', 'France', 1, 1234567890123456, '12/27', 30, 30000, 'F');
-- Insertion avec email déjà utilisé (doit échouer)
INSERT INTO customers (firstname, lastname, email, phone, username, password, address1, city, state, zip, country, region, creditcardtype, creditcard, creditcardexpiration, age, income, gender)
VALUES ('Bob', 'Durand', 'alice@example.com', '0102030406', 'bobd', 'pass', '2 rue B', 'Lyon', 'ARA', '69000', 'France', 2, 1234567890123457, '11/28', 25, 25000, 'M');

```

11. "Une commande ne peut pas contenir plus de 100 unités d'un même produit."

```sql
ALTER TABLE orderlines
ADD CONSTRAINT max_quantity_per_line CHECK (quantity <= 100);
```

Test de la contrainte :
```sql
-- Insertion valide
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate)
VALUES (1, 1, 1, 50, '2025-10-05');
-- Insertion dépassant le plafond (doit échouer)
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate)
VALUES (2, 1, 1, 150, '2025-10-05');
```

12.  "Permettre la suppression d'un client tout en conservant ses commandes, mais en mettant le champ customerid à NULL dans orders"

```sql
ALTER TABLE orders
DROP CONSTRAINT IF EXISTS orders_customerid_fkey;
ALTER TABLE orders
ADD CONSTRAINT orders_customerid_fkey FOREIGN KEY (customerid)
REFERENCES customers(customerid)
ON DELETE SET NULL;
```

Test de la contrainte :
```sql
-- Créer un client et une commande
INSERT INTO customers (firstname, lastname, address1, city, country, region, email, phone, creditcardtype, creditcard, creditcardexpiration, username, password, age, income, gender)
VALUES ('Test', 'Client', '1 rue X', 'Marseille', 'France', 1, 'test@ex.com', '0101010101', 1, '1234', '12/30', 'testuser', 'pass', 30, 20000, 'M');
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount)
VALUES ('2025-10-05', currval('customers_customerid_seq'), 100, 20, 120);
-- Supprimer le client
DELETE FROM customers WHERE email = 'test@ex.com';
-- Vérifier que la commande existe toujours mais customerid est NULL
SELECT * FROM orders WHERE customerid IS NULL;
```

13. "Empêcher la commande de produits "spéciaux" par des clients de moins de 18 ans."

```sql
CREATE OR REPLACE FUNCTION forbid_special_for_minors() RETURNS TRIGGER AS $$
DECLARE
  is_special SMALLINT;
  client_age SMALLINT;
BEGIN
  SELECT special INTO is_special FROM products WHERE prodid = NEW.prodid;
  SELECT age INTO client_age FROM customers WHERE customerid = (SELECT customerid FROM orders WHERE orderid = NEW.orderid);
  IF is_special = 1 AND client_age < 18 THEN
    RAISE EXCEPTION 'Client mineur ne peut commander un produit spécial.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_forbid_special_for_minors
BEFORE INSERT ON orderlines
FOR EACH ROW
EXECUTE PROCEDURE forbid_special_for_minors();
```

Test de la contrainte :
```sql
-- Créer un client mineur et un produit spécial
INSERT INTO customers (firstname, lastname, address1, city, country, region, email, phone, creditcardtype, creditcard, creditcardexpiration, username, password, age, income, gender)
VALUES ('Jeune', 'Mineur', '2 rue Y', 'Lyon', 'France', 1, 'mineur@ex.com', '0101010102', 1, '5678', '11/29', 'minuser', 'pass', 16, 1000, 'F');
INSERT INTO products (category, title, actor, price, special, commonprodid)
VALUES (1, 'Film Interdit', 'Acteur Z', 20, 1, 1);
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount)
VALUES ('2025-10-05', currval('customers_customerid_seq'), 20, 4, 24);
-- Doit échouer :
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate)
VALUES (10, currval('orders_orderid_seq'), currval('products_prodid_seq'), 1, '2025-10-05');
```

14. "Mise à jour automatique du stock après la commande d'un nouveau produit."

```sql
CREATE OR REPLACE FUNCTION update_stock_after_order() RETURNS TRIGGER AS $$
BEGIN
  UPDATE inventory SET quaninstock = quaninstock - NEW.quantity WHERE prodid = NEW.prodid;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_stock_after_order
AFTER INSERT ON orderlines
FOR EACH ROW
EXECUTE PROCEDURE update_stock_after_order();
```

Test du mécanisme :
```sql
-- Stock initial
UPDATE inventory SET quaninstock = 10 WHERE prodid = 1;
-- Ajouter une commande
INSERT INTO orderlines (orderlineid, orderid, prodid, quantity, orderdate)
VALUES (20, 1, 1, 2, '2025-10-05');
-- Vérifier le stock
SELECT quaninstock FROM inventory WHERE prodid = 1;
```

15.  "Un client ne peut pas avoir plus de 3 commandes le même jour."

```sql
CREATE OR REPLACE FUNCTION limit_orders_per_day() RETURNS TRIGGER AS $$
DECLARE
  nb_orders INTEGER;
BEGIN
  SELECT COUNT(*) INTO nb_orders FROM orders WHERE customerid = NEW.customerid AND orderdate = NEW.orderdate;
  IF nb_orders >= 3 THEN
    RAISE EXCEPTION 'Limite de 3 commandes par jour dépassée pour ce client.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_limit_orders_per_day
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE PROCEDURE limit_orders_per_day();
```

Test de la contrainte :
```sql
-- Insérer 3 commandes pour le même client et jour
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-06', 1, 10, 2, 12);
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-06', 1, 20, 4, 24);
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-06', 1, 30, 6, 36);
-- 4e commande (doit échouer)
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-06', 1, 40, 8, 48);
```

16. "Historiser les changements de prix des produits."

```sql
CREATE TABLE product_price_history (
  histid SERIAL PRIMARY KEY,
  prodid INTEGER,
  old_price NUMERIC,
  new_price NUMERIC,
  changedate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_price_change() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.price <> OLD.price THEN
    INSERT INTO product_price_history (prodid, old_price, new_price)
    VALUES (NEW.prodid, OLD.price, NEW.price);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_price_change
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE PROCEDURE log_price_change();
```

Test du mécanisme :
```sql
-- Modifier le prix
UPDATE products SET price = price + 1 WHERE prodid = 1;
-- Vérifier l'historique
SELECT * FROM product_price_history WHERE prodid = 1;
```

17.  "Après chaque commande, si le total cumulé du client dépasse 1000€, enregistrer une alerte dans une table."

```sql
CREATE TABLE big_buyer_alerts (
  alertid SERIAL PRIMARY KEY,
  customerid INTEGER,
  total_orders NUMERIC,
  alertdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION alert_big_buyer() RETURNS TRIGGER AS $$
DECLARE
  total_orders NUMERIC;
BEGIN
  SELECT SUM(totalamount) INTO total_orders FROM orders WHERE customerid = NEW.customerid;
  IF total_orders > 1000 THEN
    INSERT INTO big_buyer_alerts (customerid, total_orders) VALUES (NEW.customerid, total_orders);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alert_big_buyer
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE PROCEDURE alert_big_buyer();
```

Test du mécanisme:
```sql
-- Ajouter des commandes pour dépasser 1000€
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-08', 1, 600, 120, 720);
INSERT INTO orders (orderdate, customerid, netamount, tax, totalamount) VALUES ('2025-10-08', 1, 400, 80, 480);
-- Vérifier l'alerte
SELECT * FROM big_buyer_alerts WHERE customerid = 1;
```