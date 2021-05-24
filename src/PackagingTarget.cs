using System;

namespace UMNAutoPackager
{
    public class PackagingTarget : JsonBase
    {
        public string Type { get; set; }
        public string Site { get; set; }
        public string SiteCode { get; set; }
        public Uri DownloadLocationPath { get; set; }
        public Uri ApplicationContentPath { get; set; }
        public string PreAppName { get; set; }
        public string PostAppName { get; set; }
        public DeploymentPoint DeploymentPoints { get; set; }
        public CollectionTarget[] CollectionTargets { get; set; }
        public string Name { get; set; }
        public string Owner { get; set; }
        public string SupportContact { get; set; }
        public string AdminComments { get; set; }
        public string OptionalReference { get; set; }
        public string[] AdminCategories { get; set; }
        public DateTime DatePublished { get; set; }
        public bool AllowTSUsage { get; set; }
        public string LocalizedApplicationName { get; set; }
        public string[] UserCategories { get; set; }
        public Uri UserDocumentation { get; set; }
        public string UserDocumentationText { get; set; }
        public Uri PrivacyLink { get; set; }
        public string LocalizedDescription { get; set; }
        public string[] Keywords { get; set; }
        public bool FeaturedApp { get; set; }
        public string IconFilename { get; set; }
        public DeploymentType[] DeploymentTypes { get; set; }
    }
}
