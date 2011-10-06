require("cmds_mods_bans.nut");
require("cmds_mods_login.nut");

/**
* Moderator help command registration
*/
CCManager.Register(ClientCommand(
	"modhelp",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "",
		HelpIndex = 101,
		ShortHelp = "Moderator commands list & help"
	}
	function(client, ...) {
		// print default group commands
		::SAIServer.SayClient(client, "List of available moderator commands, use '/help [command]' for details.");				
		CCManager.PrintHelpGroup(client, "mods");
	}
));


/**
*  Kick client from current game
*/
CCManager.Register(ClientCommand(
	"kick",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 20,
		ShortHelp = "Kick client from game",
		LongHelp = [
			"Kicks client from game (he can reconnect).",
			"Usage: /kick client_spec",
			"  client_spec - client id specification, use /clients command to get this.",
			"Examples:",
			"  /kick 154 - kick client with id 154 from game"
		]
	}
	function(client, ...) {
		local kick_client;
		
		if (vargc > 0) 			
			kick_client = Utils.GetInteger(vargv[0], 0);
			
		if (kick_client > 1 && ::SAIClient.IsValid(kick_client)) {
			if (::SAIClient.IsAdmin(kick_client) || ::SAIClient.IsModerator(kick_client)) {
				::SAIServer.SayClient(client, "Cannot kick admin or moderator.");
				return;
			}
			::SAIServer.Say(format("[MOD] %s is kicking \"%s\" out of the game", ::SAIClient.GetName(client), ::SAIClient.GetName(kick_client)));
			::SAIServer.ConsoleCmd(format("kick %d", kick_client));
		} else {
			::SAIServer.SayClient(client, "Invalid client-id specified.");
		}
	}
));


/**
*  Kick client from company and force him to join spectators
*/
CCManager.Register(ClientCommand(
	"kickc",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 21,
		Aliases = ["kc"],
		ShortHelp = "Kick client from company",
		LongHelp = [
			"Kicks client from company (he joins the spectators).",
			"Usage: /kickc client_spec",
			"  client_spec - client id specification, use /clients command to get this.",
			"Examples:",
			"  /kickc 154 - kick client with id 154 from his company"
		]		
	}
	function(client, ...) {
		local kick_client;
		
		if (vargc > 0) 			
			kick_client = Utils.GetInteger(vargv[0], 0);
			
		if (kick_client > 1 && ::SAIClient.IsValid(kick_client)) {
			if (::SAIClient.IsAdmin(kick_client) || ::SAIClient.IsModerator(kick_client)) {
				::SAIServer.SayClient(client, "Cannot kick admin or moderator.");
				return;
			}
			if (::SAIClient.GetCompany(kick_client) != ::SAICompany.COMPANY_SPECTATOR) {
				::SAIServer.Say(format("[MOD] %s is kicking \"%s\" out of company", ::SAIClient.GetName(client), ::SAIClient.GetName(kick_client)));				
				::SAIServer.ConsoleCmd(format("move %d 255", kick_client));
			} else {
				::SAIServer.SayClient(client, "Client is already spectator.");			
			}
		} else {
			::SAIServer.SayClient(client, "Invalid client-id specified.");
		}
	}
));

