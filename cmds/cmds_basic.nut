/**
* Clients command registration
*/
CCManager.Register(ClientCommand(
	"clients",
	{
		HelpIndex = 10,
		ShortHelp = "Display connected clients"
	}
	function(client, ...) {
		Commands_ClientsImpl(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); } 
		);	
	}
));

function Commands_ClientsImpl(print_func)
{
	local clients = SAIClientList();
	
	if (clients.Count() == 0) {
		print_func("No connected clients");
		return; 
	}		
	clients.Valuate(SAIClient.GetCompany);
	
	// sort by client # (from oldest joined)
	clients.Sort(::SAIClientList.SORT_BY_ITEM, ::SAIClientList.SORT_ASCENDING); 
	
	foreach(cli, company in clients) {
		local joined_str  = Utils.FormatDate(::SAIClient.GetJoinedDate(cli));
		
		local atr_mod = "";
		if (::SAIClient.IsAdmin(cli)) {
			atr_mod = "[Admin]";		
		} else if (::SAIClient.IsModerator(cli)) {
			atr_mod = "[Moderator]";
		}
		
		local atr_company = "";
		if (company == ::SAICompany.COMPANY_SPECTATOR) {
			atr_company = "is spectating";
		} else if (company == ::SAICompany.COMPANY_NEW_COMPANY) {
			atr_company = "is joining";
		} else {
			atr_company = format("plays as '%s'", ::SAICompany.GetName(company));
		}	
								
		print_func(
			format("Client #%d - %s (%s), joined %s, %s %s", 
				cli,
				::SAIClient.GetName(cli),
				::SAIClient.GetAnonymizedHostName(cli),
				joined_str,
				atr_company,
				atr_mod			
		));		
	}	
}

/**
* Clients command registration
*/
CCManager.Register(ClientCommand(
	"companies",
	{
		HelpIndex = 11,
		ShortHelp = "Display companies"
	}
	function(client, ...) {
		Commands_CompaniesImpl(
			function(msg) : (client) { ::SAIServer.SayClient(client, msg); } 
		);			
	}
));

function Commands_CompaniesImpl(print_func)
{
	local companies = SAICompanyList();
	local clients = SAIClientList();
	
	if (companies.Count() == 0) {
		print_func("No companies");
		return; 
	}		
	clients.Valuate(SAIClient.GetCompany);
	
	foreach(company, dummy in companies) {
		local suspended = "";
		if (SAICompany.IsSuspended(company))
			suspended = " (suspended)";
	
		local company_clients = [];
		foreach(client, playas in clients) {
			if (playas == company)
				company_clients.append(SAIClient.GetName(client));			
		}
		company_clients.sort();

		local client_part = "";
		if (company_clients.len() > 0) {
			// make client string				
			local clientstr = ""; 
			for(local i=0; i<company_clients.len(); i++) {
				if (i>0 && i<company_clients.len()-1)
					clientstr += ", ";
				clientstr += company_clients[i];
			}
			
			client_part = "clients: "+ clientstr;
		} else {
			if (SAICompany.IsProtected(company)) {
				client_part = "protected from autoclean";
			} else {			
				// iddle months
				client_part = format("iddle for %i months", SAICompany.MonthsEmpty(company));
			}
		}		
		
		local atr_mod = "";
		if (::SAICompany.IsServer(company)) {
			atr_mod = " [Server]";		
		}
													
		print_func( 
			format("Company #%i - '%s'%s, inaugurated %i, %s%s", 
				company + 1, 
				SAICompany.GetName(company), 
				suspended, 
				SAICompany.InauguratedYear(company), 
				client_part, 
				atr_mod)
		);
	}		
}

