---
layout: post
title: "TP 1 -- Programmation procédurale en SQL"
categories: jekyll update

mathjax: true
---

# TP 1 -- Programmation procédurale en SQL (PL/pgSQL)

## Objectif global
L'objectif de ce TP est de manipuler les principaux concepts  de la programmation procédurale en SQL. 

Dans cet objectif, nous allons utiliser le SGBD open-source PostgreSQL (www.postgresql.org/). PostgreSQL a l'avantage de proposer une implémentation du SQL très proche des standards. Gardez à l'esprit que si vous changez de SGBD, vous avez des chances de devoir utiliser d'autres variantes du SQL. Toutefois, les différences ne touchent normalement que certaines fonctionnalités avancées du SGBD.

## Présentation de la base de données et du cadre applicatif

Nous allons construire et utiliser la base de données d'un site de e-commerce. Cette base de données s'appelle "Dell DVD Store" et est fournie par Dell afin de pouvoir tester les fonctionnalités des différents SGBD . Cet exemple est typique des bases de données servant à gérer un stock.

Elle est composée de 8 tables et proposée en trois tailles: "small", "medium" et "large". Dans ce TP, nous allons utiliser la plus petite version. Elle fait 10 Mo, et référence 20 000 clients, 1000 commandes et 10 000 produits. A titre indicatif, la version "large" fait 100Go, et génère 200 millions de clients, 10 millions de commandes et un million de produits.


## Connexion au SGBD
Pour se connecter à PostgreSQL, nous allons utiliser l'outil pgAdmin3 et suivre les étapes suivantes:
1.	lancer pgAdmin.
2.	Connecter vous au serveur PostgreSQL.
3.	saisir le mot de passe du compte administrateur postgres : root
4.	cliquer sur le bouton ok.


## Création de la base de données et chargement des données

La première étape est de créer la base de données et de charger son contenu (en étant connecté avec le compte postgres). Afin de faciliter l'installation, Dell a fournit un script permettant de créer les tables et de charger leur contenu.
Tout d'abord, il faut créer la base de données en faisant (à partir de pgAdmin)
1.	cliquer droit sur "Databases" dans le navigateur d'objets de pgAdmin4,
2.	cliquer sur "Create > Database … " dans le menu contextuel qui s'affiche,
3.	donner un nom à votre base données. Le nom sera "ds2" dans le cadre de ce TP,
4.	sauvegarder.

Ensuite, il faut importer les tables et leurs données à partir du fichier [DS2light.backup](/TP/data/tp1/DS2light.backup) en faisant
1.	un clique droit sur la base de données "ds2",
2.	 "Restore …",
3.	sélectionner le fichier "ds2.backup" et cliquer sur "Restore".

## Analyse de la base de données

Si aucune documentation n'est fournie sur la base de données sur laquelle vous devez travailler, il existe trois options pour connaître les détails concernant sa structure et les mécanismes qu'elle intègre.
- Option 1 : Exploiter un outil graphique comme pgAdmin (si disponible);
- Option 2 : Exploiter la commande [psql \d](https://docs.postgresql.fr/17/app-psql.html) dans le terminal (si vous avez accès au serveur où est installé le SGBD);
- Option 3 : Interroger en SQL les [catalogues systèmes](https://docs.postgresql.fr/17/catalogs.html) (les métadonnées) de la base de données.


Un SGBD relationnel conserve des méta-informations sur les relations (p.ex. informations sur les schémas, les contraintes d'intégrité et leur indexes) dans des tables spéciales appelées [catalogues systèmes](https://docs.postgresql.fr/17/catalogs-overview.html). Grâce à cette fonctionnalité, il est possible d'avoir des informations sur tous les objets d'une base de données en faisant de simples requêtes SQL. Par exemple, il est possible d'avoir la liste des relations d'une base de données en faisant la requête:

```SQL
SELECT * FROM pg_tables WHERE tableowner='yourlogin'
```

Il est important de noter que les outils graphiques tel que pgAdmin s'appuient aussi sur ces catalogues systèmes pour afficher les informations de la base de données dans leur interface.

Vous utiliserez  ces trois méthodes pour trouver des informations sur les tables créées, et vérifierez que les informations concordent. Ces informations devront vous permettre de faire le schéma E/A de la base de données (indispensable pour pouvoir ensuite faire des requêtes), et de déduire le rôle de chaque table.


## Création de fonctions/procédures enregistrées dans la base de données

PostgreSQL offre également la possibilité de définir des procédures en PL/pgSQL. Ces procédures sont utilisées pour enregistrer et effectuer des traitements complexes sur les données. Elles permettent ainsi de limiter les communications client/serveur, de laisser les résultats intermédiaires sur le serveur, et d'éviter de parser les mêmes requêtes SQL plusieurs fois.

Pour plus d'informations sur ces fonctions/procédures se reporter à la documentation en ligne de PostgreSQL, [section "PL/pgSQL"](https://docs.postgresql.fr/17/plpgsql.html). Par exemple, la [sous-section  "Returning from a function"](https://docs.postgresql.fr/17/plpgsql-control-structures.html#PLPGSQL-STATEMENTS-RETURNING) (section "Control Structures") décrit notamment la procédure à suivre pour retourner un ensemble de valeurs.


Ecrire les fonctions et procédures suivantes. Ne pas oublier de les tester au fur et à mesure, et de vérifier les résultats obtenus.
1.	Ecrire une fonction retournant la quantité totale de produits achetés entre deux dates passées en paramètres.
2.	Ecrire une fonction retournant la quantité totale de produits achetés pour chaque catégorie entre deux dates passées en paramètres.
3.	Ecrire une procédure qui "copie" dans l'historique une commande déjà traitée (le numéro de la commande est passé en paramètre).
4.	Ecrire une procédure affichant une erreur lorsqu'une commande est passée et que l'un des produits est en rupture de stock (le numéro de la commande est passé en paramètre).
5.	Ecrire une procédure qui enregistre une demande de réapprovisionnement (ie dans reorder) lorsque le stock des produits est en dessous d'un certain seuil.
6.	Ecrire une fonction retournant l'ensemble des clients (afficher le nom et le numéro de téléphone) dont un des produits commandés est en cours de réapprovisionnement (ie dans reorder). Afficher également le nom du produit et la date de réapprovisionnement prévue.
7.	Ecrire une procédure qui permet, lorsqu'un réapprovisionnement est fait, de mettre à jours la quantité en stock dans l'inventaire et de supprimer la demande de réapprovisionnement (dans reorder). Cette procédure prendra en paramètres l'identifiant du produit et la quantité reçue.
8.	Ecrire une fonction qui retourne les meilleurs clients (ceux dont les commandes ont le montant le plus élevé) de chaque mois. Afin de connaître le profil de ces clients, retourner aussi leur catégorie de prédilection, celle dont ils achètent en général le plus de produits.
