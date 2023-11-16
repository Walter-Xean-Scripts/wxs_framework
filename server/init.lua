require 'server.player.main'
local FWDB = require 'server.database'

-- Init the database 🚀
FWDB:CreateIfNotExist()

-- Welcome message
print("^2[FW]^7 Welcome to the WX Framework!")
print("---------------------------------")
print("A framework that values good code, compatability and performance.")
print("Created by WXScripts.")
print("---------------------------------")
