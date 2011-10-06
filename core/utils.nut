class Utils {
}

/**
* Format date and return it's string representation
* @param date Uin32 date representation
*/
function Utils::FormatDate(date) {
	return format("%d.%d.%d", AIDate.GetDayOfMonth(date), AIDate.GetMonth(date), AIDate.GetYear(date));
}

/**
* Advance date by specified number of years or months
*/
function Utils::AdvanceDate(date, years, months) {
	local adv_date = ::AIDate.GetDate(years, months + 1, 5);
	local new_date = date + adv_date; 	
	return (::AIDate.GetDate(::AIDate.GetYear(new_date), ::AIDate.GetMonth(new_date), 1));
}

/**
* Format value its string representation with k and M suffixes
*/
function Utils::FormatKMValue(value) {
	if (value / 1000.0 >= 1) {
		value = value / 1000.0;
		if (value / 1000.0 >= 1)
			return format("%.2fM", value / 1000.0);
		return format("%.2fk", value);
	}
	return format("%.0f", value);
}

function Utils::FormatCompanyValue(value) {
	if (value / 1000.0 >= 1) {
		value = value / 1000.0;
		if (value / 1000.0 >= 1)
			return format("%.2f mil", value / 1000.0);
		return format("%.1fk", value);
	}
	return format("%.1f", value);
}


/**
* Convert to integer, use def_value if not possible
*/
function Utils::GetInteger(number_spec, def_value) {
	if (typeof number_spec == "integer") {
		return number_spec;
	}
	try {
		return number_spec.tointeger();
	} catch (e) {
		return def_value;
	}
}

/**
* Logarithmic value
*/
function Utils::LogN(number, base) {
	return log(number) / log(base);
}

/**
* Get integer from specified range
*/
function Utils::GetIntegerRange(number_spec, min_value, max_value) {
	local number = Utils.GetInteger(number_spec, min_value);

	if (number < min_value)
		number = min_value;
	if (number > max_value)
		number = max_value;
		
	return number;
}

/**
* Kick all players and reset company
*/
function Utils::ResetCompany(company) {
	if (!::SAICompany.IsValid(company))
		return;	

	local clients = SAIClientList();	
	clients.Valuate(SAIClient.GetCompany);
	
	// move company clients to spectators
	foreach(client, playas in clients) {
		if (company == playas) {
			::SAIServer.ConsoleCmd(format("move %d 255", client));
		}
	}
	
	// reset company
	::SAIServer.ConsoleCmd(format("reset_company %d", company+1))
}

/**
* Kick all players (but no admins)
*/
function Utils::KickPlayers() {
	local clients = SAIClientList();	
	foreach(client, dummy in clients) {
		if (!::SAIClient.IsAdmin(client))
			::SAIServer.ConsoleCmd(format("kick %d", client));
	}
}

/**
* Disconnect all players (but no admins)
*/
function Utils::DisconnectPlayers() {
	local clients = SAIClientList();	
	foreach(client, dummy in clients) {
		if (!::SAIClient.IsAdmin(client))
			::SAIClient.Disconnect(client, 3);
	}
}


/**
* Get the page specified record is displayed on according to pageSize
*/
function Utils::GetPage(recordIdx, pageSize) {
	return floor(recordIdx / pageSize) + 1;
}

/**
* Validate if this company name is valid for multiplayer games, return null
* if there are not validation problems, returns array with problem descriptions
*/
function Utils::ValidateCompanyName(companyName) {
	local valErr = [];
	
	if (companyName != null && companyName.len() > 0) {
		local normName = companyName.tolower();
		if (normName.len() >= 7 && normName.slice(0, 7) == "player ") {
			valErr.append("company name is starting with \"Player\"");
		}		
	}
	
	if (valErr.len() > 0)
		return valErr;
	else
		return null;	
}

/**
* Convert array to string using separator
*/
function Utils::ArrayToString(arr, separator) {
	local result = ""	
	foreach(idx, val in arr) {
		if (idx > 0)
			result += separator;
		result += val;				
	}
	return result;
}

