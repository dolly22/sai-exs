require("score/score_ncv.nut");
require("goal/goal_ncv.nut");

class GoalGameController extends ServerController 
{
	static DefaultGoalValue = 6000000;
		
	function constructor()
	{
		this.Goal  = NCVGoal();
		this.Score = NCVCompanyScore();
		
		::ServerController.constructor();	
	}	
				
	// called from contructor and server newgame
	function Init() {
		::ServerController.Init();

		this.Goal.Init(DefaultGoalValue);
		this.Score.Init();
		this.Score.HiscoreModifier = 1.0;	
		
		this.HiscoreLimit = 0; 
		this.StartPause = 4;
		this.RestartDelay = 2;
	}
		
	// compute score weekly
	function OnWeeklyLoop() {	
		::ServerController.OnWeeklyLoop();
		Score.UpdateScore();		
	}
	
	function OnClientJoined(client) {
		::SAIServer.SayClient(client, "Welcome to Ex's ServerAI default server (see http://github.com/dolly22/sai-exs)");
		::SAIServer.SayClient(client, "Raise your company value to "+ Utils.FormatKMValue(Goal.GoalValue) +" GBP to win - "+ Goal.GetStatus());	
		::SAIServer.SayClient(client, "Type /help for available commands and don't forget to read the /rules.");					
		::ServerController.OnClientJoined(client);
	}	
		
	// restart game (called by server when scheduled restart date is achieved)
	function RestartGame() {
		::ServerController.RestartGame(false);
	}
}