/**
*  Move client from one company to another
*/
CCManager.Register(ClientCommand(
	"move",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 22,	
		ShortHelp = "Move client to another company",
		LongHelp = [
			"Move client from one company to another (company spectators = 256)",
			"Usage: /move [client_spec] company_spec",
			"  client_spec - if supplied, you move specific client, otherwise you move yourself",
			"  company_spec - company you are moving the client to (256 = spectators)",			
			"Examples:",
			"  /move 154 2 - move client with id 154 to company with #2",
			"  /move 2 - move yourself to company with #2"			
		]				
	}
	function(client, ...) {
		local move_client, move_company;
		
		if (vargc > 0) 			
			move_client = Utils.GetInteger(vargv[0], 0);
			
		if (move_client > 1 && ::SAIClient.IsValid(move_client) && vargc > 1) {
			if (::SAIClient.IsAdmin(move_client) || ::SAIClient.IsModerator(move_client)) {
				::SAIServer.SayClient(client, "Cannot move admin or moderator.");
				return;
			}
			move_company = Utils.GetInteger(vargv[1], 1) - 1;						
		} else if (vargc == 1) {
			move_client  = client;	
			move_company = Utils.GetInteger(vargv[0], 1) - 1;		
		} else {
			::SAIServer.SayClient(client, "Invalid client-id specified");
			return;
		}
	
		if ((::SAICompany.IsValid(move_company) || move_company == ::SAICompany.COMPANY_SPECTATOR - 1) && !::SAICompany.IsServer(move_company)) {
			if (move_company != ::SAIClient.GetCompany(move_client)) {
				if (move_client != client) {
					local companyName;
					if (move_company == ::SAICompany.COMPANY_SPECTATOR - 1)
						companyName = "spectators";
					else
						companyName = ::SAICompany.GetName(move_company)
					
					::SAIServer.Say(format("[MOD] %s is moving \"%s\" to %s", 
						::SAIClient.GetName(client), ::SAIClient.GetName(move_client), companyName));
				}
				::SAIServer.ConsoleCmd(format("move %d %d", move_client, move_company + 1));
			} else {
				::SAIServer.SayClient(client, "No need to move, already at company.");
			}				
		} else {
			::SAIServer.SayClient(client, "Invalid company specified.");	
		}
	}
));



/**
*  Suspend company actions
*/
CCManager.Register(ClientCommand(
	"suspend",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 30,
		Aliases = ["susp"],		
		ShortHelp = "Suspend company operations",
		LongHelp = [
			"Suspends company operations",
			"Usage: /suspend company_spec [months] [reason]",
			"  company_spec - company you are suspending",
			"  months - month the company will be suspended, till further notice if not specified",
			"  reaston - text description why it was suspended",			
			"Examples:",
			"  /suspend 2 - suspend #2 till further notice",
			"  /suspend 2 6 \"blocking factory\" - suspend #2 for 6 months because blocking"			
		]			
	}
	function(client, ...) {
		local company;
		if (vargc > 0)	
			company = Utils.GetInteger(vargv[0], 1) - 1;
		
		if (::SAICompany.IsValid(company) && !::SAICompany.IsServer(company)) {
			local suspend_till = null;
			if (vargc > 1) {
				suspend_till = Utils.GetInteger(vargv[1], 0);
				if (suspend_till < 3)
					suspend_till = 3;					
				suspend_till = Utils.AdvanceDate(::AIDate.GetCurrentDate(), 0, suspend_till);					
			}
			
			local suspend_reason = ""
			if (vargc > 2) {
				suspend_reason = vargv[2]
			}
			
			::SAIServer.Say(format("[MOD] %s is suspending \"%s\"", ::SAIClient.GetName(client), ::SAICompany.GetName(company)));
			::CompanyControl.SuspendCompany(company, suspend_till, suspend_reason);
		} else {
			::SAIServer.SayClient(client, "Invalid company-id specified.");
		}
	}
));

/**
*  Resume company actions
*/
CCManager.Register(ClientCommand(
	"resume",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 31,
		ShortHelp = "Resume suspended company actions",
		LongHelp = [
			"Resume suspended company operations",
			"Usage: /resume company_spec",
			"  company_spec - company you are resuming",
			"Examples:",
			"  /resume 2 - resume actions of company #2"			
		]			
	}
	function(client, ...) {
		local company;
		if (vargc > 0)	
			company = Utils.GetInteger(vargv[0], 1) - 1;
		
		if (::SAICompany.IsValid(company) && !::SAICompany.IsServer(company)) {
			if (::SAICompany.IsSuspended(company)) {
				::SAIServer.Say(format("[MOD] %s is resuming %s", ::SAIClient.GetName(client), ::SAICompany.GetName(company)));
				::CompanyControl.ResumeCompany(company);
			} else {
				::SAIServer.SayClient(client, "Company is not suspended.");
			}
		} else {
			::SAIServer.SayClient(client, "Invalid company-id specified.");
		}
	}
));

