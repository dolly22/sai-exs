/**
* Score command implementation
*/
CCManager.Register(ClientCommand(
	"score",
	{
		HelpIndex = 5,
		Aliases = ["sc", "cv", "ncv"],
		ShortHelp = "Companies score table",
		LongHelp = [
			"Displays score table or score details",
			"Usage: /score [company_spec]",
			"  company_spec - company specification either by name or company id. If ommited, the company you are playing is used.",		
			"Examples:",
			"  /score \"Player transport\" - displays score details for Player transport",	
			"  /score 2 - displays score details for company #2"		
		]			
	}
	function(client, ...) {
		//TODO: remove for production just for testing
		//Game.Score.ComputeScore();
		
		if (vargc > 0) {
			// company specified, use detail command
			CCManager.GetCommandSpec("scd").ExecuteFunction(client, vargv[0]);
			return;
		}
	
		// show all company scores	
		Game.Score.PrintScores(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
			true);			
	}
));


/**
* Clients command registration
*/
CCManager.Register(ClientCommand(
	"scd",
	{
		HelpIndex = 6,
		Aliases = ["scoredetail", "csd", "sdc", "city"],
		ShortHelp = "Detailed score information for your company",
		LongHelp = [
			"Displays detailed score information for your company."		
		]			
	}
	function(client, ...) {
		local company = ::SAIClient.GetCompany(client)	
		if (vargc > 0)	
			company = Utils.GetInteger(vargv[0], 1) - 1;		
	
		// check for spectators
		if (company == ::SAICompany.COMPANY_SPECTATOR) {
			::SAIServer.SayClient(client, "Not available for spectators, specify correct company (ex. '/score 1')");
			return;
		}
		
		// check for correct company
		if (!::SAICompany.IsValid(company)) {
			::SAIServer.SayClient(client, "Invalid company specified, specify correct company [1-16] (ex. '/score 1')");
			return;		
		}
		
		Game.Score.PrintScoreDetail(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); }, 
			company);		
	}
));


/**
* Goal command implementation
*/
CCManager.Register(ClientCommand(
	"goal",
	{
		Aliases = ["goalinfo"],		
		HelpIndex = 7,
		ShortHelp = "Game goal information"		
	}
	function(client, ...) {
		if (Game.Goal != null) {
			foreach(i, msg in Game.Goal.GetInfo()) {
				::SAIServer.SayClient(client, msg);
			}
			
			if (Game.Goal.IsCompleted()) {
				if (Game.WinRestart != null)
					::SAIServer.SayClient(client, "The goal was already completed - the game will restart at "+ Utils.FormatDate(Game.WinRestart));
				else
					::SAIServer.SayClient(client, "The goal was already completed - hiscore points not awarded yet");
			} else {
				::SAIServer.SayClient(client, "The goal is not yet complete - "+ Game.Goal.GetStatus());
			}			
		} else {
			::SAIServer.SayClient(client, "This game has no goal");
		}
	}
));