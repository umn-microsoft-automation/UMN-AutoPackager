using System;

namespace UMNAutoPackager
{
    public class PackageConfig : JsonBase
    {
        public string Publisher { get; set; }
        public string ProductName { get; set; }
        public string Description { get; set; }
        public string CurrentVersion { get; set; }
        public string VersionSource { get; set; }
        public Uri SourcePath { get; set; }
        public string ConfigNotes { get; set; }
        public bool OverridePackagingTarget { get; set; }
        public PackagingTarget[] PackagingTargets { get; set; }
    }
}
