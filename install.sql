
CREATE TABLE IF NOT EXISTS `org_upgrades` (
    `society` VARCHAR(100) NOT NULL,
    `points` INT DEFAULT 0,
    `vehicle_mods` INT DEFAULT 0,
    `custom_plate` INT DEFAULT 0,
    `plate_prefix` VARCHAR(10),
    `safe_weight` INT DEFAULT 0,
    PRIMARY KEY (`society`)
);




-- IF U WANT TO ADD SOCIETY IN TABLE, USE CODE BELOW


INSERT INTO `org_upgrades` (`society`, `points`, `vehicle_mods`, `custom_plate`, `plate_prefix`, `safe_weight`)
VALUES 
('society_name', 0, 0, 0, NULL, 0);
