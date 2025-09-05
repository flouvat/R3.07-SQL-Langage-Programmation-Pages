-- Script de création de la base de données de gestion des vins
-- PostgreSQL

-- Suppression des tables si elles existent déjà (ordre inverse à cause des contraintes FK)
DROP TABLE IF EXISTS Commandes CASCADE;
DROP TABLE IF EXISTS Catalogues CASCADE;
DROP TABLE IF EXISTS Fournisseurs CASCADE;
DROP TABLE IF EXISTS Produits CASCADE;

-- Création de la table Produits
CREATE TABLE Produits (
    pnom VARCHAR(50) PRIMARY KEY,
    couleur VARCHAR(20) NOT NULL
);

-- Création de la table Fournisseurs
CREATE TABLE Fournisseurs (
    fnom VARCHAR(50) PRIMARY KEY,
    statut VARCHAR(20) NOT NULL,
    ville VARCHAR(50) NOT NULL
);

-- Création de la table Catalogues
CREATE TABLE Catalogues (
    pnom VARCHAR(50),
    fnom VARCHAR(50),
    prix DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (pnom, fnom),
    FOREIGN KEY (pnom) REFERENCES Produits(pnom) ON DELETE CASCADE,
    FOREIGN KEY (fnom) REFERENCES Fournisseurs(fnom) ON DELETE CASCADE
);

-- Création de la table Commandes
CREATE TABLE Commandes (
    num INTEGER PRIMARY KEY,
    cnom VARCHAR(50) NOT NULL,
    pnom VARCHAR(50) NOT NULL,
    qte INTEGER NOT NULL CHECK (qte > 0),
    FOREIGN KEY (pnom) REFERENCES Produits(pnom) ON DELETE CASCADE
);

-- Insertion des données dans la table Produits
INSERT INTO Produits (pnom, couleur) VALUES
('Boudes', 'Rouge'),
('Chablis', 'Blanc'),
('Chapoutier', 'Rosé'),
('Cornas', 'Rouge'),
('Riesling', 'Blanc');

-- Insertion des données dans la table Fournisseurs
INSERT INTO Fournisseurs (fnom, statut, ville) VALUES
('Vini', 'SARL', 'Dijon'),
('BonVin', 'SA', 'Dijon'),
('Chapoutier', 'SA', 'Valence'),
('SaV', 'Association', 'Lyon');

-- Insertion des données dans la table Catalogues
INSERT INTO Catalogues (pnom, fnom, prix) VALUES
('Cornas', 'BonVin', 20.00),
('Cornas', 'Chapoutier', 18.00),
('Riesling', 'Vini', 8.20),
('Boudes', 'Vini', 4.30),
('Riesling', 'Chapoutier', 8.50),
('Chapoutier', 'Chapoutier', 5.10),
('Chablis', 'Chapoutier', 5.00);

-- Insertion des données dans la table Commandes
INSERT INTO Commandes (num, cnom, pnom, qte) VALUES
(1535, 'Jean', 'Cornas', 6),
(1854, 'Jean', 'Riesling', 20),
(1254, 'Paul', 'Chablis', 20),
(1259, 'Paul', 'Chablis', 25),
(1596, 'Paul', 'Cornas', 12);

-- Vérification des données insérées
SELECT 'Produits' as table_name, COUNT(*) as nb_lignes FROM Produits
UNION ALL
SELECT 'Fournisseurs', COUNT(*) FROM Fournisseurs
UNION ALL
SELECT 'Catalogues', COUNT(*) FROM Catalogues
UNION ALL
SELECT 'Commandes', COUNT(*) FROM Commandes;

-- Requêtes de vérification des contraintes d'intégrité
SELECT 'Vérification contrainte Catalogues->Produits' as verification;
SELECT c.pnom FROM Catalogues c 
LEFT JOIN Produits p ON c.pnom = p.pnom 
WHERE p.pnom IS NULL;

SELECT 'Vérification contrainte Catalogues->Fournisseurs' as verification;
SELECT c.fnom FROM Catalogues c 
LEFT JOIN Fournisseurs f ON c.fnom = f.fnom 
WHERE f.fnom IS NULL;

SELECT 'Vérification contrainte Commandes->Produits' as verification;
SELECT cmd.pnom FROM Commandes cmd 
LEFT JOIN Produits p ON cmd.pnom = p.pnom 
WHERE p.pnom IS NULL;