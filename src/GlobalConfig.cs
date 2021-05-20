using System;

namespace UMNAutoPackager
{
    public class GlobalConfig : JsonBase
    {
        private DateTime _lastModified;
        public string CompanyName { get; set; }
        public string LastModified
        {
            get
            {
                return _lastModified.ToString();
            }
            set
            {
                if (value == "{currentDate}")
                {
                    _lastModified = DateTime.Now;
                }
            }
        }
        public PackagingTarget[] PackagingTargets { get; set; }
        public RecipeLocation[] RecipeLocations { get; set; }
    }
}