/**
** Get percentage of value achieved
**/
function Utils::GetPercent(value, min_val, max_val) {	
	local int_len = max_val - min_val;			
	local normalized = min(max(min_val, value), max_val);
	return (normalized - min_val) / int_len.tofloat() * 100.0;
}


/**
** Test if line (horizontal, vertical or diagonal) intersects rectangle
**/
function Utils::TestRectLineCollision(rblx, rbly, rtrx, rtry, llx, lly, lrx, lry) 
{	
	//print(format("Test rect line collision: BL[%d,%d], TR[%d,%d], L1[%d,%d], L2[%d,%d]", rblx, rbly, rtrx, rtry, llx, lly, lrx, lry));	
	if (llx == lrx) {
		//print(format("vertical line: [%d,%d-%d]", llx, lly, lry));
		
		// vertical line - is the x coordinate inside rectangle
		if (llx >= rblx && llx <= rtrx) {
			// whole line below or above box						
			if ((lly < rbly && lry < rbly) || (lly > rtry && lry > rtry))
				return false;  				
			else
				return true; 
		}		 		
	} else if (lly == lry) {
		//print(format("horizontal line: [%d-%d,%d]", llx, lrx, lly));
		
		// horizontal line - is the y coordinate inside rectangle
		if (lly >= rbly && lly <= rtry) {				
			// all line on the left or right
			if ((llx < rblx && lrx < rblx) || (llx > rtrx && lrx > rtrx))
				return false;
			else					
				return true;
		}			
	} else {
		// diagonal line
		//print("diagonal line");
		
		
		// whole line on the left or right side				
		if ((llx < rblx && lrx < rblx) || (llx > rtrx && lrx > rtrx)) {
			//print("whole line on left or right side");
			return false;
		}
		
		// whole line above or below
		 if ((lly < rbly && lry < rbly) || (lly > rtry && lry > rtry)) {
		 	//print("whole line on top or bottom");
		 	return false;
		 }
		 	
										
		if (lly < lry) {
			// ascending line
			local ymin = rbly - rtrx;	// minimal colission point on yaxis				
			local ymax = rtry - rblx;	// maximal colission point on yaxis
			local yline = lly - llx;	// line y posision on axis
			
			//print(format("diagonal asc ymin=%d, ymax=%d, yline=%d", ymin, ymax, yline));
			if (yline >= ymin && yline <= ymax)
				return true;						
		} else {
			// descending line
			local xmin = rblx + rbly;	
			local xmax = rtrx + rtry;
			local xline = llx + lly;
			
			//print(format("diagonal desc xmin=%d, xmax=%d, xline=%d", xmin, xmax, xline));
			if (xline >= xmin && xline <= xmax)
				return true;
		}
	}	
	return false;
}		

/**
** Test collision of rectangle and single point
**/
function Utils::TestRectPointCollision(rblx, rbly, rtrx, rtry, px, py)
{
	//print(format("Testing rectangle collision r1 bl[%d,%d] tr[%d,%d] and point [%d,%d]", rblx, rbly, rtrx, rtry, px, py));	
	if (px >= rblx && px <= rtrx && py >= rbly && py <= rtry)
		return true;
	return false; 		
}

/**
** Test collision of two rectangles
**/
function Utils::TestRectCollision(r1blx, r1bly, r1trx, r1try, r2blx, r2bly, r2trx, r2try)
{
	//print(format("Testing rectangle collision r1 - bl[%d,%d] tr[%d,%d], r2 bl[%d,%d] tr[%d,%d]", r1blx, r1bly, r1trx, r1try, r2blx, r2bly, r2trx, r2try));	
	// whole r1 on the left or on the rigt of r2
	if ((r1blx < r2blx && r1trx < r2blx) || (r1blx > r2trx && r1trx > r2trx))
		return false;
		
	// whole r1 on the bottom or on the top of r2
	if ((r1bly < r2bly && r1try < r2bly) || (r1bly > r2try && r1try > r2try))
		return false;
		
	return true;	
}




