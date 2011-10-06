/**
*  Ban client from current game
*/
CCManager.Register(ClientCommand(
	"bangame",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 10,
		Aliases = ["bang"],
		ShortHelp = "Ban client from game",
		LongHelp = [
			"Ban client from current game (he can reconnect when new game starts)",
			"Usage: /bangame client_spec",
			"  client_spec - client id specification, use /clients command to get this.",
			"Examples:",
			"  /bangame 154 - ban client with id 154 from current game"
		]		
	}
	function(client, ...) {
		local ban_client;
		
		if (vargc > 0) 			
			ban_client = Utils.GetInteger(vargv[0], 0);
			
		if (ban_client > 1 && ::SAIClient.IsValid(ban_client)) {
			if (::SAIClient.IsAdmin(ban_client) || ::SAIClient.IsModerator(ban_client)) {
				::SAIServer.SayClient(client, "Cannot ban admin or moderator.");
				return;
			}				
			::SAIServer.Say(format("[MOD] %s is banning \"%s\" from current game", ::SAIClient.GetName(client), ::SAIClient.GetName(ban_client)));					
			::BanHelper.BanClientGame(ban_client, ::SAIClient.GetName(client));
		} else {
			::SAIServer.SayClient(client, "Invalid client-id specified.");
		}
	}
));


/**
*  Display game ban list
*/
CCManager.Register(ClientCommand(
	"bangamelist",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 11,
		Aliases = ["bangl"],
		ShortHelp = "List client game bans"		
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "List of clients banned from this game.");
		local banList = ::BanHelper.GetGameBanList().GetBans();
		
		foreach(key, val in banList) {
			::SAIServer.SayClient(client,
				format("#%d. - \"%s\" (%s) - banned by %s at %s", key, val.Name, val.IPHash, val.BannedBy, ::Utils.FormatDate(val.Date)));	
		}		
		
		if (banList.len() == 0)
			::SAIServer.SayClient(client, " - no banned clients.");		
	}
));


/**
*  Remove client ban from current game
*/
CCManager.Register(ClientCommand(
	"bangameremove",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 12,
		Aliases = ["bangr"],
		ShortHelp = "Remove ban from current game"
	}
	function(client, ...) {
		local ban_client = 0;
		local banList = ::BanHelper.GetGameBanList();
		
		if (vargc > 0) 			
			ban_client = Utils.GetInteger(vargv[0], 0);		
		
		if (banList.GetBanEntry(ban_client) != null) {
			::BanHelper.UnbanClientGame(ban_client);
		} else {
			::SAIServer.SayClient(client, format("Client #%d was not banned.", ban_client));
		}		
	}
));
