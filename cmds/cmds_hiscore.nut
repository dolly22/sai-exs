/**
* Hiscore help command registration
*/
CCManager.Register(ClientCommand(
	"hshelp",
	{
		HelpIndex = 100,
		ShortHelp = "Hiscore commands list & help"
	}
	function(client, ...) {
		// print default group commands
		::SAIServer.SayClient(client, "List of available hiscore commands, use '/help [command]' for details.");				
		CCManager.PrintHelpGroup(client, "hiscore");
	}
));


/**
*  Hiscore overview client command 
*/
CCManager.Register(ClientCommand(
	"hs",
	{
		HelpGroup = "hiscore",
		HelpIndex = 1,
		ShortHelp = "Hiscore overview",
		Aliases = ["hiscore"],
		LongHelp = [
			"Displays hiscore overview tables. These are the same tables the server displays every year."		
		]
	}
	function(client, ...) {
		Hiscore.PrintOverview(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }
		);	
	}
));


CCManager.Register(ClientCommand(
	"ranking",
	{
		HelpGroup = "hiscore",
		HelpIndex = 2,
		ShortHelp = "Information about hiscore ranking",
		LongHelp = [
			"Displays information how the hiscore ranking works."		
		]
	}
	function(client, ...) {
		local messages = [
			"-= Total points chart =-",
			"Only games from last 100 days are counted. The points decay at the rate of 1% per day in this chart.",			
			"-= Weekly points chart =-",
			"Only the games in last 7 days are taken into account. Points dont's decay in this chart.",
			"-= Best games chart =-",
			"You need to have at least 5 awarded games to be rated in the best games chart. The actual value in",
			"this chart is the point average of your 5-10 best games. Only games from last 100 days are counted."
		]
		
		foreach(msg in messages) {
			::SAIServer.SayClient(client, msg);
		}
	}
));


/**
*  Company last games statistics
*/
CCManager.Register(ClientCommand(
	"lgc",
	{
		HelpGroup = "hiscore",
		HelpIndex = 10,
		ShortHelp = "Display company last games statistics",
		Aliases = ["lastgamescompany", "lg"],
		LongHelp = [
			"Displays last rated games for specified company.",
			"Usage: /lgc [company_spec] [page_spec]",
			"  company_spec - company specification either by name or company id. If ommited, the company you are playing is used.",
			"  page_spec - page specification (1-20)",
			"Examples:",
			"  /lgc \"Player transport\" - displays last games for company Player transport",
			"  /lgc \"Player transport\" 2 - displays last games for company Player transport second page",		
			"  /lgc 2 - displays last games for company #2"		
		]
	}
	function(client, ...) {
		local page_spec = 1
		local company_spec;
		
		if (vargc > 0)	
			company_spec = vargv[0];		
		if (vargc > 1)	
			page_spec = Utils.GetInteger(vargv[1], 1);	
			
		local company_name = CmdUtils.GetCompanyNameBySpec(client, company_spec);	
		if (company_name != null && company_name.len() > 0) {
			Hiscore.PrintLastGamesCompany(
				function(msg) : (client) { ::SAIServer.SayClient(client, msg); },
				company_name,
				page_spec);	
				
			if (page_spec == 1)	
				::SAIServer.SayClient(client, "Use \'/lgc company_spec 2\' and so on to see next pages.")		
		}
	}
));

/**
*  Company best games statistics
*/
CCManager.Register(ClientCommand(
	"bgc",
	{
		HelpGroup = "hiscore",
		HelpIndex = 11,
		ShortHelp = "Display company best (top awarded) games statistics",
		Aliases = ["bestgamescompany", "bg"],
		LongHelp = [
			"Displays best rated games for specified company.",
			"Usage: /bgc [company_spec] [page_spec]",
			"  company_spec - company specification either by name or company id. If ommited, the company you are playing is used.",
			"Examples:",
			"  /bgc \"Player transport\" - displays best games for company Player transport",	
			"  /bgc 2 - displays best games for company #2"		
		]
	}
	function(client, ...) {
		local company_spec;
		
		if (vargc > 0)	
			company_spec = vargv[0];		
			
		local company_name = CmdUtils.GetCompanyNameBySpec(client, company_spec);	
		if (company_name != null && company_name.len() > 0) {
			Hiscore.PrintBestGamesCompany(
				function(msg) : (client) { ::SAIServer.SayClient(client, msg); },
				company_name);	
		}
	}
));


