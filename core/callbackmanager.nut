/** 
* Class to handle callback registration and dispatching
*/
class CallbackManager {
	static _callback_listeners = {};
	
	/**
	* Register callback function fro specified event
	*/
	static function RegisterCallback(event, callback_func) {
		if (typeof callback_func != "function")
			return;		
		if (!(event in CallbackManager._callback_listeners)) {
			CallbackManager._callback_listeners[event] <- [];
		}
		CallbackManager._callback_listeners[event].append(callback_func);		
	}	
	
	/**
	* Returns all callbacks registered for specified event
	*/	
	static function GetCallbacks(event) {
		if (event in CallbackManager._callback_listeners)
			return CallbackManager._callback_listeners[event];
		return [];							
	}
}
