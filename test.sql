/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.5-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: 
-- ------------------------------------------------------
-- Server version	11.8.5-MariaDB-ubu2404

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Current Database: `booklore`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `booklore` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `booklore`;

--
-- Table structure for table `annotations`
--

DROP TABLE IF EXISTS `annotations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `annotations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `cfi` varchar(1000) NOT NULL,
  `text` varchar(5000) NOT NULL,
  `color` varchar(20) DEFAULT NULL,
  `style` varchar(50) DEFAULT NULL,
  `note` varchar(5000) DEFAULT NULL,
  `chapter_title` varchar(500) DEFAULT NULL,
  `version` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_annotation_user_book_cfi` (`user_id`,`book_id`,`cfi`) USING HASH,
  KEY `idx_annotations_user_id` (`user_id`),
  KEY `idx_annotations_book_id` (`book_id`),
  KEY `idx_annotations_user_book` (`user_id`,`book_id`),
  KEY `idx_annotations_user_created` (`user_id`,`created_at`),
  CONSTRAINT `fk_annotations_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_annotations_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotations`
--

LOCK TABLES `annotations` WRITE;
/*!40000 ALTER TABLE `annotations` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `annotations` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `app_migration`
--

DROP TABLE IF EXISTS `app_migration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_migration` (
  `migration_key` varchar(100) NOT NULL COMMENT 'Unique identifier for the migration',
  `executed_at` timestamp NOT NULL COMMENT 'When the migration was executed',
  `description` text DEFAULT NULL COMMENT 'Optional description of what the migration did',
  PRIMARY KEY (`migration_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci COMMENT='Tracks one-time application-level data migrations';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_migration`
--

LOCK TABLES `app_migration` WRITE;
/*!40000 ALTER TABLE `app_migration` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `app_migration` VALUES
('generateCoverHash','2026-01-06 17:57:47','Generate unique cover hash for all books using BookCoverUtils'),
('generateInstallationId','2025-12-29 20:14:28','Generate unique installation ID using timestamp and UUID'),
('migrateInstallationIdToJson','2025-12-31 11:00:32','Migrate existing installation_id from plain string to JSON format with date'),
('migrateProgressToFileProgress','2026-02-28 11:46:03','Migrate existing reading progress from UserBookProgressEntity to UserBookFileProgressEntity'),
('moveIconsToDataFolder','2025-12-29 18:45:03','Move SVG icons from resources/static/images/icons/svg to data/icons/svg'),
('populateCoversAndResizeThumbnails','2025-12-29 18:45:03','Copy thumbnails to images/{bookId}/cover.jpg and create resized 250x350 images as thumbnail.jpg'),
('populateFileHashesV2','2025-12-29 18:45:03','Calculate and store initialHash and currentHash for all books'),
('populateFileSizes','2025-12-29 18:45:03','Populate file size for existing books'),
('populateMetadataScores_v2','2025-12-29 18:45:03','Calculate and store metadata match score for all books'),
('populateSearchText','2025-12-29 18:45:03','Populate search_text column for all books');
/*!40000 ALTER TABLE `app_migration` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `app_settings`
--

DROP TABLE IF EXISTS `app_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `val` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_app_settings_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_settings`
--

LOCK TABLES `app_settings` WRITE;
/*!40000 ALTER TABLE `app_settings` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `app_settings` VALUES
(2,'cover_image_resolution','250x350'),
(3,'auto_book_search','false'),
(4,'quick_book_match','{\"libraryId\":null,\"refreshCovers\":false,\"mergeCategories\":true,\"reviewBeforeApply\":false,\"replaceMode\":\"REPLACE_MISSING\",\"fieldOptions\":{\"title\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"subtitle\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"description\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"authors\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"publisher\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"publishedDate\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"seriesName\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"seriesNumber\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"seriesTotal\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"isbn13\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"isbn10\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"language\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"categories\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"cover\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"pageCount\":{\"p1\":\"GoodReads\",\"p2\":\"Amazon\",\"p3\":\"Google\",\"p4\":\"Hardcover\"},\"asin\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"googleId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"moods\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"tags\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"comicvineId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"lubimyczytacId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"lubimyczytacRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"ranobedbId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"ranobedbRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"audibleId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"audibleRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"audibleReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null}},\"enabledFields\":{\"title\":true,\"subtitle\":true,\"description\":true,\"authors\":true,\"publisher\":true,\"publishedDate\":true,\"seriesName\":true,\"seriesNumber\":true,\"seriesTotal\":true,\"isbn13\":true,\"isbn10\":true,\"language\":true,\"categories\":true,\"cover\":true,\"pageCount\":true,\"asin\":true,\"amazonRating\":true,\"amazonReviewCount\":true,\"googleId\":true,\"goodreadsId\":true,\"goodreadsRating\":true,\"goodreadsReviewCount\":true,\"hardcoverId\":true,\"hardcoverRating\":true,\"hardcoverReviewCount\":true,\"moods\":true,\"tags\":true,\"comicvineId\":true,\"lubimyczytacId\":false,\"lubimyczytacRating\":false,\"ranobedbId\":false,\"ranobedbRating\":false,\"audibleId\":true,\"audibleRating\":true,\"audibleReviewCount\":true}}'),
(5,'library_metadata_refresh_options','[]'),
(6,'metadata_provider_settings','{\"amazon\":{\"enabled\":true,\"cookie\":\"\",\"domain\":\"com\"},\"comicvine\":{\"enabled\":false,\"apiKey\":\"\"},\"goodReads\":{\"enabled\":true},\"google\":{\"enabled\":true,\"language\":\"\",\"apiKey\":\"\"},\"hardcover\":{\"enabled\":true,\"apiKey\":\"eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJIYXJkY292ZXIiLCJ2ZXJzaW9uIjoiOCIsImp0aSI6ImRhMjY3M2Q2LWI0YmMtNGYwNC1iZGQwLTY2OTUzNWRkMTdjYSIsImFwcGxpY2F0aW9uSWQiOjIsInN1YiI6IjgxMjAwIiwiYXVkIjoiMSIsImlkIjoiODEyMDAiLCJsb2dnZWRJbiI6dHJ1ZSwiaWF0IjoxNzcyNzI3NzAwLCJleHAiOjE4MDQyNjM3MDAsImh0dHBzOi8vaGFzdXJhLmlvL2p3dC9jbGFpbXMiOnsieC1oYXN1cmEtYWxsb3dlZC1yb2xlcyI6WyJ1c2VyIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS1yb2xlIjoidXNlciIsIlgtaGFzdXJhLXVzZXItaWQiOiI4MTIwMCJ9LCJ1c2VyIjp7ImlkIjo4MTIwMH19.Yo4h5mpehNuZyvMvz_UBqvwyHUfezo29xcn42iiqOoo\"},\"douban\":{\"enabled\":false},\"lubimyczytac\":{\"enabled\":false},\"ranobedb\":{\"enabled\":false},\"audible\":{\"enabled\":false,\"domain\":\"com\"}}'),
(7,'metadata_match_weights','{\"title\":10,\"subtitle\":1,\"description\":10,\"publisher\":5,\"publishedDate\":3,\"authors\":10,\"categories\":10,\"seriesName\":2,\"seriesNumber\":2,\"seriesTotal\":1,\"isbn13\":3,\"isbn10\":5,\"pageCount\":1,\"language\":2,\"amazonRating\":3,\"amazonReviewCount\":2,\"goodreadsRating\":4,\"goodreadsReviewCount\":2,\"hardcoverRating\":2,\"hardcoverReviewCount\":1,\"doubanRating\":3,\"doubanReviewCount\":2,\"ranobedbRating\":0,\"audibleRating\":0,\"audibleReviewCount\":0,\"coverImage\":5}'),
(8,'metadata_persistence_settings','{\"saveToOriginalFile\":false,\"convertCbrCb7ToCbz\":false,\"moveFilesToLibraryPattern\":false}'),
(9,'metadata_public_reviews_settings','{\"downloadEnabled\":true,\"autoDownloadEnabled\":false,\"providers\":[{\"provider\":\"Amazon\",\"enabled\":true,\"maxReviews\":5},{\"provider\":\"GoodReads\",\"enabled\":false,\"maxReviews\":5},{\"provider\":\"Douban\",\"enabled\":false,\"maxReviews\":5}]}'),
(10,'kobo_settings','{\"convertToKepub\":false,\"conversionLimitInMb\":100,\"convertCbxToEpub\":false,\"conversionLimitInMbForCbx\":100,\"forceEnableHyphenation\":false,\"conversionImageCompressionPercentage\":85}'),
(11,'cover_cropping_settings','{\"verticalCroppingEnabled\":false,\"horizontalCroppingEnabled\":false,\"aspectRatioThreshold\":2.5,\"smartCroppingEnabled\":false}'),
(12,'upload_file_pattern','{authors}/<{series}/><{seriesIndex}. >{title}< - {authors}>< ({year})>'),
(13,'similar_book_recommendation','true'),
(14,'opds_server_enabled','true'),
(15,'cbx_cache_size_in_mb','5120'),
(16,'pdf_cache_size_in_mb','5120'),
(17,'max_file_upload_size_in_mb','100'),
(18,'metadata_download_on_bookdrop','true'),
(19,'oidc_enabled','true'),
(20,'telemetryEnabled','false'),
(21,'installation_id','{\"id\":\"c9ec88c8c485a44b1ad403cb\",\"date\":\"2025-12-31T11:00:32.833574703Z\"}'),
(22,'oidc_auto_provision_details','{\"enableAutoProvisioning\":true,\"allowLocalAccountLinking\":false,\"defaultPermissions\":[\"permissionRead\",\"permissionUpload\",\"permissionDownload\",\"permissionEditMetadata\",\"permissionManipulateLibrary\",\"permissionEmailBook\",\"permissionDeleteBook\",\"permissionSyncKoreader\",\"permissionSyncKobo\",\"permissionAccessOpds\"],\"defaultLibraryIds\":[1]}'),
(23,'oidc_provider_details','{\"providerName\": \"Authelia\", \"clientId\": \"grimmory\", \"issuerUri\": \"https://auth.ntasler.de\", \"scopes\": \"\", \"claimMapping\": {\"email\": \"email\", \"groups\": \"groups\", \"name\": \"name\", \"username\": \"preferred_username\"}}'),
(24,'last_ping_sent','2026-02-11T18:51:52.401923913Z'),
(25,'last_ping_app_version','v1.18.5'),
(26,'last_telemetry_sent','2026-02-11T18:51:52.295763547Z'),
(27,'metadata_persistence_settings_v2','{\"saveToOriginalFile\": {\"epub\": {\"enabled\": false, \"maxFileSizeInMb\": 250}, \"pdf\": {\"enabled\": false, \"maxFileSizeInMb\": 250}, \"cbx\": {\"enabled\": false, \"maxFileSizeInMb\": 250}}, \"convertCbrCb7ToCbz\": false, \"moveFilesToLibraryPattern\": false}'),
(28,'komga_group_unknown','true'),
(29,'komga_api_enabled','false'),
(30,'metadata_provider_specific_fields','{\"asin\":true,\"amazonRating\":true,\"amazonReviewCount\":true,\"googleId\":true,\"goodreadsId\":true,\"goodreadsRating\":true,\"goodreadsReviewCount\":true,\"hardcoverId\":true,\"hardcoverBookId\":true,\"hardcoverRating\":true,\"hardcoverReviewCount\":true,\"comicvineId\":true,\"lubimyczytacId\":true,\"lubimyczytacRating\":true,\"ranobedbId\":true,\"ranobedbRating\":true}'),
(31,'oidc_group_sync_mode','DISABLED'),
(32,'oidc_force_only_mode','true'),
(33,'oidc_session_duration_hours',NULL);
/*!40000 ALTER TABLE `app_settings` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) DEFAULT NULL,
  `username` varchar(255) NOT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(100) DEFAULT NULL,
  `entity_id` bigint(20) DEFAULT NULL,
  `description` varchar(1024) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `country_code` char(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_audit_log_created_at` (`created_at`),
  KEY `idx_audit_log_user_id` (`user_id`),
  KEY `idx_audit_log_action` (`action`)
) ENGINE=InnoDB AUTO_INCREMENT=178 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `audit_log` VALUES
(1,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-01 01:00:00',NULL),
(2,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-01 01:00:00',NULL),
(3,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-01 01:30:00',NULL),
(4,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Deleted Books',NULL,'2026-03-02 00:40:00',NULL),
(5,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Temporary Metadata',NULL,'2026-03-02 00:45:00',NULL),
(6,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-02 01:00:00',NULL),
(7,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-02 01:00:00',NULL),
(8,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-02 01:30:00',NULL),
(9,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-03 01:00:00',NULL),
(10,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-03 01:00:00',NULL),
(11,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-03 01:30:00',NULL),
(12,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-04 01:00:00',NULL),
(13,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-04 01:00:00',NULL),
(14,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-04 01:30:00',NULL),
(15,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-05 01:00:00',NULL),
(16,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-05 01:00:00',NULL),
(17,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-05 01:30:00',NULL),
(18,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:50:29',NULL),
(19,1,'niklas','TASK_EXECUTED','Task',NULL,'Started task: Refresh Metadata (1 books, IDs: 11)','10.1.1.148','2026-03-05 16:50:31',NULL),
(20,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:50:35',NULL),
(21,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:50:49',NULL),
(22,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:51:00',NULL),
(23,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:51:05',NULL),
(24,1,'niklas','METADATA_UPDATED','Book',10,'Updated metadata for book: Hyperion 1: Hyperion','10.1.1.148','2026-03-05 16:52:10',NULL),
(25,1,'niklas','METADATA_UPDATED','Book',10,'Updated metadata for book: Hyperion 1: Hyperion','10.1.1.148','2026-03-05 16:52:10',NULL),
(26,1,'niklas','METADATA_UPDATED','Book',10,'Updated metadata for book: Hyperion 1: Hyperion','10.1.1.148','2026-03-05 16:52:30',NULL),
(27,1,'niklas','METADATA_UPDATED','Book',10,'Updated metadata for book: Hyperion 1: Hyperion','10.1.1.148','2026-03-05 16:57:34',NULL),
(28,1,'niklas','LIBRARY_SCANNED','Library',1,'Scanned library: Default','10.1.1.148','2026-03-05 16:57:57',NULL),
(29,1,'niklas','METADATA_UPDATED','Book',11,'Updated metadata for book: The Fall of Hyperion','10.1.1.148','2026-03-05 16:58:41',NULL),
(30,1,'niklas','METADATA_UPDATED','Book',13,'Updated metadata for book: The Rise of Endymion','10.1.1.148','2026-03-05 17:01:08',NULL),
(31,1,'niklas','METADATA_UPDATED','Book',12,'Updated metadata for book: Endymion','10.1.1.148','2026-03-05 17:01:23',NULL),
(32,1,'niklas','OPDS_USER_DELETED','OpdsUser',2,'Deleted OPDS user: readest','10.1.1.148','2026-03-05 17:19:26',NULL),
(33,1,'niklas','SHELF_CREATED','Shelf',6,'Created shelf: Kobo','10.1.1.148','2026-03-05 17:40:15',NULL),
(34,1,'niklas','SHELF_DELETED','Shelf',6,'Deleted shelf: 6','10.1.1.148','2026-03-05 17:40:24',NULL),
(35,1,'niklas','SHELF_CREATED','Shelf',7,'Created shelf: Kobo','10.1.1.148','2026-03-05 17:42:21',NULL),
(36,1,'niklas','SHELF_DELETED','Shelf',7,'Deleted shelf: 7','10.1.1.148','2026-03-05 17:42:24',NULL),
(37,1,'niklas','SETTINGS_UPDATED',NULL,NULL,'Updated setting: metadata_provider_settings','10.1.1.148','2026-03-05 17:42:53',NULL),
(38,1,'niklas','METADATA_UPDATED','Book',8,'Updated metadata for book: Der Medicus','10.1.1.148','2026-03-05 17:44:50',NULL),
(39,1,'niklas','METADATA_UPDATED','Book',9,'Updated metadata for book: Der Schamane','10.1.1.148','2026-03-05 17:45:13',NULL),
(40,1,'niklas','METADATA_UPDATED','Book',6,'Updated metadata for book: Project Hail Mary','10.1.1.148','2026-03-05 17:49:05',NULL),
(41,1,'niklas','SETTINGS_UPDATED',NULL,NULL,'Updated setting: quick_book_match','10.1.1.148','2026-03-05 18:28:32',NULL),
(42,1,'niklas','MAGIC_SHELF_CREATED','MagicShelf',1,'Created magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:38:54',NULL),
(43,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:39:20',NULL),
(44,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:40:28',NULL),
(45,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:44:49',NULL),
(46,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:45:57',NULL),
(47,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:04',NULL),
(48,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:14',NULL),
(49,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:25',NULL),
(50,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:45',NULL),
(51,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:48',NULL),
(52,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:46:56',NULL),
(53,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:47:00',NULL),
(54,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:49:29',NULL),
(55,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 18:53:35',NULL),
(56,1,'niklas','TASK_EXECUTED','Task',NULL,'Started task: Refresh Metadata (19 books, IDs: 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)','10.1.1.148','2026-03-05 19:00:24',NULL),
(57,1,'niklas','METADATA_UPDATED','Book',7,'Updated metadata for book: The Wee Free Men','10.1.1.148','2026-03-05 19:05:01',NULL),
(58,1,'niklas','METADATA_UPDATED','Book',3,'Updated metadata for book: Meditation','10.1.1.148','2026-03-05 19:05:48',NULL),
(59,1,'niklas','METADATA_UPDATED','Book',3,'Updated metadata for book: Meditation','10.1.1.148','2026-03-05 19:06:24',NULL),
(60,1,'niklas','METADATA_UPDATED','Book',3,'Updated metadata for book: Meditation','10.1.1.148','2026-03-05 19:06:26',NULL),
(61,1,'niklas','METADATA_UPDATED','Book',3,'Updated metadata for book: Meditation','10.1.1.148','2026-03-05 19:06:46',NULL),
(62,1,'niklas','METADATA_UPDATED','Book',3,'Updated metadata for book: Meditation','10.1.1.148','2026-03-05 19:07:45',NULL),
(63,1,'niklas','METADATA_UPDATED','Book',2,'Updated metadata for book: Achtsamkeit statt Angst und Panik','10.1.1.148','2026-03-05 19:09:41',NULL),
(64,1,'niklas','SETTINGS_UPDATED',NULL,NULL,'Updated setting: quick_book_match','10.1.1.148','2026-03-05 19:12:36',NULL),
(65,1,'niklas','METADATA_UPDATED','Book',2,'Updated metadata for book: Achtsamkeit statt Angst und Panik','10.1.1.148','2026-03-05 19:14:33',NULL),
(66,1,'niklas','METADATA_UPDATED','Book',2,'Updated metadata for book: Achtsamkeit statt Angst und Panik','10.1.1.148','2026-03-05 19:15:51',NULL),
(67,1,'niklas','SETTINGS_UPDATED',NULL,NULL,'Updated setting: metadata_match_weights','10.1.1.148','2026-03-05 19:18:59',NULL),
(68,1,'niklas','SETTINGS_UPDATED',NULL,NULL,'Updated setting: metadata_match_weights','10.1.1.148','2026-03-05 19:19:21',NULL),
(69,1,'niklas','METADATA_UPDATED','Book',2,'Updated metadata for book: Achtsamkeit statt Angst und Panik','10.1.1.148','2026-03-05 19:19:51',NULL),
(70,1,'niklas','TASK_EXECUTED','Task',NULL,'Started task: Refresh Metadata (1 books, IDs: 2)','10.1.1.148','2026-03-05 19:19:57',NULL),
(71,1,'niklas','METADATA_UPDATED','Book',2,'Updated metadata for book: Achtsamkeit statt Angst und Panik','10.1.1.148','2026-03-05 19:20:14',NULL),
(72,1,'niklas','MAGIC_SHELF_UPDATED','MagicShelf',1,'Updated magic shelf: Missing Hardcover ID','10.1.1.148','2026-03-05 19:20:48',NULL),
(73,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-06 01:00:00',NULL),
(74,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-06 01:00:00',NULL),
(75,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-06 01:30:00',NULL),
(76,1,'niklas','AUTHOR_METADATA_UPDATED','Author',6,'Quick-matched author \'Andy Weir;\' via AUDNEXUS (ASIN: B00G0WYW92)','10.1.1.148','2026-03-06 08:27:01',NULL),
(77,1,'niklas','AUTHOR_DELETED','Author',15,'Deleted author \'Ta-Nehisi Coates\'','10.1.1.148','2026-03-06 08:27:11',NULL),
(78,1,'niklas','AUTHOR_DELETED','Author',17,'Deleted author \'Pierce Brown\'','10.1.1.148','2026-03-06 08:27:14',NULL),
(79,1,'niklas','AUTHOR_DELETED','Author',3,'Deleted author \'Mark Richards and Neal Ford\'','10.1.1.148','2026-03-06 08:27:19',NULL),
(80,1,'niklas','AUTHOR_DELETED','Author',18,'Deleted author \'Liza Klaussmann\'','10.1.1.148','2026-03-06 08:27:21',NULL),
(81,1,'niklas','AUTHOR_DELETED','Author',16,'Deleted author \'Lee Child\'','10.1.1.148','2026-03-06 08:27:23',NULL),
(82,1,'niklas','AUTHOR_DELETED','Author',8,'Deleted author \'Gordon, Noah\'','10.1.1.148','2026-03-06 08:27:26',NULL),
(83,1,'niklas','AUTHOR_DELETED','Author',6,'Deleted author \'Andy Weir;\'','10.1.1.148','2026-03-06 08:27:29',NULL),
(84,NULL,'system','AUTHOR_METADATA_UPDATED','Author',2,'Quick-matched author \'Peter Beer\' via AUDNEXUS (ASIN: B01AASFKME)',NULL,'2026-03-06 08:27:39',NULL),
(85,NULL,'system','AUTHOR_METADATA_UPDATED','Author',11,'Quick-matched author \'Ulrike Wasel\' via AUDNEXUS (ASIN: B00FNL1QZO)',NULL,'2026-03-06 08:27:40',NULL),
(86,NULL,'system','AUTHOR_METADATA_UPDATED','Author',7,'Quick-matched author \'Terry Pratchett\' via AUDNEXUS (ASIN: B000AQ0NN8)',NULL,'2026-03-06 08:27:41',NULL),
(87,NULL,'system','AUTHOR_METADATA_UPDATED','Author',12,'Quick-matched author \'Noah Gordon\' via AUDNEXUS (ASIN: B000APAMOO)',NULL,'2026-03-06 08:27:42',NULL),
(88,NULL,'system','AUTHOR_METADATA_UPDATED','Author',1,'Quick-matched author \'Nadège Nicolas\' via AUDNEXUS (ASIN: B004QUBKWW)',NULL,'2026-03-06 08:27:43',NULL),
(89,NULL,'system','AUTHOR_METADATA_UPDATED','Author',14,'Quick-matched author \'Martha Wells\' via AUDNEXUS (ASIN: B000APZA1O)',NULL,'2026-03-06 08:27:44',NULL),
(90,NULL,'system','AUTHOR_METADATA_UPDATED','Author',4,'Quick-matched author \'Mark   Richards\' via AUDNEXUS (ASIN: B00AJTA93K)',NULL,'2026-03-06 08:27:45',NULL),
(91,NULL,'system','AUTHOR_METADATA_UPDATED','Author',10,'Quick-matched author \'Klaus Timmermann\' via AUDNEXUS (ASIN: B00455P77W)',NULL,'2026-03-06 08:27:46',NULL),
(92,NULL,'system','AUTHOR_METADATA_UPDATED','Author',9,'Quick-matched author \'Dan Simmons\' via AUDNEXUS (ASIN: B000APQZD6)',NULL,'2026-03-06 08:27:47',NULL),
(93,NULL,'system','AUTHOR_METADATA_UPDATED','Author',5,'Quick-matched author \'Brown, Pierce\' via AUDNEXUS (ASIN: B00EDBZVNI)',NULL,'2026-03-06 08:27:47',NULL),
(94,NULL,'system','AUTHOR_METADATA_UPDATED','Author',13,'Quick-matched author \'Andy Weir\' via AUDNEXUS (ASIN: B00G0WYW92)',NULL,'2026-03-06 08:27:48',NULL),
(95,1,'niklas','AUTHOR_METADATA_UPDATED','Author',2,'Updated author \'Peter Beer\'','10.1.1.148','2026-03-06 08:28:14',NULL),
(96,1,'niklas','METADATA_UPDATED','Book',16,'Updated metadata for book: Rogue Protocol','10.1.1.148','2026-03-06 08:30:28',NULL),
(97,1,'niklas','METADATA_UPDATED','Book',20,'Updated metadata for book: Fugitive Telemetry','10.1.1.148','2026-03-06 08:30:52',NULL),
(98,1,'niklas','AUTHOR_METADATA_UPDATED','Author',2,'Updated author \'Peter Beer\'','10.1.1.148','2026-03-06 11:30:47',NULL),
(99,1,'niklas','METADATA_UPDATED','Book',8,'Updated metadata for book: Der Medicus','10.1.1.148','2026-03-06 11:31:17',NULL),
(100,1,'niklas','METADATA_UPDATED','Book',8,'Updated metadata for book: Der Medicus','10.1.1.148','2026-03-06 11:32:54',NULL),
(101,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-07 01:00:00',NULL),
(102,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-07 01:00:00',NULL),
(103,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-07 01:30:00',NULL),
(104,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-08 01:00:00',NULL),
(105,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-08 01:00:00',NULL),
(106,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-08 01:30:00',NULL),
(107,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Deleted Books',NULL,'2026-03-09 00:40:00',NULL),
(108,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Temporary Metadata',NULL,'2026-03-09 00:45:00',NULL),
(109,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-09 01:00:00',NULL),
(110,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-09 01:00:00',NULL),
(111,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-09 01:30:00',NULL),
(112,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-10 01:00:00',NULL),
(113,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-10 01:00:00',NULL),
(114,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-10 01:30:00',NULL),
(115,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-11 01:00:00',NULL),
(116,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-11 01:00:00',NULL),
(117,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-11 01:30:00',NULL),
(118,1,'niklas','SHELF_CREATED','Shelf',8,'Created shelf: Kobo','10.1.1.162','2026-03-11 10:00:41',NULL),
(119,1,'niklas','SHELF_DELETED','Shelf',8,'Deleted shelf: 8','10.1.1.162','2026-03-11 10:00:51',NULL),
(120,1,'niklas','SHELF_CREATED','Shelf',9,'Created shelf: Kobo','10.1.1.162','2026-03-11 10:03:30',NULL),
(121,1,'niklas','SHELF_DELETED','Shelf',9,'Deleted shelf: 9','10.1.1.162','2026-03-11 10:03:39',NULL),
(122,1,'niklas','SHELF_CREATED','Shelf',10,'Created shelf: Kobo','10.1.1.162','2026-03-11 10:05:57',NULL),
(123,1,'niklas','SHELF_DELETED','Shelf',10,'Deleted shelf: 10','10.1.1.162','2026-03-11 10:06:22',NULL),
(124,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-12 01:00:00',NULL),
(125,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-12 01:00:00',NULL),
(126,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-12 01:30:00',NULL),
(127,NULL,'system','OIDC_ACCOUNT_LINKED','User',1,'Local account linked to OIDC for user: niklas','10.1.1.148','2026-03-12 19:46:04',NULL),
(128,NULL,'system','LOGIN_SUCCESS','User',1,'Login successful for user: niklas','10.1.1.148','2026-03-12 19:46:04',NULL),
(129,NULL,'system','OIDC_LOGIN_SUCCESS','User',1,'OIDC login successful for user: niklas','10.1.1.148','2026-03-12 19:46:04',NULL),
(130,1,'niklas','OIDC_FORCE_ONLY_MODE_CHANGED',NULL,NULL,'Updated setting: oidc_force_only_mode','10.1.1.148','2026-03-12 19:46:27',NULL),
(131,1,'niklas','OIDC_FORCE_ONLY_MODE_CHANGED',NULL,NULL,'Updated setting: oidc_force_only_mode','10.1.1.148','2026-03-12 19:46:42',NULL),
(132,1,'niklas','LOGOUT','User',1,'User logged out: niklas','10.1.1.148','2026-03-12 19:46:45',NULL),
(133,NULL,'system','LOGIN_SUCCESS','User',1,'Login successful for user: niklas','10.1.1.148','2026-03-12 19:46:50',NULL),
(134,1,'niklas','OIDC_CONFIG_CHANGED',NULL,NULL,'Updated setting: oidc_provider_details','10.1.1.148','2026-03-12 19:47:11',NULL),
(135,1,'niklas','OIDC_CONFIG_CHANGED',NULL,NULL,'Updated setting: oidc_session_duration_hours','10.1.1.148','2026-03-12 19:47:11',NULL),
(136,1,'niklas','OIDC_CONNECTION_TEST',NULL,NULL,'OIDC connection test: passed','10.1.1.148','2026-03-12 19:47:21',NULL),
(137,1,'niklas','OIDC_FORCE_ONLY_MODE_CHANGED',NULL,NULL,'Updated setting: oidc_force_only_mode','10.1.1.148','2026-03-12 19:48:31',NULL),
(138,1,'niklas','OIDC_CONFIG_CHANGED',NULL,NULL,'Updated setting: oidc_auto_provision_details','10.1.1.148','2026-03-12 19:48:50',NULL),
(139,1,'niklas','OIDC_CONFIG_CHANGED',NULL,NULL,'Updated setting: oidc_group_sync_mode','10.1.1.148','2026-03-12 19:49:54',NULL),
(140,1,'niklas','LOGOUT','User',1,'User logged out: niklas','10.1.1.148','2026-03-12 19:49:55',NULL),
(141,NULL,'system','LOGIN_SUCCESS','User',1,'Login successful for user: niklas','10.1.1.148','2026-03-12 19:49:58',NULL),
(142,NULL,'system','OIDC_LOGIN_SUCCESS','User',1,'OIDC login successful for user: niklas','10.1.1.148','2026-03-12 19:49:58',NULL),
(143,1,'niklas','LOGIN_SUCCESS','User',1,'Login successful for user: niklas','10.1.1.148','2026-03-12 19:53:26',NULL),
(144,1,'niklas','OIDC_LOGIN_SUCCESS','User',1,'OIDC login successful for user: niklas','10.1.1.148','2026-03-12 19:53:26',NULL),
(145,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-13 00:00:00',NULL),
(146,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-13 00:00:00',NULL),
(147,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-13 00:30:00',NULL),
(148,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-14 00:00:00',NULL),
(149,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-14 00:00:00',NULL),
(150,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-14 00:30:00',NULL),
(151,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-15 00:00:00',NULL),
(152,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-15 00:00:00',NULL),
(153,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-15 00:30:00',NULL),
(154,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Deleted Books',NULL,'2026-03-15 23:40:00',NULL),
(155,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Cleanup Temporary Metadata',NULL,'2026-03-15 23:45:00',NULL),
(156,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-16 00:00:00',NULL),
(157,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-16 00:00:00',NULL),
(158,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-16 00:30:00',NULL),
(159,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-17 00:00:00',NULL),
(160,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-17 00:00:00',NULL),
(161,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-17 00:30:00',NULL),
(162,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-18 00:00:00',NULL),
(163,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-18 00:00:00',NULL),
(164,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-18 00:30:00',NULL),
(165,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-19 00:00:00',NULL),
(166,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-19 00:00:00',NULL),
(167,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-19 00:30:00',NULL),
(168,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-20 00:00:00',NULL),
(169,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-20 00:00:00',NULL),
(170,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-20 00:30:00',NULL),
(171,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Sync Library Files',NULL,'2026-03-21 00:00:00',NULL),
(172,-1,'system','LIBRARY_SCANNED','Library',1,'Scanned library: Default',NULL,'2026-03-21 00:00:00',NULL),
(173,-1,'system','TASK_EXECUTED','Task',NULL,'Started task: Update Book Recommendations',NULL,'2026-03-21 00:30:00',NULL),
(174,NULL,'system','OIDC_LOGIN_FAILED',NULL,NULL,'OIDC callback login failed','10.1.1.148','2026-03-21 19:09:49',NULL),
(175,NULL,'system','OIDC_LOGIN_FAILED',NULL,NULL,'OIDC callback login failed','10.1.1.148','2026-03-21 19:10:09',NULL),
(176,NULL,'system','LOGIN_SUCCESS','User',1,'Login successful for user: niklas','10.1.1.148','2026-03-21 19:12:42',NULL),
(177,NULL,'system','OIDC_LOGIN_SUCCESS','User',1,'OIDC login successful for user: niklas','10.1.1.148','2026-03-21 19:12:42',NULL);
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `author`
--

DROP TABLE IF EXISTS `author`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `author` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `asin` varchar(20) DEFAULT NULL,
  `name_locked` tinyint(1) NOT NULL DEFAULT 0,
  `description_locked` tinyint(1) NOT NULL DEFAULT 0,
  `asin_locked` tinyint(1) NOT NULL DEFAULT 0,
  `photo_locked` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_name` (`name`),
  KEY `idx_author_asin` (`asin`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `author`
--

LOCK TABLES `author` WRITE;
/*!40000 ALTER TABLE `author` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `author` VALUES
(1,'Nadège Nicolas','Nicola May is a rom-com superstar. She is the author of eighteen romantic comedies, all of which have appeared in the Kindle bestseller charts. The Corner Shop in Cockleberry Bay became the best-selling Kindle book in the UK, across all genres, in January 2019, and was Amazon’s third-bestselling novel in that year. It spawned three sequels, followed by the hit Ferry Lane Market trilogy. She is now published in 15 languages. Her new novel HOW DO I TELL YOU? is out January 2025','B004QUBKWW',0,0,0,0),
(2,'Peter Beer',NULL,NULL,0,0,0,0),
(4,'Mark   Richards','Once upon a time I had a business in financial services: nice suits, smart shirts, stripy ties. But always with a small voice inside me. “Let me out,” it said, “I’m a writer.” I kept the small voice securely under lock and key but then – in 2009 – my brother died of cancer. It was one of those pivotal moments in life. I either let the small voice out and pursued my dream, or I forgot about it for good. So I sold my business, sent my stripy ties to the charity shop and started writing. Now my time divides between writing for clients – copywriting, ghostwriting – and writing for myself. In the spring of 2016 I suffered the latest in a long line of mid-life crises and invited my youngest son to come for a walk with me. That led to ‘Father, Son and the Pennine Way’ – the first of three books ostensibly about walking, but really about my ever-changing relationship with my son. …And now – in September 2020 – I’ve turned my attention to novels. ‘Salt in the Wounds’ in the first book in the Michael Brady series and, when that’s finished, I’ll look to develop two other crime series. You can connect with me online at: W  F','B00AJTA93K',0,0,0,0),
(5,'Brown, Pierce','Pierce Brown is the #1 New York Times Bestselling author of the Red Rising Saga. He spent his childhood building forts and setting traps for his cousins in the woods of six states and the deserts of two. He now lives in Los Angeles, where he scribbles tales of spaceships, wizards, ghouls, and most things old or bizarre.','B00EDBZVNI',0,0,0,0),
(7,'Terry Pratchett','Terry Pratchett sold his first story when he was fifteen, which earned him enough money to buy a second-hand typewriter. His first novel, a humorous fantasy entitled The Carpet People, appeared in 1971 from the publisher Colin Smythe. Terry worked for many years as a journalist and press officer, writing in his spare time and publishing a number of novels, including his first Discworld novel, The Color of Magic, in 1983. In 1987 he turned to writing full time, and has not looked back since. To date there are a total of 36 books in the Discworld series, of which four (so far) are written for children. The first of these children\'s books, The Amazing Maurice and His Educated Rodents, won the Carnegie Medal. A non-Discworld book, Good Omens, his 1990 collaboration with Neil Gaiman, has been a longtime bestseller, and was reissued in hardcover by William Morrow in early 2006 (it is also available as a mass market paperback (Harper Torch, 2006) and trade paperback (Harper Paperbacks, 2006). Terry\'s latest book, Nation, a non-Discworld standalone YA novel was published in October of 2008 and was an instant New York Times and London Times bestseller. Regarded as one of the most significant contemporary English-language satirists, Pratchett has won numerous literary awards, was named an Officer of the British Empire “for services to literature” in 1998, and has received four honorary doctorates from the Universities of Warwick, Portsmouth, Bath, and Bristol. His acclaimed novels have sold more than 55 million copies (give or take a few million) and have been translated into 36 languages. Terry Pratchett lived in England with his family, and spent too much time at his word processor. Some of Terry\'s accolades include: The Carnegie Medal, Locus Awards, the Mythopoetic Award, ALA Notable Books for Children, ALA Best Books for Young Adults, Book Sense 76 Pick, Prometheus Award and the British Fantasy Award.','B000AQ0NN8',0,0,0,0),
(9,'Dan Simmons','Dan Simmons was born in Peoria, Illinois, in 1948, and grew up in various cities and small towns in the Midwest, including Brimfield, Illinois, which was the source of his fictional \"Elm Haven\" in 1991\'s SUMMER OF NIGHT and 2002\'s A WINTER HAUNTING. Dan received a  in English from Wabash College in 1970, winning a national Phi Beta Kappa Award during his senior year for excellence in fiction, journalism and art. Dan received his Masters in Education from Washington University in St. Louis in 1971. He then worked in elementary education for 18 years -- 2 years in Missouri, 2 years in Buffalo, New York -- one year as a specially trained BOCES \"resource teacher\" and another as a sixth-grade teacher -- and 14 years in Colorado. His last four years in teaching were spent creating, coordinating, and teaching in APEX, an extensive gifted/talented program serving 19 elementary schools and some 15,000 potential students. During his years of teaching, he won awards from the Colorado Education Association and was a finalist for the Colorado Teacher of the Year. He also worked as a national language-arts consultant, sharing his own \"Writing Well\" curriculum which he had created for his own classroom. Eleven and twelve-year-old students in Simmons\' regular 6th-grade class averaged junior-year in high school writing ability according to annual standardized and holistic writing assessments. Whenever someone says \"writing can\'t be taught,\" Dan begs to differ and has the track record to prove it. Since becoming a full-time writer, Dan likes to visit college writing classes, has taught in New Hampshire\'s Odyssey writing program for adults, and is considering hosting his own Windwalker Writers\' Workshop. Dan\'s first published story appeared on Feb. 15, 1982, the day his daughter, Jane Kathryn, was born. He\'s always attributed that coincidence to \"helping in keeping things in perspective when it comes to the relative importance of writing and life.\" Dan has been a full-time writer since 1987 and lives along the Front Range of Colorado -- in the same town where he taught for 14 years -- with his wife, Karen. He sometimes writes at Windwalker -- their mountain property and cabin at 8,400 feet of altitude at the base of the Continental Divide, just south of Rocky Mountain National Park. An  sculpture of the Shrike -- a thorned and frightening character from the four Hyperion/Endymion novels -- was sculpted by an ex-student and friend, Clee Richeson, and the sculpture now stands guard near the isolated cabin. Dan is one of the few novelists whose work spans the genres of fantasy, science fiction, horror, suspense, historical fiction, noir crime fiction, and mainstream literary fiction . His books are published in 27 foreign counties as well as the  and Canada. Many of Dan\'s books and stories have been optioned for film, including SONG OF KALI, DROOD, THE CROOK FACTORY, and others. Some, such as the four HYPERION novels and single Hyperion-universe novella \"Orphans of the Helix\", and CARRION COMFORT have been purchased (the Hyperion books by Warner Brothers and Graham King Films, CARRION COMFORT by European filmmaker Casta Gavras\'s company) and are in pre-production. Director Scott Derrickson (\"The Day the Earth Stood Stood Still\") has been announced as the director for the Hyperion movie and Casta Gavras\'s son has been put at the helm of the French production of Carrion Comfort. Current discussions for other possible options include THE TERROR. Dan\'s hardboiled Joe Kurtz novels are currently being looked as the basis for a possible cable TV series. In 1995, Dan\'s alma mater, Wabash College, awarded him an honorary doctorate for his contributions in education and writing.','B000APQZD6',0,0,0,0),
(10,'Klaus Timmermann','','B00455P77W',0,0,0,0),
(11,'Ulrike Wasel','','B00FNL1QZO',0,0,0,0),
(12,'Noah Gordon','Noah Gordon’s international bestsellers have sold millions of copies and have won a number of awards, among them, in America, the James Fenimore Cooper Prize for historical fiction. He lives outside of Boston with his wife, Lorraine Gordon.','B000APAMOO',0,0,0,0),
(13,'Andy Weir','ANDY WEIR built a two-decade career as a software engineer until the success of his first published novel, The Martian, allowed him to live out his dream of writing full-time. He is a lifelong space nerd and a devoted hobbyist of such subjects as relativistic physics, orbital mechanics, and the history of manned spaceflight. He also mixes a mean cocktail. He lives in California.','B00G0WYW92',0,0,0,0),
(14,'Martha Wells','Martha Wells has been writing science fiction and fantasy since 1993. Her work includes The Murderbot Diaries, The Books of the Raksura, the Ile-Rien series, and most recently Witch King and its sequel Queen Demon, as well as other novels, short fiction, non-fiction, and media tie-ins. She is a member of the Texas Literary Hall of Fame, and her work has won Nebula, Hugo, Locus Awards, and an Alex Award and a Dragon Award. It has also appeared on the World Fantasy, Philip K. Dick, and the British Science Fiction Association Award ballots, as well as the New York Times, USA Today, and the Sunday Times Bestseller Lists. Her books have been translated into over thirty languages.','B000APZA1O',0,0,0,0);
/*!40000 ALTER TABLE `author` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book`
--

DROP TABLE IF EXISTS `book`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `library_id` bigint(20) NOT NULL,
  `library_path_id` bigint(20) DEFAULT NULL,
  `added_on` timestamp NULL DEFAULT current_timestamp(),
  `similar_books_json` text DEFAULT NULL,
  `metadata_match_score` float DEFAULT NULL,
  `read_status` varchar(20) DEFAULT 'UNREAD',
  `deleted` tinyint(1) DEFAULT 0,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `metadata_updated_at` timestamp NULL DEFAULT NULL,
  `metadata_for_write_updated_at` timestamp NULL DEFAULT NULL,
  `book_cover_hash` varchar(20) DEFAULT NULL,
  `is_physical` tinyint(1) NOT NULL DEFAULT 0,
  `audiobook_cover_hash` varchar(20) DEFAULT NULL,
  `scanned_on` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_library_path_id` (`library_path_id`),
  KEY `idx_library_id` (`library_id`),
  KEY `idx_book_deleted` (`deleted`),
  KEY `idx_book_deleted_at` (`deleted_at`),
  KEY `idx_book_is_physical` (`is_physical`),
  CONSTRAINT `fk_library` FOREIGN KEY (`library_id`) REFERENCES `library` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_library_path_id` FOREIGN KEY (`library_path_id`) REFERENCES `library_path` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book`
--

LOCK TABLES `book` WRITE;
/*!40000 ALTER TABLE `book` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book` VALUES
(2,1,1,'2026-02-03 17:46:07','[{\"b\":20,\"s\":0.3453699098061722},{\"b\":15,\"s\":0.38183774960767025},{\"b\":12,\"s\":0.24488272803298625},{\"b\":3,\"s\":0.5770422121098784},{\"b\":16,\"s\":0.2904690998963384},{\"b\":19,\"s\":0.3521291846817587},{\"b\":14,\"s\":0.29641067433425516},{\"b\":17,\"s\":0.22623354392973583},{\"b\":7,\"s\":0.20069256035327623},{\"b\":9,\"s\":0.15719549837837185},{\"b\":11,\"s\":0.17334818593659662},{\"b\":18,\"s\":0.33812742789608935},{\"b\":6,\"s\":0.2821411058382022},{\"b\":5,\"s\":0.3337093439811749},{\"b\":4,\"s\":0.17711105229935742},{\"b\":10,\"s\":0.267922943165292},{\"b\":13,\"s\":0.28615503071414183},{\"b\":8,\"s\":0.1401472899649013}]',79.7753,'UNREAD',0,NULL,'2026-03-05 17:20:14','2026-03-05 17:20:02','BL-S43VXDPRKRC6G',0,NULL,NULL),
(3,1,1,'2026-02-03 17:46:08','[{\"b\":13,\"s\":0.20435099191637848},{\"b\":16,\"s\":0.2425356250363329},{\"b\":20,\"s\":0.24663792724813194},{\"b\":12,\"s\":0.21218788062107702},{\"b\":15,\"s\":0.2951194231401004},{\"b\":17,\"s\":0.41987702968967244},{\"b\":2,\"s\":0.5770422121098784},{\"b\":5,\"s\":0.1798478625208558},{\"b\":19,\"s\":0.3085280973759145},{\"b\":10,\"s\":0.24417016420109805},{\"b\":18,\"s\":0.30161122293329606},{\"b\":7,\"s\":0.14552486905820067},{\"b\":14,\"s\":0.25187268534730034},{\"b\":4,\"s\":0.15190124858317952},{\"b\":6,\"s\":0.17411430002640277},{\"b\":11,\"s\":0.24222877908308277}]',79.7753,'UNREAD',0,NULL,'2026-03-05 17:07:45','2026-03-05 17:00:35','BL-FTF5JFVMT4YCU',0,NULL,NULL),
(4,1,1,'2026-02-03 17:46:08','[{\"b\":19,\"s\":0.2568069718456461},{\"b\":2,\"s\":0.17711105229935742},{\"b\":13,\"s\":0.15672535197891746},{\"b\":14,\"s\":0.19091241456360708},{\"b\":20,\"s\":0.19911260778803197},{\"b\":7,\"s\":0.12000079339629816},{\"b\":8,\"s\":0.21815377450367382},{\"b\":12,\"s\":0.27836385273211134},{\"b\":16,\"s\":0.17750887329570952},{\"b\":11,\"s\":0.21986507344652245},{\"b\":15,\"s\":0.21680938828600546},{\"b\":18,\"s\":0.13274293224065745},{\"b\":10,\"s\":0.1921923554643351},{\"b\":17,\"s\":0.1485949032928252},{\"b\":5,\"s\":0.24022758862593227},{\"b\":3,\"s\":0.15190124858317952}]',82.0225,'UNREAD',0,NULL,'2026-03-05 17:00:39','2026-03-05 17:00:39','BL-W4T2GEYU4O2G0',0,NULL,NULL),
(5,1,1,'2026-02-07 12:15:23','[{\"b\":4,\"s\":0.24022758862593227},{\"b\":8,\"s\":0.46237000419984364},{\"b\":14,\"s\":0.6352198406395767},{\"b\":11,\"s\":0.4718220111190191},{\"b\":2,\"s\":0.3337093439811749},{\"b\":7,\"s\":0.3186000460701751},{\"b\":20,\"s\":0.4191024219354738},{\"b\":16,\"s\":0.5340085925505903},{\"b\":12,\"s\":0.6105845885204998},{\"b\":10,\"s\":0.5848188106701129},{\"b\":19,\"s\":0.5640422362405234},{\"b\":18,\"s\":0.3183595103383727},{\"b\":15,\"s\":0.5600677653848302},{\"b\":13,\"s\":0.39716243605692836},{\"b\":17,\"s\":0.258844277250269},{\"b\":6,\"s\":0.5378747578005559},{\"b\":9,\"s\":0.2458950311280015},{\"b\":3,\"s\":0.1798478625208558}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:00:47','2026-03-05 17:00:47','BL-OVQD51RFWXNXX',0,NULL,NULL),
(6,1,1,'2026-02-07 12:17:39','[{\"b\":5,\"s\":0.5378747578005559},{\"b\":16,\"s\":0.4645181264313394},{\"b\":7,\"s\":0.30566428796034806},{\"b\":12,\"s\":0.45873305849627405},{\"b\":18,\"s\":0.3379583218950666},{\"b\":14,\"s\":0.4443936478908247},{\"b\":17,\"s\":0.24227185592617448},{\"b\":3,\"s\":0.17411430002640277},{\"b\":2,\"s\":0.2821411058382022},{\"b\":11,\"s\":0.4151056535185492},{\"b\":20,\"s\":0.418420826252644},{\"b\":9,\"s\":0.3404199087681481},{\"b\":15,\"s\":0.4230658136901963},{\"b\":8,\"s\":0.2249724707883447},{\"b\":13,\"s\":0.4420184178177882},{\"b\":19,\"s\":0.4487401719653411},{\"b\":10,\"s\":0.4214383446870858}]',76.4045,'UNREAD',0,NULL,'2026-03-05 17:00:53','2026-03-05 17:00:53','BL-VKYPPX0A9KXQN',0,NULL,NULL),
(7,1,1,'2026-02-07 12:17:40','[{\"b\":5,\"s\":0.3186000460701751},{\"b\":15,\"s\":0.23455500848479607},{\"b\":12,\"s\":0.288200393069114},{\"b\":13,\"s\":0.3766832503135626},{\"b\":10,\"s\":0.20966577400385064},{\"b\":17,\"s\":0.1594214919701174},{\"b\":6,\"s\":0.30566428796034806},{\"b\":20,\"s\":0.31641012689604214},{\"b\":11,\"s\":0.22066604175836926},{\"b\":8,\"s\":0.16218408041084809},{\"b\":19,\"s\":0.330582796709004},{\"b\":14,\"s\":0.2829901415763554},{\"b\":16,\"s\":0.3596725012441572},{\"b\":9,\"s\":0.27514334116167527},{\"b\":2,\"s\":0.20069256035327623},{\"b\":18,\"s\":0.2562048358688731},{\"b\":3,\"s\":0.14552486905820067},{\"b\":4,\"s\":0.12000079339629816}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:05:01','2026-03-05 17:01:01','BL-F2BDN2V0QENBJ',0,NULL,NULL),
(8,1,1,'2026-02-07 17:17:15','[{\"b\":19,\"s\":0.2707798160971009},{\"b\":6,\"s\":0.2249724707883447},{\"b\":15,\"s\":0.29511634690344074},{\"b\":4,\"s\":0.21815377450367382},{\"b\":13,\"s\":0.2621250743920687},{\"b\":5,\"s\":0.46237000419984364},{\"b\":16,\"s\":0.37717563084449474},{\"b\":14,\"s\":0.2914666532432312},{\"b\":7,\"s\":0.16218408041084809},{\"b\":2,\"s\":0.1401472899649013},{\"b\":20,\"s\":0.3145172643264713},{\"b\":10,\"s\":0.38821747940089335},{\"b\":12,\"s\":0.4181934794568106},{\"b\":11,\"s\":0.2643038052177695}]',87.6404,'UNREAD',0,NULL,'2026-03-06 09:32:54','2026-03-05 17:01:11','BL-SULF0R4VNRV7J',0,NULL,NULL),
(9,1,1,'2026-02-28 16:30:33','[{\"b\":7,\"s\":0.27514334116167527},{\"b\":6,\"s\":0.3404199087681481},{\"b\":12,\"s\":0.27545329989724837},{\"b\":14,\"s\":0.24580378584103799},{\"b\":5,\"s\":0.2458950311280015},{\"b\":11,\"s\":0.21661266941181684},{\"b\":13,\"s\":0.278966826878299},{\"b\":10,\"s\":0.23949319385980425},{\"b\":15,\"s\":0.2808351765250693},{\"b\":2,\"s\":0.15719549837837185},{\"b\":18,\"s\":0.12876731300127242},{\"b\":20,\"s\":0.49457909548478546},{\"b\":16,\"s\":0.4914723177028987},{\"b\":19,\"s\":0.33281065011120814}]',87.6404,'UNREAD',0,NULL,'2026-03-05 17:01:18','2026-03-05 17:01:18','BL-67TS00WSYA47O',0,NULL,NULL),
(10,1,1,'2026-03-05 14:48:55','[{\"b\":20,\"s\":0.35971845827822496},{\"b\":18,\"s\":0.28259642014421077},{\"b\":17,\"s\":0.29937505379476964},{\"b\":16,\"s\":0.5123814223720757},{\"b\":6,\"s\":0.4214383446870858},{\"b\":3,\"s\":0.24417016420109805},{\"b\":19,\"s\":0.5965678971996722},{\"b\":15,\"s\":0.5476511208535928},{\"b\":9,\"s\":0.23949319385980425},{\"b\":8,\"s\":0.38821747940089335},{\"b\":2,\"s\":0.267922943165292},{\"b\":5,\"s\":0.5848188106701129},{\"b\":4,\"s\":0.1921923554643351},{\"b\":14,\"s\":0.5057838207931923},{\"b\":7,\"s\":0.20966577400385064}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:01:26','2026-03-05 17:01:26','BL-K2F2TV9SDLE4M',0,NULL,NULL),
(11,1,1,'2026-03-05 14:48:56','[{\"b\":8,\"s\":0.2643038052177695},{\"b\":14,\"s\":0.49570827568906856},{\"b\":20,\"s\":0.3555586976375615},{\"b\":18,\"s\":0.34854263371996},{\"b\":16,\"s\":0.5017491414702229},{\"b\":17,\"s\":0.26721077002832155},{\"b\":9,\"s\":0.21661266941181684},{\"b\":2,\"s\":0.17334818593659662},{\"b\":5,\"s\":0.4718220111190191},{\"b\":6,\"s\":0.4151056535185492},{\"b\":3,\"s\":0.24222877908308277},{\"b\":19,\"s\":0.5134593488871502},{\"b\":15,\"s\":0.5125944987239183},{\"b\":4,\"s\":0.21986507344652245},{\"b\":7,\"s\":0.22066604175836926}]',87.6404,'UNREAD',0,NULL,'2026-03-05 17:01:31','2026-03-05 17:01:31','BL-KV8FV979S8X7S',0,NULL,NULL),
(12,1,1,'2026-03-05 14:56:25','[{\"b\":15,\"s\":0.5396771377277246},{\"b\":6,\"s\":0.45873305849627405},{\"b\":9,\"s\":0.27545329989724837},{\"b\":5,\"s\":0.6105845885204998},{\"b\":18,\"s\":0.33031352859740537},{\"b\":17,\"s\":0.29421348886716514},{\"b\":7,\"s\":0.288200393069114},{\"b\":8,\"s\":0.4181934794568106},{\"b\":14,\"s\":0.49643845509547824},{\"b\":19,\"s\":0.5824209709764185},{\"b\":20,\"s\":0.373044486658172},{\"b\":2,\"s\":0.24488272803298625},{\"b\":16,\"s\":0.5688029080436432},{\"b\":4,\"s\":0.27836385273211134},{\"b\":3,\"s\":0.21218788062107702}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:01:40','2026-03-05 17:01:40','BL-6W9DE1SHVRFCH',0,NULL,NULL),
(13,1,1,'2026-03-05 14:56:25','[{\"b\":16,\"s\":0.49943644747781446},{\"b\":18,\"s\":0.31964321312957783},{\"b\":7,\"s\":0.3766832503135626},{\"b\":3,\"s\":0.20435099191637848},{\"b\":17,\"s\":0.31496653658313767},{\"b\":5,\"s\":0.39716243605692836},{\"b\":4,\"s\":0.15672535197891746},{\"b\":8,\"s\":0.2621250743920687},{\"b\":15,\"s\":0.4968025272182409},{\"b\":2,\"s\":0.28615503071414183},{\"b\":6,\"s\":0.4420184178177882},{\"b\":20,\"s\":0.4117548726437988},{\"b\":9,\"s\":0.278966826878299},{\"b\":14,\"s\":0.4279524556186876},{\"b\":19,\"s\":0.5083978490924063}]',87.6404,'UNREAD',0,NULL,'2026-03-05 17:01:47','2026-03-05 17:01:47','BL-8BW25KHPE48W2',0,NULL,NULL),
(14,1,1,'2026-03-05 16:31:01','[{\"b\":13,\"s\":0.4279524556186876},{\"b\":2,\"s\":0.29641067433425516},{\"b\":11,\"s\":0.49570827568906856},{\"b\":9,\"s\":0.24580378584103799},{\"b\":10,\"s\":0.5057838207931923},{\"b\":8,\"s\":0.2914666532432312},{\"b\":7,\"s\":0.2829901415763554},{\"b\":5,\"s\":0.6352198406395767},{\"b\":4,\"s\":0.19091241456360708},{\"b\":12,\"s\":0.49643845509547824},{\"b\":6,\"s\":0.4443936478908247},{\"b\":3,\"s\":0.25187268534730034}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:01:57','2026-03-05 17:01:57','BL-2KASK2PUYK30N',0,NULL,NULL),
(15,1,1,'2026-03-05 16:31:02','[{\"b\":10,\"s\":0.5476511208535928},{\"b\":2,\"s\":0.38183774960767025},{\"b\":9,\"s\":0.2808351765250693},{\"b\":4,\"s\":0.21680938828600546},{\"b\":12,\"s\":0.5396771377277246},{\"b\":11,\"s\":0.5125944987239183},{\"b\":6,\"s\":0.4230658136901963},{\"b\":8,\"s\":0.29511634690344074},{\"b\":3,\"s\":0.2951194231401004},{\"b\":13,\"s\":0.4968025272182409},{\"b\":7,\"s\":0.23455500848479607},{\"b\":5,\"s\":0.5600677653848302}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:02:05','2026-03-05 17:02:05','BL-PAW9S7UGFKE9D',0,NULL,NULL),
(16,1,1,'2026-03-05 16:31:02','[{\"b\":8,\"s\":0.37717563084449474},{\"b\":4,\"s\":0.17750887329570952},{\"b\":3,\"s\":0.2425356250363329},{\"b\":5,\"s\":0.5340085925505903},{\"b\":9,\"s\":0.4914723177028987},{\"b\":13,\"s\":0.49943644747781446},{\"b\":7,\"s\":0.3596725012441572},{\"b\":12,\"s\":0.5688029080436432},{\"b\":10,\"s\":0.5123814223720757},{\"b\":2,\"s\":0.2904690998963384},{\"b\":6,\"s\":0.4645181264313394},{\"b\":11,\"s\":0.5017491414702229}]',88.764,'UNREAD',0,NULL,'2026-03-06 06:30:28','2026-03-05 17:02:10','BL-YGUZGIKR3OANV',0,NULL,NULL),
(17,1,1,'2026-03-05 16:31:02','[{\"b\":6,\"s\":0.24227185592617448},{\"b\":13,\"s\":0.31496653658313767},{\"b\":10,\"s\":0.29937505379476964},{\"b\":2,\"s\":0.22623354392973583},{\"b\":5,\"s\":0.258844277250269},{\"b\":12,\"s\":0.29421348886716514},{\"b\":11,\"s\":0.26721077002832155},{\"b\":3,\"s\":0.41987702968967244},{\"b\":7,\"s\":0.1594214919701174},{\"b\":4,\"s\":0.1485949032928252}]',82.0225,'UNREAD',0,NULL,'2026-03-05 17:02:17','2026-03-05 17:02:17','BL-J3WFGYR7C4JQX',0,NULL,NULL),
(18,1,1,'2026-03-05 16:31:03','[{\"b\":12,\"s\":0.33031352859740537},{\"b\":4,\"s\":0.13274293224065745},{\"b\":9,\"s\":0.12876731300127242},{\"b\":2,\"s\":0.33812742789608935},{\"b\":5,\"s\":0.3183595103383727},{\"b\":3,\"s\":0.30161122293329606},{\"b\":7,\"s\":0.2562048358688731},{\"b\":10,\"s\":0.28259642014421077},{\"b\":11,\"s\":0.34854263371996},{\"b\":13,\"s\":0.31964321312957783},{\"b\":6,\"s\":0.3379583218950666}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:02:25','2026-03-05 17:02:25','BL-T2HKGEY5CKQOF',0,NULL,NULL),
(19,1,1,'2026-03-05 16:31:03','[{\"b\":13,\"s\":0.5083978490924063},{\"b\":3,\"s\":0.3085280973759145},{\"b\":5,\"s\":0.5640422362405234},{\"b\":9,\"s\":0.33281065011120814},{\"b\":4,\"s\":0.2568069718456461},{\"b\":2,\"s\":0.3521291846817587},{\"b\":12,\"s\":0.5824209709764185},{\"b\":8,\"s\":0.2707798160971009},{\"b\":10,\"s\":0.5965678971996722},{\"b\":6,\"s\":0.4487401719653411},{\"b\":11,\"s\":0.5134593488871502},{\"b\":7,\"s\":0.330582796709004}]',88.764,'UNREAD',0,NULL,'2026-03-05 17:02:33','2026-03-05 17:02:33','BL-G1XTD3DOTBYEB',0,NULL,NULL),
(20,1,1,'2026-03-05 16:31:03','[{\"b\":11,\"s\":0.3555586976375615},{\"b\":5,\"s\":0.4191024219354738},{\"b\":13,\"s\":0.4117548726437988},{\"b\":8,\"s\":0.3145172643264713},{\"b\":10,\"s\":0.35971845827822496},{\"b\":3,\"s\":0.24663792724813194},{\"b\":6,\"s\":0.418420826252644},{\"b\":4,\"s\":0.19911260778803197},{\"b\":2,\"s\":0.3453699098061722},{\"b\":7,\"s\":0.31641012689604214},{\"b\":9,\"s\":0.49457909548478546},{\"b\":12,\"s\":0.373044486658172}]',88.764,'UNREAD',0,NULL,'2026-03-06 06:30:52','2026-03-05 17:02:38','BL-VRWMHPG3DE43N',0,NULL,NULL);
/*!40000 ALTER TABLE `book` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_award`
--

DROP TABLE IF EXISTS `book_award`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_award` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `book_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `awarded_at` timestamp NOT NULL,
  `category` varchar(255) NOT NULL,
  `designation` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_book_award` (`book_id`,`name`,`category`,`awarded_at`),
  CONSTRAINT `fk_book_awards_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_award`
--

LOCK TABLES `book_award` WRITE;
/*!40000 ALTER TABLE `book_award` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `book_award` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_file`
--

DROP TABLE IF EXISTS `book_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_file` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `book_id` bigint(20) NOT NULL,
  `file_name` varchar(1000) NOT NULL,
  `file_sub_path` varchar(512) NOT NULL,
  `file_size_kb` bigint(20) DEFAULT NULL,
  `initial_hash` varchar(128) DEFAULT NULL,
  `current_hash` varchar(128) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `added_on` timestamp NULL DEFAULT current_timestamp(),
  `is_book` tinyint(1) DEFAULT 0,
  `book_type` varchar(32) DEFAULT NULL,
  `archive_type` varchar(255) DEFAULT NULL,
  `alt_format_current_hash` varchar(128) GENERATED ALWAYS AS (case when `is_book` = 1 then `current_hash` end) STORED,
  `is_folder_based` tinyint(1) NOT NULL DEFAULT 0,
  `duration_seconds` bigint(20) DEFAULT NULL,
  `bitrate` int(11) DEFAULT NULL,
  `sample_rate` int(11) DEFAULT NULL,
  `channels` int(11) DEFAULT NULL,
  `codec` varchar(50) DEFAULT NULL,
  `chapter_count` int(11) DEFAULT NULL,
  `chapters_json` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_book_additional_file_book_id` (`book_id`),
  KEY `idx_book_file_current_hash_alt_format` (`alt_format_current_hash`),
  CONSTRAINT `fk_book_file_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_file`
--

LOCK TABLES `book_file` WRITE;
/*!40000 ALTER TABLE `book_file` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_file` VALUES
(1,2,'Achtsamkeit statt Angst und Panik Mit Meditation zu Ruhe, Frieden und (Selbst-)Sicherheit - Peter Beer (2022).epub','Peter Beer',583,NULL,'b92a14c256b171164676ef6ca2335add',NULL,'2026-02-03 17:46:07',1,'EPUB',NULL,'b92a14c256b171164676ef6ca2335add',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(2,3,'Meditation - Peter Beer (2021).epub','Peter Beer',3236,NULL,'b95840175cd2b2439fa3b7e2b11446b0',NULL,'2026-02-03 17:46:08',1,'EPUB',NULL,'b95840175cd2b2439fa3b7e2b11446b0',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(3,4,'Fundamentals of Software Architecture (for Raymond Rhine) - Mark Richards and Neal Ford (2025).epub','Mark Richards and Neal Ford',23180,NULL,'28ed0f974dbf94c727aaf9d8a2dfab74',NULL,'2026-02-03 17:46:08',1,'EPUB',NULL,'28ed0f974dbf94c727aaf9d8a2dfab74',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(4,5,'Red Rising 01 - Red Rising - Brown, Pierce (2019).epub','Brown, Pierce',804,NULL,'54749951e2fa19053e8651f079f0cd9f',NULL,'2026-02-07 12:15:23',1,'EPUB',NULL,'54749951e2fa19053e8651f079f0cd9f',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(5,6,'Project Hail Mary - Andy Weir; (2021).epub','Andy Weir;',9593,NULL,'fb2010081fe45bb216be1719220f369f',NULL,'2026-02-07 12:17:39',1,'EPUB',NULL,'fb2010081fe45bb216be1719220f369f',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(6,7,'The Wee Free Men - Terry Pratchett (2015).epub','Terry Pratchett',1371,NULL,'acc5151a4789038c7143dc2fa5bd9f21',NULL,'2026-02-07 12:17:40',1,'EPUB',NULL,'acc5151a4789038c7143dc2fa5bd9f21',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(7,8,'1. [Medicus 01] • Der Medicus - Gordon, Noah (2011).epub','Gordon, Noah/Medicus',1148,NULL,'6c54952637cddd2f27cacb84576e29ec',NULL,'2026-02-07 17:17:15',1,'EPUB',NULL,'6c54952637cddd2f27cacb84576e29ec',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(8,9,'02. Medicus 02 - Der Schamane - Gordon, Noah (2013).epub','Gordon, Noah/Medicus',920,'8033b5a3ffc16364df97417e04b145c8','8033b5a3ffc16364df97417e04b145c8',NULL,'2026-02-28 16:30:33',1,'EPUB',NULL,'8033b5a3ffc16364df97417e04b145c8',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(9,10,'Hyperion 1 Hyperion - Dan Simmons (2015).epub','Dan Simmons',878,'a59e1f2bf773ba8ff1740eacbbae6300','a59e1f2bf773ba8ff1740eacbbae6300',NULL,'2026-03-05 14:48:55',1,'EPUB',NULL,'a59e1f2bf773ba8ff1740eacbbae6300',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(10,11,'The Fall of Hyperion - Dan Simmons (2011).epub','Dan Simmons',1316,'e8ce5f8b59a4a3c50f632d4b736a175b','e8ce5f8b59a4a3c50f632d4b736a175b',NULL,'2026-03-05 14:48:56',1,'EPUB',NULL,'e8ce5f8b59a4a3c50f632d4b736a175b',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(11,12,'Endymion - Dan Simmons (1996).epub','Dan Simmons',691,'fa66035c12e21843542868d93a50a7be','fa66035c12e21843542868d93a50a7be',NULL,'2026-03-05 14:56:25',1,'EPUB',NULL,'fa66035c12e21843542868d93a50a7be',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(12,13,'The Rise of Endymion - Dan Simmons (1998).epub','Dan Simmons',1191,'739d0fd466f934ace0cc3cfb1a69a520','739d0fd466f934ace0cc3cfb1a69a520',NULL,'2026-03-05 14:56:25',1,'EPUB',NULL,'739d0fd466f934ace0cc3cfb1a69a520',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(13,14,'All Systems Red The Murderbot Diaries - Martha Wells (2017).epub','Martha Wells',2068,'83d6c009b81333f0c1c85d4d19875e80','83d6c009b81333f0c1c85d4d19875e80',NULL,'2026-03-05 16:31:01',1,'EPUB',NULL,'83d6c009b81333f0c1c85d4d19875e80',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(14,15,'Artificial Condition--The Murderbot Diaries - Martha Wells (2018).epub','Martha Wells',1175,'8626a46b79b88b3fda7cc8009bd348fe','8626a46b79b88b3fda7cc8009bd348fe',NULL,'2026-03-05 16:31:02',1,'EPUB',NULL,'8626a46b79b88b3fda7cc8009bd348fe',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(15,16,'03. Rogue Protocol - Martha Wells (2018).epub','Martha Wells/Murderbot Diaries',442,'0fb4d16f5f6587b32b330d169f95da10','0fb4d16f5f6587b32b330d169f95da10',NULL,'2026-03-05 16:31:02',1,'EPUB',NULL,'0fb4d16f5f6587b32b330d169f95da10',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(16,17,'04. Exit Strategy (Novella) - Martha Wells (2018).epub','Martha Wells/The Murderbot Diaries',842,'c54b4ce85bdbd0fc9265e6223ee2c216','c54b4ce85bdbd0fc9265e6223ee2c216',NULL,'2026-03-05 16:31:02',1,'EPUB',NULL,'c54b4ce85bdbd0fc9265e6223ee2c216',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(17,18,'05. Network Effect - Martha Wells (2020).epub','Martha Wells/The Murderbot Diaries',1297,'e80b9ba39068bf4f6676078f9aa0b1cc','e80b9ba39068bf4f6676078f9aa0b1cc',NULL,'2026-03-05 16:31:03',1,'EPUB',NULL,'e80b9ba39068bf4f6676078f9aa0b1cc',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(18,19,'System Collapse - Martha Wells (2023).epub','Martha Wells',2275,'7a205644aeb3159d91da803dd1740996','7a205644aeb3159d91da803dd1740996',NULL,'2026-03-05 16:31:03',1,'EPUB',NULL,'7a205644aeb3159d91da803dd1740996',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(19,20,'06. Fugitive Telemetry - Martha Wells (2021).epub','Martha Wells/Murderbot Diaries',1037,'243162a81370c35ebb82fd7556cbf0e9','243162a81370c35ebb82fd7556cbf0e9',NULL,'2026-03-05 16:31:03',1,'EPUB',NULL,'243162a81370c35ebb82fd7556cbf0e9',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `book_file` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_marks`
--

DROP TABLE IF EXISTS `book_marks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_marks` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `cfi` varchar(1000) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `color` varchar(7) DEFAULT NULL,
  `notes` varchar(2000) DEFAULT NULL,
  `priority` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `version` bigint(20) NOT NULL DEFAULT 1,
  `position_ms` bigint(20) DEFAULT NULL,
  `track_index` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_book_cfi` (`user_id`,`book_id`,`cfi`) USING HASH,
  KEY `idx_book_marks_user_id` (`user_id`),
  KEY `idx_book_marks_book_id` (`book_id`),
  KEY `idx_bookmark_book_user_priority` (`book_id`,`user_id`,`priority`,`created_at`),
  KEY `idx_book_marks_user_created` (`user_id`,`created_at`),
  CONSTRAINT `fk_book_marks_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_marks_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_marks`
--

LOCK TABLES `book_marks` WRITE;
/*!40000 ALTER TABLE `book_marks` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `book_marks` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_metadata`
--

DROP TABLE IF EXISTS `book_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_metadata` (
  `book_id` bigint(20) NOT NULL,
  `title` varchar(1000) DEFAULT NULL,
  `subtitle` varchar(1000) DEFAULT NULL,
  `publisher` varchar(1000) DEFAULT NULL,
  `published_date` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `isbn_13` varchar(64) DEFAULT NULL,
  `isbn_10` varchar(64) DEFAULT NULL,
  `page_count` int(11) DEFAULT NULL,
  `thumbnail` varchar(2000) DEFAULT NULL,
  `language` varchar(255) DEFAULT NULL,
  `rating` float DEFAULT NULL,
  `review_count` int(11) DEFAULT NULL,
  `cover` varchar(2000) DEFAULT NULL,
  `cover_updated_on` timestamp NULL DEFAULT NULL,
  `series_name` varchar(1000) DEFAULT NULL,
  `series_number` float DEFAULT NULL,
  `series_total` int(11) DEFAULT NULL,
  `all_fields_locked` tinyint(1) DEFAULT 0,
  `title_locked` tinyint(1) DEFAULT 0,
  `authors_locked` tinyint(1) DEFAULT 0,
  `categories_locked` tinyint(1) DEFAULT 0,
  `subtitle_locked` tinyint(1) DEFAULT 0,
  `publisher_locked` tinyint(1) DEFAULT 0,
  `published_date_locked` tinyint(1) DEFAULT 0,
  `description_locked` tinyint(1) DEFAULT 0,
  `isbn_13_locked` tinyint(1) DEFAULT 0,
  `isbn_10_locked` tinyint(1) DEFAULT 0,
  `page_count_locked` tinyint(1) DEFAULT 0,
  `thumbnail_locked` tinyint(1) DEFAULT 0,
  `language_locked` tinyint(1) DEFAULT 0,
  `cover_locked` tinyint(1) DEFAULT 0,
  `rating_locked` tinyint(1) DEFAULT 0,
  `review_count_locked` tinyint(1) DEFAULT 0,
  `series_name_locked` tinyint(1) DEFAULT 0,
  `series_number_locked` tinyint(1) DEFAULT 0,
  `series_total_locked` tinyint(1) DEFAULT 0,
  `amazon_rating` float DEFAULT NULL,
  `amazon_review_count` int(11) DEFAULT NULL,
  `goodreads_rating` float DEFAULT NULL,
  `goodreads_review_count` int(11) DEFAULT NULL,
  `amazon_rating_locked` tinyint(1) DEFAULT 0,
  `amazon_review_count_locked` tinyint(1) DEFAULT 0,
  `goodreads_rating_locked` tinyint(1) DEFAULT 0,
  `goodreads_review_count_locked` tinyint(1) DEFAULT 0,
  `asin` varchar(20) DEFAULT NULL,
  `asin_locked` tinyint(1) DEFAULT 0,
  `hardcover_rating` float DEFAULT NULL,
  `hardcover_review_count` int(11) DEFAULT NULL,
  `hardcover_rating_locked` tinyint(1) DEFAULT 0,
  `hardcover_review_count_locked` tinyint(1) DEFAULT 0,
  `goodreads_id` varchar(100) DEFAULT NULL,
  `hardcover_id` varchar(512) DEFAULT NULL,
  `google_id` varchar(100) DEFAULT NULL,
  `goodreads_id_locked` tinyint(1) DEFAULT 0,
  `hardcover_id_locked` tinyint(1) DEFAULT 0,
  `google_id_locked` tinyint(1) DEFAULT 0,
  `comicvine_id` varchar(100) DEFAULT NULL,
  `comicvine_id_locked` tinyint(1) DEFAULT 0,
  `reviews_locked` tinyint(1) DEFAULT 0,
  `moods_locked` tinyint(1) DEFAULT 0,
  `tags_locked` tinyint(1) DEFAULT 0,
  `embedding_vector` text DEFAULT NULL,
  `embedding_updated_at` datetime DEFAULT NULL,
  `search_text` text DEFAULT NULL,
  `hardcover_book_id` varchar(100) DEFAULT NULL,
  `hardcover_book_id_locked` tinyint(1) DEFAULT 0,
  `lubimyczytac_id` varchar(100) DEFAULT NULL,
  `lubimyczytac_rating` float DEFAULT NULL,
  `lubimyczytac_id_locked` tinyint(1) DEFAULT 0,
  `lubimyczytac_rating_locked` tinyint(1) DEFAULT 0,
  `ranobedb_id` varchar(100) DEFAULT NULL,
  `ranobedb_rating` float DEFAULT NULL,
  `ranobedb_id_locked` tinyint(1) DEFAULT 0,
  `ranobedb_rating_locked` tinyint(1) DEFAULT 0,
  `audiobook_cover_updated_on` timestamp NULL DEFAULT NULL,
  `audible_id` varchar(100) DEFAULT NULL,
  `audible_rating` float DEFAULT NULL,
  `audible_review_count` int(11) DEFAULT NULL,
  `audible_id_locked` tinyint(1) DEFAULT 0,
  `audible_rating_locked` tinyint(1) DEFAULT 0,
  `audible_review_count_locked` tinyint(1) DEFAULT 0,
  `audiobook_cover_locked` tinyint(1) DEFAULT 0,
  `narrator_locked` tinyint(1) DEFAULT 0,
  `abridged_locked` tinyint(1) DEFAULT 0,
  `narrator` varchar(500) DEFAULT NULL,
  `abridged` tinyint(1) DEFAULT NULL,
  `age_rating` int(11) DEFAULT NULL,
  `content_rating` varchar(20) DEFAULT NULL,
  `age_rating_locked` tinyint(1) NOT NULL DEFAULT 0,
  `content_rating_locked` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`book_id`),
  CONSTRAINT `fk_book_metadata` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_metadata`
--

LOCK TABLES `book_metadata` WRITE;
/*!40000 ALTER TABLE `book_metadata` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_metadata` VALUES
(2,'Achtsamkeit statt Angst und Panik','Mit Meditation zu Ruhe, Frieden und (Selbst-)Sicherheit','Arkana','2022-09-14','<b>»Peter Beer ist ein neuer Fixstern am deutschen Trainerhimmel.« Christian Bischoff, Bestsellerautor und Mentaltrainer</b><br /><br />Wer unter Panikattacken und Angststörungen leidet, fühlt sich ausgeliefert, ohnmächtig, beschämt. Peter Beer, Bestsellerautor und Achtsamkeitslehrer, kennt diese belastenden Ausnahmezustände nur zu Jahrelang kämpfte er selbst gegen Herzrasen, Atemnot und Schlaflosigkeit. Bis er Die Angst ignorieren, lässt sie nicht verschwinden. Sie dagegen liebevoll annehmen, ist der erste Schritt zur Heilung. Aus seinem erfolgreichen Weg hat Peter ein hochwirksames Anti-Angst-Achtsamkeitsprogramm Er zeigt, wie uns gezielte Meditationen und Atemtechniken sicher durch die Angst tragen, wie wir uns tief entspannen und innere Ruhe finden. Wir kommen friedvoll im gegenwärtigen Moment an und können unsere Ängste endgültig in eine wertvolle Ressource für Selbstvertrauen, Wachstum und Heilung.Entdecke auch das Workbook »Gedankenpause« von Peter Beer mit einem vertiefenden Achtsamkeits-Programm.','9783641275921','364127592X',270,NULL,'German',NULL,NULL,NULL,'2026-02-20 16:18:45',NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.06,51,0,0,0,0,NULL,0,NULL,NULL,0,0,'75404151-achtsamkeit-statt-angst-und-panik',NULL,'EERnEAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.3796631983009996,0.0,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0,0.0,0.2847473987257497,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0949157995752499,0.1898315991504998,0.0,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0,0.0949157995752499,0.0949157995752499,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0949157995752499,0.0,0.0,0.0,0.0949157995752499,0.0949157995752499,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0,0.1898315991504998,0.0,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2847473987257497,0.0949157995752499,0.0,0.0,0.0,0.1898315991504998,0.0,0.0,0.0,0.0,0.0,0.0949157995752499,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.3796631983009996,0.0949157995752499,0.0,0.0,0.0,0.0,0.0,0.4745789978762495,0.2847473987257497,0.0,0.0,0.0,0.0,0.0,0.0]','2026-02-16 00:30:00','achtsamkeit statt angst und panik mit meditation zu ruhe, frieden und (selbst-)sicherheit peter beer',NULL,0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(3,'Meditation','Stress und Ängste loswerden und endlich den Geist beruhigen - Mit Meditationen zum Audio-Download','Arkana','2021-04-19','Peter Beer führt ein scheinbar perfektes Studienabschluss, Karriere, erfolgreich im Job – und dennoch fühlt er sich total ausgebrannt. Als er in dieser tiefen Krise den uralten Heilweg der Meditation für sich entdeckt, kann er endlich (auf-)atmen und beschließt sein Leben umzukrempeln. Heute ist er einer der erfolgreichsten Achtsamkeitslehrer und begeistert mit seiner unorthodoxen Art Hunderttausende Menschen für das Sitzen in Stille. Seine Meditieren soll das neue Joggen werden. In seinem Meditations-Guide zeigt Peter Schritt für Schritt, wie wir im Lotossitz wieder zu uns selbst finden, emotionale Tiefs überwinden, negative Glaubenssätze loslassen und aus miesen Tagen gute machen. Mit exklusiven Audiomeditationen für den direkten Einstieg.','9783442342778','3442342775',336,NULL,'German',NULL,NULL,NULL,'2026-02-20 16:18:45',NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.19,112,0,0,0,0,NULL,0,NULL,NULL,0,0,'57791928-meditation',NULL,'t8f1zQEACAAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.4588314677411235,0.0,0.0,0.0,0.11470786693528087,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.22941573387056174,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.3441236008058426,0.0,0.22941573387056174,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0,0.5735393346764044,0.0,0.11470786693528087,0.0,0.0,0.0,0.0,0.0]','2026-02-16 00:30:00','meditation stress und angste loswerden und endlich den geist beruhigen - mit meditationen zum audio-download peter beer',NULL,0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(4,'Fundamentals of Software Architecture','An Engineering Approach','O\'Reilly Media','2020-03-03','Although salary surveys worldwide regularly identify software architect as one of the top ten best jobs, no decent guides exist to help developers become architects. Until now. This practical guide provides the first comprehensive overview of software architecture\'s many aspects. You\'ll examine architectural characteristics, architectural patterns, component determination, diagramming and presenting architecture, evolutionary architecture, and many other topics.<br /><br />Authors Neal Ford and Mark Richards help you learn through examples in a variety of popular programming languages, such as Java, C#, JavaScript, and others. You\'ll focus on architecture principles with examples that apply across all technology stacks.','9781492043454','1492043451',422,NULL,'English',NULL,NULL,NULL,'2026-02-20 16:18:45',NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,NULL,NULL,4.24,2228,0,0,0,0,NULL,0,0,0,0,0,'44144493-fundamentals-of-software-architecture','fundamentals-of-software-architecture-an-engineering-approach','_pNdwgEACAAJ',0,0,0,NULL,0,0,0,0,'[0.2407717061715384,0.0,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.2407717061715384,0.0,0.0,0.0,0.0601929265428846,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.0601929265428846,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.300964632714423,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.4213504858001922,0.0601929265428846,0.0,0.0,0.0,0.0,0.0,0.2407717061715384,0.0,0.1203858530857692,0.2407717061715384,0.0601929265428846,0.0,0.0,0.0,0.0,0.2407717061715384,0.0,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.0,0.0,0.0601929265428846,0.0,0.0,0.0601929265428846,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.0601929265428846,0.0,0.0,0.2407717061715384,0.0,0.0601929265428846,0.0,0.0,0.1805787796286538,0.0,0.2407717061715384,0.0,0.0,0.0,0.0,0.0,0.1203858530857692,0.0,0.0,0.0,0.0,0.0,0.2407717061715384,0.0601929265428846,0.0,0.0601929265428846,0.0,0.2407717061715384,0.0,0.0,0.0,0.0,0.0,0.0,0.300964632714423,0.0,0.0,0.0,0.0,0.0,0.0,0.0601929265428846,0.0,0.0,0.0,0.0]','2026-02-16 00:30:00','fundamentals of software architecture an engineering approach mark richards','2132394',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(5,'Red Rising 01 - Red Rising','Sons of Ares #1','Heyne Verlag','2019-01-14','Wenn du Gerechtigkeit willst, musst du dafür kämpfen!\n\nDer junge Darrow lebt in einer Welt, in der die Menschheit die Erde verlassen und die Planeten erobert hat. Bei der Besiedlung des Mars kommt ihm eine wichtige Aufgabe zu, das jedenfalls glaubt Darrow, der in den Minen im Untergrund schuftet, um eines Tages die Oberfläche des Mars bewohnbar zu machen. Doch dann erkennt er, dass er und seine Leidensgenossen von einer herrschenden Klasse ausgebeutet werden. Denn der Mars ist längst erschlossen, und die Oberschicht lebt in luxuriösen Städten inmitten üppiger Parklandschaften. Sein tief verwurzelter Gerechtigkeitssinn lässt Darrow nur eine Wahl: sich gegen die Unterdrücker aufzulehnen. Dabei führt ihn sein Weg zunächst ins Zentrum der Macht. Der unerschrockene Darrow schleust sich in ihr sagenumwobenes Institut ein, in dem die Elite herangezogen wird. Denn um sie vernichtend schlagen zu können, muss er einer von ihnen werden …','9786053435174','6053435171',382,NULL,'de',NULL,NULL,NULL,'2026-02-20 16:17:43','Red Rising Saga',1,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.5,501063,0,0,0,0,NULL,0,4.18,2688,0,0,'136977717','red-rising','7D7CEAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.19004573525823196,0.0,0.0,0.19004573525823196,0.0,0.0,0.0,0.0,0.33258003670190595,0.0,0.19004573525823196,0.0,0.0,0.0,0.0,0.0,0.2850686028873479,0.0,0.0,0.0,0.0,0.0,0.19004573525823196,0.0,0.19004573525823196,0.0,0.0,0.0,0.09502286762911598,0.23755716907278995,0.0,0.0,0.0,0.0,0.19004573525823196,0.0,0.0,0.0,0.0,0.0,0.19004573525823196,0.0,0.04751143381455799,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.04751143381455799,0.04751143381455799,0.19004573525823196,0.0,0.0,0.0,0.0,0.4751143381455799,0.0,0.0,0.0,0.04751143381455799,0.04751143381455799,0.04751143381455799,0.0,0.0,0.0,0.0,0.04751143381455799,0.0,0.0,0.0,0.04751143381455799,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.09502286762911598,0.0,0.0,0.0,0.04751143381455799,0.0,0.0,0.04751143381455799,0.0,0.0,0.0,0.19004573525823196,0.0,0.0,0.0,0.0,0.0,0.19004573525823196,0.0,0.0,0.0,0.04751143381455799,0.0,0.0,0.19004573525823196,0.19004573525823196,0.0,0.04751143381455799,0.0,0.0,0.0,0.0,0.0,0.09502286762911598,0.0,0.0,0.04751143381455799,0.0,0.19004573525823196,0.0]','2026-03-06 00:30:00','red rising 01 - red rising sons of ares #1 red rising saga brown, pierce','427473',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(6,'Project Hail Mary','A Novel','Penguin Random House LLC','2021-01-01','\"Except that right now, he doesn’t know that. He can’t even remember his own name, let alone the nature of his assignment or how to complete it.\n\nAll he knows is that he’s been asleep for a very, very long time. And he’s just been awakened to find himself millions of miles from home, with nothing but two corpses for company.\n\nHis crewmates dead, his memories fuzzily returning, Ryland realizes that an impossible task now confronts him. Hurtling through space on this tiny ship, it’s up to him to puzzle out an impossible scientific mystery—and conquer an extinction-level threat to our species.\n\nAnd with the clock ticking down and the nearest human being light-years away, he’s got to do it all alone.\n\nOr does he?\"-- Provided by Amazon','9781529157468','1529157463',496,NULL,'en',NULL,NULL,NULL,'2026-02-20 16:17:57',NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0,0,0,NULL,0,4.49,5047,0,0,NULL,'project-hail-mary','eFSjzgEACAAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.25298221281347033,0.0,0.25298221281347033,0.06324555320336758,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06324555320336758,0.25298221281347033,0.0,0.18973665961010278,0.0,0.0,0.0,0.06324555320336758,0.06324555320336758,0.25298221281347033,0.0,0.18973665961010278,0.18973665961010278,0.0,0.0,0.31622776601683794,0.0,0.0,0.12649110640673517,0.0,0.0,0.06324555320336758,0.0,0.0,0.0,0.0,0.0,0.25298221281347033,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.25298221281347033,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.25298221281347033,0.06324555320336758,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.18973665961010278,0.0,0.0,0.0,0.0,0.06324555320336758,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.12649110640673517,0.0,0.0,0.06324555320336758,0.0,0.0,0.25298221281347033,0.06324555320336758,0.06324555320336758,0.0,0.0,0.0,0.0,0.0,0.25298221281347033,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.18973665961010278,0.0,0.06324555320336758,0.06324555320336758,0.0,0.25298221281347033,0.0]','2026-03-06 00:30:00','project hail mary a novel andy weir','427578',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(7,'The Wee Free Men','A Tiffany Aching Novel','HarperCollinsPublishers','2003-01-01','A riotous, wise, and gripping junior Discworld novel from the Carnegie Medal-winning author and acknowledged master of comic fantasy.Nine-year-old Tiffany Aching thinks her Granny Aching - a wise shepherd - might have been a witch, but now Granny Aching is dead and it\'s up to Tiffany to work it all out when strange things begin happening: a fairy-tale monster in the stream, a headless horseman and, strangest of all, the tiny blue men in kilts, the Wee Free Men, who have come looking for the new \'hag\'. These are the Nac Mac Feegles, the pictsies, who like nothing better than thievin\', fightin\' and drinkin\'. Then Tiffany\'s young brother goes missing and Tiffany and the Wee Free Men must join forces to save him from the Queen of the Fairies-','9781407042466','1407042467',336,NULL,'en',NULL,NULL,NULL,'2026-02-20 16:17:29','Discworld',30,41,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.79,434,0,0,0,0,NULL,0,4.23,411,0,0,'26203937','the-wee-free-men','MJ8Y2wU4BrkC',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.1812366279990531,0.0,0.2416488373320708,0.0,0.0604122093330177,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.0604122093330177,0.0,0.0,0.2416488373320708,0.0,0.0,0.0604122093330177,0.0,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0604122093330177,0.0,0.42288546533112387,0.0,0.2416488373320708,0.1208244186660354,0.0,0.0604122093330177,0.0,0.0,0.2416488373320708,0.0,0.0,0.0604122093330177,0.0604122093330177,0.0,0.0,0.0604122093330177,0.2416488373320708,0.0,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0604122093330177,0.0,0.0,0.0604122093330177,0.0,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.3020610466650885,0.0,0.0,0.2416488373320708,0.0,0.0,0.2416488373320708,0.0,0.0,0.0,0.3020610466650885,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2416488373320708,0.0604122093330177,0.0,0.0,0.0,0.0604122093330177,0.0,0.0604122093330177,0.0,0.0,0.0,0.0,0.0,0.0,0.2416488373320708]','2026-03-06 00:30:00','the wee free men a tiffany aching novel discworld terry pratchett','326042',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(8,'Der Medicus',NULL,'Knaus, Albrecht Verlag','1986-08-07','Abenteuerreiches Leben eines Engländers, der im 11. Jahrhundert quer durch Europa reiste, um an der berühmten Akademie in Isfahan/Persien Medizin zu studieren.','9783426191927','342619192X',1162,NULL,'de',NULL,NULL,NULL,'2026-02-20 16:18:45','Cole Family Trilogy',1,21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.42,61359,0,0,0,0,NULL,0,4.17,12,0,0,'19466773','der-medicus','L4qzngEACAAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.06711560552140243,0.4026936331284146,0.0,0.0,0.0,0.0,0.0,0.0,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2684624220856097,0.0,0.2013468165642073,0.06711560552140243,0.0,0.0,0.0,0.0,0.13423121104280486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06711560552140243,0.13423121104280486,0.0,0.0,0.0,0.0,0.0,0.13423121104280486,0.0,0.6040404496926219,0.06711560552140243,0.0,0.0,0.0,0.33557802760701216,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2684624220856097,0.0,0.0,0.0,0.06711560552140243,0.0,0.0,0.2684624220856097,0.0,0.0,0.06711560552140243,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]','2026-03-07 00:30:00','der medicus cole family trilogy noah gordon','577336',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(9,'Der Schamane',NULL,'Goldmann','1992-01-01','Als Nachfahre des legendären Medicus will Rob J. Cole seine medizinische Laufbahn in der Neuen Welt beginnen. Nach ersten Erfahrungen als Armenarzt in Boston lässt er sich am Mississippi als Landarzt nieder. Eine indianische Schamanin weiht ihn dort in ihr Wissen über die heilenden Kräfte der Natur ein. Doch schon bald wird das ruhige Leben am Fluss vom beginnenden Bürgerkrieg erschüttert. Bester historischer Roman des Jahres - der SPIEGEL-Bestseller jetzt exklusiv bei Goldmann! Noah Gordon, 1926 in Worcester, Massachusetts, geboren, arbeitete lange Jahre als Journalist beim \"Boston Herald\". Mit \"Der Medicus\" gelang ihm ein Weltbestseller, der auch in Deutschland viele Monate auf der Bestsellerliste stand. Seine nachfolgenden Romane wurden ebenso sensationelle Erfolge. Noah Gordon hat drei erwachsene Kinder und lebt mit seiner Frau in der Nähe von Boston.','9783453418202','3453418204',703,NULL,'de',NULL,NULL,NULL,'2026-03-05 15:45:13','Cole Family Trilogy',2,21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.2,16902,0,0,0,0,NULL,0,4,2,0,0,'1618557','der-schamane','4ueeoAEACAAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.2760262237369417,0.06900655593423542,0.06900655593423542,0.0,0.0,0.0,0.41403933560541256,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.13801311186847084,0.0,0.0,0.0,0.3450327796711771,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06900655593423542,0.06900655593423542,0.0,0.0,0.2760262237369417,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06900655593423542,0.0,0.0,0.0,0.0,0.0,0.3450327796711771,0.06900655593423542,0.0,0.0,0.3450327796711771,0.13801311186847084,0.06900655593423542,0.06900655593423542,0.0,0.0,0.0,0.0,0.06900655593423542,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06900655593423542,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06900655593423542,0.2760262237369417,0.0,0.0,0.0,0.20701966780270628,0.0,0.06900655593423542,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2760262237369417,0.0,0.0,0.0,0.0,0.0,0.06900655593423542,0.0,0.0,0.06900655593423542,0.0,0.0,0.0,0.13801311186847084,0.0]','2026-03-06 00:30:00','der schamane cole family trilogy noah gordon','1248327',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(10,'Hyperion 1: Hyperion','Los Cantos de Hyperion - 1','Bantam Doubleday Dell Publishing Group','2015-11-02','A stunning tour de force filled with transcendent awe and wonder, Hyperion is a masterwork of science fiction that resonates with excitement and invention, the first volume in a remarkable epic by the multiple-award-winning author of The Hollow Man. On the world called Hyperion, beyond the reach of galactic law, waits a creature called the Shrike. There are those who worship it. There are those who fear it. And there are those who have vowed to destroy it. In the Valley of the Time Tombs, where huge, brooding structures move backward through time, the Shrike waits for them all. On the eve of Armageddon, with the entire galaxy at war, seven pilgrims set forth on a final voyage to Hyperion seeking the answers to the unsolved riddles of their lives. Each carries a desperate hope—and a terrible secret. And one may hold the fate of humanity in his hands. Praise for Dan Simmons and Hyperion “Dan Simmons has brilliantly conceptualized a future 700 years distant. In sheer scope and complexity it matches, and perhaps even surpasses, those of Isaac Asimov and James Blish.”—The Washington Post Book World “An unfailingly inventive narrative . . . generously conceived and stylistically sure-handed.”—The New York Times Book Review “Simmons’s own genius transforms space opera into a new kind of poetry.”—The Denver Post “An essential part of any science fiction collection.”—Booklist','9789635981298','9635981295',492,NULL,'en',NULL,NULL,NULL,'2026-03-05 14:48:56','Hyperion Cantos',1,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.28,302530,0,0,0,0,NULL,0,4.25,1519,0,0,'77566','hyperion','U0JnBAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.41647033204447276,0.0,0.0,0.18509792535309902,0.0,0.0,0.0,0.18509792535309902,0.0,0.046274481338274755,0.0,0.0,0.0,0.0,0.18509792535309902,0.0,0.046274481338274755,0.0,0.0,0.0,0.0,0.18509792535309902,0.18509792535309902,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.18509792535309902,0.0,0.0,0.0,0.0,0.0,0.18509792535309902,0.0,0.0,0.046274481338274755,0.0,0.0,0.0,0.09254896267654951,0.0,0.0,0.0,0.046274481338274755,0.0,0.0,0.0,0.2776468880296485,0.0,0.37019585070619804,0.0,0.046274481338274755,0.0,0.0,0.046274481338274755,0.0,0.0,0.046274481338274755,0.0,0.0,0.0,0.046274481338274755,0.0,0.0,0.0,0.0,0.0,0.0,0.18509792535309902,0.0,0.0,0.0,0.0,0.046274481338274755,0.046274481338274755,0.0,0.0,0.0,0.0,0.046274481338274755,0.2776468880296485,0.0,0.0,0.0,0.046274481338274755,0.0,0.18509792535309902,0.0,0.0,0.046274481338274755,0.046274481338274755,0.0,0.18509792535309902,0.0,0.0,0.0,0.0,0.0,0.0,0.2776468880296485,0.18509792535309902,0.0,0.046274481338274755,0.0,0.18509792535309902,0.046274481338274755,0.0,0.046274481338274755,0.0,0.0,0.0,0.0,0.0,0.046274481338274755,0.0]','2026-03-06 00:30:00','hyperion 1: hyperion los cantos de hyperion - 1 hyperion cantos dan simmons','427460',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(11,'The Fall of Hyperion',NULL,'Spectra','2011-02-02','In the stunning continuation of the epic adventure begun in <i>Hyperion</i>, Simmons returns us to a far future resplendent with drama and invention. On the world of Hyperion, the mysterious Time Tombs are opening. And the secrets they contain mean that nothing--nothing anywhere in the universe--will ever be the same.<br /><br /><i>From the Paperback edition.</i>','9780307781895','0307781895',528,NULL,'English',NULL,NULL,NULL,'2026-03-05 14:58:40','Hyperion Cantos',2,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.24,149821,0,0,0,0,NULL,0,4.17,831,0,0,'77565.The_Fall_of_Hyperion','the-fall-of-hyperion','DaN3-r0EXOcC',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.5136571309818146,0.0,0.0,0.22829205821413984,0.0,0.0,0.05707301455353496,0.22829205821413984,0.0,0.0,0.0,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.22829205821413984,0.05707301455353496,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.05707301455353496,0.0,0.05707301455353496,0.22829205821413984,0.0,0.0,0.0,0.0,0.0,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.0,0.0,0.05707301455353496,0.3424380873212098,0.0,0.22829205821413984,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.11414602910706992,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.05707301455353496,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.22829205821413984,0.05707301455353496,0.05707301455353496,0.1712190436606049,0.0,0.0,0.0,0.0,0.05707301455353496,0.22829205821413984,0.0,0.0,0.0,0.0,0.0,0.22829205821413984,0.0,0.11414602910706992,0.0,0.0,0.0,0.0,0.05707301455353496,0.0,0.0,0.05707301455353496,0.0,0.22829205821413984,0.11414602910706992,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.1712190436606049,0.0]','2026-03-06 00:30:00','the fall of hyperion hyperion cantos dan simmons','369986',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(12,'Endymion','Pforten der Zeit / Die Auferstehung','Bantam Books','1996-02-15','<p class=\"description\">SUMMARY:<br>The multiple-award-winning science fiction master returns to the universe that is his greatest triumph--the world of Hyperion and The Fall ofHyperion --with a novel even more magnificent than its predecessors.Dan Simmons\'s Hyperion was an immediate sensation on its first publication in 1989. This staggering multifaceted tale of the far future heralded the conquest of the science fiction field by a man who had already won the World Fantasy Award for his first novel (Song of Kali) and had also published one of the most well-received horror novels in the field, Carrion Comfort. Hyperion went on to win the Hugo Award as Best Novel, and it and its companion volume, The Fall of Hyperion, took their rightful places in the science fiction pantheon of new classics.Now, six years later, Simmons returns to this richly imagined world of technological achievement, excitement, wonder and fear. Endymion is a story about love and memory, triumph and terror--an instant candidate for the field\'s highest honors.</p>','9780553572940','0553572946',577,NULL,'en',NULL,NULL,NULL,'2026-03-05 14:56:25','Hyperion Cantos',3,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.19,71326,0,0,0,0,NULL,0,4.1,399,0,0,'3977','endymion','nAmOEAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.14603771505337063,0.0,0.04867923835112355,0.0,0.0,0.4381131451601119,0.0,0.0,0.24339619175561772,0.0,0.0,0.0,0.1947169534044942,0.04867923835112355,0.0,0.0,0.0,0.0,0.0,0.1947169534044942,0.0,0.04867923835112355,0.0,0.0,0.0,0.0,0.0,0.1947169534044942,0.04867923835112355,0.0,0.04867923835112355,0.04867923835112355,0.0,0.0,0.0973584767022471,0.0,0.0,0.0,0.0,0.1947169534044942,0.0,0.0,0.0,0.0,0.0,0.1947169534044942,0.0,0.0,0.04867923835112355,0.0,0.04867923835112355,0.1947169534044942,0.04867923835112355,0.0,0.04867923835112355,0.0,0.0,0.04867923835112355,0.0,0.0,0.29207543010674125,0.0,0.3894339068089884,0.1947169534044942,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.04867923835112355,0.0,0.0,0.04867923835112355,0.0,0.0,0.0,0.04867923835112355,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.1947169534044942,0.0,0.0,0.04867923835112355,0.0,0.1947169534044942,0.24339619175561772,0.0,0.04867923835112355,0.0,0.0,0.0,0.0,0.0,0.1947169534044942,0.04867923835112355,0.0,0.0,0.0,0.04867923835112355,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]','2026-03-06 00:30:00','endymion pforten der zeit die auferstehung hyperion cantos dan simmons','427353',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(13,'The Rise of Endymion',NULL,'Random House, Inc.','1998-02-15','<h3>Amazon.com Review</h3><p>This conclusion of the Hyperion saga ( </p><h3>From</h3><p>The latest episode (following last year\'s <em>Endymion</em>) of Simmons\' Foundation-like saga of the far future tells of the struggle for dominance between humanity and its siblings, one of which is a highly evolved race with artificial intelligence and another of which has experimented upon its own DNA until it is no longer quite human. What might be called classical humankind is under the rule of a newly established, dominant Catholic Church, which undertakes to exterminate one of its rivals, the Ousters, and also seeks the girl Aenea, part-human and part-machine and a messiah for whom the adventurer Endymion is guardian. But Endymion and Aenea part as their destinies begin to fulfill themselves, and before they meet again, Endymion leaps through time portals from world to world. These worlds, including a gas giant with jellyfishlike lifeforms in its upper atmosphere and an ice kingdom carved among mountain peaks, are brilliantly realized. Thus Simmons pushes his vast entertainment along unfalteringly. <em>John Mort</em></p>','9780553572988','0553572989',709,NULL,'en',NULL,NULL,NULL,'2026-03-05 14:56:25','Hyperion Cantos',4,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.17,65599,0,0,0,0,NULL,0,4.04,362,0,0,'11289','the-rise-of-endymion','mgmOEAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.2055566129482595,0.0,0.0,0.0,0.06851887098275317,0.411113225896519,0.0,0.0,0.27407548393101266,0.0,0.0,0.06851887098275317,0.06851887098275317,0.06851887098275317,0.06851887098275317,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.13703774196550633,0.0,0.06851887098275317,0.06851887098275317,0.0,0.27407548393101266,0.0,0.0,0.0,0.0,0.0,0.06851887098275317,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.13703774196550633,0.0,0.27407548393101266,0.0,0.0,0.2055566129482595,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06851887098275317,0.0,0.411113225896519,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06851887098275317,0.06851887098275317,0.0,0.06851887098275317,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.27407548393101266,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.06851887098275317,0.0,0.0,0.0,0.0,0.0,0.27407548393101266,0.13703774196550633,0.0,0.0,0.0,0.0,0.0,0.06851887098275317,0.27407548393101266,0.0,0.0,0.0,0.0,0.06851887098275317,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]','2026-03-06 00:30:00','the rise of endymion hyperion cantos dan simmons','438682',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(14,'All Systems Red: The Murderbot Diaries','The Murderbot Diaries','Tor Publishing Group','2017-05-02','In a corporate-dominated spacefaring future, planetary missions must be approved and supplied by the Company. Exploratory teams are accompanied by Company-supplied security androids, for their own safety.\n\nBut in a society where contracts are awarded to the lowest bidder, safety isn\'t a primary concern.\n\nOn a distant planet, a team of scientists are conducting surface tests, shadowed by their Company-supplied \'droid -- a self-aware SecUnit that has hacked its own governor module, and refers to itself (though never out loud) as \"Murderbot.\" Scornful of humans, all it really wants is to be left alone long enough to figure out who it is.\n\nBut when a neighboring mission goes dark, it\'s up to the scientists and their Murderbot to get to the truth.','9786069000335','6069000331',149,NULL,'en',NULL,NULL,NULL,'2026-03-05 16:31:02','The Murderbot Diaries',1,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.12,377624,0,0,0,0,NULL,0,4.07,3180,0,0,'32758901','all-systems-red','nY8hEQAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.048795003647426664,0.0,0.2439750182371333,0.0,0.0,0.0,0.19518001458970666,0.19518001458970666,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.0,0.2439750182371333,0.0,0.0,0.0,0.0,0.19518001458970666,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.09759000729485333,0.19518001458970666,0.0,0.0,0.0,0.09759000729485333,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.14638501094227999,0.0,0.0,0.19518001458970666,0.19518001458970666,0.0,0.048795003647426664,0.0,0.0,0.0,0.048795003647426664,0.0,0.0,0.14638501094227999,0.0,0.048795003647426664,0.0,0.048795003647426664,0.0,0.0,0.0,0.048795003647426664,0.0,0.0,0.09759000729485333,0.0,0.048795003647426664,0.048795003647426664,0.4879500364742666,0.0,0.0,0.0,0.0,0.048795003647426664,0.0,0.0,0.048795003647426664,0.0,0.0,0.0,0.09759000729485333,0.19518001458970666,0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.0,0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.19518001458970666,0.0,0.0,0.0,0.0,0.0,0.048795003647426664,0.048795003647426664,0.0,0.0,0.0,0.0,0.0,0.19518001458970666,0.0]','2026-03-06 00:30:00','all systems red: the murderbot diaries the murderbot diaries the murderbot diaries martha wells','427971',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(15,'Artificial Condition--The Murderbot Diaries','All Systems Red, Artificial Condition','Tom Doherty Associates','2018-03-03','<p><b>A <i>USA Today </i>bestseller</b><br><b></b><br><b>The \"I love Murderbot!\" &#8212;Ann Leckie</b></p><p><b><i>Artificial Condition</i> is the follow-up to Martha Wells\'s Hugo, Nebula, Alex, and Locus Award-winning, <i>New York Times</i> bestselling <i>All Systems Red</i></b></p><p>It has a dark past&#8212;one in which a number of humans were killed. A past that caused it to christen itself \"Murderbot\". But it has only vague memories of the massacre that spawned that title, and it wants to know more.</p><p>Teaming up with a Research Transport vessel named ART (you don\'t want to know what the \"A\" stands for), Murderbot heads to the mining facility where it went rogue.</p><p>What it discovers will forever change the way it thinks...</p><p>At the Publisher\'s request, this title is being sold without Digital Rights Management Software (DRM) applied.</p>','9781250326874','1250326877',159,NULL,'en-US',NULL,NULL,NULL,'2026-03-05 16:31:02','The Murderbot Diaries',2,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.25,218612,0,0,0,0,NULL,0,4.17,2040,0,0,'36223860','artificial-condition','nY8hEQAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.1403340809174964,0.0,0.0,0.0,0.1871121078899952,0.0,0.0,0.4210022427524892,0.0467780269724988,0.0,0.0,0.1871121078899952,0.0,0.0,0.0,0.0,0.1871121078899952,0.0,0.0467780269724988,0.0,0.0467780269724988,0.0,0.0,0.0,0.0,0.0,0.1871121078899952,0.0,0.0,0.0467780269724988,0.0,0.0,0.0,0.1871121078899952,0.0467780269724988,0.0,0.0,0.0,0.0,0.0,0.0935560539449976,0.0,0.0,0.0,0.1871121078899952,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.1871121078899952,0.1403340809174964,0.0,0.0,0.0467780269724988,0.1871121078899952,0.0,0.0,0.0,0.0467780269724988,0.0467780269724988,0.0,0.0,0.0,0.1403340809174964,0.0,0.0467780269724988,0.0,0.0,0.0,0.0,0.0467780269724988,0.0,0.0467780269724988,0.0935560539449976,0.0,0.0467780269724988,0.0,0.0,0.467780269724988,0.0,0.0467780269724988,0.1871121078899952,0.0,0.0,0.0,0.0,0.0,0.0,0.0467780269724988,0.0467780269724988,0.0,0.1871121078899952,0.0,0.0,0.0,0.0,0.0467780269724988,0.1871121078899952,0.0,0.0,0.0,0.0467780269724988,0.0,0.0,0.1871121078899952,0.1871121078899952,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.1871121078899952,0.0]','2026-03-06 00:30:00','artificial condition--the murderbot diaries all systems red, artificial condition the murderbot diaries martha wells','427537',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(16,'Rogue Protocol','The Murderbot Diaries 3','Tom Doherty Associates','2018-01-01','Sci-fi’s favorite antisocial A.I. is back on a mission. The case against the too-big-to-fail GrayCris Corporation is floundering, and more importantly, authorities are beginning to ask more questions about where Dr. Mensah\'s SecUnit is.\n\nAnd Murderbot would rather those questions went away. For good.','9781250191786','1250191785',160,NULL,'en',NULL,NULL,NULL,'2026-03-05 16:31:02','The Murderbot Diaries',3,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.24,175414,0,0,0,0,'1250191785',0,4.15,1672,0,0,'35519101','rogue-protocol','0ohhDwAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.055641488407465724,0.0,0.2225659536298629,0.0,0.2225659536298629,0.0,0.0,0.2782074420373286,0.0,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.0,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.4451319072597258,0.0,0.0,0.055641488407465724,0.0,0.0,0.055641488407465724,0.2782074420373286,0.0,0.0,0.0,0.055641488407465724,0.0,0.0,0.11128297681493145,0.0,0.0,0.0,0.2225659536298629,0.0,0.0,0.0,0.0,0.0,0.16692446522239718,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.055641488407465724,0.0,0.055641488407465724,0.2225659536298629,0.0,0.0,0.0,0.0,0.11128297681493145,0.0,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.0,0.0,0.0,0.055641488407465724,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.055641488407465724,0.38949041885226005,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2225659536298629,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2225659536298629,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2225659536298629,0.0,0.055641488407465724,0.0,0.0,0.055641488407465724,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2225659536298629,0.0]','2026-03-07 00:30:00','rogue protocol the murderbot diaries 3 the murderbot diaries martha wells','427560',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(17,'Exit Strategy (Novella)','The Murderbot Diaries 4','Tor; Tom Doherty Associates','2018-10-02','<p>ebook, 117 pages</p><div> <p>Kindle Edition, 176 pages</p> <p>Published: 2018 </p> <p>The fourth and final part of the Murderbot Diaries series that began with <em>All Systems Red.</em></p> <p>Murderbot wasn’t programmed to care. So, its decision to help the only human who ever showed it respect must be a system glitch, right?</p> <p>Having traveled the width of the galaxy to unearth details of its own murderous transgressions, as well as those of the GrayCris Corporation, Murderbot is heading home to help Dr. Mensah—its former owner (protector? friend?)—submit evidence that could prevent GrayCris from destroying more colonists in its never-ending quest for profit.</p> <p>But who’s going to believe a SecUnit gone rogue?</p> <p>And what will become of it when it’s caught?</p></div>','9781250191854','1250191858',172,NULL,'en',NULL,NULL,NULL,'2026-03-05 16:31:03','The Murderbot Diaries',4,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0,0,0,NULL,0,4.31,1482,0,0,NULL,'exit-strategy','aOYlDwAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.4256282653793743,0.0,0.08512565307587486,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.34050261230349943,0.0,0.0,0.17025130615174972,0.17025130615174972,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.5107539184552492,0.0,0.0,0.0,0.0,0.2553769592276246,0.0,0.0,0.0,0.0,0.08512565307587486,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.34050261230349943,0.17025130615174972,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08512565307587486,0.0,0.2553769592276246,0.0,0.0,0.08512565307587486,0.0,0.0]','2026-03-06 00:30:00','exit strategy (novella) the murderbot diaries 4 the murderbot diaries martha wells','432448',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(18,'Network Effect','The Murderbot Diaries 5','Tor Books','2020-05-18','<div>\n<p style=\"font-weight: 600\">Murderbot returns in its highly-anticipated, first, full-length standalone novel. </p>\n<p>You know that feeling when you\'re at work, and you\'ve had enough of people, and then the boss walks in with yet another job that needs to be done right this second or the world will end, but all you want to do is go home and binge your favorite shows? And you\'re a sentient murder machine programmed for destruction? Congratulations, you\'re Murderbot.</p>\n<p>Come for the pew-pew space battles, stay for the most relatable A.I. you\'ll read this century.<br><br><strong>—</strong></p>\n<p id=\"freeText16018513572204058536\"><em>’</em><em>m usually alone in my head, and that’s where 90 plus percent of my problems are.</em><br><br>When Murderbot\'s human associates (not friends, never friends) are captured and another not-friend from its past requires urgent assistance, Murderbot must choose between inertia and drastic action.<br><br>Drastic action it is, then.</p></div>','9781250229861','1250229863',352,NULL,'en-US',NULL,NULL,NULL,'2026-03-05 16:31:03','The Murderbot Diaries',5,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.46,128711,0,0,0,0,NULL,0,4.41,1189,0,0,'52381770','network-effect','sBK_yAEACAAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.4240944648399855,0.0,0.0,0.08481889296799709,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.16963778593599418,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.08481889296799709,0.33927557187198837,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2544566789039913,0.0,0.0,0.0,0.0,0.0,0.0,0.16963778593599418,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.5089133578079826,0.0,0.2544566789039913,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.33927557187198837,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.0,0.0,0.0,0.08481889296799709,0.0,0.0,0.0,0.16963778593599418,0.08481889296799709,0.08481889296799709]','2026-03-06 00:30:00','network effect the murderbot diaries 5 the murderbot diaries martha wells','440171',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(19,'System Collapse','The Murderbot Diaries','Tor Publishing Group','2023-08-30','<p><b>A <i>New York Times</i> bestseller.<br>A <i>Washington Post </i>bestseller.<br>A <i>USA Today</i> bestseller.</b><br><b>Everyone\'s favorite lethal SecUnit is back in the next installment in Martha Wells\'s</b> <b>bestselling and award-winning Murderbot Diaries series.</b><br><i><br>Am I making it worse? I think I\'m making it worse.</i><br>Following the events in <i>Network Effect</i>, the Barish-Estranza corporation has sent rescue ships to a newly-colonized planet in peril, as well as additional SecUnits. But if there\'s an ethical corporation out there, Murderbot has yet to find it, and if Barish-Estranza can\'t have the planet, they\'re sure as hell not leaving without <i>something</i>. If that something just happens to be an entire colony of humans, well, a free workforce is a decent runner-up prize.<br>But there\'s something wrong with Murderbot; it isn\'t running within normal operational parameters. ART\'s crew and the humans from Preservation are doing everything they can...','9781705041024','1705041027',256,NULL,'en-US',NULL,NULL,NULL,'2026-03-05 16:31:03','The Murderbot Diaries',7,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.25,75908,0,0,0,0,NULL,0,4.12,746,0,0,'65211701','system-collapse','bbKiEAAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.18549555830406733,0.0,0.18549555830406733,0.0,0.0,0.41736500618415145,0.0,0.0,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.0,0.18549555830406733,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.18549555830406733,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.18549555830406733,0.0,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.0,0.0,0.37099111660813466,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.18549555830406733,0.0,0.0,0.0,0.04637388957601683,0.18549555830406733,0.0,0.0,0.0,0.04637388957601683,0.04637388957601683,0.0,0.0,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.13912166872805048,0.0,0.0,0.0,0.0,0.18549555830406733,0.0,0.0,0.0,0.04637388957601683,0.27824333745610097,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.04637388957601683,0.27824333745610097,0.18549555830406733,0.0,0.0,0.0,0.0,0.04637388957601683,0.18549555830406733,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.18549555830406733,0.18549555830406733,0.0,0.18549555830406733,0.0,0.0,0.18549555830406733,0.0,0.0,0.0,0.04637388957601683,0.0,0.0,0.0,0.04637388957601683,0.0]','2026-03-06 00:30:00','system collapse the murderbot diaries the murderbot diaries martha wells','462038',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0),
(20,'Fugitive Telemetry','The Murderbot Diaries, Book 6','Night Shade Books','2021-04-27','Having captured the hearts of readers across the globe (Annalee Newitz says it\'s \"one of the most humane portraits of a nonhuman I\'ve ever read\") Murderbot has also established Martha Wells as one of the great SF writers of today.\n\nNo, I didn\'t kill the dead human. If I had, I wouldn\'t dump the body in the station mall.\n\nWhen Murderbot discovers a dead body on Preservation Station, it knows it is going to have to assist station security to determine who the body is (was), how they were killed (that should be relatively straightforward, at least), and why (because apparently that matters to a lot of people―who knew?)\n\nYes, the unthinkable is about to happen: Murderbot must voluntarily speak to humans!\n\nAgain!','9781250765376','1250765374',176,NULL,'en-US',NULL,NULL,NULL,'2026-03-05 16:31:03','The Murderbot Diaries',6,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,4.29,105950,0,0,0,0,'1250765374',0,4.2,1010,0,0,'53205854','fugitive-telemetry','IhLjDwAAQBAJ',0,0,0,NULL,0,0,0,0,'[0.0,0.0,0.0,0.27565892320998564,0.055131784641997125,0.0,0.0,0.0,0.27565892320998564,0.2205271385679885,0.055131784641997125,0.0,0.055131784641997125,0.0,0.0,0.0,0.0,0.0,0.2205271385679885,0.055131784641997125,0.11026356928399425,0.0,0.0,0.0,0.0,0.0,0.0,0.2205271385679885,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.2205271385679885,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.441054277135977,0.0,0.0,0.0,0.0,0.0,0.0,0.055131784641997125,0.055131784641997125,0.0,0.0,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.055131784641997125,0.0,0.0,0.055131784641997125,0.0,0.055131784641997125,0.0,0.0,0.0,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.3859224924939799,0.0,0.0,0.0,0.0,0.0,0.1653953539259914,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2205271385679885,0.055131784641997125,0.0,0.0,0.055131784641997125,0.0,0.0,0.0,0.27565892320998564,0.0,0.2205271385679885,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2205271385679885,0.0]','2026-03-07 00:30:00','fugitive telemetry the murderbot diaries, book 6 the murderbot diaries martha wells','435167',0,NULL,NULL,0,0,NULL,NULL,0,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,NULL,NULL,NULL,NULL,0,0);
/*!40000 ALTER TABLE `book_metadata` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_metadata_author_mapping`
--

DROP TABLE IF EXISTS `book_metadata_author_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_metadata_author_mapping` (
  `book_id` bigint(20) NOT NULL,
  `author_id` bigint(20) NOT NULL,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`book_id`,`sort_order`),
  KEY `idx_book_metadata_id` (`book_id`),
  KEY `idx_author_id` (`author_id`),
  KEY `idx_author_mapping_author_id` (`book_id`,`author_id`),
  CONSTRAINT `fk_book_metadata_author_mapping_author` FOREIGN KEY (`author_id`) REFERENCES `author` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_metadata_author_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_metadata_author_mapping`
--

LOCK TABLES `book_metadata_author_mapping` WRITE;
/*!40000 ALTER TABLE `book_metadata_author_mapping` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_metadata_author_mapping` VALUES
(2,2,0),
(3,2,0),
(4,4,0),
(5,5,0),
(7,7,0),
(10,9,0),
(11,9,0),
(12,9,0),
(13,9,0),
(8,12,0),
(9,12,0),
(6,13,0),
(14,14,0),
(15,14,0),
(16,14,0),
(17,14,0),
(18,14,0),
(19,14,0),
(20,14,0);
/*!40000 ALTER TABLE `book_metadata_author_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_metadata_category_mapping`
--

DROP TABLE IF EXISTS `book_metadata_category_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_metadata_category_mapping` (
  `book_id` bigint(20) NOT NULL,
  `category_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`category_id`),
  KEY `fk_book_metadata_category_mapping_category` (`category_id`),
  CONSTRAINT `fk_book_metadata_category_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_metadata_category_mapping_category` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_metadata_category_mapping`
--

LOCK TABLES `book_metadata_category_mapping` WRITE;
/*!40000 ALTER TABLE `book_metadata_category_mapping` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_metadata_category_mapping` VALUES
(5,1),
(6,1),
(7,1),
(9,1),
(10,1),
(11,1),
(12,1),
(13,1),
(14,1),
(15,1),
(16,1),
(18,1),
(19,1),
(20,1),
(4,4),
(4,5),
(4,6),
(4,7),
(4,8),
(4,9),
(4,10),
(2,11),
(3,11),
(4,11),
(4,12),
(4,13),
(5,13),
(10,13),
(11,13),
(12,13),
(14,13),
(15,13),
(16,13),
(19,13),
(5,15),
(6,15),
(10,15),
(11,15),
(12,15),
(14,15),
(15,15),
(16,15),
(19,15),
(5,16),
(10,16),
(11,16),
(12,16),
(13,16),
(15,16),
(19,16),
(10,17),
(11,17),
(11,18),
(5,19),
(6,19),
(7,19),
(8,19),
(9,19),
(10,19),
(11,19),
(12,19),
(13,19),
(14,19),
(15,19),
(16,19),
(19,19),
(20,19),
(5,20),
(10,20),
(11,20),
(12,20),
(14,20),
(15,20),
(19,20),
(10,21),
(11,21),
(12,21),
(5,22),
(6,22),
(7,22),
(10,22),
(11,22),
(12,22),
(13,22),
(14,22),
(15,22),
(16,22),
(17,22),
(18,22),
(19,22),
(20,22),
(5,23),
(6,23),
(7,23),
(8,23),
(9,23),
(10,23),
(12,23),
(13,23),
(14,23),
(15,23),
(16,23),
(19,23),
(20,23),
(13,24),
(8,25),
(10,25),
(12,25),
(8,26),
(8,27),
(9,28),
(12,28),
(9,29),
(9,30),
(6,31),
(10,31),
(12,31),
(19,31),
(6,32),
(5,33),
(6,33),
(14,33),
(15,33),
(19,33),
(6,34),
(14,34),
(15,34),
(16,34),
(20,34),
(6,35),
(5,37),
(7,37),
(5,38),
(14,38),
(16,50),
(5,53),
(10,53),
(5,54),
(14,54),
(15,54),
(16,54),
(19,54),
(20,54),
(5,55),
(5,56),
(7,57),
(19,57),
(12,61),
(10,66),
(10,67),
(10,68),
(12,71),
(7,72),
(12,72),
(14,74),
(15,74),
(19,74),
(14,75),
(14,76),
(14,77),
(15,77),
(15,78),
(15,79),
(16,80),
(19,80),
(20,80),
(19,83),
(20,83),
(19,84),
(20,84),
(20,85),
(7,86),
(7,87),
(7,88);
/*!40000 ALTER TABLE `book_metadata_category_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_metadata_mood_mapping`
--

DROP TABLE IF EXISTS `book_metadata_mood_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_metadata_mood_mapping` (
  `book_id` bigint(20) NOT NULL,
  `mood_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`mood_id`),
  KEY `fk_book_metadata_mood_mapping_mood` (`mood_id`),
  CONSTRAINT `fk_book_metadata_mood_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_metadata_mood_mapping_mood` FOREIGN KEY (`mood_id`) REFERENCES `mood` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_metadata_mood_mapping`
--

LOCK TABLES `book_metadata_mood_mapping` WRITE;
/*!40000 ALTER TABLE `book_metadata_mood_mapping` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_metadata_mood_mapping` VALUES
(3,1),
(5,1),
(6,1),
(14,1),
(15,1),
(16,1),
(17,1),
(18,1),
(19,1),
(20,1),
(5,2),
(6,2),
(7,2),
(10,2),
(11,2),
(12,2),
(13,2),
(14,2),
(15,2),
(16,2),
(17,2),
(18,2),
(19,2),
(20,2),
(6,3),
(19,3),
(5,4),
(6,4),
(10,4),
(16,4),
(17,4),
(18,4),
(19,4),
(6,5),
(7,5),
(14,5),
(15,5),
(16,5),
(17,5),
(18,5),
(19,5),
(20,5),
(3,6),
(10,6),
(11,6),
(14,6),
(15,6),
(16,6),
(18,6),
(20,6),
(5,7),
(10,7),
(11,7),
(5,8),
(11,8),
(7,9),
(10,9),
(11,9),
(7,10),
(14,10),
(15,10),
(17,10),
(20,10),
(7,11);
/*!40000 ALTER TABLE `book_metadata_mood_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_metadata_tag_mapping`
--

DROP TABLE IF EXISTS `book_metadata_tag_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_metadata_tag_mapping` (
  `book_id` bigint(20) NOT NULL,
  `tag_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`tag_id`),
  KEY `fk_book_metadata_tag_mapping_tag` (`tag_id`),
  CONSTRAINT `fk_book_metadata_tag_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_metadata_tag_mapping_tag` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_metadata_tag_mapping`
--

LOCK TABLES `book_metadata_tag_mapping` WRITE;
/*!40000 ALTER TABLE `book_metadata_tag_mapping` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `book_metadata_tag_mapping` VALUES
(6,1),
(5,2),
(6,2),
(7,2),
(10,2),
(14,2),
(15,2),
(16,2),
(17,2),
(18,2),
(20,2),
(5,3),
(6,3),
(7,3),
(10,3),
(14,3),
(15,3),
(16,3),
(17,3),
(18,3),
(19,3),
(20,3),
(3,4),
(5,4),
(6,4),
(7,4),
(12,4),
(14,4),
(15,4),
(16,4),
(17,4),
(19,4),
(20,4),
(5,5),
(6,5),
(7,5),
(10,5),
(11,5),
(12,5),
(13,5),
(14,5),
(15,5),
(16,5),
(17,5),
(18,5),
(19,5),
(20,5),
(5,6),
(6,6),
(7,6),
(10,6),
(11,6),
(14,6),
(15,6),
(16,6),
(17,6),
(18,6),
(19,6),
(20,6),
(3,7),
(5,7),
(6,7),
(7,7),
(10,7),
(11,7),
(12,7),
(13,7),
(14,7),
(15,7),
(16,7),
(17,7),
(18,7),
(19,7),
(20,7),
(5,8),
(6,8),
(7,8),
(10,8),
(11,8),
(12,8),
(13,8),
(14,8),
(15,8),
(16,8),
(17,8),
(18,8),
(19,8),
(20,8),
(3,9),
(5,9),
(6,9),
(10,9),
(14,9),
(15,9),
(16,9),
(17,9),
(18,9),
(19,9),
(20,9),
(3,10),
(5,10),
(6,10),
(10,10),
(11,10),
(14,10),
(15,10),
(16,10),
(17,10),
(18,10),
(19,10),
(20,10),
(14,11),
(16,11),
(7,12);
/*!40000 ALTER TABLE `book_metadata_tag_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_notes`
--

DROP TABLE IF EXISTS `book_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_notes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_book_notes_user_id` (`user_id`),
  KEY `idx_book_notes_book_id` (`book_id`),
  CONSTRAINT `fk_book_notes_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_notes_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_notes`
--

LOCK TABLES `book_notes` WRITE;
/*!40000 ALTER TABLE `book_notes` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `book_notes` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_notes_v2`
--

DROP TABLE IF EXISTS `book_notes_v2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_notes_v2` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `cfi` varchar(1000) NOT NULL,
  `selected_text` varchar(5000) DEFAULT NULL,
  `note_content` text NOT NULL,
  `color` varchar(20) DEFAULT NULL,
  `chapter_title` varchar(500) DEFAULT NULL,
  `version` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_notes_v2_user_book_cfi` (`user_id`,`book_id`,`cfi`) USING HASH,
  KEY `idx_book_notes_v2_user_id` (`user_id`),
  KEY `idx_book_notes_v2_book_id` (`book_id`),
  KEY `idx_book_notes_v2_user_book` (`user_id`,`book_id`),
  KEY `idx_book_notes_v2_user_created` (`user_id`,`created_at`),
  CONSTRAINT `fk_book_notes_v2_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_notes_v2_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_notes_v2`
--

LOCK TABLES `book_notes_v2` WRITE;
/*!40000 ALTER TABLE `book_notes_v2` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `book_notes_v2` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `book_shelf_mapping`
--

DROP TABLE IF EXISTS `book_shelf_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_shelf_mapping` (
  `book_id` bigint(20) NOT NULL,
  `shelf_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`shelf_id`),
  KEY `fk_book_shelf_mapping_shelf` (`shelf_id`),
  CONSTRAINT `fk_book_shelf_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_book_shelf_mapping_shelf` FOREIGN KEY (`shelf_id`) REFERENCES `shelf` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_shelf_mapping`
--

LOCK TABLES `book_shelf_mapping` WRITE;
/*!40000 ALTER TABLE `book_shelf_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `book_shelf_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `bookdrop_file`
--

DROP TABLE IF EXISTS `bookdrop_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookdrop_file` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `file_path` text NOT NULL,
  `file_name` varchar(512) NOT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'PENDING_REVIEW',
  `original_metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`original_metadata`)),
  `fetched_metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`fetched_metadata`)),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_file_path` (`file_path`(255))
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookdrop_file`
--

LOCK TABLES `bookdrop_file` WRITE;
/*!40000 ALTER TABLE `bookdrop_file` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `bookdrop_file` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `category` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `category` VALUES
(28,' American'),
(46,'Action'),
(76,'Action & Adventure'),
(33,'Adult'),
(23,'Adventure'),
(44,'African Americans'),
(31,'Aliens'),
(5,'Architecture'),
(70,'Audio Book'),
(13,'Audiobook'),
(72,'Aventure'),
(43,'Biography'),
(42,'Biography & Autobiography'),
(75,'Book Club'),
(73,'Chemistry'),
(25,'Classics'),
(67,'Classique'),
(7,'Coding'),
(66,'Comics & Graphic Novels'),
(9,'Computer Science'),
(52,'Computers'),
(48,'Crime'),
(51,'Detective'),
(64,'Drama'),
(55,'Dystopia'),
(54,'Dystopian'),
(81,'Dystopian Fiction'),
(4,'Engineering'),
(39,'Epic'),
(19,'Fantasy'),
(71,'Fantasy Fiction'),
(86,'Fantasy:humour'),
(1,'Fiction'),
(82,'Fiction > Sci-fi/fantasy'),
(83,'Free Will And Determinism'),
(30,'Frontier And Pioneer Life'),
(85,'Funny'),
(24,'General'),
(65,'German Literature'),
(35,'Hard Science Fiction'),
(2,'Health & Fitness'),
(62,'Historical'),
(29,'Historical Fiction'),
(68,'Horreur'),
(17,'Horror'),
(57,'Humor'),
(69,'Hyperion (imaginary Place)'),
(87,'Jeune Adulte'),
(58,'Juvenile Fiction'),
(45,'Juvenile Nonfiction'),
(80,'Lgbtq'),
(40,'Literature & Fiction'),
(47,'Literature & Fiction|mystery'),
(59,'Medicine'),
(60,'Medieval'),
(27,'Middle Ages'),
(34,'Mystery'),
(11,'Nonfiction'),
(74,'Novella'),
(61,'Novels'),
(26,'Physicians'),
(79,'Picaresque'),
(56,'Politics'),
(10,'Programming'),
(78,'Quests (expeditions)'),
(77,'Robots'),
(14,'Roman'),
(41,'Romance'),
(22,'Science Fiction'),
(38,'Science Fiction & Fantasy'),
(20,'Science Fiction Fantasy'),
(12,'Software'),
(15,'Space'),
(84,'Space Colonies'),
(16,'Space Opera'),
(36,'Speculative'),
(18,'Speculative Fiction'),
(49,'Speech'),
(50,'Suspense'),
(8,'Technical'),
(6,'Technology'),
(63,'The United States Of America'),
(32,'Thriller'),
(21,'Time Travel'),
(53,'War'),
(3,'Yoga'),
(37,'Young Adult'),
(88,'Young Adult Fiction');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `cbx_viewer_preference`
--

DROP TABLE IF EXISTS `cbx_viewer_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cbx_viewer_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `spread` varchar(16) DEFAULT NULL,
  `view_mode` varchar(16) DEFAULT NULL,
  `fit_mode` varchar(16) DEFAULT NULL,
  `scroll_mode` varchar(16) DEFAULT NULL,
  `background_color` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cbx_viewer_preference`
--

LOCK TABLES `cbx_viewer_preference` WRITE;
/*!40000 ALTER TABLE `cbx_viewer_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `cbx_viewer_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_character`
--

DROP TABLE IF EXISTS `comic_character`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_character` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_character`
--

LOCK TABLES `comic_character` WRITE;
/*!40000 ALTER TABLE `comic_character` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_character` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_creator`
--

DROP TABLE IF EXISTS `comic_creator`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_creator` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_creator`
--

LOCK TABLES `comic_creator` WRITE;
/*!40000 ALTER TABLE `comic_creator` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_creator` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_location`
--

DROP TABLE IF EXISTS `comic_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_location` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_location`
--

LOCK TABLES `comic_location` WRITE;
/*!40000 ALTER TABLE `comic_location` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_location` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_metadata`
--

DROP TABLE IF EXISTS `comic_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_metadata` (
  `book_id` bigint(20) NOT NULL,
  `issue_number` varchar(50) DEFAULT NULL,
  `volume_name` varchar(255) DEFAULT NULL,
  `volume_number` int(11) DEFAULT NULL,
  `story_arc` varchar(255) DEFAULT NULL,
  `story_arc_number` int(11) DEFAULT NULL,
  `alternate_series` varchar(255) DEFAULT NULL,
  `alternate_issue` varchar(50) DEFAULT NULL,
  `imprint` varchar(255) DEFAULT NULL,
  `format` varchar(50) DEFAULT NULL,
  `black_and_white` tinyint(1) DEFAULT 0,
  `manga` tinyint(1) DEFAULT 0,
  `reading_direction` varchar(10) DEFAULT 'ltr',
  `web_link` varchar(1000) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `issue_number_locked` tinyint(1) DEFAULT 0,
  `volume_name_locked` tinyint(1) DEFAULT 0,
  `volume_number_locked` tinyint(1) DEFAULT 0,
  `story_arc_locked` tinyint(1) DEFAULT 0,
  `creators_locked` tinyint(1) DEFAULT 0,
  `characters_locked` tinyint(1) DEFAULT 0,
  `teams_locked` tinyint(1) DEFAULT 0,
  `locations_locked` tinyint(1) DEFAULT 0,
  `imprint_locked` tinyint(1) DEFAULT 0,
  `format_locked` tinyint(1) DEFAULT 0,
  `black_and_white_locked` tinyint(1) DEFAULT 0,
  `manga_locked` tinyint(1) DEFAULT 0,
  `reading_direction_locked` tinyint(1) DEFAULT 0,
  `web_link_locked` tinyint(1) DEFAULT 0,
  `notes_locked` tinyint(1) DEFAULT 0,
  `story_arc_number_locked` tinyint(1) DEFAULT 0,
  `alternate_series_locked` tinyint(1) DEFAULT 0,
  `alternate_issue_locked` tinyint(1) DEFAULT 0,
  `pencillers_locked` tinyint(1) DEFAULT 0,
  `inkers_locked` tinyint(1) DEFAULT 0,
  `colorists_locked` tinyint(1) DEFAULT 0,
  `letterers_locked` tinyint(1) DEFAULT 0,
  `cover_artists_locked` tinyint(1) DEFAULT 0,
  `editors_locked` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`book_id`),
  KEY `idx_comic_metadata_story_arc` (`story_arc`),
  KEY `idx_comic_metadata_volume_name` (`volume_name`),
  CONSTRAINT `fk_comic_metadata_book` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_metadata`
--

LOCK TABLES `comic_metadata` WRITE;
/*!40000 ALTER TABLE `comic_metadata` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_metadata` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_metadata_character_mapping`
--

DROP TABLE IF EXISTS `comic_metadata_character_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_metadata_character_mapping` (
  `book_id` bigint(20) NOT NULL,
  `character_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`character_id`),
  KEY `fk_comic_char_mapping_char` (`character_id`),
  CONSTRAINT `fk_comic_char_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `comic_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comic_char_mapping_char` FOREIGN KEY (`character_id`) REFERENCES `comic_character` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_metadata_character_mapping`
--

LOCK TABLES `comic_metadata_character_mapping` WRITE;
/*!40000 ALTER TABLE `comic_metadata_character_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_metadata_character_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_metadata_creator_mapping`
--

DROP TABLE IF EXISTS `comic_metadata_creator_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_metadata_creator_mapping` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `book_id` bigint(20) NOT NULL,
  `creator_id` bigint(20) NOT NULL,
  `role` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_comic_creator_mapping_creator` (`creator_id`),
  KEY `idx_comic_creator_mapping_role` (`role`),
  KEY `idx_comic_creator_mapping_book` (`book_id`),
  CONSTRAINT `fk_comic_creator_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `comic_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comic_creator_mapping_creator` FOREIGN KEY (`creator_id`) REFERENCES `comic_creator` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_metadata_creator_mapping`
--

LOCK TABLES `comic_metadata_creator_mapping` WRITE;
/*!40000 ALTER TABLE `comic_metadata_creator_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_metadata_creator_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_metadata_location_mapping`
--

DROP TABLE IF EXISTS `comic_metadata_location_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_metadata_location_mapping` (
  `book_id` bigint(20) NOT NULL,
  `location_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`location_id`),
  KEY `fk_comic_loc_mapping_loc` (`location_id`),
  CONSTRAINT `fk_comic_loc_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `comic_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comic_loc_mapping_loc` FOREIGN KEY (`location_id`) REFERENCES `comic_location` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_metadata_location_mapping`
--

LOCK TABLES `comic_metadata_location_mapping` WRITE;
/*!40000 ALTER TABLE `comic_metadata_location_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_metadata_location_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_metadata_team_mapping`
--

DROP TABLE IF EXISTS `comic_metadata_team_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_metadata_team_mapping` (
  `book_id` bigint(20) NOT NULL,
  `team_id` bigint(20) NOT NULL,
  PRIMARY KEY (`book_id`,`team_id`),
  KEY `fk_comic_team_mapping_team` (`team_id`),
  CONSTRAINT `fk_comic_team_mapping_book` FOREIGN KEY (`book_id`) REFERENCES `comic_metadata` (`book_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comic_team_mapping_team` FOREIGN KEY (`team_id`) REFERENCES `comic_team` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_metadata_team_mapping`
--

LOCK TABLES `comic_metadata_team_mapping` WRITE;
/*!40000 ALTER TABLE `comic_metadata_team_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_metadata_team_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `comic_team`
--

DROP TABLE IF EXISTS `comic_team`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comic_team` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comic_team`
--

LOCK TABLES `comic_team` WRITE;
/*!40000 ALTER TABLE `comic_team` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `comic_team` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `custom_font`
--

DROP TABLE IF EXISTS `custom_font`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `custom_font` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `font_name` varchar(255) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `original_file_name` varchar(255) NOT NULL,
  `format` varchar(10) NOT NULL,
  `file_size` bigint(20) NOT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `file_name` (`file_name`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `custom_font_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `custom_font`
--

LOCK TABLES `custom_font` WRITE;
/*!40000 ALTER TABLE `custom_font` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `custom_font` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `ebook_viewer_preference`
--

DROP TABLE IF EXISTS `ebook_viewer_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ebook_viewer_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `font_family` varchar(128) DEFAULT NULL,
  `font_size` int(11) DEFAULT NULL,
  `gap` float DEFAULT NULL,
  `hyphenate` tinyint(1) DEFAULT NULL,
  `is_dark` tinyint(1) DEFAULT NULL,
  `justify` tinyint(1) DEFAULT NULL,
  `line_height` float DEFAULT NULL,
  `max_block_size` int(11) DEFAULT NULL,
  `max_column_count` int(11) DEFAULT NULL,
  `max_inline_size` int(11) DEFAULT NULL,
  `theme` varchar(64) DEFAULT NULL,
  `flow` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`),
  KEY `fk_ebook_viewer_preference_book` (`book_id`),
  CONSTRAINT `fk_ebook_viewer_preference_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ebook_viewer_preference_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ebook_viewer_preference`
--

LOCK TABLES `ebook_viewer_preference` WRITE;
/*!40000 ALTER TABLE `ebook_viewer_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `ebook_viewer_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `email_provider`
--

DROP TABLE IF EXISTS `email_provider`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_provider` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `host` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `from_address` varchar(255) DEFAULT NULL,
  `auth` tinyint(1) NOT NULL,
  `start_tls` tinyint(1) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`host`,`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_provider`
--

LOCK TABLES `email_provider` WRITE;
/*!40000 ALTER TABLE `email_provider` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `email_provider` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `email_provider_v2`
--

DROP TABLE IF EXISTS `email_provider_v2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_provider_v2` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `host` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `from_address` varchar(255) DEFAULT NULL,
  `auth` tinyint(1) NOT NULL,
  `start_tls` tinyint(1) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `shared` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`name`),
  KEY `idx_email_provider_v2_user_id` (`user_id`),
  CONSTRAINT `fk_email_provider_v2_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_provider_v2`
--

LOCK TABLES `email_provider_v2` WRITE;
/*!40000 ALTER TABLE `email_provider_v2` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `email_provider_v2` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `email_recipient`
--

DROP TABLE IF EXISTS `email_recipient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_recipient` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_recipient`
--

LOCK TABLES `email_recipient` WRITE;
/*!40000 ALTER TABLE `email_recipient` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `email_recipient` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `email_recipient_v2`
--

DROP TABLE IF EXISTS `email_recipient_v2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_recipient_v2` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `email` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`email`),
  KEY `idx_email_recipient_v2_user_id` (`user_id`),
  CONSTRAINT `fk_email_recipient_v2_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_recipient_v2`
--

LOCK TABLES `email_recipient_v2` WRITE;
/*!40000 ALTER TABLE `email_recipient_v2` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `email_recipient_v2` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `epub_viewer_preference`
--

DROP TABLE IF EXISTS `epub_viewer_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `epub_viewer_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `theme` varchar(255) DEFAULT NULL,
  `font` varchar(255) DEFAULT NULL,
  `font_size` int(11) DEFAULT NULL,
  `flow` varchar(32) DEFAULT NULL,
  `letter_spacing` float DEFAULT NULL,
  `line_height` float DEFAULT NULL,
  `spread` varchar(20) DEFAULT 'double',
  `custom_font_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`),
  KEY `custom_font_id` (`custom_font_id`),
  CONSTRAINT `epub_viewer_preference_ibfk_1` FOREIGN KEY (`custom_font_id`) REFERENCES `custom_font` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `epub_viewer_preference`
--

LOCK TABLES `epub_viewer_preference` WRITE;
/*!40000 ALTER TABLE `epub_viewer_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `epub_viewer_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `flyway_schema_history`
--

DROP TABLE IF EXISTS `flyway_schema_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `flyway_schema_history` (
  `installed_rank` int(11) NOT NULL,
  `version` varchar(50) DEFAULT NULL,
  `description` varchar(200) NOT NULL,
  `type` varchar(20) NOT NULL,
  `script` varchar(1000) NOT NULL,
  `checksum` int(11) DEFAULT NULL,
  `installed_by` varchar(100) NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT current_timestamp(),
  `execution_time` int(11) NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`),
  KEY `flyway_schema_history_s_idx` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `flyway_schema_history`
--

LOCK TABLES `flyway_schema_history` WRITE;
/*!40000 ALTER TABLE `flyway_schema_history` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `flyway_schema_history` VALUES
(1,'1','Create Tables','SQL','V1__Create_Tables.sql',441949368,'booklore','2025-12-29 18:44:43',1151,1),
(2,'2','Insert Initial Data','SQL','V2__Insert_Initial_Data.sql',2105058525,'booklore','2025-12-29 18:44:43',1,1),
(3,'3','Create Email Tables','SQL','V3__Create_Email_Tables.sql',-888522085,'booklore','2025-12-29 18:44:43',116,1),
(4,'4','Insert Cover Image Settings','SQL','V4__Insert_Cover_Image_Settings.sql',-1633964822,'booklore','2025-12-29 18:44:43',147,1),
(5,'5','Insert Auto Book Search Settings','SQL','V5__Insert_Auto_Book_Search_Settings.sql',527402947,'booklore','2025-12-29 18:44:43',3,1),
(6,'6','Add amazon goodreads rating columns','SQL','V6__Add_amazon_goodreads_rating_columns.sql',-801290522,'booklore','2025-12-29 18:44:43',42,1),
(7,'7','Add similar books json column to book','SQL','V7__Add_similar_books_json_column_to_book.sql',-614923526,'booklore','2025-12-29 18:44:43',48,1),
(8,'8','Add file size column to book table','SQL','V8__Add_file_size_column_to_book_table.sql',-1020387681,'booklore','2025-12-29 18:44:43',52,1),
(9,'9','Create app migration table','SQL','V9__Create_app_migration_table.sql',1644051704,'booklore','2025-12-29 18:44:44',26,1),
(10,'10','Create opds user table','SQL','V10__Create_opds_user_table.sql',1974834775,'booklore','2025-12-29 18:44:44',31,1),
(11,'11','Create refresh token table','SQL','V11__Create_refresh_token_table.sql',1118485775,'booklore','2025-12-29 18:44:44',45,1),
(12,'12','Update app settings table','SQL','V12__Update_app_settings_table.sql',-999658752,'booklore','2025-12-29 18:44:44',147,1),
(13,'13','Add provisioned method column to users','SQL','V13__Add_provisioned_method_column_to_users.sql',1385026614,'booklore','2025-12-29 18:44:44',47,1),
(14,'14','Create user settings table','SQL','V14__Create_user_settings_table.sql',992621917,'booklore','2025-12-29 18:44:44',117,1),
(15,'15','Migrate user settings to user settings table','SQL','V15__Migrate_user_settings_to_user_settings_table.sql',200339025,'booklore','2025-12-29 18:44:44',1,1),
(16,'16','Widen selected column sizes','SQL','V16__Widen_selected_column_sizes.sql',20124511,'booklore','2025-12-29 18:44:45',520,1),
(17,'17','Add flow column to epub viewer preference','SQL','V17__Add_flow_column_to_epub_viewer_preference.sql',2010057070,'booklore','2025-12-29 18:44:45',50,1),
(18,'18','Add progress percent columns to user book progress','SQL','V18__Add_progress_percent_columns_to_user_book_progress.sql',-1121150387,'booklore','2025-12-29 18:44:45',51,1),
(19,'19','Widen selected column sizes even more','SQL','V19__Widen_selected_column_sizes_even_more.sql',502130045,'booklore','2025-12-29 18:44:45',376,1),
(20,'20','Add from address to email provider','SQL','V20__Add_from_address_to_email_provider.sql',912512983,'booklore','2025-12-29 18:44:45',53,1),
(21,'21','Change series number to float in book metadata','SQL','V21__Change_series_number_to_float_in_book_metadata.sql',-1023533259,'booklore','2025-12-29 18:44:45',62,1),
(22,'22','Create cbx viewer table','SQL','V22__Create_cbx_viewer_table.sql',453421476,'booklore','2025-12-29 18:44:45',32,1),
(23,'23','Add cbx progress to user book progress','SQL','V23__Add_cbx_progress_to_user_book_progress.sql',1329102045,'booklore','2025-12-29 18:44:45',48,1),
(24,'24','Add asin column','SQL','V24__Add_asin_column.sql',1681236340,'booklore','2025-12-29 18:44:45',93,1),
(25,'25','Add hardcover rating columns','SQL','V25__Add_hardcover_rating_columns.sql',-1339963032,'booklore','2025-12-29 18:44:46',44,1),
(26,'26','Create new pdf viewer table','SQL','V26__Create_new_pdf_viewer_table.sql',1225578202,'booklore','2025-12-29 18:44:46',37,1),
(27,'27','Add provider book ids to book metadata','SQL','V27__Add_provider_book_ids_to_book_metadata.sql',-1668397073,'booklore','2025-12-29 18:44:46',50,1),
(28,'28','Delete quick book match setting','SQL','V28__Delete_quick_book_match_setting.sql',1153722263,'booklore','2025-12-29 18:44:46',3,1),
(29,'29','Add metadata match score to book','SQL','V29__Add_metadata_match_score_to_book.sql',715282296,'booklore','2025-12-29 18:44:46',46,1),
(30,'30','Change setting value column to text','SQL','V30__Change_setting_value_column_to_text.sql',-598210439,'booklore','2025-12-29 18:44:46',73,1),
(31,'31','Add delete books permission','SQL','V31__Add_delete_books_permission.sql',-1246965722,'booklore','2025-12-29 18:44:46',51,1),
(32,'32','Add personal rating column','SQL','V32__Add_personal_rating_column.sql',-104428850,'booklore','2025-12-29 18:44:46',47,1),
(33,'33','Add read status to book','SQL','V33__Add_read_status_to_book.sql',-1685031460,'booklore','2025-12-29 18:44:46',48,1),
(34,'34','Add letter spacing and line height for epub settings','SQL','V34__Add_letter_spacing_and_line_height_for_epub_settings.sql',524099903,'booklore','2025-12-29 18:44:46',45,1),
(35,'35','Add hash and deleted columns to book table','SQL','V35__Add_hash_and_deleted_columns_to_book_table.sql',-909262685,'booklore','2025-12-29 18:44:46',282,1),
(36,'36','Add read status to user book progress','SQL','V36__Add_read_status_to_user_book_progress.sql',-295736495,'booklore','2025-12-29 18:44:46',51,1),
(37,'37','Create metadata fetch tables','SQL','V37__Create_metadata_fetch_tables.sql',-2038840308,'booklore','2025-12-29 18:44:47',257,1),
(38,'38','Create bookdrop file table','SQL','V38__Create_bookdrop_file_table.sql',1289380209,'booklore','2025-12-29 18:44:47',36,1),
(39,'39','Create magic shelf table','SQL','V39__Create_magic_shelf_table.sql',913610306,'booklore','2025-12-29 18:44:47',31,1),
(40,'40','Add book finished to user book progress','SQL','V40__Add_book_finished_to_user_book_progress.sql',-29964120,'booklore','2025-12-29 18:44:47',91,1),
(41,'41','Add comicvine id column','SQL','V41__Add_comicvine_id_column.sql',1747339167,'booklore','2025-12-29 18:44:47',42,1),
(42,'42','Add koreader user table and sync columns','SQL','V42__Add_koreader_user_table_and_sync_columns.sql',1453296548,'booklore','2025-12-29 18:44:47',107,1),
(43,'43','Add file naming pattern column to library','SQL','V43__Add_file_naming_pattern_column_to_library.sql',1494617361,'booklore','2025-12-29 18:44:47',16,1),
(44,'44','Create book review table','SQL','V44__Create_book_review_table.sql',-970507666,'booklore','2025-12-29 18:44:47',11,1),
(45,'45','Add reviews locked column','SQL','V45__Add_reviews_locked_column.sql',-817464128,'booklore','2025-12-29 18:44:47',61,1),
(46,'46','Increase hardcover id length to 512','SQL','V46__Increase_hardcover_id_length_to_512.sql',1445072125,'booklore','2025-12-29 18:44:47',35,1),
(47,'47','Create book notes table','SQL','V47__Create_book_notes_table.sql',-46714110,'booklore','2025-12-29 18:44:47',169,1),
(48,'48','Create kobo tables','SQL','V48__Create_kobo_tables.sql',-9127635,'booklore','2025-12-29 18:44:48',223,1),
(49,'49','Create book additional file table','SQL','V49__Create_book_additional_file_table.sql',685879960,'booklore','2025-12-29 18:44:48',101,1),
(50,'50','Add library scan mode settings','SQL','V50__Add_library_scan_mode_settings.sql',1892167720,'booklore','2025-12-29 18:44:48',48,1),
(51,'51','Create opds user credentials','SQL','V51__Create_opds_user_credentials.sql',-1382141364,'booklore','2025-12-29 18:44:48',82,1),
(52,'52','Alter opds user v2 unique username','SQL','V52__Alter_opds_user_v2_unique_username.sql',-668086153,'booklore','2025-12-29 18:44:48',401,1),
(53,'53','Add Mood And Tag Tables','SQL','V53__Add_Mood_And_Tag_Tables.sql',1368130318,'booklore','2025-12-29 18:44:49',372,1),
(54,'54','Add Spread Column Epub','SQL','V54__Add_Spread_Column_Epub.sql',61769424,'booklore','2025-12-29 18:44:49',48,1),
(55,'55','Create Tasks Table','SQL','V55__Create_Tasks_Table.sql',869127108,'booklore','2025-12-29 18:44:49',57,1),
(56,'56','Add fit scroll background to cbx viewer preference','SQL','V56__Add_fit_scroll_background_to_cbx_viewer_preference.sql',-1851010863,'booklore','2025-12-29 18:44:49',48,1),
(57,'57','Create Email V2 Tables','SQL','V57__Create_Email_V2_Tables.sql',-1980456047,'booklore','2025-12-29 18:44:49',185,1),
(58,'58','Vector columns','SQL','V58__Vector_columns.sql',1650709911,'booklore','2025-12-29 18:44:49',109,1),
(59,'59','Add shared column to email V2 table','SQL','V59__Add_shared_column_to_email_V2_table.sql',1558589323,'booklore','2025-12-29 18:44:49',52,1),
(60,'60','Create user email provider preference table','SQL','V60__Create_user_email_provider_preference_table.sql',-1521942266,'booklore','2025-12-29 18:44:49',44,1),
(61,'61','Create task cron configuration table','SQL','V61__Create_task_cron_configuration_table.sql',1434445247,'booklore','2025-12-29 18:44:49',39,1),
(62,'62','Add is public to magic shelf','SQL','V62__Add_is_public_to_magic_shelf.sql',-773598375,'booklore','2025-12-29 18:44:49',49,1),
(63,'63','Add kobo progress columns to user book progress','SQL','V63__Add_kobo_progress_columns_to_user_book_progress.sql',528474880,'booklore','2025-12-29 18:44:50',98,1),
(64,'64','Unique book subpath','SQL','V64__Unique_book_subpath.sql',-2054812658,'booklore','2025-12-29 18:44:50',183,1),
(65,'65','Add kobo reading status sync tracking','SQL','V65__Add_kobo_reading_status_sync_tracking.sql',266819949,'booklore','2025-12-29 18:44:50',199,1),
(66,'66','Add icon type to entities','SQL','V66__Add_icon_type_to_entities.sql',759312723,'booklore','2025-12-29 18:44:50',156,1),
(67,'69','Add search text column','SQL','V69__Add_search_text_column.sql',-1902853586,'booklore','2025-12-29 18:44:50',46,1),
(68,'70','Add user rating column','SQL','V70__Add_user_rating_column.sql',-1897948156,'booklore','2025-12-29 18:44:50',162,1),
(69,'71','Add auto add to kobo shelf','SQL','V71__Add_auto_add_to_kobo_shelf.sql',658326328,'booklore','2025-12-29 18:44:50',49,1),
(70,'72','Create book marks table','SQL','V72__Create_book_marks_table.sql',372495746,'booklore','2025-12-29 18:44:51',393,1),
(71,'73','Add sort order to opds user v2','SQL','V73__Add_sort_order_to_opds_user_v2.sql',-1814971380,'booklore','2025-12-29 18:44:51',46,1),
(72,'74','Add hardcover book id column','SQL','V74__Add_hardcover_book_id_column.sql',927981967,'booklore','2025-12-29 18:44:51',54,1),
(73,'75','Add hardcover book id locked column','SQL','V75__Add_hardcover_book_id_locked_column.sql',-750925040,'booklore','2025-12-29 18:44:51',58,1),
(74,'76','Add user hardcover settings','SQL','V76__Add_user_hardcover_settings.sql',1232842810,'booklore','2025-12-29 18:44:51',391,1),
(75,'77','Add color notes priority to book marks table','SQL','V77__Add_color_notes_priority_to_book_marks_table.sql',573259703,'booklore','2025-12-29 18:44:52',182,1),
(76,'78','Create reading sessions table','SQL','V78__Create_reading_sessions_table.sql',1246507932,'booklore','2025-12-29 18:44:52',233,1),
(77,'79','Add New Permissions','SQL','V79__Add_New_Permissions.sql',793114044,'booklore','2025-12-29 18:44:52',43,1),
(78,'80','Add lubimyczytac provider','SQL','V80__Add_lubimyczytac_provider.sql',849200798,'booklore','2025-12-29 20:14:17',67,1),
(79,'81','Cleanup kobo snapshot book wrong user','SQL','V81__Cleanup_kobo_snapshot_book_wrong_user.sql',195063163,'booklore','2026-01-03 17:23:53',38,1),
(80,'82','Add bulk operations permissions','SQL','V82__Add_bulk_operations_permissions.sql',-53581993,'booklore','2026-01-03 17:23:53',91,1),
(81,'83','Add metadata and kobo book columns','SQL','V83__Add_metadata_and_kobo_book_columns.sql',-309266589,'booklore','2026-01-04 20:47:19',594,1),
(82,'84','Assign admin users to all libraries','SQL','V84__Assign_admin_users_to_all_libraries.sql',359218852,'booklore','2026-01-04 20:47:20',8,1),
(83,'85','Create Custom Font Table','SQL','V85__Create_Custom_Font_Table.sql',-559243380,'booklore','2026-01-10 07:37:31',62,1),
(84,'86','Add Custom Font To Epub Preferences','SQL','V86__Add_Custom_Font_To_Epub_Preferences.sql',-1512253861,'booklore','2026-01-10 07:37:31',130,1),
(85,'87','Migrate MetadataPersistenceSettings Structure','SQL','V87__Migrate_MetadataPersistenceSettings_Structure.sql',77304877,'booklore','2026-01-10 07:37:31',2,1),
(86,'88','Add Font Permissions','SQL','V88__Add_Font_Permissions.sql',1489068840,'booklore','2026-01-10 07:37:31',52,1),
(87,'89','Add archive type column to book table','SQL','V89__Add_archive_type_column_to_book_table.sql',-701793773,'booklore','2026-01-25 15:46:17',162,1),
(88,'90','Add ranobedb provider','SQL','V90__Add_ranobedb_provider.sql',1694298463,'booklore','2026-01-25 15:46:17',65,1),
(89,'91','Refactor book and book alternative files','SQL','V91__Refactor_book_and_book_alternative_files.sql',-106957208,'booklore','2026-01-25 15:46:18',1374,1),
(90,'92','Create ebook viewer preference table','SQL','V92__Create_ebook_viewer_preference_table.sql',-1776131043,'booklore','2026-01-25 15:46:18',93,1),
(91,'93','Add is public to shelf','SQL','V93__Add_is_public_to_shelf.sql',-938593544,'booklore','2026-01-25 15:46:18',49,1),
(92,'94','Add sync with booklore reader to koreader user','SQL','V94__Add_sync_with_booklore_reader_to_koreader_user.sql',-394172631,'booklore','2026-01-25 15:46:18',50,1),
(93,'95','Create annotations table','SQL','V95__Create_annotations_table.sql',880670877,'booklore','2026-01-25 15:46:19',689,1),
(94,'96','Create book notes v2 table','SQL','V96__Create_book_notes_v2_table.sql',-726516375,'booklore','2026-01-25 15:46:20',501,1),
(95,'97','Update new pdf viewer table','SQL','V97__Update_new_pdf_viewer_table.sql',107464978,'booklore','2026-01-25 15:46:20',54,1),
(96,'98','Add komga settings','SQL','V98__Add_komga_settings.sql',1711782161,'booklore','2026-01-25 15:46:20',2,1),
(97,'99','Delete clear pdf cbx cache task cron','SQL','V99__Delete_clear_pdf_cbx_cache_task_cron.sql',528441065,'booklore','2026-01-25 15:46:20',2,1),
(98,'100','Create user book file progress','SQL','V100__Create_user_book_file_progress.sql',1400729021,'booklore','2026-02-28 11:45:38',183,1),
(99,'101','Migrate default book format to format priority','SQL','V101__Migrate_default_book_format_to_format_priority.sql',10049585,'booklore','2026-02-28 11:45:38',113,1),
(100,'102','Add is folder based to book file','SQL','V102__Add_is_folder_based_to_book_file.sql',-1844352318,'booklore','2026-02-28 11:45:38',60,1),
(101,'103','Add organization mode to library','SQL','V103__Add_organization_mode_to_library.sql',-1112414822,'booklore','2026-02-28 11:45:38',325,1),
(102,'104','Add audiobook bookmark columns','SQL','V104__Add_audiobook_bookmark_columns.sql',1632193781,'booklore','2026-02-28 11:45:39',463,1),
(103,'105','Make reading session columns nullable','SQL','V105__Make_reading_session_columns_nullable.sql',2016979951,'booklore','2026-02-28 11:45:39',687,1),
(104,'106','Add physical book support','SQL','V106__Add_physical_book_support.sql',-446824709,'booklore','2026-02-28 11:45:40',216,1),
(105,'107','Change hardcover book id to varchar','SQL','V107__Change_hardcover_book_id_to_varchar.sql',1926300194,'booklore','2026-02-28 11:45:40',86,1),
(106,'108','Add user id to kobo reading state','SQL','V108__Add_user_id_to_kobo_reading_state.sql',-1117612684,'booklore','2026-02-28 11:45:40',297,1),
(107,'109','Add audiobook support','SQL','V109__Add_audiobook_support.sql',-208562268,'booklore','2026-02-28 11:45:41',1122,1),
(108,'110','Add age rating to book metadata','SQL','V110__Add_age_rating_to_book_metadata.sql',-2023068126,'booklore','2026-02-28 11:45:41',227,1),
(109,'111','Create user content restriction table','SQL','V111__Create_user_content_restriction_table.sql',-1680641058,'booklore','2026-02-28 11:45:41',127,1),
(110,'112','Fix refresh token datetime precision','SQL','V112__Fix_refresh_token_datetime_precision.sql',-729972158,'booklore','2026-02-28 11:45:42',111,1),
(111,'113','Make icon type nullable','SQL','V113__Make_icon_type_nullable.sql',-2008929222,'booklore','2026-02-28 11:45:42',504,1),
(112,'114','Create comic metadata tables','SQL','V114__Create_comic_metadata_tables.sql',-1810124584,'booklore','2026-02-28 11:45:43',796,1),
(113,'115','Add sidecar metadata support','SQL','V115__Add_sidecar_metadata_support.sql',-369851897,'booklore','2026-02-28 11:45:43',50,1),
(114,'116','Add cascade delete to library path','SQL','V116__Add_cascade_delete_to_library_path.sql',-2094901602,'booklore','2026-02-28 11:45:43',389,1),
(115,'117','Add per field comic lock columns','SQL','V117__Add_per_field_comic_lock_columns.sql',-176548919,'booklore','2026-02-28 11:45:45',1492,1),
(116,'118','Create pdf annotations table','SQL','V118__Create_pdf_annotations_table.sql',1857518544,'booklore','2026-02-28 11:45:45',495,1),
(117,'119','Add notebook composite indexes','SQL','V119__Add_notebook_composite_indexes.sql',-1545109472,'booklore','2026-02-28 11:45:46',662,1),
(118,'120','Create audit log table','SQL','V120__Create_audit_log_table.sql',795225532,'booklore','2026-02-28 11:45:47',529,1),
(119,'121','Add country code to audit log','SQL','V121__Add_country_code_to_audit_log.sql',302277570,'booklore','2026-02-28 11:45:47',48,1),
(120,'122','Add bookdrop periodic scanning task cron','SQL','V122__Add_bookdrop_periodic_scanning_task_cron.sql',656543137,'booklore','2026-02-28 11:45:47',1,1),
(121,'123','Add two way progress sync to kobo settings','SQL','V123__Add_two_way_progress_sync_to_kobo_settings.sql',-1007699463,'booklore','2026-02-28 11:45:47',46,1),
(122,'124','Add author metadata columns','SQL','V124__Add_author_metadata_columns.sql',-1030308844,'booklore','2026-02-28 11:45:47',392,1),
(123,'125','Trim whitespace in book metadata','SQL','V125__Trim_whitespace_in_book_metadata.sql',1484205157,'booklore','2026-02-28 11:45:47',4,1),
(124,'126','Update auto book search default false','SQL','V126__Update_auto_book_search_default_false.sql',-2039202616,'booklore','2026-03-01 13:29:24',37,1),
(125,'127','Add oidc schema','SQL','V127__Add_oidc_schema.sql',1434011258,'booklore','2026-03-12 17:47:34',849,1),
(126,'128','Create oidc group mapping','SQL','V128__Create_oidc_group_mapping.sql',1587016801,'booklore','2026-03-12 17:47:34',52,1),
(127,'129','Add sort order to author mapping','SQL','V129__Add_sort_order_to_author_mapping.sql',-1750996724,'booklore','2026-03-12 17:47:34',374,1),
(128,'130','Add book per file organization mode','SQL','V130__Add_book_per_file_organization_mode.sql',1335427399,'booklore','2026-03-12 17:47:34',76,1),
(129,'131','Add tts position cfi to user book file progress','SQL','V131__Add_tts_position_cfi_to_user_book_file_progress.sql',-1650568121,'booklore','2026-03-12 17:47:34',48,1),
(130,'132','Add scanned on to books','SQL','V132__Add_scanned_on_to_books.sql',1156401364,'booklore','2026-03-12 17:47:34',87,1);
/*!40000 ALTER TABLE `flyway_schema_history` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `jwt_secret`
--

DROP TABLE IF EXISTS `jwt_secret`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `jwt_secret` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `secret` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jwt_secret`
--

LOCK TABLES `jwt_secret` WRITE;
/*!40000 ALTER TABLE `jwt_secret` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `jwt_secret` VALUES
(1,'WTaheCG5uCMS6lza3jmSZ+Sgo3/YnetxcB5v5uyJqS4=','2025-12-29 18:44:58');
/*!40000 ALTER TABLE `jwt_secret` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `kobo_library_snapshot`
--

DROP TABLE IF EXISTS `kobo_library_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `kobo_library_snapshot` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `created_date` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_snapshot_user` (`user_id`),
  CONSTRAINT `fk_snapshot_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kobo_library_snapshot`
--

LOCK TABLES `kobo_library_snapshot` WRITE;
/*!40000 ALTER TABLE `kobo_library_snapshot` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `kobo_library_snapshot` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `kobo_library_snapshot_book`
--

DROP TABLE IF EXISTS `kobo_library_snapshot_book`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `kobo_library_snapshot_book` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `snapshot_id` varchar(36) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `synced` tinyint(1) NOT NULL DEFAULT 0,
  `file_hash` varchar(255) DEFAULT NULL,
  `metadata_updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_snapshot_book` (`snapshot_id`,`book_id`),
  CONSTRAINT `fk_snapshot_book` FOREIGN KEY (`snapshot_id`) REFERENCES `kobo_library_snapshot` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kobo_library_snapshot_book`
--

LOCK TABLES `kobo_library_snapshot_book` WRITE;
/*!40000 ALTER TABLE `kobo_library_snapshot_book` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `kobo_library_snapshot_book` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `kobo_reading_state`
--

DROP TABLE IF EXISTS `kobo_reading_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `kobo_reading_state` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `entitlement_id` varchar(255) NOT NULL,
  `created` varchar(255) DEFAULT NULL,
  `last_modified` varchar(255) DEFAULT NULL,
  `priority_timestamp` varchar(255) DEFAULT NULL,
  `current_bookmark_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`current_bookmark_json`)),
  `statistics_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`statistics_json`)),
  `status_info_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`status_info_json`)),
  `last_modified_string` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_kobo_reading_state_user_entitlement` (`user_id`,`entitlement_id`),
  KEY `idx_kobo_reading_state_entitlement_id` (`entitlement_id`),
  CONSTRAINT `fk_kobo_reading_state_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kobo_reading_state`
--

LOCK TABLES `kobo_reading_state` WRITE;
/*!40000 ALTER TABLE `kobo_reading_state` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `kobo_reading_state` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `kobo_removed_books_tracking`
--

DROP TABLE IF EXISTS `kobo_removed_books_tracking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `kobo_removed_books_tracking` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `snapshot_id` varchar(36) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `book_id_synced` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_snapshot_user_book` (`snapshot_id`,`user_id`,`book_id_synced`),
  CONSTRAINT `fk_removed_snapshot` FOREIGN KEY (`snapshot_id`) REFERENCES `kobo_library_snapshot` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kobo_removed_books_tracking`
--

LOCK TABLES `kobo_removed_books_tracking` WRITE;
/*!40000 ALTER TABLE `kobo_removed_books_tracking` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `kobo_removed_books_tracking` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `kobo_user_settings`
--

DROP TABLE IF EXISTS `kobo_user_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `kobo_user_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `token` varchar(2048) NOT NULL,
  `sync_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `progress_mark_as_reading_threshold` float DEFAULT 1,
  `progress_mark_as_finished_threshold` float DEFAULT 99,
  `auto_add_to_shelf` tinyint(1) NOT NULL DEFAULT 0,
  `hardcover_api_key` varchar(2048) DEFAULT NULL,
  `hardcover_sync_enabled` tinyint(1) DEFAULT 0,
  `two_way_progress_sync` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `fk_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kobo_user_settings`
--

LOCK TABLES `kobo_user_settings` WRITE;
/*!40000 ALTER TABLE `kobo_user_settings` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `kobo_user_settings` VALUES
(1,1,'240a1bef-9572-4128-95e8-40440b6173e3',0,1,99,0,NULL,0,0);
/*!40000 ALTER TABLE `kobo_user_settings` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `koreader_user`
--

DROP TABLE IF EXISTS `koreader_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `koreader_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `password_md5` varchar(255) NOT NULL,
  `sync_enabled` tinyint(1) DEFAULT NULL,
  `booklore_user_id` bigint(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sync_with_booklore_reader` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `fk_booklore_user` (`booklore_user_id`),
  CONSTRAINT `fk_booklore_user` FOREIGN KEY (`booklore_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `koreader_user`
--

LOCK TABLES `koreader_user` WRITE;
/*!40000 ALTER TABLE `koreader_user` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `koreader_user` VALUES
(1,'koreader','kommensie','0e621eca2657e0807318d097a686cd17',1,1,'2026-02-07 17:41:05','2026-02-20 16:50:25',0);
/*!40000 ALTER TABLE `koreader_user` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `library`
--

DROP TABLE IF EXISTS `library`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `library` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `sort` varchar(255) DEFAULT NULL,
  `icon` varchar(64) DEFAULT NULL,
  `watch` tinyint(1) NOT NULL DEFAULT 0,
  `file_naming_pattern` varchar(1000) DEFAULT NULL,
  `icon_type` varchar(255) DEFAULT NULL,
  `format_priority` text DEFAULT NULL,
  `organization_mode` varchar(50) DEFAULT 'BOOK_PER_FILE',
  `allowed_formats` text DEFAULT NULL,
  `metadata_source` varchar(20) DEFAULT 'EMBEDDED',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `library`
--

LOCK TABLES `library` WRITE;
/*!40000 ALTER TABLE `library` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `library` VALUES
(1,'Default',NULL,'pi pi-book',1,NULL,'PRIME_NG',NULL,'AUTO_DETECT',NULL,'EMBEDDED');
/*!40000 ALTER TABLE `library` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `library_path`
--

DROP TABLE IF EXISTS `library_path`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `library_path` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `path` text DEFAULT NULL,
  `library_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_library_path` (`library_id`),
  CONSTRAINT `fk_library_path` FOREIGN KEY (`library_id`) REFERENCES `library` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `library_path`
--

LOCK TABLES `library_path` WRITE;
/*!40000 ALTER TABLE `library_path` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `library_path` VALUES
(1,'/books',1);
/*!40000 ALTER TABLE `library_path` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `magic_shelf`
--

DROP TABLE IF EXISTS `magic_shelf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `magic_shelf` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `icon` varchar(64) DEFAULT NULL,
  `filter_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`filter_json`)),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  `icon_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_name` (`user_id`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `magic_shelf`
--

LOCK TABLES `magic_shelf` WRITE;
/*!40000 ALTER TABLE `magic_shelf` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `magic_shelf` VALUES
(1,1,'Missing Hardcover ID','pi pi-file-excel','{\"type\":\"group\",\"join\":\"and\",\"rules\":[{\"field\":\"metadataPresence\",\"operator\":\"not_equals\",\"value\":\"hardcoverId\"}]}','2026-03-05 17:38:54','2026-03-05 17:46:56',0,'PRIME_NG');
/*!40000 ALTER TABLE `magic_shelf` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `metadata_fetch_jobs`
--

DROP TABLE IF EXISTS `metadata_fetch_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `metadata_fetch_jobs` (
  `task_id` varchar(100) NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `status_message` text DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` timestamp NULL DEFAULT NULL,
  `total_books_count` int(11) DEFAULT NULL,
  `completed_books` int(11) DEFAULT 0,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metadata_fetch_jobs`
--

LOCK TABLES `metadata_fetch_jobs` WRITE;
/*!40000 ALTER TABLE `metadata_fetch_jobs` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `metadata_fetch_jobs` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `metadata_fetch_proposals`
--

DROP TABLE IF EXISTS `metadata_fetch_proposals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `metadata_fetch_proposals` (
  `proposal_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(100) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `fetched_at` timestamp NULL DEFAULT current_timestamp(),
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewer_user_id` bigint(20) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'pending',
  `metadata_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`metadata_json`)),
  PRIMARY KEY (`proposal_id`),
  KEY `idx_metadata_proposal_task_id` (`task_id`),
  KEY `idx_metadata_proposal_book_id` (`book_id`),
  KEY `idx_metadata_proposal_status` (`status`),
  CONSTRAINT `fk_metadata_fetch_task` FOREIGN KEY (`task_id`) REFERENCES `metadata_fetch_jobs` (`task_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metadata_fetch_proposals`
--

LOCK TABLES `metadata_fetch_proposals` WRITE;
/*!40000 ALTER TABLE `metadata_fetch_proposals` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `metadata_fetch_proposals` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `mood`
--

DROP TABLE IF EXISTS `mood`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mood` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mood`
--

LOCK TABLES `mood` WRITE;
/*!40000 ALTER TABLE `mood` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `mood` VALUES
(2,'Adventurous'),
(8,'Challenging'),
(7,'Dark'),
(4,'Emotional'),
(5,'Funny'),
(3,'Hopeful'),
(11,'Inspiring'),
(10,'Lighthearted'),
(6,'Mysterious'),
(9,'Reflective'),
(1,'Tense');
/*!40000 ALTER TABLE `mood` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `new_pdf_viewer_preference`
--

DROP TABLE IF EXISTS `new_pdf_viewer_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `new_pdf_viewer_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `spread` varchar(16) DEFAULT NULL,
  `view_mode` varchar(16) DEFAULT NULL,
  `fit_mode` varchar(16) DEFAULT NULL,
  `scroll_mode` varchar(16) DEFAULT NULL,
  `background_color` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `new_pdf_viewer_preference`
--

LOCK TABLES `new_pdf_viewer_preference` WRITE;
/*!40000 ALTER TABLE `new_pdf_viewer_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `new_pdf_viewer_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `oidc_group_mapping`
--

DROP TABLE IF EXISTS `oidc_group_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `oidc_group_mapping` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `oidc_group_claim` varchar(255) NOT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `permissions` text DEFAULT NULL,
  `library_ids` text DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `oidc_group_claim` (`oidc_group_claim`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `oidc_group_mapping`
--

LOCK TABLES `oidc_group_mapping` WRITE;
/*!40000 ALTER TABLE `oidc_group_mapping` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `oidc_group_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `oidc_session`
--

DROP TABLE IF EXISTS `oidc_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `oidc_session` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `oidc_subject` varchar(255) NOT NULL,
  `oidc_issuer` varchar(512) NOT NULL,
  `oidc_session_id` varchar(255) DEFAULT NULL,
  `id_token_hint` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `last_refreshed_at` timestamp NULL DEFAULT NULL,
  `revoked` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_oidc_session_user_id` (`user_id`),
  KEY `idx_oidc_session_subject` (`oidc_subject`),
  KEY `idx_oidc_session_sid` (`oidc_session_id`),
  KEY `idx_oidc_session_sub_iss_revoked` (`oidc_subject`,`oidc_issuer`,`revoked`),
  CONSTRAINT `fk_oidc_session_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `oidc_session`
--

LOCK TABLES `oidc_session` WRITE;
/*!40000 ALTER TABLE `oidc_session` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `oidc_session` VALUES
(2,1,'b9f55a9b-860b-4886-ba2c-4f2927c07d51','https://auth.ntasler.de',NULL,'eyJhbGciOiJSUzI1NiIsImtpZCI6IjAyNGEzYy1yczI1NiIsInR5cCI6IkpXVCJ9.eyJhbXIiOlsicHdkIiwia2JhIl0sImF0X2hhc2giOiJTUG9LTzlMVTdYVkJnTHByMUdGZVlBIiwiYXVkIjpbImJvb2tsb3JlIl0sImF1dGhfdGltZSI6MTc3MzM0NDc2MSwiYXpwIjoiYm9va2xvcmUiLCJlbWFpbCI6Im5pa2xhc0BudGFzbGVyLmRlIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImV4cCI6MTc3MzM0ODU5OCwiaWF0IjoxNzczMzQ0OTk4LCJpc3MiOiJodHRwczovL2F1dGgubnRhc2xlci5kZSIsImp0aSI6ImNkNmYwOWM4LThkMWQtNDQxNy05ODMzLWNkOGM4NDBkNTllYiIsIm5hbWUiOiJOaWtsYXMiLCJub25jZSI6IldlSTFyeU5GOHRMRjFjYmw0VFQ4VW1OWkdacjFxN0xKNGtTYVZiYWM3VTgiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJuaWtsYXMiLCJzdWIiOiJiOWY1NWE5Yi04NjBiLTQ4ODYtYmEyYy00ZjI5MjdjMDdkNTEifQ.MYCNy46mVrphRwtv-S7O7_nMkiKpxzJcsR_F7Q330FHFWwEi_S5WDDPuo0UKNEW1I-DnmSaOnbZaJH3UUqDCmosp6_87MU2JuBYeNKRD1AY0So4s91JJmcZ_-3VHe1VXq4wU2uoH4QQcOoyyYcYU42P_Cl7EqBFcFwbnVgzJMDDkGmrNebpi-UuIPhMqdgKz-X0yS2v74_MkDPIXzNxte6-jg_jS6wc5VMyczzHgEAyRJAjw2MOg8B2xpZ65N8kW1tQ6BczgcKY09BjR8_zfCezyKtVnZrC6Sh-cxdMdrAjhPJ_-0Q2VmdJOP946tfBZY5AXtHuay20M_Xcwto6n-w','2026-03-12 18:49:58',NULL,0),
(3,1,'b9f55a9b-860b-4886-ba2c-4f2927c07d51','https://auth.ntasler.de',NULL,'eyJhbGciOiJSUzI1NiIsImtpZCI6IjAyNGEzYy1yczI1NiIsInR5cCI6IkpXVCJ9.eyJhbXIiOlsicHdkIiwia2JhIl0sImF0X2hhc2giOiJabmd1WTVZeVFvYVcteUNoR1lVcnVRIiwiYXVkIjpbImJvb2tsb3JlIl0sImF1dGhfdGltZSI6MTc3MzM0NDc2MSwiYXpwIjoiYm9va2xvcmUiLCJlbWFpbCI6Im5pa2xhc0BudGFzbGVyLmRlIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImV4cCI6MTc3MzM0ODgwNSwiaWF0IjoxNzczMzQ1MjA1LCJpc3MiOiJodHRwczovL2F1dGgubnRhc2xlci5kZSIsImp0aSI6IjE2Njk2MjViLTg1ZDItNGFkZC1hNmZmLWE5ZDRkOWQyOGYwZCIsIm5hbWUiOiJOaWtsYXMiLCJub25jZSI6ImxsR1lBUjFrRGQwb01yWThJaHJTbUpEc0hFaV9udjg2S0NUaU1FSEdNQzAiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJuaWtsYXMiLCJzdWIiOiJiOWY1NWE5Yi04NjBiLTQ4ODYtYmEyYy00ZjI5MjdjMDdkNTEifQ.uczaoUydOiAg0wYVQUukmrQ-3FIPlfBgBPgIgwRc-ZVryqDOD1eAm4fpUr1oYF5ZbYGYFnmFHAELH6GuQZdx4q97onVNP1QSb0X-Szpr8srTW4ylU34VVT8zetHC1ysmC5tA7DJ0ZmvYlqwoDGQeYPCldUrIDx0kHQYg8hDUkgd-6nYb9xDRBLf6vNkIuYrrrjygitjQUJBwLGg-Cf3sYOhar6fCnUtXXk7VPSXRngZ6Uvg568CDji1yihgNApr1a2XT7XCjDgxejEu3wGgPsqMJSIZiJGbHflG59-jYoAMuOxV--PB6iN7AMWDTxobnwYk_jri4imWmMuxYq5qf3A','2026-03-12 18:53:26',NULL,0),
(4,1,'b9f55a9b-860b-4886-ba2c-4f2927c07d51','https://auth.ntasler.de',NULL,'eyJhbGciOiJSUzI1NiIsImtpZCI6IjAyNGEzYy1yczI1NiIsInR5cCI6IkpXVCJ9.eyJhbXIiOlsicHdkIiwia2JhIiwicG9wIiwic3drIiwidXNlciIsInBpbiIsIm1mYSJdLCJhdF9oYXNoIjoiOG92amJ1Zi1YYkI3X1FMRm42N2hpdyIsImF1ZCI6WyJncmltbW9yeSJdLCJhdXRoX3RpbWUiOjE3NzQxMTkzMDgsImF6cCI6ImdyaW1tb3J5IiwiZW1haWwiOiJuaWtsYXNAbnRhc2xlci5kZSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJleHAiOjE3NzQxMjM5NjEsImdyb3VwcyI6WyJhdWRpb2Jvb2tzaGVsZl9hZG1pbiIsImdhdHVzX3VzZXIiLCJncmFmYW5hX2FkbWluIiwiZ3JpbW1vcnlfdXNlciIsImltbWljaF9hZG1pbiIsImthbmVvX3VzZXIiLCJrYXJha2VlcF91c2VyIiwibGxkYXBfYWRtaW4iLCJub3Jpc2hfYWRtaW4iLCJvdXRsaW5lX3VzZXIiLCJwYXBlcmxlc3NfdXNlciIsInBhcHJhX3VzZXIiLCJxdWlfdXNlciIsInZhdWx0d2FyZGVuX3VzZXIiLCJ3YWxsb3NfdXNlciJdLCJpYXQiOjE3NzQxMjAzNjEsImlzcyI6Imh0dHBzOi8vYXV0aC5udGFzbGVyLmRlIiwianRpIjoiZjRkMzk0ZWEtNjgzOS00YWFjLWE4MGMtOTNjMTE3ZjNlNDVkIiwibmFtZSI6Ik5pa2xhcyIsIm5vbmNlIjoiQWRMUUxPWXdXYkJvajFCT3V1U0pnVWk2S2R1bTBraHZsQy11MzFtanBTcyIsInByZWZlcnJlZF91c2VybmFtZSI6Im5pa2xhcyIsInN1YiI6ImI5ZjU1YTliLTg2MGItNDg4Ni1iYTJjLTRmMjkyN2MwN2Q1MSJ9.necLES5k-AZYkGBEyv0lU7ADGmXU8JikbO5iqik5cTRMuaZdzWxSCanIIk_7Y-FkXJ1VD7a9XMAw_pbHWL8AKWisqRT2-SMX-2fpJeXDzlgVZEhrDQLfgpejCGXgff61pFuO6DAVk6RYhI536_SifGhnX-Tzp6qOEP_6IpOJyK2TDvlVhhIbRUuInC8bHOjvd_AZLUuDybdSAzf67g_ShsTKTqUJl4K4UrL7W4PBi3ye--FFpMLvKVJ-NIuNi24DwIozDhkW9f_230B8E1bN_GM57RoD9nqmoFmnwEuoqxyHpDjOJwAUeNh1Mm4MINmxuRpPXCiW9LRAfxDunSbtOg','2026-03-21 18:12:42',NULL,0);
/*!40000 ALTER TABLE `oidc_session` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `opds_user`
--

DROP TABLE IF EXISTS `opds_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `opds_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opds_user`
--

LOCK TABLES `opds_user` WRITE;
/*!40000 ALTER TABLE `opds_user` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `opds_user` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `opds_user_v2`
--

DROP TABLE IF EXISTS `opds_user_v2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `opds_user_v2` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sort_order` varchar(20) NOT NULL DEFAULT 'RECENT',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_username` (`username`),
  KEY `fk_opds_user` (`user_id`),
  CONSTRAINT `fk_opds_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opds_user_v2`
--

LOCK TABLES `opds_user_v2` WRITE;
/*!40000 ALTER TABLE `opds_user_v2` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `opds_user_v2` VALUES
(1,1,'koreader','$2a$10$s814Dkz3kopHIdOTZy7/jephmgah3xRK88pR2G4OufR3G83hZTkdG','2026-02-07 09:32:48','2026-02-07 09:32:48','RECENT');
/*!40000 ALTER TABLE `opds_user_v2` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pdf_annotations`
--

DROP TABLE IF EXISTS `pdf_annotations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pdf_annotations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `data` longtext NOT NULL,
  `version` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`),
  KEY `idx_pdf_annotations_user_id` (`user_id`),
  KEY `idx_pdf_annotations_book_id` (`book_id`),
  CONSTRAINT `fk_pdf_annotations_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pdf_annotations_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pdf_annotations`
--

LOCK TABLES `pdf_annotations` WRITE;
/*!40000 ALTER TABLE `pdf_annotations` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pdf_annotations` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pdf_viewer_preference`
--

DROP TABLE IF EXISTS `pdf_viewer_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pdf_viewer_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `zoom` varchar(64) DEFAULT NULL,
  `spread` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`book_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pdf_viewer_preference`
--

LOCK TABLES `pdf_viewer_preference` WRITE;
/*!40000 ALTER TABLE `pdf_viewer_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pdf_viewer_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `public_book_review`
--

DROP TABLE IF EXISTS `public_book_review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `public_book_review` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `metadata_provider` varchar(255) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `reviewer_name` varchar(512) DEFAULT NULL,
  `title` varchar(512) DEFAULT NULL,
  `rating` float DEFAULT NULL,
  `date` timestamp NULL DEFAULT NULL,
  `body` text DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `spoiler` tinyint(1) DEFAULT NULL,
  `followers_count` int(11) DEFAULT NULL,
  `text_reviews_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `public_book_review_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `book_metadata` (`book_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `public_book_review`
--

LOCK TABLES `public_book_review` WRITE;
/*!40000 ALTER TABLE `public_book_review` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `public_book_review` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `reading_sessions`
--

DROP TABLE IF EXISTS `reading_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reading_sessions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `book_type` varchar(10) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `duration_seconds` int(11) NOT NULL,
  `start_progress` float DEFAULT NULL,
  `end_progress` float DEFAULT NULL,
  `progress_delta` float DEFAULT NULL,
  `start_location` varchar(500) DEFAULT NULL,
  `end_location` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `duration_formatted` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_reading_session_user_time` (`user_id`,`start_time` DESC),
  KEY `idx_reading_session_book` (`book_id`,`start_time` DESC),
  KEY `idx_reading_session_user_book` (`user_id`,`book_id`,`start_time` DESC),
  CONSTRAINT `fk_reading_session_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reading_session_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reading_sessions`
--

LOCK TABLES `reading_sessions` WRITE;
/*!40000 ALTER TABLE `reading_sessions` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `reading_sessions` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `refresh_token`
--

DROP TABLE IF EXISTS `refresh_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_token` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `token` varchar(512) NOT NULL,
  `expiry_date` datetime(6) NOT NULL,
  `revoked` tinyint(1) NOT NULL DEFAULT 0,
  `revocation_date` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_refresh_token` (`token`),
  KEY `fk_refresh_token_user` (`user_id`),
  CONSTRAINT `fk_refresh_token_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_token`
--

LOCK TABLES `refresh_token` WRITE;
/*!40000 ALTER TABLE `refresh_token` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `refresh_token` VALUES
(1,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzY3MDM2NjQzLCJleHAiOjE3Njk2Mjg2NDN9.21hRarZIq7YFUwz9n4xwfx8Ct-Fxfjh8vqYzrtJNblE','2026-01-28 19:30:43.000000',1,'2026-03-12 19:46:45.623722'),
(2,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzY3MDQ1MzMwLCJleHAiOjE3Njk2MzczMzB9.qGPUurqk9uQzgeuy-0yRO5ZPQg1jcG5fnXeTYFevJhQ','2026-01-28 21:55:30.000000',1,'2026-03-12 19:46:45.629228'),
(3,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzY3MDQ1Njk4LCJleHAiOjE3Njk2Mzc2OTh9.l86I9Mwd3u6nhSN9q8ceSF9FgiMaHJ8DA0CoPr1ewxs','2026-01-28 22:01:38.000000',1,'2026-03-12 19:46:45.637630'),
(4,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzczMzQ0NzY0LCJleHAiOjE3NzU5MzY3NjR9.XVzKjCgKoiZh1zezIma_29YY9zjy6ufyPh5B5a4P7OU','2026-04-11 19:46:04.677692',1,'2026-03-12 19:46:45.643095'),
(5,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzczMzQ0ODEwLCJleHAiOjE3NzU5MzY4MTB9.4zRigUNnHASPt7FcTnXe7Y62jJHlwlsimFBtI7W7FNA','2026-04-11 19:46:50.508141',1,'2026-03-12 19:49:55.484575'),
(6,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzczMzQ0OTk4LCJleHAiOjE3NzU5MzY5OTh9.2wpoKxoG6uoDtLfzjIlJWNtLe8w3R6xbJe-IokdT9As','2026-04-11 19:49:58.559893',0,NULL),
(7,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzczMzQ1MjA2LCJleHAiOjE3NzU5MzcyMDZ9.bQjhEMr31IJ_jQa6KL-fTCtFItQ4Lq3vgZFxWry9wQw','2026-04-11 19:53:26.063338',0,NULL),
(8,1,'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuaWtsYXMiLCJ1c2VySWQiOjEsImlzRGVmYXVsdFBhc3N3b3JkIjpmYWxzZSwiaWF0IjoxNzc0MTIwMzYyLCJleHAiOjE3NzY3MTIzNjJ9.5NA_mp6vFkivrOj46zJUV_N1rVybcaK8aeYs_IXt7w8','2026-04-20 19:12:42.223737',0,NULL);
/*!40000 ALTER TABLE `refresh_token` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `shelf`
--

DROP TABLE IF EXISTS `shelf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `shelf` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `sort` varchar(255) DEFAULT NULL,
  `icon` varchar(64) DEFAULT NULL,
  `icon_type` varchar(255) DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`name`),
  CONSTRAINT `fk_shelf_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shelf`
--

LOCK TABLES `shelf` WRITE;
/*!40000 ALTER TABLE `shelf` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `shelf` VALUES
(1,1,'Favorites',NULL,'heart','PRIME_NG',0);
/*!40000 ALTER TABLE `shelf` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `tag`
--

DROP TABLE IF EXISTS `tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tag`
--

LOCK TABLES `tag` WRITE;
/*!40000 ALTER TABLE `tag` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `tag` VALUES
(6,'A Mix Driven'),
(11,'Audiobook'),
(12,'Borrowed'),
(3,'Character Driven'),
(7,'Diverse Characters'),
(5,'Loveable Characters'),
(2,'Not Diverse Characters'),
(4,'Plot Driven'),
(1,'Space'),
(8,'Strong Character Development'),
(10,'Unloveable Characters'),
(9,'Weak Character Development');
/*!40000 ALTER TABLE `tag` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `task_cron_configuration`
--

DROP TABLE IF EXISTS `task_cron_configuration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_cron_configuration` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_type` varchar(100) NOT NULL,
  `cron_expression` varchar(100) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` bigint(20) NOT NULL DEFAULT -1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_task_type` (`task_type`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_cron_configuration`
--

LOCK TABLES `task_cron_configuration` WRITE;
/*!40000 ALTER TABLE `task_cron_configuration` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `task_cron_configuration` VALUES
(3,'CLEANUP_DELETED_BOOKS','0 40 0 * * 1',1,-1,'2025-12-29 18:44:49','2025-12-29 18:44:49'),
(4,'CLEANUP_TEMP_METADATA','0 45 0 * * 1',1,-1,'2025-12-29 18:44:49','2025-12-29 18:44:49'),
(5,'SYNC_LIBRARY_FILES','0 0 1 * * *',1,-1,'2025-12-29 18:44:49','2025-12-29 18:44:49'),
(6,'UPDATE_BOOK_RECOMMENDATIONS','0 30 1 * * *',1,-1,'2025-12-29 18:44:49','2025-12-29 18:44:49'),
(7,'BOOKDROP_PERIODIC_SCANNING','0 */10 * * * *',0,-1,'2026-02-28 11:45:47','2026-02-28 11:45:47');
/*!40000 ALTER TABLE `task_cron_configuration` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tasks` (
  `id` varchar(36) NOT NULL,
  `type` varchar(50) NOT NULL,
  `status` varchar(50) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `progress_percentage` int(11) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `errorDetails` text DEFAULT NULL,
  `task_options` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tasks_user_id` (`user_id`),
  KEY `idx_tasks_type` (`type`),
  KEY `idx_tasks_status` (`status`),
  KEY `idx_tasks_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `tasks` VALUES
('0073389b-eab4-4471-8e1b-e30c02a10cd3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-21 01:30:00','2026-01-21 01:30:00','2026-01-21 01:30:00',100,'Task completed successfully',NULL,'{}'),
('02befe51-6121-404a-9ea5-be1f4b878fde','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-19 01:00:00','2026-02-19 01:00:00','2026-02-19 01:00:00',100,'Task completed successfully',NULL,'{}'),
('04351c6f-6210-43b9-9b27-271f392547ae','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-01 01:30:00','2026-01-01 01:30:00','2026-01-01 01:30:00',100,'Task completed successfully',NULL,'{}'),
('06db7c0c-9a24-4166-ade5-a4cb9751034d','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-18 00:30:00','2026-03-18 00:30:00','2026-03-18 00:30:00',100,'Task completed successfully',NULL,'{}'),
('08b60191-b72d-4b8f-920b-12fd5824ee1c','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-02-16 00:45:00','2026-02-16 00:45:00','2026-02-16 00:45:00',100,'Task completed successfully',NULL,'{}'),
('08d9e3b2-f723-44d2-ad08-26094a3ddab3','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-01 01:00:00','2026-03-01 01:00:00','2026-03-01 01:00:00',100,'Task completed successfully',NULL,'{}'),
('0b900318-60e7-416f-a4b5-1d03bd300af0','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-13 01:30:00','2026-01-13 01:30:00','2026-01-13 01:30:00',100,'Task completed successfully',NULL,'{}'),
('0d6011f8-3398-4f8b-b41e-bea8a25ca505','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-03-05 16:50:31','2026-03-05 16:50:31','2026-03-05 16:50:31',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[11],\"refreshOptions\":null}'),
('0dc41d92-846b-4798-a2db-3d242dc560a1','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-09 01:30:00','2026-02-09 01:30:00','2026-02-09 01:30:00',100,'Task completed successfully',NULL,'{}'),
('0e19e4f1-dcd0-4aad-a6c4-34b5d594a53e','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-09 01:00:00','2026-02-09 01:00:00','2026-02-09 01:00:00',100,'Task completed successfully',NULL,'{}'),
('10f72f65-20da-4cee-9a83-0c3f6a5903ea','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-26 01:30:00','2026-02-26 01:30:00','2026-02-26 01:30:00',100,'Task completed successfully',NULL,'{}'),
('12535a3c-9667-460c-bc93-ac7380badd8f','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-16 00:00:00','2026-03-16 00:00:00','2026-03-16 00:00:00',100,'Task completed successfully',NULL,'{}'),
('14390e61-a2b2-40e7-b388-cdca2bbf842a','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-29 01:30:00','2026-01-29 01:30:00','2026-01-29 01:30:00',100,'Task completed successfully',NULL,'{}'),
('1521507a-5e6f-40a9-a8a4-3f8d0605fa14','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-03-02 00:45:00','2026-03-02 00:45:00','2026-03-02 00:45:00',100,'Task completed successfully',NULL,'{}'),
('15cc04d6-c19d-486f-ab8c-0377e6b25930','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-02-23 00:45:00','2026-02-23 00:45:00','2026-02-23 00:45:00',100,'Task completed successfully',NULL,'{}'),
('17aff69d-3cf2-43ba-a2f8-c2a39a62b234','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-10 01:00:00','2026-02-10 01:00:00','2026-02-10 01:00:00',100,'Task completed successfully',NULL,'{}'),
('19fdb1aa-4a97-4d83-a879-873eebc95054','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2025-12-31 01:30:00','2025-12-31 01:30:00','2025-12-31 01:30:00',100,'Task completed successfully',NULL,'{}'),
('1ba72549-94c3-4599-bc4c-257599ed35fe','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-19 00:30:00','2026-03-19 00:30:00','2026-03-19 00:30:00',100,'Task completed successfully',NULL,'{}'),
('1bffcfc5-ec54-465f-89ac-4b78aef44e6d','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-26 01:00:00','2026-02-26 01:00:00','2026-02-26 01:00:00',100,'Task completed successfully',NULL,'{}'),
('1ee62a66-d501-4f72-9e27-4b4c64d5e9cf','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-02-03 19:50:59','2026-02-03 19:50:59','2026-02-03 19:50:59',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[3],\"refreshOptions\":null}'),
('2046231c-caa5-4d72-9fd1-08cda216a6b3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-15 01:30:00','2026-02-15 01:30:00','2026-02-15 01:30:00',100,'Task completed successfully',NULL,'{}'),
('21d94c5c-4cb0-48e2-a681-59d8b67ab281','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-02 01:30:00','2026-02-02 01:30:00','2026-02-02 01:30:00',100,'Task completed successfully',NULL,'{}'),
('22ac0c24-4787-43a8-adfe-58c25d691d55','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-18 00:00:00','2026-03-18 00:00:00','2026-03-18 00:00:00',100,'Task completed successfully',NULL,'{}'),
('2479b087-828a-45cd-9926-4564a268c63c','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-10 01:30:00','2026-03-10 01:30:00','2026-03-10 01:30:00',100,'Task completed successfully',NULL,'{}'),
('26d4d057-cb60-489f-9bea-359c82ac33c7','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-19 01:30:00','2026-02-19 01:30:00','2026-02-19 01:30:00',100,'Task completed successfully',NULL,'{}'),
('283fbfd0-dace-43ad-bd8f-392f5893bbb1','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-02-09 00:45:00','2026-02-09 00:45:00','2026-02-09 00:45:00',100,'Task completed successfully',NULL,'{}'),
('2916a3c5-d538-4f89-b034-c83d5d80a30b','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-03-15 23:45:00','2026-03-15 23:45:00','2026-03-15 23:45:00',100,'Task completed successfully',NULL,'{}'),
('29a00e57-a4ea-4d49-8b75-5ef95768d71b','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-07 01:30:00','2026-01-07 01:30:00','2026-01-07 01:30:00',100,'Task completed successfully',NULL,'{}'),
('29c2de38-1bfc-4e8d-806c-3b657272c547','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-06 01:30:00','2026-02-06 01:30:00','2026-02-06 01:30:00',100,'Task completed successfully',NULL,'{}'),
('2a8437d6-a034-4172-bf8b-795383f045d6','REFRESH_METADATA_MANUAL','COMPLETED',1,'2025-12-31 17:23:46','2025-12-31 17:23:52','2025-12-31 17:23:52',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[1],\"refreshOptions\":{\"libraryId\":null,\"refreshCovers\":false,\"mergeCategories\":true,\"reviewBeforeApply\":false,\"fieldOptions\":{\"title\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"subtitle\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"description\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"authors\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"publisher\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"publishedDate\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"seriesName\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"seriesNumber\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"seriesTotal\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"isbn13\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"isbn10\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"language\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"categories\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"cover\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"pageCount\":{\"p1\":\"Amazon\",\"p2\":\"Google\",\"p3\":\"GoodReads\",\"p4\":\"Hardcover\"},\"asin\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"comicvineId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"googleId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"moods\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"tags\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null}},\"enabledFields\":{\"title\":true,\"subtitle\":true,\"description\":true,\"authors\":true,\"publisher\":true,\"publishedDate\":true,\"seriesName\":true,\"seriesNumber\":true,\"seriesTotal\":true,\"isbn13\":true,\"isbn10\":true,\"language\":true,\"categories\":true,\"cover\":true,\"pageCount\":true,\"asin\":true,\"goodreadsId\":true,\"comicvineId\":true,\"hardcoverId\":true,\"googleId\":true,\"amazonRating\":true,\"amazonReviewCount\":true,\"goodreadsRating\":true,\"goodreadsReviewCount\":true,\"hardcoverRating\":true,\"hardcoverReviewCount\":true,\"moods\":true,\"tags\":true}}}'),
('2a998585-720a-413a-bc0f-ba6d41932481','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-26 01:00:00','2026-01-26 01:00:00','2026-01-26 01:00:00',100,'Task completed successfully',NULL,'{}'),
('2b46f102-1267-4348-8b98-6a89ec4dccc3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-03 01:30:00','2026-02-03 01:30:00','2026-02-03 01:30:00',100,'Task completed successfully',NULL,'{}'),
('2b77b25f-135a-4d90-967f-7e9675bbc1c3','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-11 01:00:00','2026-03-11 01:00:00','2026-03-11 01:00:00',100,'Task completed successfully',NULL,'{}'),
('2c081857-64f0-42d6-9a17-b964759bb906','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-14 01:30:00','2026-02-14 01:30:00','2026-02-14 01:30:00',100,'Task completed successfully',NULL,'{}'),
('2c399479-f3f8-47f6-b918-4c897b597a08','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-15 00:30:00','2026-03-15 00:30:00','2026-03-15 00:30:00',100,'Task completed successfully',NULL,'{}'),
('2d3ecb4e-2b59-4e00-8b33-4ead6e2b7224','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-20 01:30:00','2026-01-20 01:30:00','2026-01-20 01:30:00',100,'Task completed successfully',NULL,'{}'),
('2daddee5-81d5-4118-8be2-250553972e53','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-03-05 19:00:24','2026-03-05 19:02:38','2026-03-05 19:02:38',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20],\"refreshOptions\":{\"libraryId\":null,\"refreshCovers\":false,\"mergeCategories\":true,\"reviewBeforeApply\":false,\"replaceMode\":\"REPLACE_MISSING\",\"fieldOptions\":{\"title\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"subtitle\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"description\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"authors\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"publisher\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"publishedDate\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"seriesName\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"seriesNumber\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"seriesTotal\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"isbn13\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"isbn10\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"language\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"categories\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"cover\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"pageCount\":{\"p1\":\"Hardcover\",\"p2\":\"GoodReads\",\"p3\":\"Amazon\",\"p4\":\"Google\"},\"asin\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"comicvineId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"googleId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"lubimyczytacId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"lubimyczytacRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"ranobedbId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"ranobedbRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"moods\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"tags\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null}},\"enabledFields\":{\"title\":true,\"subtitle\":true,\"description\":true,\"authors\":true,\"publisher\":true,\"publishedDate\":true,\"seriesName\":true,\"seriesNumber\":true,\"seriesTotal\":true,\"isbn13\":true,\"isbn10\":true,\"language\":true,\"categories\":true,\"cover\":true,\"pageCount\":true,\"asin\":true,\"goodreadsId\":true,\"comicvineId\":true,\"hardcoverId\":true,\"googleId\":true,\"lubimyczytacId\":false,\"amazonRating\":true,\"amazonReviewCount\":true,\"goodreadsRating\":true,\"goodreadsReviewCount\":true,\"hardcoverRating\":true,\"hardcoverReviewCount\":true,\"lubimyczytacRating\":false,\"ranobedbId\":false,\"ranobedbRating\":false,\"moods\":true,\"tags\":true}}}'),
('2e5b7a56-bd4d-4007-a49a-889759119290','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-23 01:00:00','2026-01-23 01:00:00','2026-01-23 01:00:00',100,'Task completed successfully',NULL,'{}'),
('2e8fbfbe-7131-41f5-ab9e-44d5d1eb42cf','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-03-09 00:40:00','2026-03-09 00:40:00','2026-03-09 00:40:00',100,'Task completed successfully',NULL,'{}'),
('2f2d8560-1c5a-4004-a565-5c838f98a4cc','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-04 01:30:00','2026-01-04 01:30:00','2026-01-04 01:30:00',100,'Task completed successfully',NULL,'{}'),
('2fff1107-550c-402d-8348-fc92ff5cb09a','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-15 01:00:00','2026-02-15 01:00:00','2026-02-15 01:00:00',100,'Task completed successfully',NULL,'{}'),
('310a687a-62bb-431e-aa02-58a04e609ed5','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-12 01:30:00','2026-03-12 01:30:00','2026-03-12 01:30:00',100,'Task completed successfully',NULL,'{}'),
('31ced36c-258f-4105-8a75-bfd70ad112d3','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-19 00:00:00','2026-03-19 00:00:00','2026-03-19 00:00:00',100,'Task completed successfully',NULL,'{}'),
('3436a80d-0dc8-41fc-8686-4a7fc2d12f86','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-03 01:00:00','2026-02-03 01:00:00','2026-02-03 01:00:00',100,'Task completed successfully',NULL,'{}'),
('381ba34c-2a14-4d37-9765-845caeb75b74','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-03 01:00:00','2026-01-03 01:00:00','2026-01-03 01:00:00',100,'Task completed successfully',NULL,'{}'),
('3ba94c21-aae5-48d1-9d0e-8043b6d3d44c','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-20 00:00:00','2026-03-20 00:00:00','2026-03-20 00:00:00',100,'Task completed successfully',NULL,'{}'),
('3dcf47e1-3a9a-45c1-a4da-0cab4506a253','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-11 01:00:00','2026-01-11 01:00:00','2026-01-11 01:00:00',100,'Task completed successfully',NULL,'{}'),
('3f19de1f-9f3f-43eb-8761-e54a5be28340','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-22 01:00:00','2026-01-22 01:00:00','2026-01-22 01:00:00',100,'Task completed successfully',NULL,'{}'),
('3fe7edf4-c8ba-406e-8d00-763750621d47','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-25 01:00:00','2026-01-25 01:00:00','2026-01-25 01:00:00',100,'Task completed successfully',NULL,'{}'),
('4087cc67-bdf5-4afe-bb76-455550b37e4f','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-23 01:30:00','2026-02-23 01:30:00','2026-02-23 01:30:00',100,'Task completed successfully',NULL,'{}'),
('463d7f5e-5e95-4142-8e5d-35d675e031bb','SYNC_LIBRARY_FILES','COMPLETED',-1,'2025-12-31 01:00:00','2025-12-31 01:00:00','2025-12-31 01:00:00',100,'Task completed successfully',NULL,'{}'),
('465c45d4-b937-4d98-bccb-a600723c1075','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-01-19 00:45:00','2026-01-19 00:45:00','2026-01-19 00:45:00',100,'Task completed successfully',NULL,'{}'),
('474fa414-2b86-42e3-91fc-641fd7b2d45b','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-22 01:30:00','2026-02-22 01:30:00','2026-02-22 01:30:00',100,'Task completed successfully',NULL,'{}'),
('479f67ad-c00c-40ac-b170-3d8dfb0eaa33','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-05 01:30:00','2026-01-05 01:30:00','2026-01-05 01:30:00',100,'Task completed successfully',NULL,'{}'),
('4a1fa6c1-cf07-4fa5-b625-b98f869ae798','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-20 01:00:00','2026-01-20 01:00:00','2026-01-20 01:00:00',100,'Task completed successfully',NULL,'{}'),
('4b01216f-f2ef-40fa-b5d3-7be8ea28fc6c','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-03-15 23:40:00','2026-03-15 23:40:00','2026-03-15 23:40:00',100,'Task completed successfully',NULL,'{}'),
('4b18edaf-2330-4a6c-8488-d12b8cadfefe','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-18 01:30:00','2026-02-18 01:30:00','2026-02-18 01:30:00',100,'Task completed successfully',NULL,'{}'),
('4ba3ada7-1a9c-445d-99cb-19658b78d362','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-28 01:00:00','2026-02-28 01:00:00','2026-02-28 01:00:00',100,'Task completed successfully',NULL,'{}'),
('4c3dc813-5868-4e50-a39e-fd28b317e5c8','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-19 01:00:00','2026-01-19 01:00:00','2026-01-19 01:00:00',100,'Task completed successfully',NULL,'{}'),
('4d0f8975-df3c-42c2-ad19-d1d3bdfd6639','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-09 01:00:00','2026-01-09 01:00:00','2026-01-09 01:00:00',100,'Task completed successfully',NULL,'{}'),
('4f0f3624-29a9-4791-b625-334cfef87400','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-01-12 00:45:00','2026-01-12 00:45:00','2026-01-12 00:45:00',100,'Task completed successfully',NULL,'{}'),
('517cd3a7-86e6-4d85-9d3b-ea7504400e61','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-21 01:00:00','2026-01-21 01:00:00','2026-01-21 01:00:00',100,'Task completed successfully',NULL,'{}'),
('5245fa31-956c-476a-bf7a-5e6298b31216','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-25 01:30:00','2026-01-25 01:30:00','2026-01-25 01:30:00',100,'Task completed successfully',NULL,'{}'),
('52d52c5b-e2e2-418b-a36a-fd6b9fae8f05','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-10 01:00:00','2026-01-10 01:00:00','2026-01-10 01:00:00',100,'Task completed successfully',NULL,'{}'),
('54380871-2708-4294-830b-2a58326794a0','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-14 01:00:00','2026-01-14 01:00:00','2026-01-14 01:00:00',100,'Task completed successfully',NULL,'{}'),
('54a73aca-894e-439e-ae06-3691641f0308','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-01-05 00:40:00','2026-01-05 00:40:00','2026-01-05 00:40:00',100,'Task completed successfully',NULL,'{}'),
('54eebbf8-5c70-4f48-b8f2-6ef0b6bc832f','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-29 01:00:00','2026-01-29 01:00:00','2026-01-29 01:00:00',100,'Task completed successfully',NULL,'{}'),
('551c3b0e-24b0-4361-9172-689af1794de5','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-04 01:30:00','2026-03-04 01:30:00','2026-03-04 01:30:00',100,'Task completed successfully',NULL,'{}'),
('55b0ffaa-00bd-4920-9517-404837ebd8e4','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-18 01:00:00','2026-02-18 01:00:00','2026-02-18 01:00:00',100,'Task completed successfully',NULL,'{}'),
('56aff7ed-adf4-4c63-bfd7-309341eda948','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-03 01:30:00','2026-03-03 01:30:00','2026-03-03 01:30:00',100,'Task completed successfully',NULL,'{}'),
('58ebd0ce-8ca1-48cd-a25a-af44279ed42f','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-08 01:00:00','2026-01-08 01:00:00','2026-01-08 01:00:00',100,'Task completed successfully',NULL,'{}'),
('5a0b696c-427a-4f2f-a8cd-767b72e9c2fa','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-16 00:30:00','2026-03-16 00:30:00','2026-03-16 00:30:00',100,'Task completed successfully',NULL,'{}'),
('5a5a7062-1cd9-482b-96c3-4672666ad358','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-13 00:30:00','2026-03-13 00:30:00','2026-03-13 00:30:00',100,'Task completed successfully',NULL,'{}'),
('5be26bec-1187-4c16-b3cd-5f998b1bf39c','REFRESH_METADATA_MANUAL','COMPLETED',1,'2025-12-31 17:26:27','2025-12-31 17:26:28','2025-12-31 17:26:28',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[1],\"refreshOptions\":{\"libraryId\":null,\"refreshCovers\":false,\"mergeCategories\":true,\"reviewBeforeApply\":false,\"fieldOptions\":{\"title\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"subtitle\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"description\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"authors\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"publisher\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"publishedDate\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"seriesName\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"seriesNumber\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"seriesTotal\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"isbn13\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"isbn10\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"language\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"categories\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"cover\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"pageCount\":{\"p1\":\"Amazon\",\"p2\":null,\"p3\":null,\"p4\":null},\"asin\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"comicvineId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"googleId\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"amazonReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"goodreadsReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverRating\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"hardcoverReviewCount\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"moods\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null},\"tags\":{\"p1\":null,\"p2\":null,\"p3\":null,\"p4\":null}},\"enabledFields\":{\"title\":true,\"subtitle\":true,\"description\":true,\"authors\":true,\"publisher\":true,\"publishedDate\":true,\"seriesName\":true,\"seriesNumber\":true,\"seriesTotal\":true,\"isbn13\":true,\"isbn10\":true,\"language\":true,\"categories\":true,\"cover\":true,\"pageCount\":true,\"asin\":true,\"goodreadsId\":true,\"comicvineId\":true,\"hardcoverId\":true,\"googleId\":true,\"amazonRating\":true,\"amazonReviewCount\":true,\"goodreadsRating\":true,\"goodreadsReviewCount\":true,\"hardcoverRating\":true,\"hardcoverReviewCount\":true,\"moods\":true,\"tags\":true}}}'),
('5d340fd3-b8b9-4703-9bb6-85fb5c7bdaf4','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-12 01:00:00','2026-03-12 01:00:00','2026-03-12 01:00:00',100,'Task completed successfully',NULL,'{}'),
('5f5fefd8-e6bd-44e0-9c33-b5488d5748c3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-06 01:30:00','2026-03-06 01:30:00','2026-03-06 01:30:00',100,'Task completed successfully',NULL,'{}'),
('6699add9-2c2a-42f7-a5ca-959f89eea55f','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-17 01:30:00','2026-02-17 01:30:00','2026-02-17 01:30:00',100,'Task completed successfully',NULL,'{}'),
('66b3e820-d2f4-4d7d-b66d-0cecc2fedbac','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-30 01:00:00','2026-01-30 01:00:00','2026-01-30 01:00:00',100,'Task completed successfully',NULL,'{}'),
('68093a67-7b64-43de-894f-35071595be7a','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-02 01:30:00','2026-01-02 01:30:00','2026-01-02 01:30:00',100,'Task completed successfully',NULL,'{}'),
('69ee4093-5f58-413e-9f5f-db32ce96fc26','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-10 01:30:00','2026-02-10 01:30:00','2026-02-10 01:30:00',100,'Task completed successfully',NULL,'{}'),
('6c964f5a-2858-4277-b099-34b254992512','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-12 01:00:00','2026-02-12 01:00:00','2026-02-12 01:00:00',100,'Task completed successfully',NULL,'{}'),
('6dabd29f-1fcf-498f-900b-a06e5a6a4ddb','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-27 01:30:00','2026-02-27 01:30:00','2026-02-27 01:30:00',100,'Task completed successfully',NULL,'{}'),
('6eb20e6a-c4e7-4676-bdba-01019aed0ac3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-28 01:30:00','2026-02-28 01:30:00','2026-02-28 01:30:00',100,'Task completed successfully',NULL,'{}'),
('6f4c839a-901e-4f75-b8e5-692bb7950879','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-21 01:00:00','2026-02-21 01:00:00','2026-02-21 01:00:00',100,'Task completed successfully',NULL,'{}'),
('6fac5585-9077-434f-adc9-442b9a4f0c20','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-03-02 00:40:00','2026-03-02 00:40:00','2026-03-02 00:40:00',100,'Task completed successfully',NULL,'{}'),
('6fc4a1cd-a1d3-4b38-b2ad-6e02dfea7074','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-13 01:00:00','2026-02-13 01:00:00','2026-02-13 01:00:00',100,'Task completed successfully',NULL,'{}'),
('704d3308-b681-449d-a31c-066d1cc38ded','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-14 01:30:00','2026-01-14 01:30:00','2026-01-14 01:30:00',100,'Task completed successfully',NULL,'{}'),
('726352a6-922e-4281-aeb7-b5ac066c29d3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-24 01:30:00','2026-01-24 01:30:00','2026-01-24 01:30:00',100,'Task completed successfully',NULL,'{}'),
('73217338-1ea6-4dc5-a292-018e68ca2200','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-02-03 19:51:54','2026-02-03 19:51:54','2026-02-03 19:51:54',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[3],\"refreshOptions\":null}'),
('73a78603-61ae-41b1-a14c-6f084dc66cc8','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-02 01:00:00','2026-03-02 01:00:00','2026-03-02 01:00:00',100,'Task completed successfully',NULL,'{}'),
('74f1b26e-c7e6-4f54-a317-11013e8db9b4','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-21 00:30:00','2026-03-21 00:30:00','2026-03-21 00:30:00',100,'Task completed successfully',NULL,'{}'),
('76f69d84-c569-48c3-8e0b-20a961ef0efe','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-05 01:00:00','2026-01-05 01:00:00','2026-01-05 01:00:00',100,'Task completed successfully',NULL,'{}'),
('7b6557a9-7e0a-4aa3-9e6a-e5d8c5ef06c5','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-10 01:00:00','2026-03-10 01:00:00','2026-03-10 01:00:00',100,'Task completed successfully',NULL,'{}'),
('7c2a3241-6c53-4eb3-ac59-93771f5bbb10','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-17 01:00:00','2026-01-17 01:00:00','2026-01-17 01:00:00',100,'Task completed successfully',NULL,'{}'),
('7cef18e2-f02f-4a7d-aa9e-f9832f4d9451','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-16 01:00:00','2026-01-16 01:00:00','2026-01-16 01:00:00',100,'Task completed successfully',NULL,'{}'),
('7eb9c5f7-c7ab-4bef-8268-e921f7002f0c','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-13 00:00:00','2026-03-13 00:00:00','2026-03-13 00:00:00',100,'Task completed successfully',NULL,'{}'),
('7ecc63c9-aed9-42a6-8b57-4a5b43ec2246','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-07 01:00:00','2026-02-07 01:00:00','2026-02-07 01:00:00',100,'Task completed successfully',NULL,'{}'),
('847ed72c-7f11-4eb2-8d1f-81b993ac3419','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-01 01:00:00','2026-01-01 01:00:00','2026-01-01 01:00:00',100,'Task completed successfully',NULL,'{}'),
('851f567f-2e0a-4b5a-a1e6-ea3ef5d82119','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-27 01:00:00','2026-02-27 01:00:00','2026-02-27 01:00:00',100,'Task completed successfully',NULL,'{}'),
('88252f20-577e-46ef-9f7d-5ba698908bca','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-06 01:00:00','2026-02-06 01:00:00','2026-02-06 01:00:00',100,'Task completed successfully',NULL,'{}'),
('88e0191f-bb12-48e3-beec-6501f5150739','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-31 01:30:00','2026-01-31 01:30:00','2026-01-31 01:30:00',100,'Task completed successfully',NULL,'{}'),
('8baf6706-0c88-43b3-ace4-ce1ff9eed9d8','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-23 01:30:00','2026-01-23 01:30:00','2026-01-23 01:30:00',100,'Task completed successfully',NULL,'{}'),
('8d222e41-4312-4f3b-a413-8178a8e3dfa3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-09 01:30:00','2026-01-09 01:30:00','2026-01-09 01:30:00',100,'Task completed successfully',NULL,'{}'),
('8f580fb1-6a8b-426d-b1ca-7060d8b8c505','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-03 01:30:00','2026-01-03 01:30:00','2026-01-03 01:30:00',100,'Task completed successfully',NULL,'{}'),
('90f53745-fb2c-4cca-bf58-a259c9a1bfc7','SYNC_LIBRARY_FILES','COMPLETED',-1,'2025-12-30 01:00:00','2025-12-30 01:00:00','2025-12-30 01:00:00',100,'Task completed successfully',NULL,'{}'),
('91fa6a56-10e4-473e-896d-686473ba839d','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-07 01:30:00','2026-03-07 01:30:00','2026-03-07 01:30:00',100,'Task completed successfully',NULL,'{}'),
('938dbcb6-dcb2-4f73-956a-74622eacf2c2','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-16 01:30:00','2026-01-16 01:30:00','2026-01-16 01:30:00',100,'Task completed successfully',NULL,'{}'),
('97a59f97-5571-4bdb-90da-1ca6e4dcf65a','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-15 00:00:00','2026-03-15 00:00:00','2026-03-15 00:00:00',100,'Task completed successfully',NULL,'{}'),
('9820a6df-fa3b-4616-a81f-df19cf98476f','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-08 01:00:00','2026-02-08 01:00:00','2026-02-08 01:00:00',100,'Task completed successfully',NULL,'{}'),
('9b537451-0079-4beb-9a3e-3b63bb8fd723','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-20 01:30:00','2026-02-20 01:30:00','2026-02-20 01:30:00',100,'Task completed successfully',NULL,'{}'),
('a0fe574b-e278-473d-85e2-3e8b9ffb3bfa','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-03 01:00:00','2026-03-03 01:00:00','2026-03-03 01:00:00',100,'Task completed successfully',NULL,'{}'),
('a101fbd6-a887-410c-980c-d71df086f6ae','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-12 01:30:00','2026-01-12 01:30:00','2026-01-12 01:30:00',100,'Task completed successfully',NULL,'{}'),
('a1684535-b52c-4df6-9780-af1e08ce6a5d','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-22 01:30:00','2026-01-22 01:30:00','2026-01-22 01:30:00',100,'Task completed successfully',NULL,'{}'),
('a1b2e4f9-6730-478b-bb9a-4742e56ec545','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-21 00:00:00','2026-03-21 00:00:00','2026-03-21 00:00:00',100,'Task completed successfully',NULL,'{}'),
('a32fcb6c-1184-41c8-9c11-6563afb662ca','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-25 01:00:00','2026-02-25 01:00:00','2026-02-25 01:00:00',100,'Task completed successfully',NULL,'{}'),
('a36a5e26-8161-4d7b-97be-7a97dcf481f1','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-01-05 00:45:00','2026-01-05 00:45:00','2026-01-05 00:45:00',100,'Task completed successfully',NULL,'{}'),
('a4f8cbf3-10d7-43ef-a5a6-bbeefe101762','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-16 01:30:00','2026-02-16 01:30:00','2026-02-16 01:30:00',100,'Task completed successfully',NULL,'{}'),
('a53e05e6-e665-4d6b-bc3b-52ffd69585dd','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2025-12-30 01:30:00','2025-12-30 01:30:00','2025-12-30 01:30:00',100,'Task completed successfully',NULL,'{}'),
('a6da0285-658f-4390-8dcd-3b6eab0999df','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-20 00:30:00','2026-03-20 00:30:00','2026-03-20 00:30:00',100,'Task completed successfully',NULL,'{}'),
('a823f8ff-740f-4418-8c96-58480cec5536','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-17 01:00:00','2026-02-17 01:00:00','2026-02-17 01:00:00',100,'Task completed successfully',NULL,'{}'),
('a8337964-f026-45a7-8567-236746f73e1c','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-07 01:00:00','2026-03-07 01:00:00','2026-03-07 01:00:00',100,'Task completed successfully',NULL,'{}'),
('a94e0eb9-0344-4412-9a39-1d448c5abde7','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-11 01:00:00','2026-02-11 01:00:00','2026-02-11 01:00:00',100,'Task completed successfully',NULL,'{}'),
('a9e9c85b-065d-45e0-980b-0184bf696a82','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-14 00:30:00','2026-03-14 00:30:00','2026-03-14 00:30:00',100,'Task completed successfully',NULL,'{}'),
('ac414fb0-6128-4afc-9490-95fa7a16cd3a','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-03-09 00:45:00','2026-03-09 00:45:00','2026-03-09 00:45:00',100,'Task completed successfully',NULL,'{}'),
('ad1e61d7-f6d6-4836-bd0f-5f74877bed85','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-04 01:00:00','2026-03-04 01:00:00','2026-03-04 01:00:00',100,'Task completed successfully',NULL,'{}'),
('aed276d8-3672-4f05-a870-7bab09111b86','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-12 01:30:00','2026-02-12 01:30:00','2026-02-12 01:30:00',100,'Task completed successfully',NULL,'{}'),
('b2323b98-91a0-467e-b171-4a8df81bbb83','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-05 01:00:00','2026-03-05 01:00:00','2026-03-05 01:00:00',100,'Task completed successfully',NULL,'{}'),
('b382aef9-a93c-468f-8784-13e84f530faa','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-27 01:00:00','2026-01-27 01:00:00','2026-01-27 01:00:00',100,'Task completed successfully',NULL,'{}'),
('b4faab55-5d6b-4179-a8c4-a1d095fcbba4','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-04 01:30:00','2026-02-04 01:30:00','2026-02-04 01:30:00',100,'Task completed successfully',NULL,'{}'),
('b5032cb9-8aad-421b-92d3-252cfa6173ea','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-10 01:30:00','2026-01-10 01:30:00','2026-01-10 01:30:00',100,'Task completed successfully',NULL,'{}'),
('b6a53abc-2b03-4d9d-8b62-8619c5717146','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-01 01:00:00','2026-02-01 01:00:00','2026-02-01 01:00:00',100,'Task completed successfully',NULL,'{}'),
('b6bf6326-e7ef-47f5-83a0-64f02da8f5b5','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-08 01:30:00','2026-02-08 01:30:00','2026-02-08 01:30:00',100,'Task completed successfully',NULL,'{}'),
('b78b1325-d32e-4b3b-affd-3b49a9d28c41','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-02 01:00:00','2026-01-02 01:00:00','2026-01-02 01:00:00',100,'Task completed successfully',NULL,'{}'),
('b7cdb502-bc08-4e95-9b1d-d22b48e2b580','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-02-15 14:45:07','2026-02-15 14:45:08','2026-02-15 14:45:08',100,'Task completed successfully',NULL,'{\"refreshType\":\"LIBRARY\",\"libraryId\":1,\"bookIds\":null,\"refreshOptions\":null}'),
('bb0546e3-ff8d-43ea-9c87-13738719c293','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-26 01:30:00','2026-01-26 01:30:00','2026-01-26 01:30:00',100,'Task completed successfully',NULL,'{}'),
('bcffb4f2-f105-406c-ad70-6f7dd6755587','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-01-26 00:45:00','2026-01-26 00:45:00','2026-01-26 00:45:00',100,'Task completed successfully',NULL,'{}'),
('bdc64812-34f7-40a6-b74b-53e42f17b1f5','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-02-02 00:40:00','2026-02-02 00:40:00','2026-02-02 00:40:00',100,'Task completed successfully',NULL,'{}'),
('be0c8998-293f-42d9-ae0c-b6b23c65e162','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-01 01:30:00','2026-02-01 01:30:00','2026-02-01 01:30:00',100,'Task completed successfully',NULL,'{}'),
('be26e349-4668-4455-bef8-58805c350f09','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-30 01:30:00','2026-01-30 01:30:00','2026-01-30 01:30:00',100,'Task completed successfully',NULL,'{}'),
('c11fbe79-dde7-47b2-9be7-6679487d5239','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-01 01:30:00','2026-03-01 01:30:00','2026-03-01 01:30:00',100,'Task completed successfully',NULL,'{}'),
('c1dda40d-80ba-4e9e-bfad-9e9a1ad3a6ba','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-14 00:00:00','2026-03-14 00:00:00','2026-03-14 00:00:00',100,'Task completed successfully',NULL,'{}'),
('c21a0de0-4eee-4710-ab8f-6f32cb6277d0','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-01-19 00:40:00','2026-01-19 00:40:00','2026-01-19 00:40:00',100,'Task completed successfully',NULL,'{}'),
('c3e1393d-6fc5-45eb-b258-45f90c9c6b4b','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-24 01:00:00','2026-02-24 01:00:00','2026-02-24 01:00:00',100,'Task completed successfully',NULL,'{}'),
('c4f748c4-f845-4568-8979-42abcc945fd2','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-06 01:30:00','2026-01-06 01:30:00','2026-01-06 01:30:00',100,'Task completed successfully',NULL,'{}'),
('c526c771-2f95-45b6-a03c-bce3e2c91b21','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-24 01:00:00','2026-01-24 01:00:00','2026-01-24 01:00:00',100,'Task completed successfully',NULL,'{}'),
('c6735f67-cecb-47db-8d5f-486cb7e79b95','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-05 01:30:00','2026-02-05 01:30:00','2026-02-05 01:30:00',100,'Task completed successfully',NULL,'{}'),
('c7451817-eaaa-4ee7-9cec-2de0e3a0d0f2','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-12 01:00:00','2026-01-12 01:00:00','2026-01-12 01:00:00',100,'Task completed successfully',NULL,'{}'),
('cc5ffd7a-b32c-4b26-832e-5cfc3be2dfb5','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-02 01:00:00','2026-02-02 01:00:00','2026-02-02 01:00:00',100,'Task completed successfully',NULL,'{}'),
('d0734287-c400-478e-819a-43170868a45b','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-27 01:30:00','2026-01-27 01:30:00','2026-01-27 01:30:00',100,'Task completed successfully',NULL,'{}'),
('d1b324e5-ab80-43cf-9555-e9940d166d64','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-28 01:30:00','2026-01-28 01:30:00','2026-01-28 01:30:00',100,'Task completed successfully',NULL,'{}'),
('d3732571-f4d1-4f95-83de-0c31cad16fdc','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-08 01:30:00','2026-01-08 01:30:00','2026-01-08 01:30:00',100,'Task completed successfully',NULL,'{}'),
('d872537c-da89-400c-a57c-d36828c9b4d0','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-01-26 00:40:00','2026-01-26 00:40:00','2026-01-26 00:40:00',100,'Task completed successfully',NULL,'{}'),
('da3d53ea-248b-4f2b-b709-88e77a2ed0a6','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-05 01:30:00','2026-03-05 01:30:00','2026-03-05 01:30:00',100,'Task completed successfully',NULL,'{}'),
('dbc6288e-7330-4509-985b-9b9971cb198e','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-06 01:00:00','2026-03-06 01:00:00','2026-03-06 01:00:00',100,'Task completed successfully',NULL,'{}'),
('dbeec7dc-f4fc-4322-81e4-c0e7b252858a','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-31 01:00:00','2026-01-31 01:00:00','2026-01-31 01:00:00',100,'Task completed successfully',NULL,'{}'),
('dc1c13b0-09ca-4e6c-8e98-ad3764917227','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-17 01:30:00','2026-01-17 01:30:00','2026-01-17 01:30:00',100,'Task completed successfully',NULL,'{}'),
('de8cf0d5-73a6-4803-9bda-b790c174a54f','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-01-12 00:40:00','2026-01-12 00:40:00','2026-01-12 00:40:00',100,'Task completed successfully',NULL,'{}'),
('df3d918f-a625-4289-8b48-eabde0eba358','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-04 01:00:00','2026-01-04 01:00:00','2026-01-04 01:00:00',100,'Task completed successfully',NULL,'{}'),
('e0e2265a-529b-47b5-b692-a182cd260d55','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-22 01:00:00','2026-02-22 01:00:00','2026-02-22 01:00:00',100,'Task completed successfully',NULL,'{}'),
('e11df47e-a7d3-4928-8a4a-75c446db13a5','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-18 01:00:00','2026-01-18 01:00:00','2026-01-18 01:00:00',100,'Task completed successfully',NULL,'{}'),
('e1571465-89b9-4ef9-927b-2c6c272cee63','REFRESH_METADATA_MANUAL','COMPLETED',1,'2026-03-05 19:19:57','2026-03-05 19:20:02','2026-03-05 19:20:02',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[2],\"refreshOptions\":null}'),
('e2be84b0-2ddc-4570-89a4-94a60126f6d8','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-17 00:30:00','2026-03-17 00:30:00','2026-03-17 00:30:00',100,'Task completed successfully',NULL,'{}'),
('e406338d-21e7-41cb-91af-74fa22fb5315','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-09 01:30:00','2026-03-09 01:30:00','2026-03-09 01:30:00',100,'Task completed successfully',NULL,'{}'),
('e7b9e53a-7f3c-4865-88a7-ee428186ee22','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-08 01:00:00','2026-03-08 01:00:00','2026-03-08 01:00:00',100,'Task completed successfully',NULL,'{}'),
('e7c230d8-f2a5-4604-a5b6-2918fbeb7f31','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-07 01:30:00','2026-02-07 01:30:00','2026-02-07 01:30:00',100,'Task completed successfully',NULL,'{}'),
('e8c5ffa5-3dea-4ea5-ae97-6d7e550e1cde','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-15 01:30:00','2026-01-15 01:30:00','2026-01-15 01:30:00',100,'Task completed successfully',NULL,'{}'),
('e935a611-dff0-4bd2-a65e-89bce2067858','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-06 01:00:00','2026-01-06 01:00:00','2026-01-06 01:00:00',100,'Task completed successfully',NULL,'{}'),
('e948dd0d-6212-4b56-bf7a-19e8807284ac','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-16 01:00:00','2026-02-16 01:00:00','2026-02-16 01:00:00',100,'Task completed successfully',NULL,'{}'),
('ea4cc565-00cf-4a9c-a58e-059b0694104c','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-11 01:30:00','2026-02-11 01:30:00','2026-02-11 01:30:00',100,'Task completed successfully',NULL,'{}'),
('ebbbc5ec-a664-4a96-a6d6-5974ae6e4156','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-08 01:30:00','2026-03-08 01:30:00','2026-03-08 01:30:00',100,'Task completed successfully',NULL,'{}'),
('ebdd80b8-d419-4353-ab39-50051bcc660f','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-04 01:00:00','2026-02-04 01:00:00','2026-02-04 01:00:00',100,'Task completed successfully',NULL,'{}'),
('ebf27efb-2ccf-4e43-95e0-f81191f5831e','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-17 00:00:00','2026-03-17 00:00:00','2026-03-17 00:00:00',100,'Task completed successfully',NULL,'{}'),
('ecb65ef2-c3e8-4990-9c1d-7236a1c06058','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-02 01:30:00','2026-03-02 01:30:00','2026-03-02 01:30:00',100,'Task completed successfully',NULL,'{}'),
('ee010185-55ea-476a-b66b-4cbfb251ee62','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-18 01:30:00','2026-01-18 01:30:00','2026-01-18 01:30:00',100,'Task completed successfully',NULL,'{}'),
('ee839a1d-364c-47c6-aab1-cea71ea3a3a3','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-03-11 01:30:00','2026-03-11 01:30:00','2026-03-11 01:30:00',100,'Task completed successfully',NULL,'{}'),
('eec74672-d607-4c00-ac9f-b880d3dad190','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-20 01:00:00','2026-02-20 01:00:00','2026-02-20 01:00:00',100,'Task completed successfully',NULL,'{}'),
('ef22e2f7-9133-431d-a4b8-79ac348d78e4','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-19 01:30:00','2026-01-19 01:30:00','2026-01-19 01:30:00',100,'Task completed successfully',NULL,'{}'),
('effe77da-348a-4745-a275-dd355adfafb2','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-25 01:30:00','2026-02-25 01:30:00','2026-02-25 01:30:00',100,'Task completed successfully',NULL,'{}'),
('f0b59180-0d44-4df7-98b5-3948993d8d03','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-02-09 00:40:00','2026-02-09 00:40:00','2026-02-09 00:40:00',100,'Task completed successfully',NULL,'{}'),
('f0d6ce99-0b9a-41d5-afb5-b94f9127b893','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-02-23 00:40:00','2026-02-23 00:40:00','2026-02-23 00:40:00',100,'Task completed successfully',NULL,'{}'),
('f5daf484-a3b4-4da1-aeb3-555132b18644','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-23 01:00:00','2026-02-23 01:00:00','2026-02-23 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f6e56553-da0f-4d91-89c0-b294f8e1796e','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-03-09 01:00:00','2026-03-09 01:00:00','2026-03-09 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f708e7d0-7eab-430f-9eb6-b9717ecd98e4','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-13 01:00:00','2026-01-13 01:00:00','2026-01-13 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f774aee4-25c3-4f80-a709-0feffaf605b6','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-24 01:30:00','2026-02-24 01:30:00','2026-02-24 01:30:00',100,'Task completed successfully',NULL,'{}'),
('f7d2a0e1-ad90-4b3c-8ecd-d812245584b7','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-15 01:00:00','2026-01-15 01:00:00','2026-01-15 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f8403ecd-b201-41dd-8e68-20b550a8a7c7','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-01-11 01:30:00','2026-01-11 01:30:00','2026-01-11 01:30:00',100,'Task completed successfully',NULL,'{}'),
('f868bfbc-fce2-4ab9-8ff5-a776925376a9','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-07 01:00:00','2026-01-07 01:00:00','2026-01-07 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f8f04a71-02c8-4c3c-9a39-4b52fbc0c386','CLEANUP_TEMP_METADATA','COMPLETED',-1,'2026-02-02 00:45:00','2026-02-02 00:45:00','2026-02-02 00:45:00',100,'Task completed successfully',NULL,'{}'),
('f927fcdd-e30e-4b5a-8677-cdbe5a2222c2','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-05 01:00:00','2026-02-05 01:00:00','2026-02-05 01:00:00',100,'Task completed successfully',NULL,'{}'),
('f9451e3f-44b7-4965-8f1e-e75bd4bdbb94','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-21 01:30:00','2026-02-21 01:30:00','2026-02-21 01:30:00',100,'Task completed successfully',NULL,'{}'),
('fb85a480-378f-43eb-be4e-4585ed3ad6cf','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-02-14 01:00:00','2026-02-14 01:00:00','2026-02-14 01:00:00',100,'Task completed successfully',NULL,'{}'),
('fbbba777-63b0-4160-88e8-78c766214f11','CLEANUP_DELETED_BOOKS','COMPLETED',-1,'2026-02-16 00:40:00','2026-02-16 00:40:00','2026-02-16 00:40:00',100,'Task completed successfully',NULL,'{}'),
('fcb319ab-b964-4b8a-a5f2-58e0963da979','SYNC_LIBRARY_FILES','COMPLETED',-1,'2026-01-28 01:00:00','2026-01-28 01:00:00','2026-01-28 01:00:00',100,'Task completed successfully',NULL,'{}'),
('fed24aad-f5da-4da9-844a-65fc867810fb','UPDATE_BOOK_RECOMMENDATIONS','COMPLETED',-1,'2026-02-13 01:30:00','2026-02-13 01:30:00','2026-02-13 01:30:00',100,'Task completed successfully',NULL,'{}'),
('ff04f862-35d8-4a21-9494-a7073c201312','REFRESH_METADATA_MANUAL','COMPLETED',1,'2025-12-31 17:23:16','2025-12-31 17:23:17','2025-12-31 17:23:17',100,'Task completed successfully',NULL,'{\"refreshType\":\"BOOKS\",\"libraryId\":null,\"bookIds\":[1],\"refreshOptions\":null}');
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_book_file_progress`
--

DROP TABLE IF EXISTS `user_book_file_progress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_book_file_progress` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_file_id` bigint(20) NOT NULL,
  `position_data` varchar(1000) DEFAULT NULL,
  `position_href` varchar(1000) DEFAULT NULL,
  `progress_percent` float DEFAULT NULL,
  `last_read_time` timestamp NULL DEFAULT NULL,
  `tts_position_cfi` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_book_file` (`user_id`,`book_file_id`),
  KEY `fk_ubfp_book_file` (`book_file_id`),
  KEY `idx_ubfp_user_book_file` (`user_id`,`book_file_id`),
  CONSTRAINT `fk_ubfp_book_file` FOREIGN KEY (`book_file_id`) REFERENCES `book_file` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ubfp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_book_file_progress`
--

LOCK TABLES `user_book_file_progress` WRITE;
/*!40000 ALTER TABLE `user_book_file_progress` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `user_book_file_progress` VALUES
(1,1,1,'epubcfi(/6/2!/4/2,,/2)',NULL,0.1,'2026-02-07 17:36:30',NULL),
(2,1,5,NULL,NULL,NULL,'2026-03-05 16:10:11',NULL),
(3,1,7,NULL,NULL,NULL,'2026-03-05 15:51:45',NULL),
(4,1,10,'epubcfi(/6/2!/4/2,,/2)','OEBPS/Simm_9780307781895_epub_cvi_r1.htm',0.0541495,'2026-03-05 14:49:18',NULL);
/*!40000 ALTER TABLE `user_book_file_progress` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_book_progress`
--

DROP TABLE IF EXISTS `user_book_progress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_book_progress` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `book_id` bigint(20) NOT NULL,
  `last_read_time` timestamp NULL DEFAULT NULL,
  `pdf_progress` int(11) DEFAULT NULL,
  `epub_progress` varchar(1000) DEFAULT NULL,
  `pdf_progress_percent` float DEFAULT NULL,
  `epub_progress_percent` float DEFAULT NULL,
  `cbx_progress` int(11) DEFAULT NULL,
  `cbx_progress_percent` float DEFAULT NULL,
  `read_status` varchar(20) DEFAULT NULL,
  `date_finished` timestamp NULL DEFAULT NULL,
  `koreader_progress` varchar(1000) DEFAULT NULL,
  `koreader_progress_percent` float DEFAULT NULL,
  `koreader_device` varchar(100) DEFAULT NULL,
  `koreader_device_id` varchar(100) DEFAULT NULL,
  `koreader_last_sync_time` timestamp NULL DEFAULT NULL,
  `kobo_progress_percent` float DEFAULT NULL,
  `kobo_location` varchar(1000) DEFAULT NULL,
  `kobo_location_type` varchar(50) DEFAULT NULL,
  `kobo_location_source` varchar(512) DEFAULT NULL,
  `kobo_progress_received_time` timestamp NULL DEFAULT NULL,
  `kobo_status_sent_time` timestamp NULL DEFAULT NULL,
  `read_status_modified_time` timestamp NULL DEFAULT NULL,
  `kobo_progress_sent_time` timestamp NULL DEFAULT NULL,
  `personal_rating` tinyint(4) DEFAULT NULL,
  `epub_progress_href` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_book_progress` (`user_id`,`book_id`),
  KEY `idx_user_book_progress_user` (`user_id`),
  KEY `idx_user_book_progress_book` (`book_id`),
  KEY `idx_user_book_progress_date_finished` (`date_finished`),
  CONSTRAINT `fk_user_book_progress_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_book_progress_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_book_progress`
--

LOCK TABLES `user_book_progress` WRITE;
/*!40000 ALTER TABLE `user_book_progress` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `user_book_progress` VALUES
(2,1,2,'2026-02-07 17:36:30',NULL,'epubcfi(/6/2!/4/2,,/2)',NULL,0.1,NULL,NULL,'UNREAD',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(3,1,8,'2026-03-05 15:51:45',NULL,NULL,NULL,NULL,NULL,NULL,'READ','2026-03-05 15:51:45','/body/DocFragment[86]/body/div/img.0',1,'Kobo_spaBW','766BD985D6F040268A84D069BA0036A6','2026-03-05 15:51:45',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(4,1,6,'2026-03-05 16:10:11',NULL,NULL,NULL,NULL,NULL,NULL,'READ','2026-03-05 16:10:11','/body/DocFragment[40]/body/a',0.9987,'Kobo_spaBW','766BD985D6F040268A84D069BA0036A6','2026-03-05 16:10:11',NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-05 16:09:01',NULL,NULL,NULL),
(5,1,11,'2026-03-05 14:49:18',NULL,'epubcfi(/6/2!/4/2,,/2)',NULL,0.0541495,NULL,NULL,'UNREAD',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'OEBPS/Simm_9780307781895_epub_cvi_r1.htm');
/*!40000 ALTER TABLE `user_book_progress` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_content_restriction`
--

DROP TABLE IF EXISTS `user_content_restriction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_content_restriction` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `restriction_type` varchar(20) NOT NULL,
  `mode` varchar(15) NOT NULL,
  `value` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_restriction` (`user_id`,`restriction_type`,`value`),
  KEY `idx_ucr_user_id` (`user_id`),
  CONSTRAINT `fk_ucr_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_content_restriction`
--

LOCK TABLES `user_content_restriction` WRITE;
/*!40000 ALTER TABLE `user_content_restriction` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `user_content_restriction` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_email_provider_preference`
--

DROP TABLE IF EXISTS `user_email_provider_preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_email_provider_preference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `default_provider_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_id` (`user_id`),
  KEY `fk_user_email_preference_provider` (`default_provider_id`),
  CONSTRAINT `fk_user_email_preference_provider` FOREIGN KEY (`default_provider_id`) REFERENCES `email_provider_v2` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_email_preference_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_email_provider_preference`
--

LOCK TABLES `user_email_provider_preference` WRITE;
/*!40000 ALTER TABLE `user_email_provider_preference` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `user_email_provider_preference` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_library_mapping`
--

DROP TABLE IF EXISTS `user_library_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_library_mapping` (
  `user_id` bigint(20) NOT NULL,
  `library_id` bigint(20) NOT NULL,
  PRIMARY KEY (`user_id`,`library_id`),
  KEY `fk_user_library_mapping_library` (`library_id`),
  CONSTRAINT `fk_user_library_mapping_library` FOREIGN KEY (`library_id`) REFERENCES `library` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_library_mapping_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_library_mapping`
--

LOCK TABLES `user_library_mapping` WRITE;
/*!40000 ALTER TABLE `user_library_mapping` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `user_library_mapping` VALUES
(1,1);
/*!40000 ALTER TABLE `user_library_mapping` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_permissions`
--

DROP TABLE IF EXISTS `user_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `permission_upload` tinyint(1) NOT NULL DEFAULT 0,
  `permission_download` tinyint(1) NOT NULL DEFAULT 0,
  `permission_edit_metadata` tinyint(1) NOT NULL DEFAULT 0,
  `permission_manipulate_library` tinyint(1) NOT NULL DEFAULT 0,
  `permission_admin` tinyint(1) NOT NULL DEFAULT 0,
  `permission_email_book` tinyint(1) NOT NULL DEFAULT 1,
  `permission_delete_book` tinyint(1) NOT NULL DEFAULT 0,
  `permission_sync_koreader` tinyint(1) NOT NULL DEFAULT 0,
  `permission_sync_kobo` tinyint(1) NOT NULL DEFAULT 0,
  `permission_access_opds` tinyint(1) NOT NULL DEFAULT 0,
  `permission_manage_metadata_config` tinyint(1) NOT NULL DEFAULT 0,
  `permission_access_bookdrop` tinyint(1) NOT NULL DEFAULT 0,
  `permission_access_library_stats` tinyint(1) NOT NULL DEFAULT 0,
  `permission_access_user_stats` tinyint(1) NOT NULL DEFAULT 0,
  `permission_access_task_manager` tinyint(1) NOT NULL DEFAULT 0,
  `permission_manage_global_preferences` tinyint(1) NOT NULL DEFAULT 0,
  `permission_manage_icons` tinyint(1) NOT NULL DEFAULT 0,
  `permission_demo_user` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_auto_fetch_metadata` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_custom_fetch_metadata` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_edit_metadata` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_regenerate_cover` tinyint(1) NOT NULL DEFAULT 0,
  `permission_move_organize_files` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_lock_unlock_metadata` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_reset_booklore_read_progress` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_reset_koreader_read_progress` tinyint(1) NOT NULL DEFAULT 0,
  `permission_bulk_reset_book_read_status` tinyint(1) NOT NULL DEFAULT 0,
  `permission_manage_fonts` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user_permissions_user` (`user_id`),
  CONSTRAINT `fk_user_permissions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_permissions`
--

LOCK TABLES `user_permissions` WRITE;
/*!40000 ALTER TABLE `user_permissions` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `user_permissions` VALUES
(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1);
/*!40000 ALTER TABLE `user_permissions` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `user_settings`
--

DROP TABLE IF EXISTS `user_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`setting_key`),
  CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_settings`
--

LOCK TABLES `user_settings` WRITE;
/*!40000 ALTER TABLE `user_settings` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `user_settings` VALUES
(1,1,'cbxReaderSetting','{\"pageSpread\":\"ODD\",\"pageViewMode\":\"SINGLE_PAGE\",\"fitMode\":\"FIT_HEIGHT\",\"scrollMode\":\"PAGINATED\",\"backgroundColor\":\"GRAY\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(2,1,'newPdfReaderSetting','{\"pageSpread\":\"ODD\",\"pageViewMode\":\"SINGLE_PAGE\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(3,1,'epubReaderSetting','{\"theme\":\"white\",\"font\":null,\"fontSize\":100,\"letterSpacing\":null,\"lineHeight\":null,\"flow\":\"paginated\",\"spread\":\"double\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(4,1,'entityViewPreferences','{\"global\":{\"sortKey\":\"title\",\"sortDir\":\"ASC\",\"view\":\"GRID\",\"coverSize\":1.0,\"seriesCollapsed\":false},\"overrides\":null}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(5,1,'sidebarMagicShelfSorting','{\"field\":\"id\",\"order\":\"asc\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(6,1,'metadataCenterViewMode','route','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(7,1,'pdfReaderSetting','{\"pageSpread\":\"odd\",\"pageZoom\":\"page-fit\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(8,1,'sidebarLibrarySorting','{\"field\":\"id\",\"order\":\"asc\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(9,1,'perBookSetting','{\"pdf\":\"Individual\",\"epub\":\"Individual\",\"cbx\":\"Individual\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(10,1,'tableColumnPreference','null','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(11,1,'sidebarShelfSorting','{\"field\":\"id\",\"order\":\"asc\"}','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(12,1,'filterMode','and','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(13,1,'filterSortingMode','count','2025-12-29 19:30:32','2025-12-29 19:30:32'),
(14,1,'ebookReaderSetting','{\"fontFamily\":\"serif\",\"fontSize\":16,\"gap\":0.05,\"hyphenate\":false,\"isDark\":false,\"justify\":false,\"lineHeight\":1.5,\"maxBlockSize\":1440,\"maxColumnCount\":2,\"maxInlineSize\":720,\"theme\":\"gray\",\"flow\":\"paginated\"}','2026-02-03 18:45:06','2026-02-03 18:45:06'),
(43,1,'hardcoverApiKey','eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJIYXJkY292ZXIiLCJ2ZXJzaW9uIjoiOCIsImp0aSI6ImRhMjY3M2Q2LWI0YmMtNGYwNC1iZGQwLTY2OTUzNWRkMTdjYSIsImFwcGxpY2F0aW9uSWQiOjIsInN1YiI6IjgxMjAwIiwiYXVkIjoiMSIsImlkIjoiODEyMDAiLCJsb2dnZWRJbiI6dHJ1ZSwiaWF0IjoxNzcyNzI3NzAwLCJleHAiOjE4MDQyNjM3MDAsImh0dHBzOi8vaGFzdXJhLmlvL2p3dC9jbGFpbXMiOnsieC1oYXN1cmEtYWxsb3dlZC1yb2xlcyI6WyJ1c2VyIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS1yb2xlIjoidXNlciIsIlgtaGFzdXJhLXVzZXItaWQiOiI4MTIwMCJ9LCJ1c2VyIjp7ImlkIjo4MTIwMH19.Yo4h5mpehNuZyvMvz_UBqvwyHUfezo29xcn42iiqOoo','2026-03-05 16:21:04','2026-03-05 16:29:33'),
(44,1,'hardcoverSyncEnabled','true','2026-03-05 16:21:04','2026-03-05 16:45:40');
/*!40000 ALTER TABLE `user_settings` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `is_default_password` tinyint(1) NOT NULL DEFAULT 1,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `book_preferences` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `provisioning_method` varchar(50) DEFAULT NULL,
  `oidc_subject` varchar(255) DEFAULT NULL,
  `oidc_issuer` varchar(512) DEFAULT NULL,
  `avatar_url` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `idx_users_oidc_issuer_subject` (`oidc_issuer`,`oidc_subject`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `users` VALUES
(1,'niklas','$2a$10$RxgrcfTZyp9wTnftJIxdsOq44LPDfynF0XdUbdDTJBClEI7uVDttG',0,'Niklas','niklas@ntasler.de',NULL,'2025-12-29 19:30:32','OIDC','b9f55a9b-860b-4886-ba2c-4f2927c07d51','https://auth.ntasler.de',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
commit;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-03-21 20:27:54