/**
*  Reset company
*/
CCManager.Register(ClientCommand(
	"reset",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 35,
		ShortHelp = "Reset company",
		LongHelp = [
			"Reset company (move clients to spectators and delete company). You have to",
			"confirm this action by calling /reset command again.",			
			"Usage: /reset company_spec",
			"  company_spec - company beeing reset",
			"Examples:",
			"  /reset 2 - reset company #2"
		]				
	}
	function(client, ...) {
		local company = -1;
		if (vargc > 0)	
			company = Utils.GetInteger(vargv[0], 1) - 1;
		
		if (::SAICompany.IsValid(company) && !::SAICompany.IsServer(company)) {
			local resetFlag = ::CompanyStorage.GetValue(company, "CompResetFlag");
			if (resetFlag != null) {
				if (::AIDate.GetCurrentDate() <= ::Utils.GetInteger(resetFlag, 0) + 15) {
					// do reset company
					::SAIServer.Say(format("[MOD] %s is reseting company \"%s\"", ::SAIClient.GetName(client), ::SAICompany.GetName(company)));
					::Utils.ResetCompany(company);	
					return;				
				}
			}
			::CompanyStorage.SetValue(company, "CompResetFlag", ::AIDate.GetCurrentDate());			
			::SAIServer.SayClient(client, format("Company #%d \"%s\" reset requested, use /reset %d within 15 days to confirm.", 
				company+1, ::SAICompany.GetName(company), company+1));			
		} else {
			::SAIServer.SayClient(client, "Invalid company-id specified.");
		}
	}
));


/**
*  Detect duplicate clients
*/
CCManager.Register(ClientCommand(
	"dupclients",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 40,
		Aliases = ["dc"],
		ShortHelp = "Detect duplicate clients in game.",
		LongHelp = [
			"Detect ingame duplicate clients, ip and network id is checked.",
			"\"I\" stands for ip match, \"N\" stands for network id match."			
		]			
	}
	function(client, ...) {
		local clients = SAIClientList();		
		if (clients.Count() == 0) {
			::SAIServer.SayClient(client, "No connected clients");
			return; 
		}		
		clients.Valuate(SAIClient.GetCompany);
		
		// do some temporary array
		local cliArr = [];
		foreach(cli, company in clients) {
			cliArr.append({
				Id = cli,
				Name = ::SAIClient.GetName(cli),				
				Company = company,
				IP = ::SAIClient.GetAddress(cli),
				IpHash = ::SAIClient.GetAnonymizedAddress(cli),
				JoinedDate = ::SAIClient.GetJoinedDate(cli),
				DetectedDuplicate  = false
			});
		};
		
		// sort the array by joined date...
		cliArr.sort(function(a,b) {
			return a.JoinedDate - b.JoinedDate;
		});
		
		::SAIServer.SayClient(client, "Displaying detected duplicate clients in the joined date order.");
		
		local reportStr, duplStr, compCliDef;
		local sameIp;
		local duplCount = 0;
					
		// just iterate through clients
		for (local i=0; i<cliArr.len(); i++) {
			local cliDef = cliArr[i];
			if (cliDef.DetectedDuplicate)
				continue; // this one is no more interesting
			
			reportStr = format("#%d - %s (%s) same as ", cliDef.Id, cliDef.Name, cliDef.IpHash)
			for (local j=i+1; j<cliArr.len(); j++) {
				compCliDef = cliArr[j];	
				if (compCliDef.DetectedDuplicate)
					continue;
										
				sameIp = false;
			
				// this one is not detected as duplicate yet, so it's potential
				if (cliDef.IP == compCliDef.IP) {
					sameIp = true;
				}
				
				if (sameIp || sameHash) {
					duplStr = format("\"%s\" (#%d) [%s]", compCliDef.Name, compCliDef.Id, sameIp ? "I" : "");
					
					if (j != i+1)
						reportStr += ", ";
					reportStr += duplStr;
												
					cliDef.DetectedDuplicate = true;
					compCliDef.DetectedDuplicate = true;
					duplCount++;
				}			
			}
			
			if (cliDef.DetectedDuplicate) {
				::SAIServer.SayClient(client, reportStr);
			}
		}		
		if (duplCount == 0)
			::SAIServer.SayClient(client, "- no detected clients");		
	}
));

