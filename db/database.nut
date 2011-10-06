/**
* Database base class
*/
class Database {
	conn = null;
	IsPersistable = false;	// need to by persisted sometimes?
	DataVolume = "";
	DataPath = "";

	function constructor(dataVolume, dataPath) {
		DataVolume = dataVolume;
		DataPath = dataPath;
				
		conn = ::SqliteConn();
	}	

	function Open() {		
		conn.Open(DataVolume + DataPath);
	}

	function Close() {
		conn.Close(true);
	}
	
	/**
	* Persist database (in case of fbwf storage
	*/
	function Persist() {
		if (IsPersistable) {
			::Log.Info(format("Persisting database %s%s", DataVolume, DataPath));
			
			Close();
			try {
				system(format("start cmd /c \"fbwfmgr /commit %s %s\"", DataVolume, DataPath));
			} catch(e) {
				::Log.Error(format("Cannot persist database (%s%s): %s", DataVolume, DataPath, e));
			}
			Open();
		}		
	}
}