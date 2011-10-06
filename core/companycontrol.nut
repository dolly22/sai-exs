class CompanyControl {
	static ResetmeTag = "CC_resetme";
	static SuspendedTillTag = "CC_suspended_till";	
	static SuspendedReasonTag = "CC_suspended_reason";	

	static function OnMonthlyLoop() {
		local companies = ::SAICompanyList();
		local current_date = ::AIDate.GetCurrentDate();
		
		foreach(company, dummy in companies) {
			CompanyControl.HandleResetmeMonthly(company, current_date);	
		}	
	}
	
	static function OnWeeklyLoop() {
		local companies = ::SAICompanyList();
		local current_date = ::AIDate.GetCurrentDate();
		
		foreach(company, dummy in companies) {
			CompanyControl.HandleResetmeWeekly(company, current_date);
			CompanyControl.HandleSuspendedWeekly(company, current_date);
		}
	}	
	
	// resetme handling
	
	/**
	* Monthly /resetme timer for company
	**/
	static function HandleResetmeMonthly(company, current_date) {
		local reset_date = CompanyStorage.GetValue(company, CompanyControl.ResetmeTag);
		if (reset_date != null && reset_date <= current_date) {
			// do company reset
			local company_name = ::SAICompany.GetName(company);			
			::SAIServer.Say(format("The company '%s' is beeing shut down by request of it's owners.", company_name));
			Utils.ResetCompany(company);
		}		
	}
	
	/**
	* Weekly /resetme timer for company
	**/
	static function HandleResetmeWeekly(company, current_date) {	
		local reset_date = CompanyStorage.GetValue(company, CompanyControl.ResetmeTag);
		if (reset_date != null && current_date < reset_date) {
			::SAIServer.SayCompany(company, 
				format("Your company will be reset in %d days (at %s), use '/resetme' command to cancel.", 
				reset_date - current_date, 
				Utils.FormatDate(reset_date))
			);
		}	
	}	
	
	// suspend handling
	
	/**
	* Weekly suspended timer for company
	**/
	static function HandleSuspendedWeekly(company, current_date) {
		if (::SAICompany.IsSuspended(company)) {
			local suspend_till_date = CompanyStorage.GetValue(company, CompanyControl.SuspendedTillTag);
			local suspend_reason = CompanyStorage.GetValue(company, CompanyControl.SuspendedReasonTag);

			local reason = "";
			if (suspend_reason != null && suspend_reason.len() > 0) {
				reason = " ("+ suspend_reason +")";
			}
			
			if (suspend_till_date != null) {			
				if (current_date >= suspend_till_date) {
					// resume company
					CompanyControl.ResumeCompany(company);
				} else {
					// company still suspended
					::SAIServer.SayCompany(company, format("Operations of your company are suspeded till next week after %s%s",
														Utils.FormatDate(suspend_till_date), reason));					
				} 
			} else {
				// suspended without date
				::SAIServer.SayCompany(company, "Operations of your company are suspeded till further notice" + reason);
				//TODO: notify admins about it
			}			
		}		
	}	
		
	/**
	* Resume company operations
	*/
	static function ResumeCompany(company) {
		::SAICompany.SetSuspended(company, false);					
		CompanyStorage.RemoveKey(company, CompanyControl.SuspendedTillTag);
		CompanyStorage.RemoveKey(company, CompanyControl.SuspendedReasonTag);					
		::SAIServer.Say(format("Operations of \"%s\" have been resumed.", ::SAICompany.GetName(company)));		
	}
	
	/**
	* Suspend company till specified date with optional reason
	* param 1 - suspend till
	* param 2 - suspend reason
	*/
	static function SuspendCompany(company, ...) {
		local suspend_till = null;
		local suspend_reason = "";
		
		if (::SAICompany.IsValid(company)) {
			if (::SAICompany.IsSuspended(company)) {
				local suspend_extend = false;
				
				if (vargc > 0 && vargv[0] != null) {
					// time limited suspend, check for extension
					suspend_till = vargv[0];
					
					local currentSuspendedTill = CompanyStorage.GetValue(company, CompanyControl.SuspendedTillTag)					
					if (suspend_till > currentSuspendedTill) {
						// extend suspend time
						suspend_extend = true;	
					}						
				} else {
					// unlimited suspend
					suspend_extend = true;				
				}
				
				if (suspend_extend) {
					CompanyStorage.SetValue(company, CompanyControl.SuspendedTillTag, suspend_till);					
					
					// will extend the suspend
					if (vargc > 1 && vargv[1] != null && vargv[1].len() > 0) {
						suspend_reason = vargv[1];
						CompanyStorage.SetValue(company, CompanyControl.SuspendedReasonTag, suspend_reason);
						suspend_reason = " ("+ suspend_reason +")";				
					} else {
						CompanyStorage.RemoveKey(company, CompanyControl.SuspendedReasonTag);
					}						
					if (suspend_till != null) {
						::SAIServer.Say(format("Suspension for \"%s\" has been extended till %s%s",
								::SAICompany.GetName(company), Utils.FormatDate(suspend_till), suspend_reason));						
					} else {
						::SAIServer.Say(format("Suspension for \"%s\" has been extended till further notice%s",
								::SAICompany.GetName(company), suspend_reason));				
					}
				}											
			} else {
				// not suspended handling
				if (vargc > 0 && vargv[0] != null) {
					suspend_till = vargv[0];
					CompanyStorage.SetValue(company, CompanyControl.SuspendedTillTag, suspend_till);	
				}
				if (vargc > 1 && vargv[1] != null && vargv[1].len() > 0) {
					suspend_reason = vargv[1];
					CompanyStorage.SetValue(company, CompanyControl.SuspendedReasonTag, suspend_reason);
					suspend_reason = "  ("+ suspend_reason +")";				
				}
				
				if (suspend_till != null) {
					::SAIServer.Say(format("Operations of \"%s\" have been suspended till %s%s",
							::SAICompany.GetName(company), Utils.FormatDate(suspend_till), suspend_reason));						
				} else {
					::SAIServer.Say(format("Operations of \"%s\" have been suspended till further notice%s",
							::SAICompany.GetName(company), suspend_reason));				
				}				
				::SAICompany.SetSuspended(company, true);
			}			
		}
	}	
}


// library initialization
CallbackManager.RegisterCallback("OnMonthlyLoop", CompanyControl.OnMonthlyLoop);
CallbackManager.RegisterCallback("OnWeeklyLoop", CompanyControl.OnWeeklyLoop);