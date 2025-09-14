---
layout: post
title: "TD 1 -- Exemple de solutions"
categories: jekyll update

mathjax: true
---

# TD 1 -- Rappels et Programmation procédurale en PL/pgSQL -- Correction

## 1 - Rappels de SQL

1. Donner le nom des fournisseurs de Riesling ou de Cornas à un prix inférieur à 10 €.

```sql
SELECT DISTINCT fnom
FROM catalogues
WHERE ((pnom='Riesling') OR (pnom='Cornas')) AND (prix<10);
```

2. Donner le nom et la couleur des produits commandés par Jean.

```sql
SELECT P.pnom,couleur
FROM commandes C, produits P
WHERE C.pnom=P.pnom AND cnom='Jean';
```

3. Donner le nom des produits qui coûtent plus de 15 € ou qui sont commandés par Jean.


```sql
SELECT pnom
FROM catalogues
WHERE prix\>15
UNION
SELECT pnom
FROM commandes
WHERE cnom='Jean';
```

4. Donner le nom des produits qui n'ont pas été commandés.

```sql
SELECT pnom
FROM produits
MINUS
SELECT pnom
FROM commandes;
```

5. Donner le nom des produits commandés en quantité supérieure à 10 et dont le prix est inférieur à 15 €.

```sql
SELECT pnom
FROM commandes
WHERE qte\>10
INTERSECT
SELECT pnom
FROM catalogues
WHERE prix\<15;
```

6. Donner le nom, la couleur et le prix moyen de tous les vins commandés.

```sql
SELECT P.pnom, couleur, AVG(prix) AS prixMoy
FROM produits P, commandes Co, catalogues Ca
WHERE P.pnom = Co.pnom AND Co.pnom= Ca.pnom
GROUP BY P.pnom, couleur ;
```
OU

```sql
SELECT P.pnom, couleur, prixMoy
FROM produits P,( SELECT Co.pnom, AVG(prix) AS prixMoy
                    FROM commandes Co, catalogues Ca
                    WHERE Co.pnom= Ca.pnom
                    GROUP BY pnom ) C
WHERE P.pnom = C.pnom;
```

7. Donner le nom des produits qui sont fournis par tous les fournisseurs.

```sql
SELECT pnom
FROM catalogues
GROUP BY pnom
HAVING COUNT(DISTINCT fnom)=(SELECT COUNT(fnom)
                             FROM Fournisseurs);
```
   
## 2 - Programmation procédurale en PL/pgSQL


1.	Ecrire une fonction retournant le nombre de produits dont le stock est en dessous d'un seuil donné en paramètre.

```sql
create or replace function get_nb_low_stock( seuil IN integer ) returns integer as $$
declare
	nb integer;
begin
	select count(*) into nb from inventory where stock < seuil ;
	return nb ;
end;
$$ language plpgsql;

select * from get_nb_low_stock( 30 );
```

2.	Ecrire une fonction retournant l'ensemble des produits dont le stock est en dessous d'un seuil donné en paramètre.

```sql
create or replace function get_products_low_stock( seuil IN integer ) returns TABLE( pname text ) as 
$$
begin
	return query (select name 
                  from product, inventory 
                  where product.pid = inventory.pid and stock < seuil) ;
end;
$$ language plpgsql;

select * from get_products_low_stock( 30 );
```

3.	Ecrire une procédure appliquant une réduction de 5% aux prix des produits dont le stock est supérieur à un seuil donné, tout en vérifiant que ce prix ne devienne pas inférieur au prix d'achat chez le fournisseur.

```sql
create or replace function apply_discount( seuil IN integer )  returns void as $$
declare
	curs CURSOR(s integer)  FOR select * from product, inventory where  product.pid = inventory. pid and stock > s;
	
	tupleProd record ;

	priceSupp supplies.priceS%TYPE;

	newPrice product.price%TYPE;

begin
	-- pour chaque produit
	for tupleProd in curs(seuil) loop
		
		select max(priceS) into priceSupp from supplies where pid = tupleProd.pid ;
		
		newPrice = round( tupleProd.price  * 0.95) ;

		if( priceSupp < newPrice ) then 
			update product set price = newPrice
			where pid= tupleProd.pid ;
		end if;
	end loop;
end
$$ language plpgsql;

select * from apply_discount( 30 );

```

