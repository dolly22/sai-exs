
class ExSAI extends SAIInfo {
	function GetAuthor()      { return "Dolly aka Ex"; }
	function GetName()        { return "exs"; }
	function GetShortName()   { return "EXAI"; }
	function GetDescription() { return "This is Ex's ServerAI reference project"; }
	function GetVersion()     { return 1; }
	function GetDate()        { return "{BuildDate}"; }
	function CreateInstance() { return "GoalGameController"; }
}

RegisterSAI(ExSAI());

