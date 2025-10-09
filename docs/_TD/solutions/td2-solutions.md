---
layout: post
title: "TD 2 -- Exemple de solutions"
categories: jekyll update

mathjax: true
---

# TD 2 -- Contraindre les données

### Définitions de clés


1.	Écrire une requête SQL permettant de modifier le schéma de Manufacturer afin de définir la clé primaire. 

```sql
ALTER TABLE manufacturer
ADD CONSTRAINT pkey_manufacturer PRIMARY KEY (mid);
```
Tests :

```sql
-- Cas valide : insérer un nouveau manufacturer avec id unique
INSERT INTO manufacturer(mid, name, address) VALUES (60, 'New Manufacturer', 'New Address');

-- Cas erreur : doublon mid (clé primaire) avec id 1 existant
INSERT INTO manufacturer(mid, name, address) VALUES (1, 'Duplicate Manufacturer', 'Address');
```


2.	Modifier le schéma de la relation Supplies afin de définir les clés primaire et étrangères. Vous utiliserez la politique de validation de contraintes en cascade.

```sql
ALTER TABLE supplies
ADD CONSTRAINT pkey_supplies PRIMARY KEY (sid, pid);

ALTER TABLE supplier
ADD CONSTRAINT pkey_supplier PRIMARY KEY (sid);

ALTER TABLE supplies
ADD CONSTRAINT fkey_supplies_sid FOREIGN KEY (sid) REFERENCES supplier(sid) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE supplies
ADD CONSTRAINT fkey_supplies_pid FOREIGN KEY (pid) REFERENCES product(pid) ON DELETE CASCADE ON UPDATE CASCADE;
```

Certaines données ne vérifient pas les contraintes. Il faut donc les corriger :
```sql
-- erreur déclenchée lors de la création de la clé primaire car des doublons existent déjà 
SELECT pid,sid FROM supplies
GROUP BY pid,sid
HAVING count(*) > 1 ; 


-- suppression des doublons en ne conservant que les tuples avec le prix le plus élevé
DELETE FROM supplies
WHERE (pid,sid, prices) NOT IN( 
	SELECT pid,sid, max(prices) FROM supplies
	GROUP BY pid,sid
	HAVING count(*) > 1
	UNION
	SELECT pid,sid, max(prices) FROM supplies
	GROUP BY pid,sid
	HAVING count(*) = 1 
	);

-- le tuple (66,171,18) apparaît deux fois et n'est pas supprimé par la requête précédente
SELECT pid,sid, prices
FROM supplies
WHERE pid = 66 AND sid = 171;

-- suppression des tuples en double en utilisant l'identifiant interne PostgreSQL "ctid"
DELETE FROM supplies s
USING supplies t
WHERE s.ctid > t.ctid
  AND s.sid = t.sid
  AND s.pid = t.pid
  AND s.prices = t.prices;

```


Tests des contraintes créées :
```sql
-- Cas valide : sid = 107 et pid = 12 existe
INSERT INTO supplies(sid, pid, prices) VALUES (107, 12, 45);

-- Cas erreur FK : sid inexistant
INSERT INTO supplies(sid, pid, prices) VALUES (999, 1, 50);

-- Cas erreur PK : doublon (sid, pid)
INSERT INTO supplies(sid, pid, prices) VALUES (101, 1, 15);
INSERT INTO supplies(sid, pid, prices) VALUES (101, 1, 20);
```

