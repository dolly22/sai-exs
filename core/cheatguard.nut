class CheatGuard {
	static UnloadsTag = "CG_Unloads";
	static TownsAbsPeopleTag = "CG_TownsAbsPeople";
	static TownsAbsHousesTag = "CG_TownsAbsHouses";
	static TownsRelativeTag  = "CG_TownsRelative";

	/**
	* Town destroying handling
	*/
	static function OnHouseDestroyed(company, city, housePopulation) {
		local influencedCompanies = 0;
		
		if (!::SAICompany.IsValid(company) || !AITown.IsValidTown(city))
			return;
		
		local companies = ::SAICompanyList();
		foreach(cmp, dummy in companies) {
			if (company == cmp) {
				// handle itself
				::SAIServer.SayCompany(company, 
					format("Your company just destroyed a house in %s and evicted %d people.",
						::AITown.GetName(city), housePopulation));
			} else if (::AITown.GetRating(city, cmp) != ::AITown.TOWN_RATING_NONE) {
				influencedCompanies++;
				::SAIServer.SayCompany(cmp, 
					format("%s just destroyed the house in %s, %d people evicted.", 
						::SAICompany.GetName(company), ::AITown.GetName(city), housePopulation));			
			}
		}
		
		local population = ::AITown.GetPopulation(city);		
		local relIncrement = floor(100 * 2.0 * housePopulation / (0.0 + population + housePopulation) * (1.0 + min(0.1 * influencedCompanies, 0.5)));

		// increment relative, absolute people and absolute houses		
		local townRelative = CompanyStorage.IncrementValue(company, CheatGuard.TownsRelativeTag, relIncrement);
		local townAbsolutePeople = CompanyStorage.IncrementValue(company, CheatGuard.TownsAbsPeopleTag, housePopulation);
		local townAbsoluteHouses = CompanyStorage.IncrementValue(company, CheatGuard.TownsAbsHousesTag, 1);		
		
		if (::Log.IsInfo()) {
			::Log.Info(format("Company #%d house rel: %d (+%d), ppl: %d (+%d), houses: %d",
				company+1, townRelative, relIncrement, townAbsolutePeople, housePopulation, townAbsoluteHouses));
		}		
		CheatGuard.HandleHouseDestroyed(company, townRelative, townAbsolutePeople, townAbsoluteHouses);		
	}

	/**
	* Handle house destroyed limits
	*/	
	static function HandleHouseDestroyed(company, townRelative, townAbsolutePeople, townAbsoluteHouses) {
		if (::SAICompany.IsServer(company))
			return;
		
		// handle suspend limits
		if (townRelative >= 100 || townAbsolutePeople >= 700 || townAbsoluteHouses >= 10) {
			// suspend company
			::SAIServer.Say(format("Company \"%s\" made the council of towns were angry because of destroying too many houses and it's operations were suspended for next 6 month.", ::SAICompany.GetName(company)));
			::CompanyControl.SuspendCompany(company, Utils.AdvanceDate(::AIDate.GetCurrentDate(), 0, 6), "destroying towns");
		} else if (townRelative >= 50 || townAbsolutePeople >= 400 || townAbsoluteHouses >= 5) {
			// issue warning
			::SAIServer.SayCompany(company, "Your company is far beyond the safe number or evicted people and destroyed houses, the city council is watching you closely.");
		}					
	}	
	
	/**
	* Callback to allow house destroying
	*/	
	static function OnHouseDestroying(client, tile1, tile2, count) {
		local company = ::SAIClient.GetCompany(client);
		if (::SAICompany.IsValid(company) && !::SAICompany.IsServer(company)) {
			local townAbsoluteHouses = CompanyStorage.GetValue(company, CheatGuard.TownsAbsHousesTag);
			if (townAbsoluteHouses == null)
				townAbsoluteHouses = 0;
								
			if ((townAbsoluteHouses + count) > 3) {
				::SAIServer.SayClient(client, "You are over you house destroy limit, wait for new month.");
				return -1;
			}
		}
		return 0;
	}	

	/**
	* Single tile station unload handling
	*/
	static function OnUnloadingExploit(company) {	
		local unloads = CompanyStorage.IncrementValue(company, CheatGuard.UnloadsTag, 1);
		
		if (::Log.IsInfo()) {
			::Log.Info(format("Company #%d unloads: %d", company+1, unloads));
		}		
							
		if (unloads >= 4) {
			// too many unloads, suspend company for 6 months
			::SAIServer.Say(format("Operations of \"%s\" have been suspended for next 4 months for strange unloading practices.", ::SAICompany.GetName(company)));
			::CompanyControl.SuspendCompany(company, Utils.AdvanceDate(::AIDate.GetCurrentDate(), 0, 4), "single tile station unload");			
		} else {
			// just issue a warning
			::SAIServer.SayCompany(company, "It seems you are not unloading your trains the proper way, better for you to stop this.");			
		}							
	}
	
	/**
	* Call every month to expire some timers
	*/
	static function OnMonthlyLoop() {
		local companies = ::SAICompanyList();
		foreach(company, dummy in companies) {
			CheatGuard.ExpireUnloads(company);
			CheatGuard.ExpireBuildingDestroy(company);		
		}		
	}	
	
	/**
	* Called when expiring unload cheats
	*/
	static function ExpireUnloads(company) {
		CompanyStorage.DecrementValue(company, CheatGuard.UnloadsTag, 2);				
	}
	
	/**
	* Called when expiring town building destroy
	*/
	static function ExpireBuildingDestroy(company) {
		CompanyStorage.DecrementValue(company, CheatGuard.TownsRelativeTag, 20);	
		CompanyStorage.DecrementValue(company, CheatGuard.TownsAbsPeopleTag, 150);		
		CompanyStorage.DecrementValue(company, CheatGuard.TownsAbsHousesTag, 2);				
	}
}

// delegate callbacks
CallbackManager.RegisterCallback("OnMonthlyLoop", CheatGuard.OnMonthlyLoop);
CallbackManager.RegisterCallback("OnUnloadingExploit", CheatGuard.OnUnloadingExploit);
CallbackManager.RegisterCallback("OnHouseDestroyed", CheatGuard.OnHouseDestroyed);
CallbackManager.RegisterCallback("OnHouseDestroying", CheatGuard.OnHouseDestroying);


