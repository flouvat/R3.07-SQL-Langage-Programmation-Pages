---
layout: post
title: "TP 2 -- Contraindre les données"
categories: jekyll update

mathjax: true
---

# TP 2 -- Contraindre les données

## Objectif global
L'objectif de ce TP est de manipuler le principal mécanisme permettant de contrôler et structurer le contenu des bases de de données : les contraintes d'intégrité. Dans ce TP, nous allons utiliser PostgreSQL pour étudier ces techniques

## Présentation de la base de données et du cadre applicatif

Nous allons utiliser la base de données "Dell DVD Store" manipulée dans le TP précédent.

## Les contraintes d'intégrité 

Les contraintes d'intégrité permettent d'imposer des restrictions sur les données stockées dans la base de données.

### Analyse de la base de données 
Dans un premier temps, vous identifierez les contraintes d'intégrités déjà affectées à chacune des relations de la base de données (utiliser pour cela les tables du catalogue p.ex.). Il faudra notamment préciser les attributs sur lesquels sont définis les clés primaires et étrangères.

### Définition de contraintes
Dans un second temps, vous implémenterez les contraintes suivantes (chaque contrainte devra être testée):
1.	"Une même commande ne peut être constituée de deux lignes associées au même produit."
2.	"Une commande est nécessairement associée à un client. Si le client est supprimé, toutes ses commandes sont supprimées (et par extension toutes les lignes de ces commandes aussi)". Que se passe-t-il si une commande est insérée avec un mauvais numéro de client ?
3.	"L'identifiant d'une ligne d'une commande est unique et non null."
4. "Une demande de réapprovisionnement est nécessairement associée à un produit référencé (dans products). Il est impossible de supprimer un produit si celui-ci est en cours de réapprovisionnement."
5. "L'âge des clients est nécessairement supérieur à zéro. Leur adresse mail est composée d'un "@" et d'un point. Leur numéro de carte de crédit est composé de 16 chiffres."
6. "Pour chaque nouvelle commande, l'historique des commandes (cust_hist) doit être automatiquement mis à jour."
7. "Pour chaque nouvelle commande, le montant total net (netamount) de la commande, et le montant avec les taxes (totalamount), devront être automatiquement renseignés (si ces informations ne sont pas précisées au moment de l'enregistrement de la commande)."
8. "Pour chaque produit commandé, il faudra mettre à jour le nombre total de ventes associées à ce produit (champ sales de inventory)."
9. "Il est impossible de commander un produit si la quantité en stock est insuffisante (prendre aussi en compte les commandes en cours des autres clients)."
