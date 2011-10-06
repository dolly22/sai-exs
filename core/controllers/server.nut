require("goal/goal_base.nut")
require("score/score_base.nut")

class ServerController extends SAIController {
	Goal = null;			// game goal controller...
	Score = null;			// game company rating type...
	WinRestart = null;		// restart game at this date
	WinCompany = null;		// game winner (game controller specific pointer), if null there is not winner yet
	
	StartPause	= 0;		// weeks to pause game on start
	RestartDelay = 3;		// how many month to wait for restart after the game has ended
	HiscoreLimit = 10;		// minimal points to award hiscore
	
	TranscriptDir = "";		// we will be saving transcript if this directory is not empty
	
	RecycleProcess = false; 	// recycle openttd process sometimes?
	RecycleGamesPlayed = 0;		// games played from last recycle
	
	_startPausedWeeks = 0;
	_lastLeader	= null;
	
	privateIndustries = null;	// private industries precomputed collision coordinates
			
	function constructor()
	{
		// setup global shared controller pointer
		::Game <- this;		
		
		// initialize default callback flags
		::SAIServer.SetCallbackFlags(::SAIServer.GetCallbackFlags() | ::SAIServer.BUILD_STATION | ::SAIServer.BUILD_UNMOVABLES);	
	}			
	
	function Start()
	{
		Init();
		
		// initialize from config file		
		if ("ConfigInit" in ::ServerController) {
			::ServerController.ConfigInit(this);
		}			
	}	
							
	function OnServerNewGame(switch_mode) {
		datadb.UpdateCompanyStats();
				
		WinCompany = null;
		WinRestart = null;
		Init();
		
		// increase recycle count		
		::Log.Info(format("Games since last restart: %d (recycle: %s)", RecycleGamesPlayed, RecycleProcess.tostring()));
		RecycleGamesPlayed++;
						
		privateIndustries = null;
		_startPausedWeeks = this.StartPause;
		if (_startPausedWeeks > 0) {
			::SAIServer.ConsoleCmd("pause");
		}
		
		if (this.TranscriptDir.len() > 0) {
			local transcriptFile = this.TranscriptDir + "transcript.log";

			// make sure to close previous script...			
			::Log.Info(format("Copying console output to \"%s\"", transcriptFile));
			::SAIServer.ConsoleCmd("script");
			::SAIServer.ConsoleCmd(format("script %s", transcriptFile));								
		}	
		
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnServerNewGame")) {
			callback(switch_mode);
		}	
		
