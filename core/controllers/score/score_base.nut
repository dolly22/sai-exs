/**
* Company score entry. Every score entry must be inherited from this class
*/
class CompanyScoreEntryBase {
	Company 		= ::SAICompany.OWNER_NONE;	// company index (0 based)
	CompanyName 	= null;						// company name (when score was computed)
	Score 			= 0;						// company achieved score
	HiscorePoints	= 0;						// points for hiscore (may be different from score)

	function constructor(company) {
		if (::SAICompany.IsValid(company)) {
			this.Company 	 = company;
			this.CompanyName = ::SAICompany.GetName(company);
		}
	}

	/**
	* Get score part for /score entry
	*/	
	function GetScoreTag() {
		return format("%d points", this.Score)
	}
	
	/**
	* Get tag for win game reporting
	*/
	function GetWinTag() {
		return GetScoreTag();
	}
	
	/**
	* Print score detail for this score entry
	*/
	function PrintScoreDetails(print_func) {
		print_func(
			format("Detailed score for company #%d - '%s':",
				this.Company + 1,
				this.CompanyName)
		);
	
		print_func(format("- Score  ... %.1f", this.Score));
		print_func(format("- Hiscore points  ... %.1f", this.HiscorePoints));	
	}
}

/** 
* Every company score must inherit from this class
*/
class CompanyScoreBase {
	Scores = [];	// sorted array of companies (from the best)
	
	scoreLastUpdated = null;	// last date the score was updated	

	function constructor() {
		Init();
	}

	/** 
	* Init score system
	*/
	function Init() {
		Scores = [];
		scoreLastUpdated = null;
	}
		
	/**
	** Function to update score table. Update only when necessary (not twice the same day)
	**/
	function UpdateScore() {
		local currentDate = ::AIDate.GetCurrentDate();
		
		// does it needs updating?
		if (this.scoreLastUpdated == null || this.scoreLastUpdated != currentDate) {
			this.scoreLastUpdated = currentDate;
			this.ComputeScore();
		}	
	}	
	
	/**
	* Compute company scores, you have to implement this
	*/
	function ComputeScore() {
		local companies = ::SAICompanyList();
		this.Scores = [];
		
		foreach(company, dummy in companies) {
			local companyScoreEntry = ComputeScoreCompany(company);
			if (companyScoreEntry != null) {
				this.Scores.append(companyScoreEntry);
			}			
		}
		
		// sort companies by performance
		this.Scores.sort(function(a, b) { return b.Score - a.Score})	
	}
	
	/** 
	* Compute score for single company
	*/
	function ComputeScoreCompany(company);
	
	/**
	* Get score entry for specified company, null if not found
	*/
	function GetCompanyScore(company) {
		foreach(i, scoreEntry in Scores) {
			if (scoreEntry.Company == company)
				return scoreEntry;
		}
		return null;	
	}
	
	/**
	* Get best company if it exists, returns null when threre is no best company
	*/
	function GetBestCompany() {
		if (this.Scores.len() > 0)
			return this.Scores[0];
		return null;	
	}
		
	/**
	* Print score details for specified company
	*/
	function PrintScoreDetail(print_func, company) {
		// find correct company
		foreach(idx, companyEntry in this.Scores) {
			if (companyEntry.Company == company) {
				// show details
				companyEntry.PrintScoreDetails(print_func);
				return;
			}
		}	
		print_func(format("No rating available for company '%s' yet.", ::SAICompany.GetName(company)));	
	}		
				
	/**
	* Display list of companies with computed rating values
	*/
	function PrintScores(print_func, show_all) {
			
		if (Scores.len() > 0) {
			local msg = "Company scores";
			if (Game.Goal != null)
				msg += " - "+ Game.Goal.GetStatus();
			
			local max_idx = Scores.len();
			if (!show_all) {
				max_idx = min(3, Scores.len());
				msg += " Three best companies displayed - use \'/score\' for full list, \'/score #x\' for company details."
			}		
			print_func(msg);
		
			// score for all companies
			for (local i=0; i < max_idx; i++) {
				local scoreEntry = Scores[i];				
				print_func(format("%d. %s (#%d %d) %s",
						i+1,
						scoreEntry.CompanyName,
						scoreEntry.Company + 1,
						::SAICompany.InauguratedYear(scoreEntry.Company),
						scoreEntry.GetScoreTag()
				));
			}	
		} else {
			if (show_all)
				print_func("No company scores available yet.");
		}			
	}		
		
}