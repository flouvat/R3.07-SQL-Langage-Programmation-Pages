---
layout: post
title: "TD 2 -- Contraindre les données"
categories: jekyll update

mathjax: true
---

# TD 2 -- Contraindre les données

Nous allons continuer à travailler avec la base de données utilisée en TD1.

Pour rappel, elle est constituée des tables :

- **product(pid: integer, name: text, min_age: integer, price: integer)**
- **manufacturer(mid: integer, name: varchar(20), address: varchar(50))**
- **supplier(sid: integer, name: varchar(20), address: varchar(50))**
- **client(cid: integer, name: varchar(20))**
- **inventory(pid:integer, stock: integer)**
- **manufactures(mid:integer, pid: integer)**
- **supplies(sid: integer, pid: integer, priceS: integer)**
- **buy(pid: integer, sid: integer, cid: integer, deleveryAdress: varchar(30), qty: integer, dateCde : date)**

### Définitions de clés


1.	Écrire une requête SQL permettant de modifier le schéma de Manufacturer afin de définir la clé primaire. 

2.	Modifier le schéma de la relation Supplies afin de définir les clés primaire et étrangères. Vous utiliserez la politique de validation de contraintes en cascade.

3.	Que se passe-t-il si un utilisateur essaye de supprimer un produit dans Product déjà fournit par un fournisseur ?

### Définition de contraintes sur les attributs, sur les tuples et entre des relations

1.	Définir une contrainte interdisant les valeurs négatives pour le stock des produits.

2.	Définir une contrainte interdisant les commandes en quantité supérieur à 100 et dont l'adresse de livraison est dans un autre pays.

3.	Définir une contrainte interdisant que le nom d'un fournisseur soit identique à celui d'un fabricant.

4.	Définir une contrainte vérifiant que le nombre total de produits commandés reste bien inférieur à la quantité totale de produits en stock.

### Définition de déclencheurs (triggers) et de procédures stockées

1.	Définir une contrainte interdisant que le nom d'un fournisseur soit identique à celui d'un fabricant.

2.	Définir une contrainte vérifiant que le nombre total de produits commandés reste bien inférieur à la quantité totale de produits en stock.

3. Écrire un trigger qui fasse les traitements suivants: si la quantité d'un produit en stock devient zéro et qu'il n'y a plus de fournisseurs de ce produit, supprimer le produit des tables Product et Inventory.

4. Interdire la vente d'un produit à perte (cad avec un prix inférieur au prix du fournisseur).



