/**
* Moderator login
*/
CCManager.Register(ClientCommand(
	"modlogin",
	{
		HelpGroup = "mods",
		HelpIndex = 1,
		ShortHelp = "Login moderator"
	}
	function(client, ...) {
		if (vargc == 0) {
			::SAIServer.SayClient(client, "Please specify moderators password.")
			return;
		}
		local pass = vargv[0];
		local clientName = ::SAIClient.GetName(client);
		
		if (clientName.tolower() in ::StaticModerators) {
			local cdef = ::StaticModerators[clientName.tolower()];			
			if (cdef.Pass == pass) {
				::SAIClient.SetModerator(client, true);				
				if (cdef.IsAdmin == true)
					::SAIClient.SetAdmin(client, true);
				
				::SAIServer.Say(format("[MOD] %s identified as moderator.", clientName));
			} else {
				::SAIServer.SayClient(client, "Invalid password!");
			}
		}
	}
));


/**
* Moderator logout
*/
CCManager.Register(ClientCommand(
	"modlogout",
	{
		Audience = AudienceFlags.Moderators,
		HelpGroup = "mods",
		HelpIndex = 2,
		ShortHelp = "Logout as moderator"
	}
	function(client, ...) {
		if (::SAIClient.IsModerator(client)) {
			::SAIClient.SetModerator(client, false);
			::SAIClient.SetAdmin(client, false);
			::SAIServer.SayClient(client, "You were logged out as moderator.");
		} else {
			::SAIServer.SayClient(client, "You are not logged in as moderator.");
		}		
	}
));
