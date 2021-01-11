INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_winemaker', 'Winemaker', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_winemaker', 'Winemaker', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_winemaker', 'Winemaker', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('winemaker', 'Winemaker')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('winemaker',0,'brigadier','Brigadier',0,'{}','{}'),
	('winemaker',1,'beginner','Beginner',0,'{}','{}'),
	('winemaker',2,'collector','Collector',0,'{}','{}'),
	('winemaker',3,'manager','Manager',0,'{}','{}'),
	('winemaker',4,'boss','Patron',0,'{}','{}')
;

INSERT INTO `items` (`name`, `label`) VALUES
	('white_raisin', 'White wine'),
	('red_raisin', 'Red wine'),
	('flaska_white_raisin', 'Bottle of white wine'),
	('flaska_red_raisin', 'Bottle of red wine')
;