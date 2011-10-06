class BanListEntry {
	ClientID = null;
	Name = "";	
	ClientIP = "";
	IPHash = "";
	Date = null;
	BannedBy = "";
}

class BanList {
	_clients = null;
	_lookups = null;
			
	function constructor() {
		_clients = {};
		_lookups = {};
	}
	
	/**
	* Add client ban to list
	*/
	function AddBan(client, bannedBy) {
		if (client > 1 && ::SAIClient.IsValid(client)) {
			local banEntry = BanListEntry()
			
			banEntry.ClientID = client
			banEntry.Name	  = ::SAIClient.GetName(client);
			banEntry.ClientIP = ::SAIClient.GetAddress(client);
			banEntry.IPHash   = ::SAIClient.GetAnonymizedAddress(client);			
			banEntry.Date 	  = ::AIDate.GetCurrentDate();
			banEntry.BannedBy = bannedBy
						
			AddBanEntry(banEntry);	
		}		
	}	

	/** 
	* Get ban by ipHash
	*/
	function GetBan(ipHash) {
		if (ipHash in this._lookups) {
			return this._lookups[ipHash];
		}		
		return null;
	}
	
	/**
	* Remove entry from banlist
	*/
	function RemoveBan(client) {
		local banEntry = GetBanEntry(client);
		if (banEntry) {
			RemoveBanEntry(banEntry);
		}		
	}
		
	/**
	* Get ban entry by client id (doesn't have to be online anymore)
	*/
	function GetBanEntry(client)
	{
		if (client in this._clients) {
			return this._clients[client];
		}		
		return null;
	}
	
	/**
	* Add ban entry to list (table) - identified by iphash
	*/
	function AddBanEntry(banEntry) {
		this._clients[banEntry.ClientID] <- banEntry;

		local ipHash = banEntry.IPHash;
		if (ipHash != null && ipHash.len() > 0 && !(ipHash in this._lookups)) {
			this._lookups[ipHash] <- banEntry;
		}
	}
	
	/**
	* Remove ban entry from list
	*/
	function RemoveBanEntry(banEntry) {		
		if (banEntry != null) {
			if ((banEntry.IPHash in this._lookups) && this._lookups[banEntry.IPHash].ClientID == banEntry.ClientID) {
				delete this._lookups[banEntry.IPHash];
			}					
			delete this._clients[banEntry.ClientID];
		}	
	}		
	
	/**
	* Return list of bans in list
	*/
	function GetBans() {
		return this._clients;
	}
}
 

class BanHelper { 
	static GameBanListTag = "BL_gamebanlist";
	static sBanList = null;
		
	static function GetGameBanList() {
		local banList = ::Cache.Get(BanHelper.GameBanListTag);		
		if (banList == null) {
			// create and store to cache
			banList = BanList();
			::Cache.StoreGame(BanHelper.GameBanListTag, banList);
		}
		return banList;			
	}	
	
	static function GetStaticBanList() {
		if (BanHelper.sBanList == null) {
			BanHelper.sBanList <- ::StaticBanList();
		}
		return BanHelper.sBanList;
	}	
	
	static function ProcessCheckBan(client) {
		local ipHash = ::SAIClient.GetAnonymizedAddress(client);
		
		// check game banlist
		local gameBanList = BanHelper.GetGameBanList();	
		local banEntry = gameBanList.GetBan(ipHash);
		
		if (banEntry != null) {
			if (::Log.IsDebug) {	
				::Log.Debug(format("\"%s\" is banned from this game.", 
					::SAIClient.GetName(client)
				));
			}	
			::BanHelper.NotifyBanned(client, banEntry);
			return true;			
		}	

		// check static banlist
		local staticBans = BanHelper.GetStaticBanList();
		local staticBanEntry = staticBans.GetBan(ipHash);
		
		if (staticBanEntry != null) {
			if (::Log.IsDebug) {	
				::Log.Debug(format("\"%s\" is banned by static list.", 
					::SAIClient.GetName(client)
				));
			}							
			return true;
		}						

		return false;		
	}
	
	static function NotifyBanned(client, banEntry) {
		// prepare message
		local sameIp = ::SAIClient.GetAnonymizedAddress(client) == banEntry.IPHash;
		
		local msg = format("[MOD] Client %s (%s) [%s] trying to join - banned as %s by %s at %s", 
						::SAIClient.GetName(client), ::SAIClient.GetAnonymizedAddress(client), sameIp ? "I" : "", banEntry.Name, banEntry.BannedBy, ::Utils.FormatDate(banEntry.Date));
				
		foreach(client, dummy in ::SAIClientList()) {
			if (::SAIClient.IsAdmin(client) || ::SAIClient.IsModerator(client)) {
				::SAIServer.SayClient(client, msg);
			}
		}	
	}	
	
	/**
	* Ban client from current game
	*/
	static function BanClientGame(client, bannedBy) {
		local gameBanList = BanHelper.GetGameBanList();		
		if (client > 1 && ::SAIClient.IsValid(client)) {
			gameBanList.AddBan(client, bannedBy);
			::SAIServer.Say(format("Client \"%s\" (%s) is banned from current game.", ::SAIClient.GetName(client), ::SAIClient.GetAnonymizedAddress(client)));
			::SAIServer.ConsoleCmd(format("kick %d", client));			
		}
	}
	
	/**
	* Unban client with iphash from current game
	*/
	static function UnbanClientGame(client) {
		local gameBanList = BanHelper.GetGameBanList();		
		local banEntry = gameBanList.GetBanEntry(client);		
		if (banEntry != null) {
			gameBanList.RemoveBanEntry(banEntry);
			::SAIServer.Say(format("Client \"%s\" (%s) unbanned from current game.", banEntry.Name, banEntry.IPHash));
		}		
	}		
}

