enum LogLevel {
	Error 	= 0
	Warn 	= 1	
	Info	= 2
	Debug 	= 3
}

/**
* Script logging support
*/
class Log {
	static Level = LogLevel.Debug;
	
	static function IsError() {
		return (Log.Level >= LogLevel.Error);
	}
	
	static function IsWarn() {
		return (Log.Level >= LogLevel.Warn);
	}	
	
	static function IsInfo() {
		return (Log.Level >= LogLevel.Info);
	}

	static function IsDebug() {
		return (Log.Level >= LogLevel.Debug);
	}		
	
	static function Error(msg) {
		Log.Event(LogLevel.Error, msg);		
	}
	
	static function Warn(msg) {
		Log.Event(LogLevel.Warn, msg);
	}	
	
	static function Info(msg) {
		Log.Event(LogLevel.Info, msg);
	}
	
	static function Debug(msg) {
		Log.Event(LogLevel.Debug, msg);
	}
	
	static function Event(level, msg) {
		if (msg != null && msg.tostring().len() > 0) {		
			if (Log.Level >= level) {
				local datespec = date();
				local prefix;
				
				switch (level) {
					case LogLevel.Error:
						prefix = "err";
						break;		
					case LogLevel.Warn:
						prefix = "wrn";
						break;	
					case LogLevel.Info:
						prefix = "inf";
						break;
					case LogLevel.Debug:
					default:
						prefix = "dbg";
						break;												
				}							
				local fmt_msg = format("%s[%d:%02d] %s", prefix, datespec.hour, datespec.min, msg.tostring()); 								
				print(fmt_msg);
			}
		}
	}
}