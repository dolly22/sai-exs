/**
* Server hiscore database
*/
class DataDb extends Database {
}

/**
* Get id of current running game
*/
function DataDb::GetCurrentGame() {
	local sql = 
		"	SELECT "+			 
		"		gam_id "+ 			
		"	FROM "+			
		"	  	game "+		
		"	WHERE "+ 			
		"	  	gam_unique = :gamunique "+ 
		"	  	AND date(gam_date) >= date('now', '-1 days') "+
		"	ORDER BY "+
		"		gam_id DESC "+		
		"	LIMIT 1";
			
	local cmd = conn.CreateCommand(sql);
	cmd.BindStringName(":gamunique", 
		format("%u", ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.generation_seed")));
	
	local gameId = null; 	
	local reader = cmd.ExecuteReader();
	if (reader.Read())
		gameId = reader.GetIntName("gam_id");
	reader.Close();
	cmd.Finalize();
	
	return gameId;	
}

/**
* Create record for current game
*/
function DataDb::CreateCurrentGame() {
	// try to create this game
	local sql = 
		"	INSERT INTO game  "+
		"	    (gam_unique, gam_date, gam_started) "+    
		"	VALUES "+
		"	    (:gamunique, date('now'), :gamstarted)"
			
	local cmd = conn.CreateCommand(sql);
	
	cmd.BindStringName(":gamunique", 
		format("%u", ::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.generation_seed")));
	cmd.BindIntName(":gamstarted",
		::SAIGameSettings.GetIntValue(::SAIGameSettings.GS_CURRENT_GAME, "game_creation.starting_year"));
		
	cmd.ExecuteNonQuery();
	cmd.Finalize();
	
	return conn.GetLastAutoId();
}

/**
* Get id of current running game, create game if it does not exist
*/
function DataDb::CreateOrGetCurrentGame() {
	local gameId = GetCurrentGame();
	if (gameId == null) {
		gameId = CreateCurrentGame();					
	}	
	return gameId;
}


/**
* Get id for specified company name
*/
function DataDb::RetrieveCompany(company_name) {
	local sql =
		"SELECT "+
		"  com_id "+
		"FROM "+
		"  company "+
		"WHERE "+
		"  com_name = :comname COLLATE NOCASE";
			
	local cmd = conn.CreateCommand(sql);
	cmd.BindStringName(":comname", company_name);
	
	local companyId = null; 	
	local reader = cmd.ExecuteReader();
	if (reader.Read())
		companyId = reader.GetIntName("com_id");
	reader.Close();
	cmd.Finalize();
	
	return companyId;
}

/**
* Create or retrieve company specified by name from database
*/
function DataDb::CreateOrRetrieveCompany(company_name) {
	local companyId = RetrieveCompany(company_name);	
	if (companyId == null) {
		local sql = 
			"	INSERT INTO company  "+
			"	    (com_name) "+    
			"	VALUES "+
			"	    (:comname)"
				
		local cmd = conn.CreateCommand(sql);	
		cmd.BindStringName(":comname", company_name);
		
		cmd.ExecuteNonQuery();
		cmd.Finalize();
		
		companyId = conn.GetLastAutoId();		
	}	
	return companyId;
}

/**
* Store company win to database
*/
function DataDb::StoreCompanyWin(company_name, points) {
	local gameId = CreateOrGetCurrentGame();
	local companyId = CreateOrRetrieveCompany(company_name);
	
	if (gameId != null && companyId != null) {
		local sql = 
			"	INSERT INTO gamewin  "+
			"	    (gwi_game_fk, gwi_company_fk, gwi_points) "+    
			"	VALUES "+
			"	    (:gwigame, :gwicompany, :gwipoints)"
				
		local cmd = conn.CreateCommand(sql);	
		cmd.BindIntName(":gwigame", gameId);	
		cmd.BindIntName(":gwicompany", companyId);
		cmd.BindDoubleName(":gwipoints", points.tointeger());
		
		cmd.ExecuteNonQuery();
		cmd.Finalize();
		
		return true;		
	}	
	return false;
}

/**
* Get company ranking
*/
function DataDb::GetCompanyRanking(company_name) {
	local companyId = RetrieveCompany(company_name);
	local companyRanking = null;
	
	if (companyId != null) {
		local sql = 
			"  SELECT "+
			"    (SELECT COUNT(*)+1 FROM company_stats tot_points WHERE tot_points.cst_total_points_decay > my_stats.cst_total_points_decay) AS points_decay_rank, "+
			"    (SELECT COUNT(*)+1 FROM company_stats week_points WHERE week_points.cst_week_points > my_stats.cst_week_points) AS week_points_rank, "+
			"    (SELECT COUNT(*)+1 FROM company_stats score WHERE score.cst_best_games_score > my_stats.cst_best_games_score) AS best_games_score_rank, "+
			"    my_stats.cst_total_points_decay, "+
			"    my_stats.cst_week_points, "+
			"    my_stats.cst_best_games_score "+
			"  FROM "+
			"    company_stats my_stats "+
			"  WHERE my_stats.cst_company_fk = :cstcompany";
			
		local cmd = conn.CreateCommand(sql);			
		cmd.BindIntName(":cstcompany", companyId);			
	
		local reader = cmd.ExecuteReader();
		if (reader.Read()) {
			companyRanking = {
				rank_total 			= reader.GetIntName("points_decay_rank"),			// rank by total points earned
				rank_week 			= reader.GetIntName("week_points_rank"),			// rank by points earned this week
				rank_best_games 	= reader.GetIntName("best_games_score_rank"),		// rank by best scored games
				points_total 		= reader.GetDoubleName("cst_total_points_decay"),	// total points
				points_week 		= reader.GetDoubleName("cst_week_points"),			// points earned this week
				points_best_games 	= reader.GetDoubleName("cst_best_games_score")		// best scored games average
			};			
		}		
		reader.Close();
		cmd.Finalize();				
	}
	return companyRanking;
}

/**
* Update company precomputed statistics
*/
function DataDb::UpdateCompanyStats() {
	local sql = 
		"	INSERT OR REPLACE INTO company_stats "+
		"	    (cst_company_fk, cst_total_games, cst_total_points, cst_total_points_decay, cst_week_games, cst_week_points, cst_best_games_score) "+
		"	SELECT "+
		"	    gws_company_fk, gws_rated_games, gws_total_points, gws_total_points_decay, gws_week_rated_games, gws_week_points, gwb_score "+
		"	FROM "+
		"	    gamewin_stats "+
		"	    INNER JOIN gamewin_best_games ON (gws_company_fk = gwb_company_fk)"	
	conn.Exec(sql);
	
	sql = 
		"	DELETE FROM company_stats WHERE NOT EXISTS (SELECT com_id FROM company WHERE com_id = cst_company_fk)";
	conn.Exec(sql);
}

/**
* Get best companies statistics
*-- scoretype:
*-- 1 = cst_total_games, cst_total_points_decay
*-- 2 = cst_week_games, cst_week_points
*-- 3 = cst_best_games_score
*/
function DataDb::GetBestCompaniesCmd(scoretype, limit, offset) {
	local limit_str;
	if (limit != 0) {
	    limit_str = "LIMIT "+ limit;
	    if (offset != 0)
	        limit_str = limit_str +" OFFSET "+ offset
	}
	
	local from_str = "";
	local order_str = "";
	
	if (scoretype == 1) {
	    from_str  = "cst_total_games, cst_total_points_decay"
	    order_str = "cst_total_points_decay DESC"
	} else if (scoretype == 2) {
	    from_str  = "cst_week_games, cst_week_points"
	    order_str = "cst_week_points DESC"
	} else {
	    from_str  = "cst_best_games_score"
	    order_str = "cst_best_games_score DESC"
	}
	
	local sql = format(
		"	SELECT "+
		"		com_name, %s "+
		"	FROM "+
		"		company_stats "+
		"		INNER JOIN company ON (com_id = cst_company_fk) "+
		"	ORDER BY "+
		"		%s "+
		"	%s",
		from_str, order_str, limit_str);
		
	return conn.CreateCommand(sql);		
}

/**
* Get best companies according to total points earned
*/
function DataDb::GetBestCompaniesTotalPoints(limit, offset) {	
	local cmd = GetBestCompaniesCmd(1, limit, offset);
	local res_arr = [];

	local reader = cmd.ExecuteReader();
	while (reader.Read()) {
		res_arr.append({
			name 		 = reader.GetStringName("com_name"),				// company name
			total_games  = reader.GetIntName("cst_total_games"),			// total rated games
			total_points = reader.GetDoubleName("cst_total_points_decay")	// total earned points
		});			
	}		
	reader.Close();
	cmd.Finalize();
	
	return res_arr;	
}

/**
* Get best companies according to points earned in last 7 days
*/
function DataDb::GetBestCompaniesWeekPoints(limit, offset) {	
	local cmd = GetBestCompaniesCmd(2, limit, offset);
	local res_arr = [];

	local reader = cmd.ExecuteReader();
	while (reader.Read()) {
		res_arr.append({
			name 		= reader.GetStringName("com_name"),			// company name
			week_games  = reader.GetIntName("cst_week_games"),		// rated games in last 7 days
			week_points = reader.GetDoubleName("cst_week_points")	// earned points in last 7 days
		});			
	}		
	reader.Close();
	cmd.Finalize();
	
	return res_arr;	
}

/**
* Get best companies according to points earned in best games
*/
function DataDb::GetBestCompaniesBestGames(limit, offset) {	
	local cmd = GetBestCompaniesCmd(3, limit, offset);
	local res_arr = [];

	local reader = cmd.ExecuteReader();
	while (reader.Read() && reader.GetDoubleName("cst_best_games_score") > 0) {
		res_arr.append({
			name 		= reader.GetStringName("com_name"),				// company name
			best_score  = reader.GetDoubleName("cst_best_games_score")	// average best games score
		});			
	}		
	reader.Close();
	cmd.Finalize();
	
	return res_arr;	
}


/**
* Get last games for specified company
*/
function DataDb::GetLastGamesCompany(company, limit, offset) {
	local limit_str;
	local res_arr = [];
		
	if (limit != 0) {
	    limit_str = "LIMIT "+ limit;
	    if (offset != 0)
	        limit_str = limit_str +" OFFSET "+ offset
	}
		
	local sql = format(
		"	SELECT "+
		"		gwi_points, "+
		"		round((100 - julianday(date('now')) + julianday(gam_date)) / 100.0 * gwi_points, 1) as gwi_decayed_points, "+
		"		strftime(\"%%d.%%m.%%Y\", gam_date) as conv_date "+
		"	FROM "+
		"	    gamewingame "+
		"	WHERE "+
		"	    gwi_company_fk = :company "+
		"	    AND gam_date >= date('now', '-100 days') "+
		"	ORDER BY "+
		"	    gam_date DESC "+
		" 	%s"
		,limit_str);
		
	local cmd = conn.CreateCommand(sql);
	cmd.BindIntName(":company", company);	
		
	local reader = cmd.ExecuteReader();
	while (reader.Read()) {
		res_arr.append({
			points 			= reader.GetIntName("gwi_points"),			// points
			points_decayed  = reader.GetIntName("gwi_decayed_points")	// decayed points
			date			= reader.GetStringName("conv_date"),		// game date
		});			
	}		
	reader.Close();
	cmd.Finalize();	
	
	return res_arr;
}


/**
* Get best games for specified company
*/
function DataDb::GetBestGamesCompany(company) {
	local res_arr = [];

	local sql = format(
		"	SELECT "+
		"		gwi_points, "+
		"		strftime(\"%%d.%%m.%%Y\", gam_date) as conv_date "+
		"	FROM "+
		"	    gamewingame "+
		"	WHERE "+
		"	    gwi_company_fk = :company "+
		"	    AND gam_date >= date('now', '-100 days') "+
		"	ORDER BY "+
		"	    gwi_points DESC "+
		" 	LIMIT 10");
		
	local cmd = conn.CreateCommand(sql);
	cmd.BindIntName(":company", company);	
		
	local reader = cmd.ExecuteReader();
	while (reader.Read()) {
		res_arr.append({
			points 			= reader.GetIntName("gwi_points"),		// points
			date			= reader.GetStringName("conv_date")		// game date
		});			
	}		
	reader.Close();
	cmd.Finalize();	
	
	return res_arr;
}

/**
* Cleanup database (remove old entries and vacuum)
*/
function DataDb::Cleanup() {
	Log.Info("Database cleanup started...");	
	
	// delete old gamewins	
	local sql = 
		"	DELETE FROM gamewin "+
		"	WHERE "+
		"  	EXISTS (SELECT gam_id FROM game WHERE gam_id = gwi_game_fk AND gam_date < date('now', '-150 days'))";
	
	Log.Info("Deleting old gamewins");
	conn.Exec(sql);

	// delete old games	
	sql = 
		"	DELETE FROM game WHERE gam_date < date('now', '-150 days')";
	
	Log.Info("Deleting old games");
	conn.Exec(sql);	
		
	// delete unused companies
	sql = 
		"	DELETE FROM company WHERE "+
		"	NOT EXISTS (SELECT gwi_company_fk FROM gamewin WHERE gwi_company_fk = com_id)";

	Log.Info("Cleanup unused companies");
	conn.Exec(sql);		
		
	// update stats			
	UpdateCompanyStats();	
	
	// vacuum database
	Log.Info("Vacuum database");
	conn.Exec("VACUUM");		
}


