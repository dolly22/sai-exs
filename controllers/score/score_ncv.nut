class NCVScoreEntry extends CompanyScoreEntryBase {
	function GetScoreTag() {
		if (this.Score > 1000) {
			if (this.HiscorePoints > 0)
				return format("  %s  (%d score points)", Utils.FormatCompanyValue(this.Score), this.HiscorePoints);
			else
				return format("  %s ", Utils.FormatCompanyValue(this.Score));
		}
		return "0.0k";
	}
	
	function GetWinTag() {
		return format("%d hiscore points", this.HiscorePoints);
	}
	
	function PrintScoreDetails(print_func) {
		print_func(
			format("Detailed score for company #%d - '%s':",
				this.Company + 1,
				this.CompanyName)
		);
	
		print_func(format("- Company value   ... %s GBP", Utils.FormatCompanyValue(this.Score)));
		print_func(format("- Hiscore points  ... %d points", this.HiscorePoints));	
	}	
}

/**
* NCV based score implementation
*/
class NCVCompanyScore extends CompanyScoreBase {
	static HiscoreLimit = 30.0;		// minimal % of goal value to compute some hiscore points
	HiscoreModifier = 1.0;			// hiscore percentage modifier (based on map values and difficulty?)	
	
	/**
	* Compute score for all companies
	*/
	function ComputeScore() {
		::CompanyScoreBase.ComputeScore();
		
		//now we have sorted array of score entries
		ComputeHiscorePoints(Game.Goal.GoalValue);
	}