/**
* Clients command registration
*/
CCManager.Register(ClientCommand(
	"resetme",
	{
		Audience = AudienceFlags.ValidCompany					// only available for valid companies
		HelpIndex = 20,
		ShortHelp = "Reset your company so you can fresh start"
	}
	function(client, ...) {
		local storage_flag = CompanyControl.ResetmeTag;
		
		local company = SAIClient.GetCompany(client);
		if (::SAICompany.IsValid(company)) {	
			local resetflag = CompanyStorage.GetValue(company, storage_flag);
			if (resetflag != null) {
				// reset already pending
				CompanyStorage.RemoveKey(company, storage_flag);
				::SAIServer.SayCompany(company, "Company reset canceled.");			
			} else {
				// new reset request
				local current_date = ::AIDate.GetCurrentDate();
				local reset_date   = current_date + 31;
				
				if (::AIDate.GetDayOfMonth(current_date) >= 15)
					reset_date += 31;
					
				reset_date = AIDate.GetDate(AIDate.GetYear(reset_date), AIDate.GetMonth(reset_date), 1);				
				
				::SAIServer.SayCompany(company, format("Your company will be reset at %s, use '/resetme' command to cancel.", Utils.FormatDate(reset_date)));			
				CompanyStorage.SetValue(company, storage_flag, reset_date);			
			}		
		} else {
			// some problem with company, probably spectator?
			if (company == SAICompany.COMPANY_SPECTATOR) {
				::SAIServer.SayClient(client, "Not supported for spectators.");
			}	
		}		
	}
));

/**
* Clients command registration - saveme
*/
CCManager.Register(ClientCommand(
	"saveme",
	{
		Audience = AudienceFlags.ValidCompany					// only available for valid companies
		Aliases = ["save"],
		HelpIndex = 21,
		ShortHelp = "Protect your company from autoclean"
	}
	function(client, ...) {
		local company = SAIClient.GetCompany(client);
		if (::SAICompany.IsValid(company)) {
			local protected = ::SAICompany.IsProtected(company);			
			if (protected) {
				::SAICompany.SetProtected(company, false);
				::SAIServer.SayCompany(company, "Your company is no longer protected from autoclean.");
			} else {
				local year = ::AIDate.GetYear(::AIDate.GetCurrentDate());
				local inauguratedYear = ::SAICompany.InauguratedYear(company);
								
				if ((year - inauguratedYear) >= 2) {
					::SAIServer.SayCompany(company, "Your company is now protected from autocleaning.");
					::SAICompany.SetProtected(company, true);				
				} else {
					::SAIServer.SayCompany(company, "Your company has to be at least 3 years old to use /saveme.");
				}
			}
		} else {
			// some problem with company, probably spectator?
			if (company == SAICompany.COMPANY_SPECTATOR) {
				::SAIServer.SayClient(client, "Not supported for spectators.");
			}	
		}		
	}
));


/**
* Clients command registration
*/
CCManager.Register(ClientCommand(
	"page",
	{
		HelpIndex = 450,
		Aliases = ["admin", "pageadmin"],
		ShortHelp = "Page server moderators and request help",
		LongHelp = [
			"Pages all available operators on every connected server",
			"Usage: /page text",
			"  text - why do you need moderator help.",		
			"Examples:",
			"  /page Sisi is breaking rules #2 and #3",	
			"  /page Somebody is blocking my factory"			
		]			
	}
	function(client, ...) {
		if (vargc > 0) {
			local msg = "";
			for(local i = 0; i < vargc; i++) {
				msg += " "+ vargv[i];
			}			
			local pageMsg = format("Client \'%s\' asks for assistance:%s", ::SAIClient.GetName(client), msg);
			
			// page admins locally
			foreach(moderator, dummy in ::SAIClientList())
			{
				if (::SAIClient.IsModerator(moderator) || ::SAIClient.IsAdmin(moderator)) {
					::SAIServer.SayClient(moderator, "[MOD] "+ pageMsg);
				}
			}			
			// page IRC admins
			::IrcServer.PageOperators(pageMsg);
			
			::SAIServer.SayClient(client, format("All available operators have been notified (%s)", msg));										
		} else {
			::SAIServer.SayClient(client, "You have to supply some reason, see \"/help page\" for details.");
		}			
	}
));

/*

CCManager.Register(ClientCommand(
	"serverinfo",
	{
		HelpIndex = 500,
		ShortHelp = "Information about server",
		LongHelp = [
			"Displays detailed information about this server."		
		]			
	}
	function(client, ...) {		
		local messages = [
			"-= Server info =-",
			"Script version: "+ ServerScriptVersion + " (build "+ ServerScriptBuildDate +")",
			"-= Gameplay differences from standard OpenTTD =-",
			"* Funded secondary industries are private for their owner and protected from others",
			"* Excesive destroying of town buildings leads to suspending your company for 6 months",
			"* Single tile station unloading leads to suspending your company for 6 months",
			"* Train unload exploiting guard is active",
			"* Multiple map loading slots active",
		]
		
		foreach(msg in messages) {
			::SAIServer.SayClient(client, msg);
		}
	}		
));

*/

