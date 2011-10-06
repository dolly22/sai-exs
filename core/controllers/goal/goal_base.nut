/**
* Game goal ancestor. Every goal must inherit from this class.
*/
class GameGoalBase {
	
	function constructor();
		
	/**
	* Check if goal was achieved
	*/
	function IsCompleted();
	
	/**
	* Returns goal progress and status
	*/
	function GetStatus();
	
	/**
	* Returns goal information as array
	*/
	function GetInfo();
}