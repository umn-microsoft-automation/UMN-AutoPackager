using System;

namespace UMNAutoPackager
{
    public class GlobalConfig : JsonBase
    {
        public string CompanyName { get; set; }
        public DateTime LastModified { get; set; }
        public Uri MEMCMModulePath { get; set; }
        public PackagingTarget[] PackagingTargets { get; set; }
        public RecipeLocation[] RecipeLocations { get; set; }
    }
}
