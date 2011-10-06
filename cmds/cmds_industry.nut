/**
* Rules command registration
*/
CCManager.Register(ClientCommand(
	"reserve",
	{	
		Audience = AudienceFlags.ValidCompany | AudienceFlags.Admins					// only available for valid companies		
		HelpIndex = 100,
		ShortHelp = "Reserve one raw industry for yourself"
	}
	function(client, ...) {
		local company = ::SAIClient.GetCompany(client);
		
		// empty = info, remove = remove reservation, location = try to reserve
		if (vargc > 0) {
			local arg = vargv[0];
			
			if (arg == "remove") {
				// remove reservation
				;
			} else {
				local loc;
				if (vargc > 1)
					loc = GetLocation(vargv[0], vargv[1]);
				else
					loc = GetLocation(vargv[0]);
			
				if (loc == null) {
					::SAIServer.SayClient(client, "Invalid location specified (use \"WxH\" or \"W H\" format");
					return;
				}	
					
				local tile = ::AIMap.GetTileIndex(loc.x, loc.y);
				if (!::AIMap.IsValidTile(tile))	{
					::SAIServer.SayClient(client, "Invalid tile, location coordinates are out of map range");
					return;
				}			
				
				if (!::SAITile.IsIndustryTile(tile)) {
					::SAIServer.SayClient(client, "The tile you specified does not have industry on it.");
					return;					
				}	
				
				local indIndex = ::SAITile.GetIndustryIndex(tile);
				
					
								
			}
		} else {
			// show info
			;
		}
					
		// is the company young enough (only available in 2 first years)
		//if (::SAICompany.GetStartingYer
		

	}
));


function GetLocation(...) {
	local x, y;
	
	if (vargc == 2) {
		// x  y style
		x = vargv[0];
		y = vargv[1];		
	} else if (vargc == 1) {
		// PxQ style
		local arr = split(vargv[0].tolower(), "x");
		if (arr.len() >= 2) {
			x = arr[0];
			y = arr[1];
		} else {
			// unsupported
			return null;
		}		
	} else {
		// unsupported
		return null;
	}
	
	// x, y should have some location coordinates
	local x_int = ::Utils.GetInteger(x, -1);
	local y_int = ::Utils.GetInteger(y, -1);
	
	// not converted or negative numbers
	if (x_int <= 0 || y_int <= 0)
		return null;
	
	// return location as table [x,y]
	return { x = x_int, y = y_int };	
}