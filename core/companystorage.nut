/**
* Company specific storage
*/
class CompanyStorage {
	static _companies = {};
	
	/**
	* Get storage for specific company
	*/
	static function Get(company) {		
		if (!(company in CompanyStorage._companies))
			CompanyStorage._companies[company] <- {};
		return CompanyStorage._companies[company];
	}
	
	/**
	* Get company specific value identified by key
	*/
	static function GetValue(company, key) {
		local storage = CompanyStorage.Get(company);
		if (key in storage)
			return storage[key];
		return null;		
	}

	/**
	* Set company specific value identified by key
	*/	
	static function SetValue(company, key, value) {
		local storage = CompanyStorage.Get(company);
		if (key in storage) {
			storage[key] = value;
			return;
		}
		storage[key] <- value;
	}
	
	/**
	* Increment value for specified key, if not exist set it to value. Returns incremented value
	*/
	static function IncrementValue(company, key, value)
	{
		local storedValue = CompanyStorage.GetValue(company, key);
		if (storedValue != null)
			storedValue += value;
		else
			storedValue = value;
			
		CompanyStorage.SetValue(company, key, storedValue);
		return storedValue;
	}	
	
	/**
	* Decrement value at specified key, remove completely if it's zero or below. Do nothing if it does
	* not even exists.
	*/
	static function DecrementValue(company, key, value) {
		local storedValue = CompanyStorage.GetValue(company, key);
		if (storedValue != null) {
			storedValue -= max(0, value);
			if (storedValue <= 0)
				CompanyStorage.RemoveKey(company, key);
			else
				CompanyStorage.SetValue(company, key, storedValue);
		}		
		return storedValue;
	}
	
	
	/**
	* Check if specific key exists in this company storage
	*/
	static function KeyExists(company, key) {
		local storage = CompanyStorage.Get(company);
		return (key in storage);
	}
	
	/**
	* Remove company key from storage
	*/
	static function RemoveKey(company, key) {
		local storage = CompanyStorage.Get(company);
		if (key in storage)
			delete storage[key];		
	}	
	
	/**
	* Remove company from storage (OnCompanyDeleted)
	*/
	static function RemoveCompany(company) {
		if (company in CompanyStorage._companies) {
			delete CompanyStorage._companies[company];	
		}
	}
	
	/**
	* Reset storage completely
	*/
	static function OnServerNewGame(seed) {
		CompanyStorage._companies <- {};
	}
}

// Initialize callback registration
CallbackManager.RegisterCallback("OnCompanyDeleted", CompanyStorage.RemoveCompany);
CallbackManager.RegisterCallback("OnServerNewGame", CompanyStorage.OnServerNewGame);
