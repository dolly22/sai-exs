/* Client commands support library

- define your commands with ... parameter at the end to avoid script errors

*/

enum AudienceFlags {
	ValidCompany = 1	// only clients with valid company
	Moderators 	 = 2	// only moderators can use this command
	Admins 	 	 = 4	// only admins can use this command	
}

/**
* Client command implementation
*/
class ClientCommand {	
	Name = "";			// command primary name
	Aliases = [];		// command aliases
		
	ShortHelp = "";		// short help string
	LongHelp = [];		// long help string array
	
	Audience = 0		// audience bitmask, by default everyone can execute
	
	HelpGroup = "";		// group of help commands
	HelpIndex = 0;		// index in help group (command sorting)
	
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
	function PrintLongHelp(client) {
		if (CanUse(client, false)) {			
			local alias_str = "";
			if (this.Aliases != null) {									
				foreach(i, alias in this.Aliases) {
					if (i > 0)
						alias_str += ", ";
					alias_str += ("/"+ alias);
				}
				alias_str = " (aliases "+ alias_str +")";				
			}
			::SAIServer.SayClient(client, format("-= Detailed help for command '/%s'%s =-", this.Name, alias_str));				

			// print long command help								
			if (this.LongHelp != null)
				foreach(i, msg in this.LongHelp) {
					::SAIServer.SayClient(client, msg);
				}
		}	
	}
	
	/**
	* Print command short help
	*/
	function PrintShortHelp(client) {
		if (CanUse(client, false)) {
			::SAIServer.SayClient(client, format("/%s - %s", this.Name, this.ShortHelp));
		}
	}
	
	/**
	* May the client use this command? (for admin/mod implementation)
	*/
	function CanUse(client, print_errors) {
		if (Audience != 0) {
			// handle command restrictions
			if ((Audience & AudienceFlags.ValidCompany) != 0) {
				//only clients with valid company				
				if (!::SAICompany.IsValid(::SAIClient.GetCompany(client))) {
					if (print_errors)
						::SAIServer.SayClient(client, "This command is only available when you are playing in a company.");
					return false;
				}				
			}		
			if ((Audience & AudienceFlags.Moderators) != 0) {
				//only moderators								
				if (!::SAIClient.IsModerator(client) && !::SAIClient.IsAdmin(client)) {
					if (print_errors)
						::SAIServer.SayClient(client, "This command is only available for server moderators.");
					return false;
				}				
			}	
			if ((Audience & AudienceFlags.Admins) != 0) {
				//only admins								
				if (!::SAIClient.IsAdmin(client)) {
					if (print_errors)
						::SAIServer.SayClient(client, "This command is only available for server admins.");
					return false;
				}				
			}	
		}		
		return true;
	}
}

/**
* Client command manager class for command registration and handling
*/
class CCManager {
	static commandLookups = {};
	
	/**
	* Register new client command
	*/
	static function Register(commandSpec) {
		if (!(commandSpec instanceof ClientCommand)) {
			Log.Error("You have to supply instance of ClientCommand to Register()");
			return false;
		}
		if (commandSpec.Name in CCManager.commandLookups) {
			Log.Error(format("Command \"%s\" already registed", commandSpec.Name));
			return false;
		}
		if (commandSpec.ExecuteFunction != null && typeof(commandSpec.ExecuteFunction) != "function") {
			Log.Error(format("Command \"%s\" invalid ExecuteFunction specification", commandSpec.Name));
			return false;		
		} 		
		CCManager.commandLookups[commandSpec.Name] <- commandSpec;
		
		// register also aliases
		foreach(i, alias in commandSpec.Aliases) {
			local lowerAlias = alias.tolower();
			if (lowerAlias in CCManager.commandLookups) {
				Log.Error(format("Error registering command \"%s\" alias \"%s\", command already exists.", commandSpec.Name, lowerAlias));
				return false;
			}
			CCManager.commandLookups[lowerAlias] <- commandSpec;
		}					
	} 
	
	/**
	* Process execution of client command
	*/
	static function ProcessClientCommand(client, commandName, ...) {
		local commandNameLower = commandName.tolower();
		if (commandNameLower in CCManager.commandLookups) {
			local commandSpec = CCManager.commandLookups[commandNameLower];
			
			// process params
			local param_arr = array(vargc + 2)
			param_arr[0] = commandSpec 	// this context
			param_arr[1] = client		// client id
			
			// fill dynamic params
			for(local i=0; i<vargc; i++)
				param_arr[i+2] = vargv[i];
	
			if (!commandSpec.CanUse(client, true)) {
				Log.Warn(format("Client %d, tried to execute command \"%s\" (cannot use)", client, commandNameLower))
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
			return
		}
		
		// command was not found
		::SAIServer.SayClient(client, format("Command \"%s\" does not exist.", commandName));		
	}
	
	/**
	* Print commands from specified helpGroup
	*/
	static function PrintHelpGroup(client, helpGroup) {
		local helpCommands = [];
		
		foreach(key, commandSpec in CCManager.commandLookups) {
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
			commandSpec.PrintShortHelp(client);			
	}
	
	/**
	* Get command specification
	*/
	static function GetCommandSpec(commandName) {
		if (commandName in CCManager.commandLookups)
			return CCManager.commandLookups[commandName];
		else
			return null;
	}
	
	/**
	* Print short help for specified command
	*/
	function ShortHelp(client, command) {
		local commandSpec = CCManager.GetCommandSpec(command);
		if (commandSpec != null)
			commandSpec.PrintShortHelp(client);
	}	
	
	/**
	* Print long help for specified command
	*/
	function LongHelp(client, command) {
		local commandSpec = CCManager.GetCommandSpec(command);
		if (commandSpec != null)
			commandSpec.PrintLongHelp(client);
	}		
}
