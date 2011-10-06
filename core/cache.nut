
class CacheEntry {
	expiration_type = 0;
	expiration_date = null;
	data = null;
}

class Cache {
	static cacheStorage = {};
	
	/**
	* Store to cache for specific time period
	*/
	static function StoreDate(key, value, months) {
		local currentDate = ::AIDate.GetCurrentDate();
		local cacheEntry = CacheEntry();
		
		cacheEntry.data = value;
		cacheEntry.expiration_type = 0;
		
		if (months > 0) 
			cacheEntry.expiration_date = Utils.AdvanceDate(currentDate, 0, months);
		else
			cacheEntry.expiration_date = -1; // forever
		
		Cache.cacheStorage[key] <- cacheEntry;
	}

	/**
	* Store to cache for whole game
	*/	
	static function StoreGame(key, value) {
		local cacheEntry = CacheEntry();
		
		cacheEntry.data = value;
		cacheEntry.expiration_type = 1;
		
		Cache.cacheStorage[key] <- cacheEntry;
	}	
	
	/**
	* Returns true if specified key exists in cache
	*/
	static function HasKey(key) {
		return (key in Cache.cacheStorage);
	}
	
	/**
	* Get the specified value stored on key from cache. return null if not found
	*/
	static function Get(key) {
		if (Cache.HasKey(key)) {
			return Cache.cacheStorage[key].data;
		}		
		return null;
	}
	
	/**
	* Invalidates key in cache
	*/
	static function Invalidate(key) {
		if (Cache.HasKey(key)) {
			delete Cache.cacheStorage[key];
		}		
	}
}


/**
* Expiration handling for timed caches
*/
function Cache_OnMonthlyLoop() {
	local currentDate = ::AIDate.GetCurrentDate();
	foreach(key, value in Cache.cacheStorage) {
		if (value.expiration_type == 0 && value.expiration_date != -1 && currentDate > value.expiration_date)
			delete Cache.cacheStorage[key];
	}	
}

/**
* Expiration handling for game wide caches
*/
function Cache_OnServerNewGame(switch_mode) {
	// expire all caches...
	foreach(key, value in Cache.cacheStorage) {
		if (value.expiration_type == 1) {
			delete Cache.cacheStorage[key];
		}
	}
}

CallbackManager.RegisterCallback("OnMonthlyLoop", Cache_OnMonthlyLoop);
CallbackManager.RegisterCallback("OnServerNewGame", Cache_OnServerNewGame);