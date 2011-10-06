// Includes whole core 'library'
require("log.nut");

require("callbackmanager.nut");
require("clientcommands.nut");
require("irccommands.nut");
require("companystorage.nut");
require("companycontrol.nut");
require("cheatguard.nut");
require("controllers/server.nut")
require("ircserver.nut")
require("cache.nut");
require("utils.nut");
require("utils_industry.nut");
require("banlist.nut");
require("banlist_static.nut");
require("hiscore.nut");

/**
* Rewrite min function to work with floats
*/
function min(num1, num2) {
	if (num1 < num2)
		return num1;
	else
		return num2;
}

/**
* Rewrite max function to work with floats
*/
function max(num1, num2) {
	if (num1 > num2)
		return num1;
	else
		return num2;
}

