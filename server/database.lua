local FWDB = {}

local ENSURE_USERS = [[
    CREATE TABLE IF NOT EXISTS `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `license2` varchar(255) NOT NULL,
        `steam` varchar(255) DEFAULT NULL,
        `discord` varchar(255) DEFAULT NULL,
        `fivem` varchar(255) DEFAULT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
]]

local ENSURE_CHARACTERS = [[
    CREATE TABLE IF NOT EXISTS `characters` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `userId` INT(11) NOT NULL,
            `firstName` VARCHAR(255) NOT NULL,
            `lastName` VARCHAR(255) NOT NULL,
            `dateOfBirth` VARCHAR(255) NOT NULL,
            `height` INT(11) NULL DEFAULT NULL,
            `gender` INT(11) NOT NULL,
            `currencies` JSON NULL DEFAULT NULL,
            `inventory` JSON NULL DEFAULT NULL,
            `metadata` JSON NULL DEFAULT NULL,
            `appearance` JSON NULL DEFAULT NULL,
        PRIMARY KEY (`id`) USING BTREE,
        INDEX `FK_characters_users` (`userId`) USING BTREE,
        CONSTRAINT `FK_characters_users` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
    ) COLLATE='latin1_swedish_ci' ENGINE=InnoDB;
]]

function FWDB:CreateIfNotExist()
    local p = promise.new()
    exports.oxmysql:execute(ENSURE_USERS, function()
        p:resolve()
    end)

    Citizen.Await(p)

    exports.oxmysql:execute_async(ENSURE_CHARACTERS)
end

return FWDB