4.	Ecrire une procédure qui supprime les fournisseurs qui ne sont plus associés à aucun produit.

Version 1 :
```sql
create or replace function remove_old_suppliers() returns void  as $$
declare
  	nb integer;

	curs CURSOR  FOR select sid from supplier;
	
	delid supplier.sid%TYPE ;

begin

	-- pour chaque fournisseur
	for delid in curs loop

		select count(*) into nb from supplies where sid = delid.sid ;
		
		-- raise notice 'sId:% nb:%',delid.sid,nb;
		
		if( nb = 0 )
		then delete from supplier where sid = delid.sid;
		end if;
	
	end loop;

end
$$ language plpgsql;

select remove_old_suppliers();
```

Version 2 :
```sql
create or replace function remove_old_suppliers_v2() returns void  as $$
begin
	delete from supplier where sid not in (select sid from supplies );
end;
$$ language plpgsql;

select remove_old_suppliers_v2();
```

5.	Ecrire une fonction retournant la marge totale faite par l'entreprise sur chaque produit, cad $(price-priceS)*nbProdVendus$, en fonction des différents fournisseurs.

```sql
create type prod_marge as(
 	pname text, -- product.name%TYPE ne fonctionne pas dans ce cas 
 	marge integer
);


create or replace function get_total_profit() returns SETOF prod_marge as $$
declare

	cursProd CURSOR  FOR select pid, name, price from product;

	pidName record; 

	cursProdBuy CURSOR( prodid  product.pid%TYPE ) FOR select sid, sum(qty) as qte from buy where pid = prodid group by  sid ;

	prodFournSum record;

	prixS integer ;
	prixP integer;

	res prod_marge ;

begin

	For pidName in cursProd loop
		
		res.pname = pidName.name;
		res.marge:= 0;
		
		For prodFournSum in cursProdBuy( pidName.pid ) loop
			
			select priceS into prixS 
            from supplies 
            where sid = prodFournSum.sid and pid = pidName.pid  ;

			prixP := pidName.price ;			

			res.marge := res.marge + (prixP-prixS) * prodFournSum.qte ;
						
		end loop;

--		 if( pidName.pid = 2 ) then 			
-- 				raise notice 'produit % marge:%', res.pname , res.marge;
-- 		end if;
 
		return next res;

	end loop;

end
$$ language plpgsql;

select * from get_total_profit() where marge is not null order by marge desc;

```

6.	Ecrire une fonction qui retourne le produit le plus vendu, la quantité vendue et sa quantité en stock.

```sql
create or replace function get_best_product()  returns TABLE(  pname product.name%TYPE, qtySell bigint, qtyStock integer ) as $$
declare
	maxSell integer;
begin

	select max(ventes) into maxSell 
	from ( select pid, sum(qty) as ventes 
           from buy group by pid ) ;

	return query 
		select name, sum(qty), stock 
		from buy B, inventory I, product P
		where  B.pid=I.pid and P.pid=B.pid
		group by B.pid,name, stock
		having sum(qty) = maxSell;

end;
$$ language plpgsql;

select * from get_best_product( );
```

7.	Ecrire une fonction qui, pour un pays donné en paramètre, retourne les 10 produits les plus vendus, les quantités vendues et les quantités en stock.

Version 1 :
```sql
create or replace function get_top_ten_products( pays IN varchar(30) ) returns TABLE( pname product.name%TYPE, qtySell bigint, qtyStock inventory.stock%TYPE ) as 
$$
begin
	return  query 
		select name, sum(qty), sum(stock) 
		from buy B, inventory I, product P
		where  B.pid=I.pid and P.pid=B.pid
		and  deleveryadress like '%'||pays||'%'
		group by B.pid,name
		order by sum(qty) desc
		limit 10;
end;
$$ language plpgsql;

select * from get_top_ten_products( 'nc' );
```

