using System;

namespace UMNAutoPackger
{
    public class AutoPackagerConfiguration : GlobalConfigBase
    {
        public string CompanyName;
        public DateTime LastModified;
        public ConfigurationManagerSite[] ConfigMgr;
        public RecipieLocation[] RecipieLocations;
    }
}
