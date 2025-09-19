---
layout: post
title: "TP 1 -- Solutions"
categories: jekyll update

mathjax: true
---

# TP 1 -- Programmation procédurale en SQL (PL/pgSQL) 


## Création de fonctions/procédures enregistrées dans la base de données


### 1. Fonction quantité totale de produits achetés entre deux dates

```sql
CREATE OR REPLACE FUNCTION total_quantity_purchased(start_date DATE, end_date DATE)  
RETURNS INTEGER AS $$  
DECLARE  
  total_qty INTEGER;  
BEGIN  
  SELECT SUM(quantity) INTO total_qty  
  FROM orderlines  
  WHERE orderdate > start_date AND orderdate < end_date;  
  RETURN total_qty;  
END;  
$$ LANGUAGE plpgsql;
```



### 2. Fonction quantité totale par catégorie entre deux dates

```sql
CREATE OR REPLACE FUNCTION quantity_by_category(start_date DATE, end_date DATE)  
RETURNS TABLE(category_name categories.categoryname%TYPE, total_qty BIGINT) AS $$  
BEGIN  
  RETURN QUERY  
  SELECT c.categoryname, SUM(o.quantity)  
  FROM orderlines o  
  JOIN products p ON o.prod_id = p.prod_id  
  JOIN categories c ON p.category = c.category  
  WHERE o.orderdate > start_date AND o.orderdate < end_date  
  GROUP BY c.categoryname;  
END;  
$$ LANGUAGE plpgsql;
```



### 3. Procédure copier commande dans historique (cust_hist)

```sql
CREATE OR REPLACE FUNCTION copy_order_to_history(order_id INTEGER)  
RETURNS VOID AS $$  
declare 
  nb_doublons int;
BEGIN  

  SELECT  count(orderid) into nb _doublons
  FROM cust_hist
  WHERE orderid = order_id ;

  IF nb_doublons = 0 THEN 
    INSERT INTO cust_hist (customerid, orderid, prod_id)  
    SELECT o.customerid, o.orderid, l.prod_id  
    FROM orders o  
    JOIN orderlines l ON o.orderid = l.orderid  
    WHERE o.orderid = order_id;  
  END IF;

END;  
$$ LANGUAGE plpgsql;
```



### 4. Procédure affichant un avertissement rupture de stock

```sql
CREATE OR REPLACE FUNCTION check_stock_shortage(order_id INTEGER)  
RETURNS VOID AS $$  
DECLARE  
  prod RECORD;  
  stock_qty INTEGER;  
  product_id INTEGER;  
  order_qty INTEGER;  
BEGIN  
  FOR prod IN SELECT prod_id, quantity FROM orderlines WHERE orderid = order_id LOOP  
    SELECT quan_in_stock INTO stock_qty FROM inventory WHERE prod_id = prod.prod_id;  
    product_id := prod.prod_id;  
    order_qty := prod.quantity;  
    IF stock_qty <= order_qty THEN  
      RAISE NOTICE 'Order confirmed: Stock shortage for product id: %', product_id;  
      EXIT;  
    END IF;  
  END LOOP;  
END;  
$$ LANGUAGE plpgsql;
```



### 5. Procédure enregistrant la demande de réapprovisionnement

A compléter pour vérifier si une demande de re oroder n'a pas été déjà fait (faire la différence avec les quantités commandées)

```sql
CREATE OR REPLACE FUNCTION record_reorder_request(threshold INTEGER)  
RETURNS VOID AS $$  
DECLARE
  inventory_rec RECORD; 
  qte_deja_reorder int ;
  qte_a_reorder int ;
BEGIN  
  FOR inventory_rec IN
    SELECT prod_id, quan_in_stock FROM inventory WHERE quan_in_stock < threshold
  LOOP

    -- Filtrer les réapprovisionnements en cours pour le produit courant
    SELECT SUM( quan_reordered) into qte_deja_reorder
    FROM reorder
    WHERE date_expected > CURRENT_DATE
    AND  prod_id = inventory_rec.prod_id ;

     -- Calcul de la quantité à commander en plus pour dépasser le seuil
    qte_a_reorder := threshold - inventory_rec.quan_in_stock - qte_deja_reorder;

    IF qte_a_reorder > 0 THEN 
      INSERT INTO reorder (prod_id, date_low, quan_low)
        VALUES (inventory_rec.prod_id, CURRENT_DATE, qte_a_reorder);
    END IF;

  END LOOP;
END;  
$$ LANGUAGE plpgsql;
```


