// some constants
const HiscorePerpage = 10;
const HiscoreMaxPage = 20;

class Hiscore {
	static OverviewCT = "HiscoreOverview";	// hiscore overview cache tag

	/**
	* Award hiscore points to company
	*/
	static function AwardPoints(companyName, hiscorePoints) {
		datadb.StoreCompanyWin(companyName, hiscorePoints);	
	}

	/**
	* Print hiscore overview
	*/
	static function PrintOverview(print_func) {
		local text_rows;
		
		if (!Cache.HasKey(Hiscore.OverviewCT)) {
			// generate cache
			text_rows = [];
			Hiscore.GenerateOverview(
				function(msg) : (text_rows) { text_rows.append(msg); }
			);
			Cache.StoreGame(Hiscore.OverviewCT, text_rows);			
		} else {
			text_rows = Cache.Get(Hiscore.OverviewCT);
		}
		
		if (text_rows != null)
			foreach(i, msg in text_rows) {
				print_func(msg);
			}	
	}
		
	/**
	* Generate hiscore overview for cache...
	*/
	static function GenerateOverview(print_func) {
		print_func("Company League Table, use \'/hshelp\' for hiscore commands.")
		
		local res_arr = datadb.GetBestCompaniesTotalPoints(3, 0);
	
		if (res_arr.len() == 0)
			print_func("- There are no companies rated by total earned points yet");
		else
			print_func("--== Top 3 companies by earned points ==--");	
			
		foreach(i, row in res_arr) {
			print_func(format("%d. \'%s\' (%dx rated)  %d points", i+1, row.name, row.total_games, floor(row.total_points)));	
		}	
		
		local res_arr = datadb.GetBestCompaniesWeekPoints(3, 0);	
		if (res_arr.len() == 0)
			print_func("- There are no companies rated in last 7 days yet");
		else
			print_func("--== Top 3 companies by earned points in last 7 days ==--");		
	
		
		foreach(i, row in res_arr) {
			print_func(format("%d. %s (%dx rated)  %d points", i+1, row.name, row.week_games, floor(row.week_points)));	
		}
		
		local res_arr = datadb.GetBestCompaniesBestGames(3, 0);	
		if (res_arr.len() == 0)
			print_func("- There are no companies rated by best games yet");
		else
			print_func("--== Top 3 companies by best awarded games ==--");		
		
		foreach(i, row in res_arr) {
			print_func(format("%d. %s  %d points", i+1, row.name, floor(row.best_score)));	
		}
	}	
	
	/**
	* Print company last games
	*/
	static function PrintLastGamesCompany(print_func, company_name, page)
	{
		local offset = (Utils.GetIntegerRange(page, 1, HiscoreMaxPage) - 1) *  HiscorePerpage;
		local limit  = HiscorePerpage;
		
		local company = datadb.RetrieveCompany(company_name);
		if (company != null) {
			local res_arr = datadb.GetLastGamesCompany(company, limit, offset);
			local idx = offset + 1;
		
			print_func(format("Company \'%s\' last games - Page #%d", company_name, page))
			
			if (res_arr.len() == 0)
				print_func("- No rated games");
			
			foreach(i, row in res_arr) {
				print_func(format("%d. played on %s and scored %d points (%d for total score).", idx, row.date, row.points, row.points_decayed));			
				idx++;		
			}		
		} else {
			print_func(format("No last games for company \'%s\'", company_name));
		}
	}
	
	/**
	* Print company best games
	*/
	static function PrintBestGamesCompany(print_func, company_name)
	{
		local company = datadb.RetrieveCompany(company_name);
		if (company != null) {
			local res_arr = datadb.GetBestGamesCompany(company);
			local total_points = 0;
			local idx = 1;
				
			print_func(format("Company \'%s\' best games", company_name))
								
			if (res_arr.len() == 0)
				print_func("- No rated games");
			
			foreach(i, row in res_arr) {
				print_func(format("%d. played on %s and scored %d points.", idx, row.date, row.points));
				total_points += row.points;		
				idx++;		
			}
			
			if (idx <= 5) {
				print_func("- Not enough rated games in last 100 days yet (min 5)");
			} else if (total_points > 0) {
				print_func(format("- Averages %d points in it's best games", floor(total_points / (idx - 1))))				
			}
								
		} else {
			print_func(format("No best games for company \'%s\'", company_name));
		}
	}	
				
