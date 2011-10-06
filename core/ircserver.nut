IrcServers <- {};

::IrcServers["exs-city1"] <- {
			Name = "City builder #1"
		};
::IrcServers["exs-city2"] <- {
			Name = "City builder #2"
		};
::IrcServers["exs-cv1"] <- {
			Name = "Company Value #1"
		};
::IrcServers["exs-cv2"] <- {
			Name = "Company Value #2"
		};



class IrcServer 
{
	/**
	* Notify irc new client has joined this server
	*/	
	static function NotifyClientJoined(client) 
	{
		// notice irc clients
		::SAIIrc.Notice(format("*** %s (%s) has joined the server"
			::SAIClient.GetName(client),
			::SAIClient.GetAnonymizedHostName(client)
		));			
	}	
	
	/**
	* Notify irc client has left server
	*/		
	static function NotifyClientLeft(client)
	{
		// notice irc clients
		::SAIIrc.Notice(format("*** %s (%s) left the server"
			::SAIClient.GetName(client),
			::SAIClient.GetAnonymizedHostName(client)
		));		
	}
	
	/**
	* Send command to all servers excluding myself
	**/
	static function OnAllServers(command)
	{
		local myServer = ::SAIGameSettings.GetStringValue(::SAIGameSettings.GS_CURRENT_GAME, "network.irc_nick");
				
		local dest = ""
		foreach(server in ::IrcServers) {
			if (server != myServer) {
				if (dest.len() > 0)
					dest += ",";
				dest += server;
			}			
		}			
		// broadcast to linked servers (as normal say)
		::SAIIrc.MessageNick(dest, command);		
	}	
	
	/**
	* Notice message on all registered irc channels
	**/
	static function OnAllChannels(msg) {
		::SAIIrc.NoticeNick("#openttd,#servers", msg);
	}
		
	static function NoticeFromServer(nick, msg) {
		// try to find server friendly name
		local friendlyName = nick;		
		if (nick in ::IrcServers) {
			friendlyName = servers[nick].Name;		
		}		
		::SAIServer.SayEx(false, format("%s notice - %s", friendlyName, msg));		
	}		
		
	/**
	* Broadcast message to all servers and all channels
	**/
	static function BroadcastWithServers(msg)
	{
		// broadcast to linked servers
		::IrcServer.OnAllServers("!server_bcast "+ msg);
		//also broadcast on #openttd and #servers channels
		::IrcServer.OnAllChannels(msg);
	}
	
	/**
	* Notify irc and other game servers new game has just started here
	*/
	static function NotifyGameStarted()
	{	
		local mapRes = format("%dx%d",
			pow(2, ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.map_x")),
			pow(2, ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.map_y")));
		
		local landscape;
		switch(::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.landscape"))
		{
			case 0:
				landscape = "Temperate";
				break;
			case 1:
				landscape = "Arctic";
				break;
			case 2:
			default:
				landscape = "Tropical";
				break;
		}

		local goalTag = "";
		if (Game.Goal != null)
		{
			local goalInfo = Game.Goal.GetInfo();
			if (goalInfo.len() > 0)			
				goalTag = " - "+ goalInfo[0];
		}		
		
		local yearTag = ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.starting_year");
				
		// rozliseni, climate goal ...
		::IrcServer.BroadcastWithServers(format("Game just started - %s %d [%s]%s", landscape, yearTag, mapRes, goalTag));
	}	
	
	/**
	* Notify irc and other game servers has ended here
	*/
	static function NotifyGameEnded()
	{	
		local winnerTag = "";
		if (Game.HasWinner()) {
			winnerTag = format(" '%s' is the winner - %s.", Game.WinCompany.CompanyName, Game.WinCompany.GetWinTag());
		}		
		
		// rozliseni, climate goal ...
		::IrcServer.BroadcastWithServers(format("Game just ended.%s New game is about to start in a few minutes.", winnerTag));
	}	
	
	/**
	* Page all operators on every server and IRC chat
	**/
	static function PageOperators(msg)
	{
		// broadcast to linked servers (to ingame chat)
		::IrcServer.OnAllServers("!server_opbcast "+ msg);	
		//notice irc server channel separately
		::SAIIrc.Notice(msg);
		// page all operators available for help on IRC
		::SAIServer.IrcRaw(format("OTTDHELP :%s\r\n", msg));
	}	
	
	static function GetServerStatus()
	{
		local companiesTag = ::SAICompanyList().Count() +"/"+ ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "network.max_companies");
		local goalTag = "";
		local bestCompanyTag = "";
		
		if (Game.Goal != null)
		{
			goalTag = Game.Goal.GetStatus();
		}
		
		if (Game.Score != null)
		{
			local bestCompany = Game.Score.GetBestCompany();
			if (bestCompany != null)
			{
				if (Game.Goal != null)
					bestCompanyTag += ", ";				
				bestCompanyTag += "'"+ bestCompany.CompanyName +"' is leading the game.";
			}
		}
		return format("[%s] %s - %s%s", 
					companiesTag,
					Utils.FormatDate(::AIDate.GetCurrentDate()),  
					Game.Goal.GetStatus(), 
					bestCompanyTag);
	}	
}