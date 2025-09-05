---
layout: post
title: "TD 1 -- Rappels et Programmation procédurale en PL/pgSQL"
categories: jekyll update

mathjax: true
---

# TD 1 -- Rappels et Programmation procédurale en PL/pgSQL

## 1 - Rappels de SQL
Soit la base de données bd1 dont le schéma relationnel est le suivant : 

- **Produits(pnom, couleur)**
- **Fournisseurs(fnom, statut, ville)**
- **Catalogues(pnom, fnom, prix)**
- **Commandes(num, cnom, pnom, qte)**

Contraintes d'intégrité référentielle :
- Catalogues(pnom) ⊆ Produits(pnom)
- Catalogues(fnom) ⊆ Fournisseurs(fnom)
- Commandes(pnom) ⊆ Produits(pnom)

### Exemple de données

#### **Produits**
<custom-element data-json="%7B%22type%22%3A%22table-metadata%22%2C%22attributes%22%3A%7B%22title%22%3A%22Produits%22%7D%7D" />
 | pnom        | couleur |
 |-------------|---------|
 | Boudes      | Rouge   |
 | Chablis     | Blanc   |
 | Chapoutier  | Rosé    |
 | Cornas      | Rouge   |
 | Riesling    | Blanc   |

---

#### **Fournisseurs**
<custom-element data-json="%7B%22type%22%3A%22table-metadata%22%2C%22attributes%22%3A%7B%22title%22%3A%22Fournisseurs%22%7D%7D" />
 | fnom       | statut      | ville    |
 |------------|-------------|----------|
 | Vini       | SARL        | Dijon    |
 | BonVin     | SA          | Dijon    |
 | Chapoutier | SA          | Valence  |
 | SaV        | Association | Lyon     |

---

#### **Catalogues**
<custom-element data-json="%7B%22type%22%3A%22table-metadata%22%2C%22attributes%22%3A%7B%22title%22%3A%22Catalogues%22%7D%7D" />
 | pnom       | fnom       | prix |
 |------------|------------|------|
 | Cornas     | BonVin     | 20   |
 | Cornas     | Chapoutier | 18   |
 | Riesling   | Vini       | 8,2  |
 | Boudes     | Vini       | 4,3  |
 | Riesling   | Chapoutier | 8,5  |
 | Chapoutier | Chapoutier | 5,1  |
 | Chablis    | Chapoutier | 5    |

---

#### **Commandes**
<custom-element data-json="%7B%22type%22%3A%22table-metadata%22%2C%22attributes%22%3A%7B%22title%22%3A%22Commandess%22%7D%7D" />
 | num  | cnom | pnom       | qte |
 |------|------|------------|-----|
 | 1535 | Jean | Cornas     | 6   |
 | 1854 | Jean | Riesling   | 20  |
 | 1254 | Paul | Chablis    | 20  |
 | 1259 | Paul | Chablis    | 25  |
 | 1596 | Paul | Cornas     | 12  |

---

### Questions

Pour chaque question ci-dessous, donner une expression en SQL :

1. Donner le nom des fournisseurs de Riesling ou de Cornas à un prix inférieur à 10 €.
2. Donner le nom et la couleur des produits commandés par Jean.
3. Donner le nom des produits qui coûtent plus de 15 € ou qui sont commandés par Jean.
4. Donner le nom des produits qui n'ont pas été commandés.
5.  Donner le nom des produits commandés en quantité supérieure à 10 et dont le prix est inférieur à 15 €.
6.  Donner le nom, la couleur et le prix moyen de tous les vins commandés.
7.  Donner le nom des produits qui sont fournis par tous les fournisseurs.

Pour tester vos requêtes, vous pouvez utiliser l'outil `pgAdmin` pour créer une base de données `td1-vins`, puis créer les tables et saisir les données exemples avec le script [td1-vins.sql](/TD/td1-data/td1-vins.sql).
 


## 2 - Programmation procédurale en PL/pgSQL

Considérons la base de données suivante:

- **Product(pid: integer, name: text, min_age: integer, price: integer)**
- **Manufacturer(mid: integer, name: varchar(20), address: varchar(50))**
- **Supplier(sid: integer, name: varchar(20), address: varchar(50))**
- **Client(cid: integer, name: varchar(20))**
- **Inventory(pid:integer, stock: integer)**
- **Manufactures(mid:integer, pid: integer)**
- **Supplies(sid: integer, pid: integer, priceS: integer)**
- **Buy(pid: integer, sid: integer, cid: integer, deleveryAdress: varchar(30), qty: integer, dateCde : date)**

La relation **Product** contient des informations sur les jouets vendus par le magasin. La colonne **Product.pid** représente le numéro (unique) du produit. **Product.name** représente le nom du jouet,  **Product.min_age** indique l'age minimum recommandé pour utiliser le jouet, et **priceP** est le prix du produit.

Les relations **Manufacturer** et **Supplier** listent les noms et adressent de tous les fabricants et fournisseurs de jouets. **Manufacturer.mid** et **Supplier.sid** représentent le numéro du fabricant et du fournisseur.

La relation **Clients** stocke les informations sur les clients ayant acheté des jouets. **Inventory** indique le nombre de jouets en stock.

Les relations **Manufactures** et **Supplies** associent les produits avec leur fabricant et leurs fournisseurs. Notons qu'un produit ne peut avoir qu'un seul fabricant, mais plusieurs fournisseurs. La relation **Buy** représente les commandes (en cours) effectuées par les clients.

1.	Ecrire une fonction retournant le nombre de produits dont le stock est en dessous d'un seuil donné en paramètre.
2.	Ecrire une fonction retournant l'ensemble des produits dont le stock est en dessous d'un seuil donné en paramètre.
3.	Ecrire une procédure appliquant une réduction de 5% aux prix des produits dont le stock est supérieur à un seuil donné, tout en vérifiant que ce prix ne devienne pas inférieur au prix d'achat chez le fournisseur.
4.	Ecrire une procédure qui supprime les fournisseurs qui ne sont plus associés à aucun produit.
5.	Ecrire une fonction retournant la marge totale faite par l'entreprise sur chaque produit, cad **(price-priceS)*nbProdVendus**, en fonction des différents fournisseurs.
6.	Ecrire une fonction qui retourne le produit le plus vendu, la quantité vendue et sa quantité en stock.
7.	Ecrire une fonction qui, pour un pays donné en paramètre, retourne les 10 produits les plus vendus, les quantités vendues et les quantités en stock.
8.	Ecrire une procédure supprimant tous les produits d'un fabricant donné (ainsi que le fabricant en question). Les commandes associées à ces produits, et datant de moins de un an, seront stockées dans une table **OldBuy(cid: integer, pname: varchar(20), dateCde : date, qte: integer )**, les autres seront supprimées.
9.	Ecrire une fonction qui retourne les produits à réapprovisionner d'urgence, car proches d'une rupture de stock étant donné les commandes clients en cours. Un produit à  réapprovisionner d'urgence est un produit dont la quantité totale en cours de commande par les clients est supérieure à X % du stock. En plus de retourner le nom du produit et la quantité actuelle en stock, cette fonction retournera pour chacun de ces produits la quantité à commander ainsi que le nom des fournisseurs possibles et les coûts de commande fournisseur associés (par ordre croissant).

Pour tester vos requêtes, vous pouvez une nouvelle fois utiliser l'outil `pgAdmin` pour créer une base de données `td1-toys`. A la place d'utiliser un script SQL, vous pouvez ensuite utiliser la sauvegarde de base de données [td1-toys.backup](TD/td1-data/td1-toys.backup) pour importer/restorer les données. 