	/**
	* Print company ranking information / statistics
	*/
	static function PrintFullCompanyRanking(print_func, company_name)
	{
		local companyRanking = datadb.GetCompanyRanking(company_name);
		if (companyRanking == null) {
			print_func(format("Company \'%s\' not found.", company_name))
			return;
		}
				
		print_func(format("Company \'%s\' rankings: ", company_name))
		
		if (companyRanking != null && companyRanking.rank_total > 0 && companyRanking.points_total > 0)
			print_func(format("- #%d - (%d points) by total Earned Points - see /hstotal %d", companyRanking.rank_total, companyRanking.points_total, Utils.GetPage(companyRanking.rank_total, HiscorePerpage)));
		else
		    print_func("- Not ranked by total Earned Points yet.");
		
		if (companyRanking != null && companyRanking.rank_week > 0 && companyRanking.points_week > 0)
			print_func(format("- #%d - (%d points) by Points Earned this week (last 7 days) - see /hsweek %d", companyRanking.rank_week, companyRanking.points_week, Utils.GetPage(companyRanking.rank_week, HiscorePerpage)));
		else
		    print_func("- Not ranked by Points Earned this week yet.");
	
		if (companyRanking != null && companyRanking.rank_best_games > 0 && companyRanking.points_best_games > 0)
			print_func(format("- #%d - (%d points) by Top Awarded Games - see /hsgame %d", companyRanking.rank_best_games, companyRanking.points_best_games, Utils.GetPage(companyRanking.rank_best_games, HiscorePerpage)));
		else
		    print_func("- Not ranked by Top Awarded Games yet.");
	}		
	
	/**
	* Print company hiscore table - by total points
	*/
	static function PrintRankingTotalPoints(print_func, page)
	{
		local offset = (Utils.GetIntegerRange(page, 1, HiscoreMaxPage) - 1) *  HiscorePerpage;
		local limit  = HiscorePerpage;
		
		local res_arr = datadb.GetBestCompaniesTotalPoints(limit, offset);
		local idx = offset + 1;
	
		print_func(format("Best rated companies by total Earned Points - Page #%d", page));	
		
		if (res_arr.len() == 0)
			print_func("- No companies");
		
		foreach(i, row in res_arr) {
			print_func(format("%d. %s (%dx rated)  %d points", idx, row.name, row.total_games, floor(row.total_points)));
			idx++;		
		}	
	}	
	
	/**
	* Print company hiscore table - by week points
	*/
	static function PrintRankingWeekPoints(print_func, page)
	{
		local offset = (Utils.GetIntegerRange(page, 1, HiscoreMaxPage) - 1) *  HiscorePerpage;
		local limit  = HiscorePerpage;
		
		local res_arr = datadb.GetBestCompaniesWeekPoints(limit, offset);
		local idx = offset + 1;
	
		print_func(format("Best rated companies by points earned this week - Page #%d", page));	
		
		if (res_arr.len() == 0)
			print_func("- No companies");
		
		foreach(i, row in res_arr) {
			print_func(format("%d. %s (%dx rated)  %d points", idx, row.name, row.week_games, floor(row.week_points)));
			idx++;		
		}	
	}
	
	/**
	* Print company hiscore table - by best games
	*/
	static function PrintRankingBestGames(print_func, page)
	{
		local offset = (Utils.GetIntegerRange(page, 1, HiscoreMaxPage) - 1) *  HiscorePerpage;
		local limit  = HiscorePerpage;
		
		local res_arr = datadb.GetBestCompaniesBestGames(limit, offset);
		local idx = offset + 1;
	
		print_func(format("Best rated companies by best (top awarded) games - Page #%d", page));	
		
		if (res_arr.len() == 0)
			print_func("- No companies");
		
		foreach(i, row in res_arr) {
			print_func(format("%d. %s  %d points", idx, row.name, floor(row.best_score)));
			idx++;		
		}	
	}
}