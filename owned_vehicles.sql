-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Czas generowania: 20 Cze 2024, 01:29
-- Wersja serwera: 8.0.37-0ubuntu0.20.04.3
-- Wersja PHP: 7.4.3-4ubuntu2.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Baza danych: `dev`
--

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `owned_vehicles`
--

CREATE TABLE `owned_vehicles` (
  `id` int NOT NULL,
  `model_name` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `owner` varchar(46) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `plate` varchar(12) COLLATE utf8mb4_general_ci NOT NULL,
  `vehicle` longtext COLLATE utf8mb4_general_ci,
  `type` varchar(20) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'car',
  `job` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'civ',
  `stored` tinyint NOT NULL DEFAULT '0',
  `glovebox` longtext COLLATE utf8mb4_general_ci,
  `trunk` longtext COLLATE utf8mb4_general_ci,
  `garage` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'San Andreas Avenue',
  `blocked` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `owned_vehicles`
--
ALTER TABLE `owned_vehicles`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT dla tabel zrzutów
--

--
-- AUTO_INCREMENT dla tabeli `owned_vehicles`
--
ALTER TABLE `owned_vehicles`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