/**
*  Company hiscore statistics
*/
CCManager.Register(ClientCommand(
	"hsc",
	{
		HelpGroup = "hiscore",
		HelpIndex = 12,
		ShortHelp = "Hiscore statistics for company",
		Aliases = ["hiscorecompany"],
		LongHelp = [
			"Displays hiscore statistics for concrete company.",
			"Usage: /hsc [company_spec]",
			"  company_spec - company specification either by name or company id. If ommited, the company you are playing is used.",		
			"Examples:",
			"  /hsc \"Player transport\" - displays hiscore statistics for Player transport",	
			"  /hsc 2 - displays hiscore statistics for company #2"			
		]
	}
	function(client, ...) {
		local company_spec;
		if (vargc > 0)	
			company_spec = vargv[0];
				
		local company_name = CmdUtils.GetCompanyNameBySpec(client, company_spec);	
		if (company_name != null && company_name.len() > 0) {
			Hiscore.PrintFullCompanyRanking(
				function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
				company_name);
		}	
	}
));


/**
*  Best games hiscore statistics
*/
CCManager.Register(ClientCommand(
	"hsgame",
	{
		HelpGroup = "hiscore",
		HelpIndex = 5,
		ShortHelp = "Hiscore table by top awarded games",
		Aliases = ["hsgames", "hiscoregame", "hiscoregames"],
		LongHelp = [
			"Display top awarded games hiscore table.",
			"Usage: /hsgame [page_spec]",
			"  page_spec - page specification (1-20)",
			"Examples:",
			"  /hsgames 2 - second page of top awarded games hiscore statistics"		
		]
	}
	function(client, ...) {
		local page_spec = 1
		
		if (vargc > 0)	
			page_spec = Utils.GetInteger(vargv[0], 1);	
			
		Hiscore.PrintRankingBestGames(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
			page_spec);		
		
		if (page_spec == 1)	
			::SAIServer.SayClient(client, "Use \'/hsgame 2\' and so on to see next hiscore pages.")
	}
));


/**
*  Week hiscore statistics 
*/
CCManager.Register(ClientCommand(
	"hsweek",
	{
		HelpGroup = "hiscore",
		HelpIndex = 6,
		ShortHelp = "Hiscore table by points earhed in last 7 days",
		Aliases = ["hiscoreweek"],
		LongHelp = [
			"Display earned points in last 7 days hiscore table.",
			"Usage: /hsweek [page_spec]",
			"  page_spec - page specification (1-20)",
			"Examples:",
			"  /hsweek 2 - second page of 7 days earned points statistics"		
		]
	}
	function(client, ...) {
		local page_spec = 1
		
		if (vargc > 0)	
			page_spec = Utils.GetInteger(vargv[0], 1);	
			
		Hiscore.PrintRankingWeekPoints(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
			page_spec);		
	
		if (page_spec == 1)			
			::SAIServer.SayClient(client, "Use \'/hsweek 2\' and so on to see next hiscore pages.")	
	}
));


/**
*  Total hiscore statistics
*/
CCManager.Register(ClientCommand(
	"hstotal",
	{
		HelpGroup = "hiscore",
		HelpIndex = 7,
		ShortHelp = "Hiscore table by total earned points",
		Aliases = ["hiscoretotal"],
		LongHelp = [
			"Display total earned points. The points decay at the rate of 1%/day in this table.",
			"Usage: /hstotal [page_spec]",
			"  page_spec - page specification (1-20)",
			"Examples:",
			"  /hstotal 2 - second page of total earned points statistics"	
		]
	}
	function(client, ...) {
		local page_spec = 1
		
		if (vargc > 0)	
			page_spec = Utils.GetInteger(vargv[0], 1);	
			
		Hiscore.PrintRankingTotalPoints(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
			page_spec);		
	
		if (page_spec == 1)			
			::SAIServer.SayClient(client, "Use \'/hstotal 2\' and so on to see next hiscore pages.")
	}
));

////////////////////////////////////
// ADMINISTRATORS COMMANDS HISCORE
////////////////////////////////////

/**
*  Hiscore overview client command 
*/
CCManager.Register(ClientCommand(
	"admhsupdate",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "adm",
		HelpIndex = 1,
		ShortHelp = "Update precomputed hiscore statistics in database"
	}
	function(client, ...) {
		datadb.UpdateCompanyStats();
		::SAIServer.SayClient(client, "Hiscore statistics updated in database");
	}
));



