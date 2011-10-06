/**
** Various industry related utilities
**/
class IndustryUtils {

	/** 
	** Get raw industry statistics for produced and transported cargo and it's types
	**/
	static function GetRawIndustryStats() {
		local ind_table = {};
		local industries = AIIndustryList();
		industries.Valuate(::AIIndustry.GetIndustryType);
		
		foreach(ind, indtype in industries) {
			if (!(indtype in ind_table)) {
				ind_table[indtype] <- {
					Interesting = false,
					Count = 0,
					Cargo1 = -1,
					Cargo1Produced = 0,
					Cargo1Transported = 0, 
					Cargo2 = -1, 
					Cargo2Produced = 0,
					Cargo2Transported = 0 
				};
				
				if (::AIIndustryType.IsRawIndustry(indtype)) {
					local ind_spec = ind_table[indtype];
					ind_spec.Interesting = true;
										
					local cargos = ::AIIndustryType.GetProducedCargo(indtype);										
					local i=1;
					
					foreach(cargo, dummy in cargos) {
						// max dual cargo supported
						if (i==1) {
							ind_spec.Cargo1 = cargo;
						} else if (i==2) {
							ind_spec.Cargo2 = cargo;							
						}									
					}
				}		
			} 			
			local ind_spec = ind_table[indtype];
			if (ind_spec.Interesting) {
				ind_spec.Count++;
				
				if (ind_spec.Cargo1 >= 0) {
					ind_spec.Cargo1Produced += ::AIIndustry.GetLastMonthProduction(ind, ind_spec.Cargo1);
					ind_spec.Cargo1Transported += ::AIIndustry.GetLastMonthTransported(ind, ind_spec.Cargo1);				
				}						
				if (ind_spec.Cargo2 >= 0) {
					ind_spec.Cargo2Produced += ::AIIndustry.GetLastMonthProduction(ind, ind_spec.Cargo2);
					ind_spec.Cargo2Transported += ::AIIndustry.GetLastMonthTransported(ind, ind_spec.Cargo2);				
				}						
			}
		}			
		return ind_table;
	}
}