### 6. Fonction liste clients avec produits en réapprovisionnement

```sql
CREATE OR REPLACE FUNCTION clients_with_reorder()  
RETURNS TABLE(first_name customers.firstname%TYPE, last_name customers.lastname%TYPE, phone customers.phone%TYPE, product_title products.title%TYPE, reorder_date reorder.date_reordered%TYPE) AS $$  
BEGIN  
  RETURN QUERY  
  SELECT c.firstname, c.lastname, c.phone, p.title, r.date_reordered  
  FROM reorder r  
  JOIN orderlines l ON r.prod_id = l.prod_id  
  JOIN products p ON p.prod_id = l.prod_id  
  JOIN orders o ON o.orderid = l.orderid  
  JOIN customers c ON c.customerid = o.customerid  
  WHERE r.date_reordered IS NOT NULL  
  ORDER BY c.firstname, c.lastname;  
END;  
$$ LANGUAGE plpgsql;
```


### 7. Procédure mise à jour stock et suppression réapprovisionnement

```sql
CREATE OR REPLACE FUNCTION update_stock_on_reorder(product_id INTEGER, quantity_received INTEGER)  
RETURNS VOID AS $$  
DECLARE  
  reorder_date DATE;  
  reorder_quantity INTEGER;  
BEGIN  
  SELECT date_reordered, quan_reordered INTO reorder_date, reorder_quantity
  FROM reorder WHERE prod_id = product_id;  

  IF reorder_date IS NOT NULL AND reorder_quantity = quantity_received THEN  
    UPDATE inventory SET quan_in_stock = quan_in_stock + quantity_received 
	WHERE prod_id = product_id;  
	
    DELETE FROM reorder WHERE prod_id = product_id;  
  END IF;  
END;  
$$ LANGUAGE plpgsql;
```



### 8a. Fonction la catégorie préférée d'un client donné pour un mois et une année

```sql
CREATE OR REPLACE FUNCTION favorite_category_for_client(client_id orders.customerid%TYPE, month INTEGER, year INTEGER)  
RETURNS products.category%TYPE AS $$  
DECLARE  
  favorite_category products.category%TYPE;  
BEGIN  
  SELECT p.category into favorite_category
  FROM orders o  
  JOIN orderlines l ON o.orderid = l.orderid  
  JOIN products p ON p.prod_id = l.prod_id  
  WHERE EXTRACT(MONTH FROM o.orderdate) = month  
    AND EXTRACT(YEAR FROM o.orderdate) = year  
    AND o.customerid = client_id  
  GROUP BY p.category  
  ORDER BY SUM(l.quantity) DESC  
  LIMIT 1;  
  
  RETURN favorite_category;  
END;  
$$ LANGUAGE plpgsql;
```



### 8b. Fonction montants totaux des commandes achetées chaque mois par les clients
```sql
CREATE OR REPLACE FUNCTION amount_bought_by_month()
RETURNS TABLE ( year integer, month integer, customer_id orders.customerid%TYPE, total_amount numeric ) AS $$
BEGIN
  RETURN QUERY
    SELECT
      EXTRACT(YEAR FROM orderdate)::INT as year,
      EXTRACT(MONTH FROM orderdate)::INT as month,
      customerid, SUM(totalamount)
    FROM orders
    GROUP BY year, month, customerid
    ORDER BY  year, month, customerid;
END;
$$ LANGUAGE plpgsql;
```

### 8c. Fonction meilleurs clients par mois avec catégorie préférée

```sql
CREATE OR REPLACE FUNCTION best_clients_by_month()
RETURNS TABLE( order_year integer, order_month integer, customer orders.customerid%TYPE, amount numeric, favorite_category products.category%TYPE  ) AS $$
BEGIN
  RETURN QUERY
    SELECT t.year, t.month, customer_id, t.total_amount, 
       favorite_category_for_client( customer_id, t.month, t.year)
    FROM amount_bought_by_month() as t, 
        ( SELECT year, month, max(total_amount) as max_amount
          FROM amount_bought_by_month()
          GROUP BY year, month
        ) as best
    WHERE  t.year = best.year
       AND t.month = best.month
       AND t.total_amount = best.max_amount;
END;
$$ LANGUAGE plpgsql;
```