Si le code a été exécuté d'un seul bloc, la première insertion ne sera pas enregistrée à cause de l'erreur déclenchée par la deuxième (mécanisme d'annulation, ou "rollback", cf chapitre sur les transactions). 


3.	Que se passe-t-il si un utilisateur essaye de supprimer un produit dans Product déjà fournit par un fournisseur ?


Si on tente de supprimer un produit dans Product qui est déjà référencé dans la table supplies, la suppression échouera à moins que la contrainte de clé étrangère ait le ON DELETE CASCADE. Sans cela, la base de données empêchera la suppression pour préserver l’intégrité référentielle.


### Définition de contraintes sur les attributs, sur les tuples et entre des relations

1.	Définir une contrainte interdisant les valeurs négatives pour le stock des produits.

```sql
ALTER TABLE inventory
ADD CONSTRAINT chk_non_negative_stock CHECK (stock >= 0);
```

Tests de la contrainte créée :
```sql
-- Cas valide : stock à 25 pour pid 1
UPDATE inventory SET stock = 25 WHERE pid = 1;

-- Cas erreur : stock négatif
UPDATE inventory SET stock = -5 WHERE pid = 1;
```

2.	Définir une contrainte interdisant les commandes en quantité supérieur à 100 et dont l'adresse de livraison est dans un autre pays.

```sql
ALTER TABLE buy
ADD CONSTRAINT check_qty_delivery CHECK (
  NOT (qty > 100 AND deleveryAdress NOT LIKE '%France%')
);
```

Tests de la contrainte créée :
```sql
-- Cas valide : qty 100, adresse '123 Paris St' (en France)
INSERT INTO buy(pid, sid, cid, deleveryadress, qty, datecde)
VALUES (1, 101, 1, '123 Marseille St', 100, CURRENT_DATE);

-- Cas erreur : qty 101 hors France (exemple adresse Allemagne)
INSERT INTO buy(pid, sid, cid, deleveryadress, qty, datecde)
VALUES (1, 101, 1, 'Berlin, Allemagne', 101, CURRENT_DATE);
```


3.	Définir une contrainte interdisant que le nom d'un fournisseur soit identique à celui d'un fabricant.

```sql
ALTER TABLE supplier
ADD CONSTRAINT chk_supplier_manufacturer_diff CHECK (
  name NOT IN (SELECT name FROM manufacturer)
);
```

Cette requête déclenche une erreur car PostgreSQL n'accepte pas les sous-requêtes dans les contraintes de type "check". Il faudra donc utiliser un trigger pour l'implémenter. (voir la section "triggers")


4.	Définir une contrainte vérifiant que le nombre total de produits commandés reste bien inférieur à la quantité totale de produits en stock.

Cette contrainte complexe ne peut pas être directement imposée avec CHECK, il faut plutôt un trigger. (voir la section "triggers")


### Définition de déclencheurs (triggers) et de procédures stockées

1. Définir une contrainte interdisant que le nom d'un fournisseur soit identique à celui d'un fabricant.

```sql
CREATE OR REPLACE FUNCTION trg_chk_supplier_name_not_manufacturer()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS(SELECT * FROM manufacturer WHERE name = NEW.name) THEN
    RAISE EXCEPTION 'Le nom fournisseur ne peut pas être identique à un fabricant';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_chk_supplier_name
BEFORE INSERT OR UPDATE ON supplier
FOR EACH ROW EXECUTE PROCEDURE trg_chk_supplier_name_not_manufacturer();
```


Tests de la contrainte créée :
```sql
-- Cas valide : nom fournisseur unique
INSERT INTO supplier(sid, name, address) 
VALUES (300, 'Unique Supplier', 'Some Address');

-- Cas erreur : nom fournisseur identique à fabricant
INSERT INTO supplier(sid, name, address) 
VALUES (301, 'Atlas', 'Some Address');
```


2.	Définir une contrainte vérifiant que le nombre total de produits commandés reste bien inférieur à la quantité totale de produits en stock.

```sql
CREATE OR REPLACE FUNCTION trg_chk_stock_before_buy()
RETURNS TRIGGER AS $$
DECLARE
  total_ordered INTEGER;
  stock_available INTEGER;
BEGIN
  -- Récupérer le stock actuel du produit
  SELECT stock INTO stock_available FROM inventory WHERE pid = NEW.pid;

  -- Calculer la somme des quantités commandées existantes plus la nouvelle commande
  SELECT SUM(qty)
  INTO total_ordered
  FROM buy
  WHERE pid = NEW.pid;

  total_ordered := total_ordered + NEW.qty;

  IF total_ordered > stock_available THEN
    RAISE EXCEPTION 'Erreur : quantité commandée (%), dépasse le stock disponible (%) pour le produit %',
      total_ordered, stock_available, NEW.pid;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_chk_stock_before_buy
BEFORE INSERT OR UPDATE ON buy
FOR EACH ROW
EXECUTE PROCEDURE trg_chk_stock_before_buy();
```

Tests de la contrainte créée :
```sql
-- Cas valide : insérer plusieurs commandes dont la somme totale <= stock (488)
INSERT INTO buy(pid, sid, cid, deleveryAdress, qty, dateCde)
VALUES (4, 61, 1, '123 Paris St', 10, CURRENT_DATE);

INSERT INTO buy(pid, sid, cid, deleveryAdress, qty, dateCde)
VALUES (4, 61, 1, '123 Paris St', 500, CURRENT_DATE);

-- Somme commandes = 10 + 15 = 25

-- Cas erreur : insérer une commande qui ferait dépasser le stock (par ex., 1)
INSERT INTO buy(pid, sid, cid, deleveryAdress, qty, dateCde)
VALUES (1, 103, 3, '123 Paris St', 1, CURRENT_DATE);  -- Devrait lever une exception

-- Cas erreur : mise à jour d'une commande existante augmentant la quantité au-delà du stock
UPDATE buy
SET qty = 20
WHERE pid = 1 AND sid = 101 AND cid = 1;  -- Si dépassement, doit provoquer erreur
```


3.	Écrire un trigger qui fasse les traitements suivants: si la quantité d'un produit en stock devient zéro et qu'il n'y a plus de fournisseurs de ce produit, supprimer le produit des tables Product et Inventory.

```sql
CREATE OR REPLACE FUNCTION trg_del_product_when_no_stock_no_suppliers()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.stock = 0 THEN
    IF NOT EXISTS (SELECT pid FROM supplies WHERE pid = NEW.pid) THEN
      DELETE FROM product WHERE pid = NEW.pid;
      DELETE FROM inventory WHERE pid = NEW.pid;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_del_product_when_no_stock_no_suppliers
AFTER UPDATE ON inventory
FOR EACH ROW
WHEN (NEW.stock = 0)
EXECUTE PROCEDURE trg_del_product_when_no_stock_no_suppliers();
```

Tests du mécanisme mis en place :
```sql
-- Cas valide : pid 7 avec fournisseurs, stock à 0 ne supprime pas
UPDATE inventory SET stock = 0 WHERE pid = 7;

SELECT * FROM product WHERE pid = 7; -- Non vide

-- Cas erreur : insertion pid 600 dans inventory mais pas dans supplies, puis stock à 0 supprime produit
INSERT INTO inventory VALUES(600,10); 

SELECT * FROM product WHERE pid = 600; -- un tuple

UPDATE inventory SET stock = 0 WHERE pid = 600;

SELECT * FROM product WHERE pid = 600; -- Vide (supprimé)
```


4.	Interdire la vente d'un produit à perte (cad avec un prix inférieur au prix du fournisseur).

```sql
CREATE OR REPLACE FUNCTION trg_chk_price_not_below_supply()
RETURNS TRIGGER AS $$
DECLARE
  min_price_supply INTEGER;
BEGIN
  SELECT MIN(priceS) INTO min_price_supply
  FROM supplies
  WHERE pid = NEW.pid;

  IF NEW.price < min_price_supply THEN
    RAISE EXCEPTION 'Prix de vente % est inférieur au prix fournisseur minimum %', NEW.price, min_price_supply;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_chk_price_not_below_supply
BEFORE INSERT OR UPDATE ON product
FOR EACH ROW
EXECUTE PROCEDURE trg_chk_price_not_below_supply();
```

Tests de la contrainte créée :
```sql
-- Cas valide : prix produit à 20 supérieur au prix fournisseur (6)
UPDATE product SET price = 20 WHERE pid = 1;

-- Cas erreur : prix produit à 1 inférieur au prix fournisseur (6)
UPDATE product SET price = 1 WHERE pid = 1;
```

