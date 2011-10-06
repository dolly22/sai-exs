/**
* Help command for admin commands
*/
CCManager.Register(ClientCommand(
	"admhelp",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "",
		HelpIndex = 1000,
		ShortHelp = "Display list of admin help commands"		
	}
	function(client, ...) {
		::SAIServer.SayClient(client, "List of available admin commands, use '/help [command]' for details.");				
		CCManager.PrintHelpGroup(client, "adm");	
	}
));


CCManager.Register(ClientCommand(
	"indstats",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "",
		HelpIndex = 1000,
		ShortHelp = "Display statistics of industries"		
	}
	function(client, ...) {
		local ind_table = ::IndustryUtils.GetRawIndustryStats();
		
		::SAIServer.SayClient(client, "Available raw industry statistics:");
		foreach(indtype, ind_spec in ind_table) {						
			if (ind_spec.Cargo1 >= 0) {
				local cargo1percent = floor(ind_spec.Cargo1Transported / (ind_spec.Cargo1Produced.tofloat() + 1.0) * 1000.0) / 10.0;
				::SAIServer.SayClient(client, format("#%d %s (%s) - %d / %d (%.1f%%)",
					indtype, ::AIIndustryType.GetName(indtype),
					::AICargo.GetCargoLabel(ind_spec.Cargo1),
					ind_spec.Cargo1Transported, ind_spec.Cargo1Produced,
					cargo1percent				
				));
			}			
			if (ind_spec.Cargo2 >= 0) {
				local cargo2percent = floor(ind_spec.Cargo2Transported / (ind_spec.Cargo2Produced.tofloat() + 1.0) * 1000.0) / 10.0;
				::SAIServer.SayClient(client, format("#%d %s (%s) - %d / %d (%.1f%%)",
					indtype, ::AIIndustryType.GetName(indtype),
					::AICargo.GetCargoLabel(ind_spec.Cargo2),
					ind_spec.Cargo2Transported, ind_spec.Cargo2Produced,
					cargo2percent
				));			
			}
		}
	}
));


CCManager.Register(ClientCommand(
	"restart_game",
	{
		Audience = AudienceFlags.Admins,
		HelpGroup = "",
		HelpIndex = 1001,
		ShortHelp = "Restarts game"		
	}
	function(client, ...) {
		::Game.RestartGame();
	}
));


