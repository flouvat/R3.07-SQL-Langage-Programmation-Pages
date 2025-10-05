---
layout: post
title: "TP 2 -- Contraindre les données"
categories: jekyll update

mathjax: true
---

# TP 2 -- Contraindre les données et automatiser des traitements

## Objectif global
L'objectif de ce TP est de manipuler le principal mécanisme permettant de contrôler et structurer le contenu des bases de de données : les contraintes d'intégrité. Dans ce TP, nous allons utiliser PostgreSQL pour étudier ces techniques.

## Présentation de la base de données et du cadre applicatif

Nous allons utiliser la base de données "Dell DVD Store" manipulée dans le TP précédent.

## Les contraintes d'intégrité et autres déclencheurs (trigger)

Les contraintes d'intégrité permettent d'imposer des restrictions sur les données stockées dans la base de données.

### Analyse de la base de données 
Dans un premier temps, vous identifierez les contraintes d'intégrités déjà affectées à chacune des relations de la base de données (utiliser pour cela les tables du catalogue p.ex.). Il faudra notamment préciser les attributs sur lesquels sont définis les clés primaires et étrangères.

### Définition de contraintes et de triggers
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
10. "Un client ne peut pas avoir la même adresse email qu'un autre client."
11. "Une commande ne peut pas contenir plus de 100 unités d'un même produit."
12. "Permettre la suppression d'un client tout en conservant ses commandes, mais en mettant le champ customerid à NULL dans orders"
13. "Empêcher la commande de produits "spéciaux" par des clients de moins de 18 ans."
14. "Mise à jour automatique du stock après la commande d'un nouveau produit."
15. "Un client ne peut pas avoir plus de 3 commandes le même jour."
16. "Historiser les changements de prix des produits."
17. "Après chaque commande, si le total cumulé du client dépasse 1000€, enregistrer une alerte dans une table."