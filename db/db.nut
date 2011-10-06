require("database.nut");
require("datadb.nut");

datadb <- DataDb(DatabaseDrive, DatabasePath);
datadb.Open();
datadb.IsPersistable = true;

/////////////////////////////////
// ADMIN ONLY DATABASE COMMANDS
/////////////////////////////////

/**
*  Disconnect data database
*/
CCManager.Register(ClientCommand(
	"adm_datadb_disconnect",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "adm",
		HelpIndex = 100,
		ShortHelp = "Disconnect data database (if you need to update it)"
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "Closing data database...");		
		datadb.Close();
		::SAIServer.SayClient(client, "Database closed");
	}
));

/**
*  Disconnect data database
*/
CCManager.Register(ClientCommand(
	"adm_datadb_connect",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "adm",
		HelpIndex = 101,
		ShortHelp = "Connect data database (if it was disconnected before)"
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "Opening data database...");		
		datadb.Open();
		::SAIServer.SayClient(client, "Database opened");
	}
));

/**
*  Disconnect data database
*/
CCManager.Register(ClientCommand(
	"adm_datadb_refresh",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "adm",
		HelpIndex = 101,
		ShortHelp = "Refresh/recompute precomputed database data"
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "Refreshing statistics...");		
		datadb.UpdateCompanyStats();
	}
));

/***
* Clean database - remove old data and vacuum 
*/
CCManager.Register(ClientCommand(
	"adm_datadb_cleanup",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "adm",
		HelpIndex = 1001,
		ShortHelp = "Cleans and compacts database (remove old entries)"		
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "Cleaning database...");
		datadb.Cleanup();
	}
));