		// notify irc and other game servers
		::IrcServer.NotifyGameStarted();
	}
	
	function Init() {
		_lastLeader = null;
	}
	
	// called when scripting subsystem is initializing
	function OnBeforeFirstStart() {
	}
	
	function OnServerStarting()
	{
		//print("OnServerStarting");
	}
	
	function OnServerStarted()
	{
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnServerStarted")) {
			callback(company);
		}			
	}
	
	function OnClientJoining(client)
	{
		if (::Log.IsDebug) {	
			::Log.Debug(format("\"%s\" joining - %s", 
				::SAIClient.GetName(client),
				::SAIClient.GetAddress(client)
			));
		}
		// check for client ban
		if (::BanHelper.ProcessCheckBan(client)) {
			// return non zero as return code...
			return 12; // kick from server
		}		
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnClientJoining")) {
			callback(company);
		}	
	}	
	
	function OnClientJoined(client)
	{
		::IrcServer.NotifyClientJoined(client);	
	}
	
	function OnClientLeft(client)
	{
		::IrcServer.NotifyClientLeft(client);	
	}
	
	function OnYearlyLoop() {
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnYearlyLoop")) {
			callback();
		}	
		// show hiscore overview
		if (!this.HasEnded()) {
			Hiscore.PrintOverview(function(msg) { ::SAIServer.SayEx(false, msg); } );
		}			
	}	
	
	/**
	* Called by server automatically every month
	*/
	function OnMonthlyLoop() {			
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnMonthlyLoop")) {
			callback();
		}						
		local current_date = ::AIDate.GetCurrentDate();		
		
		// handle game restart...
		if (typeof(WinRestart) == "integer" && current_date >= WinRestart)		
			RestartGame();
						
		CheckGoalFinished();
		 			
		// game not ended yet and we are computing some sort of score
		if (!this.HasEnded() && Score != null) {
			Score.UpdateScore();	
			if (Log.IsInfo()) {
				// log best company every month
				local best_company = Score.GetBestCompany();
				if (best_company != null) {
					Log.Info(format("Best company \"%s\" - %s", 
						best_company.CompanyName,
						best_company.GetScoreTag()
					));
				}
			}			
			local bestCompany = Score.GetBestCompany();			
			
			// show score sometimes (every second(third) month in quarter)
			if (::AIDate.GetMonth(current_date) % 4 == 2) {
				// dont print the scores to irc, instead use shorter !info version
				Score.PrintScores(function(msg) { ::SAIServer.SayEx(false, msg); } , false);
				::SAIIrc.Notice(::IrcServer.GetServerStatus());
					
			} else {
				// show lead changes if needed				
				if (bestCompany != null && bestCompany.Score > 0 && _lastLeader != null) {
					if (bestCompany.Company != _lastLeader.Company) {
						// broadcast lead change and set new best
						::SAIServer.Say(format("\"%s\" is now leading this game instead of \"%s\".", bestCompany.CompanyName, _lastLeader.CompanyName));
						_lastLeader = bestCompany;
					}
				}
			}
			if (bestCompany != null)
				_lastLeader = bestCompany;				
		}	
		
		// report problematic company names
		ReportProblematicCompanyNames();		
	}
	
	/**
	** Check for the goal is finished
	**/
	function CheckGoalFinished() {
		local current_date = ::AIDate.GetCurrentDate();	
		
		// check for goal end (only do not repeat multiple times...
		if (!this.HasEnded() && Goal != null) {
			Score.UpdateScore();
			if (Goal.IsCompleted()) {
				this.WinRestart = Utils.AdvanceDate(current_date, 0, RestartDelay);
				if (Score != null)			
					this.WinCompany = Score.GetBestCompany(); 
			
				AwardHiscorePoints();
				RestartGameReport();
				::IrcServer.NotifyGameEnded();					
			} 
		}	
	}
		
	/**
	* Called by server automatically every week
	*/
	function OnWeeklyLoop() {
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnWeeklyLoop")) {
			callback();
		}		
		// handle game restart reporting
		if (this.HasEnded())
			RestartGameReport();	
			
		// update private industry reservations (when company deleted...)
		UpdateIndustryReservations();
	}
	
	function OnPausedWeeklyLoop() {
		if (_startPausedWeeks > 0) {
			_startPausedWeeks--;
			if (_startPausedWeeks > 0) {
				::SAIServer.SayEx(false, "The game is paused for next "+ _startPausedWeeks +" weeks, waiting for other players to join.");
			} else {
				::SAIServer.Say("Game unpaused, enjoy the game!");
				::SAIServer.ConsoleCmd("unpause");
			}
		} else {
			::SAIServer.SayEx(false, "The server is paused now.");
		}
	}
	
	function OnCompanyDeleting(company) {
		// clean up all protected signs
		local signs = ::SAISignList();
		foreach(sign, dummy in signs) {
			if (::SAISign.IsProtected(sign) && ::SAISign.GetOwner(sign) == company) {
				// remove this sign
				::SAISign.RemoveSign(sign);
			}
		}
		
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnCompanyDeleting")) {
			callback(company);
		}		
	}
	
	function OnCompanyDeleted(company) {
		// dispatch all callbacks
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnCompanyDeleted")) {
			callback(company);
		}		
	}
	
	function OnTrainSellForbid(client) {
		::SAIServer.SayClient(client, "We are sorry, but we can't buy this train from you unless it's at least 1 year old. It has already made some profit, you can use autoreplace.")
	}
	
	function OnHouseDestroying(client, tile1, tile2, houses) {
		local result = 0;
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnHouseDestroying")) {
			result += callback(client, tile1, tile2, houses);
		}		
		return result;
	}		
	
	function OnHouseDestroyed(company, city, housePopulation) {
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnHouseDestroyed")) {
			callback(company, city, housePopulation);
		}			
	}
		
	function OnUnloadingExploit(company) {
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnUnloadingExploit")) {
			callback(company);
		}		
	}	
	
	/**
	* Real game restart handler
	*/
	function RestartGame(restart_server) {
		::SAIServer.Say(format("The game is restarting (restart_server: %s)...", restart_server.tostring()));
		::Utils.DisconnectPlayers();

		// cleanup database on every server restart
		if (restart_server)
			datadb.Cleanup();

		datadb.Persist();
					
		local tag = time().tostring();
				
		// save game for debug purposes
		::SAIServer.ConsoleCmd(format("save gameend_%s", tag));
		
		// save db file		
		local dbFile = datadb.DataVolume + datadb.DataPath;
		system(format("copy %s save\\openttd_%s.db3", dbFile, tag))
		
		if (this.TranscriptDir.len() > 0) {
			// stop logging and save game and log for next testing...
			local transcriptFile = this.TranscriptDir + "transcript.log";		

			::Log.Info("Saving transcript file");
			::SAIServer.ConsoleCmd("script");			
			system(format("copy %s save\\transcript_%s.log", transcriptFile, tag));
			system(format("del %s", transcriptFile));
		}		
		
		if (RecycleProcess && restart_server) {			
			Log.Info("OpenTTD process will be recycled.");
			::SAIServer.ConsoleCmd("quit");
		} else {
			::SAIServer.ConsoleCmd("newgame");
		}
	}	
	
	/** 
	* Report the game will restart shortly
	* Override in your controller class if you want detailed winner reporting
	*/
	function RestartGameReport() {
		if (this.HasWinner()) {		
			::SAIServer.SayEx(false,
				format("This game has ended, '%s' is the winner - %s. New game will start at %s, you will get disconnected when the game restarts.",
					this.WinCompany.CompanyName,
					this.WinCompany.GetWinTag(),
					::Utils.FormatDate(this.WinRestart)
				));		
		} else {
			::SAIServer.SayEx(false,
				format("This game has ended. New game will start at %s, you will get disconnected when the game restarts.",
					::Utils.FormatDate(this.WinRestart)
				));	
		}				
	}
		
	/**
	* Award hiscore points for companies
	*/
	function AwardHiscorePoints() {
		if (this.Score != null) {
			local wasAwarded = false;
			
			// only award hiscore points when we have active scoring system
			foreach(company, dummy in ::SAICompanyList()) {
				AwardHiscoreCompany(company);
				wasAwarded = true;
			}
			
			// update statistics so users can see new values
			if (wasAwarded) {
				datadb.UpdateCompanyStats();
				Cache.Invalidate(Hiscore.OverviewCT);
			}
		}
	}
		
	/**
	* Award every company with positive hiscore points, override to make hiscore decitions
	*/
	function AwardHiscoreCompany(company) {
		if (this.Score != null) {
			local scoreEntry = Score.GetCompanyScore(company);
			if (scoreEntry != null && scoreEntry.HiscorePoints > ServerController.HiscoreLimit) {
				if (Utils.ValidateCompanyName(::SAICompany.GetName(company)) == null) {
					Hiscore.AwardPoints(scoreEntry.CompanyName, scoreEntry.HiscorePoints);
					::SAIServer.Say(format("\'%s\' was awarded %d hiscore points.", scoreEntry.CompanyName, scoreEntry.HiscorePoints));
				} else {
					::SAIServer.SayCompany(scoreEntry.Company, format("We are sorry, but you were not awarded your hiscore points, because there were some problems with your company name"));
				}
			}
		}
	}				
		
	/**
	* Check for WinRestart variable, return true if it's not null, falses otherwise
	*/
	function HasEnded() {
		return (this.WinRestart != null);
	}

	/**
	* Check for WinCompany variable, return true if it's not null, false otherwise
	*/
	function HasWinner() {
		return (this.WinCompany != null);
	}
	
	/** 
	* Report to companies with problematic names to rename their company
	*/
	function ReportProblematicCompanyNames() {
		local companies = ::SAICompanyList();
		
		foreach(company, dummy in companies) {
			local valErr = Utils.ValidateCompanyName(::SAICompany.GetName(company));
			if (valErr != null) {
				local probStr = "";
				
				::SAIServer.SayCompany(company, format("There is a problem with your company name (%s). Please rename your company to be awarded hiscore points.", 
					Utils.ArrayToString(valErr, ", ")));				
			}
		}
	}	
	
	// Private industry handling...
	
	/**
	** Get reservations of private industries
	**/
	function GetIndustryReservations() {
		if (this.privateIndustries == null)
			UpdateIndustryReservations();
		return this.privateIndustries;			
	}	
	
	/**
	** Invalidate precomputed industry reservations
	**/
	function InvalidateIndustryReservations() {
		this.privateIndustries = null;
	}	
	
	/**
	** Update private industry reservations
	**/
	function UpdateIndustryReservations() {
		this.privateIndustries = ComputeIndustryReservations();
	}	
	
	/**
	** Compute private industry reservations table
	**/
	function ComputeIndustryReservations() {
		local privateIndustries = {};		
		
		//print("Industry reservations update");
		local industries = ::SAIIndustryList_PlayerFounded();
		foreach(industry, dummy in industries) {
			local industryType   = ::AIIndustry.GetIndustryType(industry);			
			local acceptedCargos = ::AIIndustryType.GetAcceptedCargo(industryType).Count();
			local producedCargos = ::AIIndustryType.GetProducedCargo(industryType).Count();
			
			if (acceptedCargos > 0 && producedCargos > 0) {
				local indLocation = ::AIIndustry.GetLocation(industry);
				local indx = ::AIMap.GetTileX(indLocation);
				local indy = ::AIMap.GetTileY(indLocation);
				local company = ::SAIIndustry.GetFounder(industry);
				
				privateIndustries[industry] <- {
					ABLx = indx,
					ABLy = indy,
					ATRx = indx + ::SAIIndustry.GetWidth(industry) - 1,
					ATRy = indy + ::SAIIndustry.GetHeight(industry) - 1,
					Company = company					
				};					
				
				/*
				print(format("Private industry reservation %d [%d,%d] [%d,%d]",
					industry,
					privateIndustries[industry].ABLx, 
					privateIndustries[industry].ABLy,
					privateIndustries[industry].ATRx,
					privateIndustries[industry].ATRy,
					privateIndustries[industry].Company
				));		
				*/	
			}		
		}		
		return privateIndustries;
	}	
	

	/**
	** Check private industries for allowed area
	**/
	function CheckAllowedPrivIndustryArea(client, tile1, tile2) 
	{	
		local coverage = 5;		
		local rblx = max(0, ::AIMap.GetTileX(tile1) - coverage);
		local rbly = max(0, ::AIMap.GetTileY(tile1) - coverage);
		local rtrx = min(::AIMap.GetMapSizeX(), ::AIMap.GetTileX(tile2) + coverage);
		local rtry = min(::AIMap.GetMapSizeY(), ::AIMap.GetTileY(tile2) + coverage);	
		
		foreach(ind, indData in GetIndustryReservations()) {
			if (Utils.TestRectCollision(indData.ABLx, indData.ABLy, indData.ATRx, indData.ATRy, rblx, rbly, rtrx, rtry)) {
				// area is colliding, check for owner				
				if (!IsActionAroundIndustryAllowed(client, indData))
					return false;
			}
		}
		return true;			
	}
	
	/**
	** Check if action is allowed on this private funded industry
	**/
	function IsActionAroundIndustryAllowed(client, indData) {	
		// allow action for company claiming this town or if it has been deleted
		if (::SAIClient.GetCompany(client) == indData.Company || !::SAICompany.IsValid(indData.Company))
			return true;
		
		// todo: friendly companies		
		local companyName = ::AICompany.GetName(indData.Company);				
		::SAIServer.SayClient(client, 
			format("You are operating on private property of \"%s\", station cannot be build this close.", 
				companyName));				
		return false;
	}		
	
	/**
	** Called when player tryies to build the industry
	**/
	function OnBuildingIndustry(client, tile, industrySpec) {
		local acceptedCargos = ::AIIndustryType.GetAcceptedCargo(industrySpec).Count();
		local producedCargos = ::AIIndustryType.GetProducedCargo(industrySpec).Count();
		local company = ::SAIClient.GetCompany(client);
						
		// all raw industries (and those not accepting anything other)
		if (::AIIndustryType.IsRawIndustry(industrySpec) || acceptedCargos == 0 || producedCargos == 0)
			return 0;
										
		// todo: industry size by industrySpec		
		local stations = ::SAITile.GetAmountOfCompetitorStationsAround(tile, 4, 4, company);		
		if (stations > 0) {
			::SAIServer.SayClient(client, format("There are already some competitor's stations around, find a suitable free spot."));
			return 1;
		}		
		local companyName = ::SAICompany.GetName(company);
		
		// build marker sign
		local signText = "Funded: "+ companyName;
		if (signText.len() >= 31) {
			// try only company name
			signText = companyName;				
			if (signText.len() >= 31) {
				// should never happen
				signText = "Funded: Company #"+ company+1;
			}
		}	
		// relative sign location...
		local locx = ::AIMap.GetTileX(tile) + 1;
		local locy = ::AIMap.GetTileY(tile) + 1;
		local signLocation = ::AIMap.GetTileIndex(locx, locy);
		
		::SAISign.BuildSignCompany(company, signLocation, 20, company, signText);	
		
		// notify other users...
		::SAIServer.Say(format("\"%s\" just funded it's private %s near %s.", 
			companyName,
			::AIIndustryType.GetName(industrySpec),
			::AITown.GetName(::AITile.GetClosestTown(tile))
		));				
		InvalidateIndustryReservations();		
		return 0;		
	} 
	
	/**
	** Handle railroad station building (with private industries in mind)
	**/
	function OnRailroadStationBuilding(client, tile1, tile2) {			
		// handle industry reservations
		//print(format("Privind test rail station coverage [%d,%d] [%d,%d]", rblx, rbly, rtrx, rtry));		
		if (!CheckAllowedPrivIndustryArea(client, tile1, tile2))
			return 1; 			
		return 0;
	}	
	
	/**
	** Handle road stop building (with private industries in mind)
	**/
	function OnRoadStopBuilding(client, tile) {	
		// handle industry reservations
		//print(format("Privind test roadstop coverage [%d,%d] [%d,%d]", rblx, rbly, rtrx, rtry));
		if (!CheckAllowedPrivIndustryArea(client, tile, tile))
			return 1; 			
		return 0;
	}	
	
	/**
	** Handle dock building (with private industries in mind)
	**/
	function OnDockBuilding(client, tile) {		
		// handle industry reservations
		if (!CheckAllowedPrivIndustryArea(client, tile, tile))
			return 1; 			
		return 0;		
	}	
	
	/**
	** Handle airport building callback
	**/
	function OnAirportBuilding(client, tile1) {
		// disable airport building alltogether		
		return 1;
	}	
	
	/**
	** Handle sign building callback
	**/
	function OnSignBuilding(company, client, tile) {		
		if (::SAITile.IsIndustryTile(tile)) {
			// maybe handle industry reservation?
			if (HandleIndustryReservation(company, client, tile))
				return 1;			
		}
		return 0;
	}
	
	/**
	** Handle sign building
	**/
	function OnSignBuild(company, signid, data1, data2, text) {
		switch(data1) {
			case 20:	// private industry build
				::SAISign.SetProtected(signid, true);			
				break;		
		}	
		foreach(dummy, callback in CallbackManager.GetCallbacks("OnSignBuild")) {
			callback(company, signid, data1, data2, text);
		}							
	}		
		
	function HandleIndustryReservation(company, client, tile) {
			
	}	
}

// register client command processing
ServerController.OnClientCommand <- CCManager.ProcessClientCommand;
ServerController.OnIrcCommand <- IRCCManager.ProcessIrcCommand;
