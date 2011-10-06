enum AllowFlags {
	Channel = 1		// allow this command in channel context
}

/**
* Client command implementation
*/
class IrcCommand {	
	Name = "";			// command primary name
	Aliases = [];		// command aliases
		
	ShortHelp = "";		// short help string
	LongHelp = [];		// long help string array
		
	HelpGroup = "";		// group of help commands
	HelpIndex = 0;		// index in help group (command sorting)
	
	Allowed = 0			// allowed bitmask, by default only private msgs are handled
	
	ExecuteFunction = null; // this function will be executed in this. context
	
	/**
	* Dummy execute function, either override this or specificy ExecuteFunction
	*/
	function ExecuteCommand(client, ...) {};
		
	/**
	* Create new client command
	*/
	function constructor(primaryName, ...) {
		if (primaryName == null || (typeof(primaryName) != "string") || primaryName.len() == 0) {
			::Log.Error("Cannot register client command, name is invalid");		
		}
		Name = primaryName.tolower();
		
		// command function third parameter
		if (vargc > 1) {			
			if (vargv[1] != null && (typeof(vargv[1]) != "function")) {
				::Log.Error(format("Cannot register command %s, funCommand must be function", primaryName));		
			}
			this.ExecuteFunction = vargv[1];
		}
		
		// command description table - second paramater
		if (vargc > 0) {		
			if (vargv[0] != null && typeof(vargv[0]) != "table") {
				::Log.Error(format("Cannot register command %s, description table invalid", primaryName));
			} else {
				// parse description table...
				ParseDescriptionTable(vargv[0]);
			}
		}
	}
	
	/**
	* Parse description table on command creation
	*/
	function ParseDescriptionTable(tblDescription) {
		foreach(key, value in tblDescription) {
			if (key in this) {
				this[key] = value;
			} else {
				::Log.Error(format("Error parsing description for command \"%s\", invalid key \"%s\"", this.Name, key));
			}
		}	
	}	
	
	/**
	* Print command long help (multiple lines)
	*/
	function PrintLongHelp(nick) {
		if (CanUse(nick, false)) {			
			local alias_str = "";
			if (this.Aliases != null) {									
				foreach(i, alias in this.Aliases) {
					if (i > 0)
						alias_str += ", ";
					alias_str += ("/"+ alias);
				}
				alias_str = " (aliases "+ alias_str +")";				
			}
			::SAIIrc.NoticeNick(nick, format("-= Detailed help for command '!%s'%s =-", this.Name, alias_str));				

			// print long command help								
			if (this.LongHelp != null)
				foreach(i, msg in this.LongHelp) {
					::SAIIrc.NoticeNick(nick, msg);
				}
		}	
	}
	
	/**
	* Print command short help
	*/
	function PrintShortHelp(nick) {
		if (CanUse(nick, false)) {
			::SAIIrc.NoticeNick(nick, format("!%s - %s", this.Name, this.ShortHelp));
		}
	}
	
	/**
	* May the client use this command? (for admin/mod implementation)
	*/
	function CanUse(nick, print_errors) {			
		return true;
	}
}

/**
* Irc command manager class for command registration and handling
*/
class IRCCManager {
	static commandLookups = {};
	
	/**
	* Register new client command
	*/
	static function Register(commandSpec) {
		if (!(commandSpec instanceof IrcCommand)) {
			Log.Error("You have to supply instance of IrcCommand to Register()");
			return false;
		}
		if (commandSpec.Name in IRCCManager.commandLookups) {
			Log.Error(format("Command \"%s\" already registed", commandSpec.Name));
			return false;
		}
		if (commandSpec.ExecuteFunction != null && typeof(commandSpec.ExecuteFunction) != "function") {
			Log.Error(format("Command \"%s\" invalid ExecuteFunction specification", commandSpec.Name));
			return false;		
		} 		
		IRCCManager.commandLookups[commandSpec.Name] <- commandSpec;
		
		// register also aliases
		foreach(i, alias in commandSpec.Aliases) {
			local lowerAlias = alias.tolower();
			if (lowerAlias in IRCCManager.commandLookups) {
				Log.Error(format("Error registering command \"%s\" alias \"%s\", command already exists.", commandSpec.Name, lowerAlias));
				return false;
			}
			IRCCManager.commandLookups[lowerAlias] <- commandSpec;
		}					
	} 
	
	/**
	* Process execution of client command
	*/
	static function ProcessIrcCommand(isPublic, nick, commandName, commandArgs) {
		local commandNameLower = commandName.tolower();
		if (commandNameLower in IRCCManager.commandLookups) {
			local commandSpec = IRCCManager.commandLookups[commandNameLower];

			local param_arr;

			// process params
			if (commandArgs.len() > 0)
			{
				param_arr = array(4);
				param_arr[3] = commandArgs	// command arguments
			}
			else
				param_arr = array(3);
			{
			} 		
			param_arr[0] = commandSpec 	// this context
			param_arr[1] = nick			// client nick
			param_arr[2] = isPublic 	// is command public
						
			if (!commandSpec.CanUse(nick, true)) {
				Log.Warn(format("Irc nick %s, tried to execute command \"%s\" (cannot use)", nick, commandNameLower))
				return true;
			}
			if (isPublic && (commandSpec.Allowed & AllowFlags.Channel) == 0)
			{
				::SAIIrc.NoticeNick(nick, format("Command '%s' cannot be used in channel context, /msg concrete server", commandNameLower));
				return true;
			}
	
			try {				
				if (commandSpec.ExecuteFunction != null)
					commandSpec.ExecuteFunction.acall(param_arr);
				else
					commandSpec.ExecuteCommand.acall(param_arr);
			} catch(e) {
				Log.Error(format("Error executing command \"%s\": %s", commandNameLower, e));
			}
			return true;
		} else {
			if (isPublic)
				::SAIIrc.NoticeNick(nick, format("Command '%s' not understood.", commandName));
		}	
		return false;
	}
	
	/**
	* Print commands from specified helpGroup
	*/
	static function PrintHelpGroup(nick, helpGroup) {
		local helpCommands = [];
		
		foreach(key, commandSpec in IRCCManager.commandLookups) {
			if (key == commandSpec.Name && commandSpec.HelpGroup == helpGroup) {
				// primary command
				helpCommands.append(commandSpec);
			}
		}
		
		if (helpCommands.len() > 0) {
			helpCommands.sort(function(a,b) {
				return (a.HelpIndex - b.HelpIndex);
			});
		}
		
		foreach(i, commandSpec in helpCommands)
			commandSpec.PrintShortHelp(nick);			
	}
	
	/**
	* Get command specification
	*/
	static function GetCommandSpec(commandName) {
		if (commandName in IRCCManager.commandLookups)
			return IRCCManager.commandLookups[commandName];
		else
			return null;
	}
	
	/**
	* Print short help for specified command
	*/
	function ShortHelp(nick, command) {
		local commandSpec = IRCCManager.GetCommandSpec(command);
		if (commandSpec != null)
			commandSpec.PrintShortHelp(nick);
	}	
	
	/**
	* Print long help for specified command
	*/
	function LongHelp(nick, command) {
		local commandSpec = IRCCManager.GetCommandSpec(command);
		if (commandSpec != null)
			commandSpec.PrintLongHelp(nick);
	}		
}