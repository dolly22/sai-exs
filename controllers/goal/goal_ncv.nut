/**
* Goal based on achived score
*/
class NCVGoal extends GameGoalBase {
	GoalValue = 0;
	
	function constructor() {
		::GameGoalBase.constructor();
	}
	
	/**
	* Initialize goal variables
	*/
	function Init(goalValue) {		
		this.GoalValue = goalValue;
	}
	
	/** 
	* Check if the goal is completed
	*/
	function IsCompleted() {
		local bestCompany = Game.Score.GetBestCompany();
		
		if (bestCompany != null && bestCompany.Score >= this.GoalValue) {
			return true;
		}
		return false;
	}
	
	/**
	* Returns goal progress and status
	*/
	function GetStatus() {
		local bestCompany = Game.Score.GetBestCompany();
		
		if (bestCompany == null) {		
			return format("0%% complete, %s GBP remaining", Utils.FormatCompanyValue(this.GoalValue));
		} else {
			local remPercent  = min(bestCompany.Score / this.GoalValue * 100.0, 100);
			local remAbsolute = max(this.GoalValue - bestCompany.Score, 0);
			
			local statusStr = format("%.0f%% complete", remPercent);
			if (remAbsolute > 0)
				statusStr += format(" (%s remaining)", Utils.FormatCompanyValue(remAbsolute));
			
			return statusStr;
		}
	}
	
	function GetInfo() {
		local info = [
			"The goal of this game is to achieve company value of "+  Utils.FormatCompanyValue(this.GoalValue) +" GBP"
		]
		return info;
	}		
}