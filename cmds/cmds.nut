require("cmds_basic.nut");
require("cmds_industry.nut");
require("cmds_score.nut")
require("cmds_hiscore.nut")
require("cmds_mods.nut")
require("cmds_admin.nut")

/**
* Help command registration
*/
CCManager.Register(ClientCommand(
	"help",
	{
		HelpGroup = "dummy"	// just not to show itself in /help list
	}
	function(client, ...) {
		if (vargc > 0) {
			CCManager.LongHelp(client, vargv[0].tostring());
		} else {
			// print default group commands
			::SAIServer.SayClient(client, "List of available commands, use '/help [command]' for details.");				
			CCManager.PrintHelpGroup(client, "");
		}		
	}
));


/**
* Rules command registration
*/
CCManager.Register(ClientCommand(
	"rules",
	{
		HelpIndex = 1,
		ShortHelp = "Display server rules"
	}
	function(client, ...) {
		if (vargc > 0) {
			CCManager.LongHelp(client, vargv[0].tostring());
		} else {
			::SAIServer.SayClient(client, "See http://expertshard.freeforums.org for rules explanation and abuse reporting.");
			::SAIServer.SayClient(client, "#1 - No blocking.");
			::SAIServer.SayClient(client, "#2 - Competition is welcome here (fund your own secondary industry if you need exclusivity).");
			::SAIServer.SayClient(client, "#3 - No town destroying.");
			::SAIServer.SayClient(client, "#4 - No single industry truck/train pushing (you can transfer from other mines, farms, ...)");
			::SAIServer.SayClient(client, "#5 - Destroying or blocking road vehicles is not allowed (don\'t block with full load in towns)");
			::SAIServer.SayClient(client, "#6 - Promoting and playing multiple companies is not allowed.")
			::SAIServer.SayClient(client, "#7 - No multiple load station for each industry/cargo combination.");
		}		
	}
));




class CmdUtils {
	/**
	* Get company name by it's specification
	*/
	static function GetCompanyNameBySpec(client, company_spec) {
		local company, company_name
	
		if (company_spec == null) {		
			company = ::SAIClient.GetCompany(client);
		    if (company != ::SAICompany.COMPANY_SPECTATOR) 
		    	company_name = ::SAICompany.GetName(company);
			else
				::SAIServer.SayClient(client, "Not supported for spectators, use company specification.")
		} else {
		    // test for company id or #id
		    try {
		    	company = company_spec.tointeger();
		    } catch (e) {
		    	try {
		    		company = company_spec.slice(1).tointeger();
		    	} catch(e) {} 
		    }
		    	    
		    if (company != null) {
		    	// specified by id
		    	if (::SAICompany.IsValid(company - 1))
		    		company_name = ::SAICompany.GetName(company - 1);
		    	else
		    		::SAIServer.SayClient(client, format("Company with index #%d does not exist.", company))
		    } else {
		    	// try to find by name
		    	company_name = company_spec	
		    }
		}	
		return company_name;
	}	
}