Version 2 :
```sql
create or replace function get_top_ten_products_v2( pays IN varchar(30) ) returns TABLE( pname product.name%TYPE, qtySell bigint, qtyStock inventory.stock%TYPE ) as 
$$
declare
	prodOrderCursor cursor for select name, sum(qty), sum(stock) 
				  from buy B, inventory I, product P
				  where  B.pid=I.pid and P.pid=B.pid
				  and  deleveryadress like '%'||pays||'%'
				  group by B.pid,name
				  order by sum(qty) desc;
	count integer;
begin
	count:= 0;
	open prodOrderCursor;

	while (count <10 )
	loop	
		fetch prodOrderCursor into pname, qtySell, qtyStock;
		exit when not found;
		
		return next;
		count:=count+1;
	end loop;

	close prodOrderCursor;
	
end;
$$ language plpgsql;

select * from get_top_ten_products_v2( 'nc' );
```

8.	Ecrire une procédure supprimant tous les produits d'un fabricant donné (ainsi que le fabricant en question). Les commandes associées à ces produits, et datant de moins de un an, seront stockées dans une table $OldBuy(cid: integer, pname: varchar(20), dateCde : date, qte: integer )$, les autres seront supprimées.

```sql
create or replace function delete_products_manufacturer( manf_name in Manufacturer.name%TYPE ) returns void  as $$
declare	
	manf_id  Manufactures.mid%TYPE;

begin

	select mid into manf_id from Manufacturer where name = manf_name;

	if not exists ( select relname from pg_class where relname ='old_buy')
	then
		CREATE TABLE old_buy( 
			cid integer, -- impossible d'utiliser Buy.cid%TYPE, 
			pname text,
			dateCde timestamp,
			qte integer
			);
	end if;
	
	insert into old_buy (  select cid,name,datecde, qty 
				from Buy B,Product P
				where B.pid= P.pid 
				and age(datecde) < interval '1 year'
				and P.pid in ( select pid from Manufactures where mid =  manf_id ) 
				 );

	delete from Buy where pid in ( select pid from Manufactures where mid =  manf_id ) ;
	
	delete from Supplies where pid in ( select pid from Manufactures where mid =  manf_id ); 
	delete from Product where pid in ( select pid from Manufactures where mid =  manf_id ); 		
	delete from Manufactures where mid =  manf_id;
	delete from Manufacturer where name = manf_name;
	
end;
$$ language plpgsql;

select delete_products_manufacturer('toto');
```

9.	Ecrire une fonction qui retourne les produits à réapprovisionner d'urgence, car proches d'une rupture de stock étant donné les commandes clients en cours. Un produit à  réapprovisionner d'urgence est un produit dont la quantité totale en cours de commande par les clients est supérieure à X % du stock. En plus de retourner le nom du produit et la quantité actuelle en stock, cette fonction retournera pour chacun de ces produits la quantité à commander ainsi que le nom des fournisseurs possibles et les coûts de commande fournisseur associés (par ordre croissant).

```sql
drop function newCommandSupplier(in real);

create or replace function get_restock_products( seuil IN real ) returns TABLE( pname product.name%TYPE, qtyStock inventory.stock%TYPE, qtyCdeSupplier integer, nameSupplier supplier.name%TYPE, totPriceS supplies.priceS%TYPE ) as 
$$
declare
	prodCursor cursor for 
        select P.pid, name, stock, sum(qty) as totCde 
		from product P, inventory I, buy B
		where P.pid=I.pid and P.pid=B.pid
		group by P.pid, name, stock
		order by P.pid;

	supplCursor cursor( pidCde supplies.pid%TYPE ) for
        select name, priceS
		from supplies S, supplier Sr
		where S.sid=Sr.sid
		and pid = pidCde
		order by priceS asc;
	
	currentProd record;
	currentSupp record;	
begin
	-- pour chaque produit commandé
	for currentProd in prodCursor loop
		
		if currentProd.stock*seuil <= currentProd.totCde then
			pname := currentProd.name;
			qtyStock:= currentProd.stock ;
			qtyCdeSupplier := round( currentProd.totCde/seuil - currentProd.stock)+1 ;

			-- pour chaque fournisseur d'un produit commandé dont la quantité en stock est inférieur à un seuil
			for currentSupp in supplCursor( currentProd.pid) loop
				nameSupplier := currentSupp.name;
				totPriceS:= qtyCdeSupplier * currentSupp.priceS;
				return next;
			end loop;
			
		end if;
		
	end loop;
	
end;
$$ language plpgsql;

select * from get_restock_products(0.7);
```
