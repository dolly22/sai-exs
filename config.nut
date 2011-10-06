require("controllers/ncv.nut");

DatabaseDrive <- "";
DatabasePath  <- ".\\openttd.db3";

function ServerController::ConfigInit(game) {
	game.TranscriptDir = ".\\";
	game.RecycleProcess = false;
}