	/**
	* Compute score for single company
	*/
	function ComputeScoreCompany(company) {
		local companyScore = NCVScoreEntry(company);		
		companyScore.Score = ::SAICompany.CurrentNCV(company)
		return companyScore;	
	}
	
	
	function ComputeHiscorePoints(goal_value) {
		local debug_score = false;
		
		// base algorithm coeficients
		local dividend_power_coef  = 0.5;	 				 // power argument pro delenec
		local dividend_normal_coef = 20;  					 // koeficient pro normalizaci delence
		local dividend_crossover   = 4000000;                // prechod z linearni charakteristiky na exponencialni
	
		local divider_power_coef   = 1 / ((1 + sqrt(5)) / 2.0);  // golden ratio koeficiet
		local divider_bonus_limit  = 1960;					 // rok pro nulovou procentni penalizaci
		local divider_normal_coef  = 100;					 // normalizace pro penalizaci za leta
		local divider_crossover    = 4;                      // crossover pro prechod linearni a exponencialni charakteristiky
		
		local points_normalizer    = 1.2;
		local hiscore_modifier 	   = HiscoreModifier + 0.0;	 // convert double	
		
		if (Log.IsDebug() && debug_score) {
			Log.Debug(format("Score rating debug - cv limit: %d%%", NCVCompanyScore.HiscoreLimit));
			Log.Debug(format("Dividend coefs - power: %.2f, normalization: %.2f", dividend_power_coef,dividend_normal_coef));
			Log.Debug(format("Divider coefs - power: %.2f, year_zero_limit: %d, year_normalization: %.2f, crossover: %d", divider_power_coef, divider_bonus_limit,divider_normal_coef, divider_crossover));	
		}
		
		local currentDate = ::AIDate.GetCurrentDate();
		
		local current_game_year = ::AIDate.GetYear(currentDate);
		local current_game_month = ::AIDate.GetMonth(currentDate);
		
		local company_inter_points = {};
		local total_points_sum = 0;		
		
		foreach(i, companyEntry in Scores) {
			// count anything above 100000 for some hiscore points bonuses
			if (companyEntry.Score >= 100000) {
				// get real cv value (never above goal value)
	    		local normalizedcv = min(companyEntry.Score, goal_value);
	    		
	    		local dividend_base = normalizedcv / (dividend_crossover / 100.0)
	    		if (normalizedcv >= dividend_crossover) {
	    	    	// already at exponential
	    	    	dividend_base =
							pow(max(dividend_normal_coef * (normalizedcv / 10000.0 - 300.0), 1), dividend_power_coef)
							- pow(dividend_normal_coef * (dividend_crossover / 10000.0 - 300), dividend_power_coef) + 100;
	    		}
	    			    		
	    		local companyInaugurated = ::SAICompany.InauguratedYear(companyEntry.Company);
	        	local divider_yearval = current_game_year - companyInaugurated + current_game_month / 12.0;
	        	local divider_base    = 1;   // constant characteristik
	        	
				// are we already in exponential
		        if (divider_yearval >= divider_crossover) {
		            divider_base =
								pow(divider_yearval + divider_normal_coef, divider_power_coef)
								- pow(divider_crossover + divider_normal_coef, divider_power_coef) + 1;
		        }
		        local divider_bonus	  = (companyInaugurated - divider_bonus_limit) / 100.0 / 2.0;
		        local divider_norm	  = divider_base * (1.0 + max(0.0, divider_bonus)); 
		        
		        // base company points
				local points_base	    = dividend_base / divider_norm;
				local points_normalized = points_base * points_normalizer;
	
				if (Log.IsDebug() && debug_score) {
					Log.Debug(
						format("#%d. - normcv: %s, points_normalized: %.2f (dividend_base: %.2f, divider_yearval: %.2f, divider_base: %.2f, divider_year_penal: %.2f, divider_norm: %.2f, points_base: %.2f)",
						companyEntry.Company+1, Utils.FormatKMValue(normalizedcv), points_normalized, dividend_base, divider_yearval, divider_base, divider_bonus, divider_norm, points_base)
					);
				}
				
				// store for further use
				company_inter_points[companyEntry.Company] <- points_normalized;
				total_points_sum = total_points_sum + points_normalized;     
			}
		}
		

		// point distribution coeficiets	
		local rank_bonus_base  = 30; // 30% bonus for first place (half for every other place...)
		local comp_bonus_rate  = 10; // % rate of competition points bonus
		local comp_bonus_limit = 30; // max % limit of competition points
	
		local bonus_points_remaining = total_points_sum;
	
		if (Log.IsDebug() && debug_score) {
			Log.Debug(
				format("Points distribution - rank_bonus_base: %.2f, comp_bonus_rate: %.2f, comp_bonus_limit: %.2f", 
				rank_bonus_base, comp_bonus_rate, comp_bonus_limit)
			);
		}		
		
		// points remaining for competition bonuses
		local competition_points_remaining = total_points_sum;
		local points_last_norm_limit = null;
		local rank_bonus = rank_bonus_base;		
		
		// is there something to distribute
		if (total_points_sum > 0) {
			foreach(i, companyEntry in Scores) {
		    	// only award companies with enough company value
		    	if (companyEntry.Score >= (goal_value * (NCVCompanyScore.HiscoreLimit / 100.0))) {	    
			    	if (companyEntry.Company in company_inter_points) { 
			    		local company_inter_points = company_inter_points[companyEntry.Company];
			    		
						competition_points_remaining = competition_points_remaining - company_inter_points;
						
						// compute competition bonuses
						local points_competition_bonus = comp_bonus_rate / 100.0 * competition_points_remaining;
						local points_competition_norm  = min(comp_bonus_rate / 100.0 * competition_points_remaining, points_competition_bonus);
						
						local points_withcomp 		= company_inter_points + points_competition_norm;
						local points_withcomp_norm  = points_withcomp;
							    					    	
						// normalize points at previous max
						if (points_last_norm_limit != null) {															   				    	    		
				    		points_withcomp_norm   = min(points_last_norm_limit, points_withcomp_norm);
						}
				    	points_last_norm_limit = points_withcomp_norm;
				    	
				    	// apply place bonuses
				    	local points_place_bonus = points_withcomp_norm * (100 + rank_bonus) / 100.0;
				    	
				    	// compute total final points
				    	local points_final = floor(points_place_bonus * hiscore_modifier);
				    	companyEntry.HiscorePoints = points_final;
				    	
				    	// debug prints
						if (Log.IsDebug() && debug_score) {
							Log.Debug(
								format("#%d. - final points: %d, hiscore_mod: %.2f, points_competition_norm: %.2f, place_bonus: %.2f%% (comp_bonus_total: %.2f)", 
								companyEntry.Company+1, points_final, hiscore_modifier, points_competition_norm, rank_bonus, points_competition_bonus)
							);	    		
						}	    	
				    	rank_bonus = rank_bonus / 2.0;
			    	}
		    	}
			}	
		}
	}
	
}