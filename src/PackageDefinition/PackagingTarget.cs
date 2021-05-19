using System;

namespace UMNAutoPackger
{
    public class PackagingTarget : PackageDefinitionBase
    {
        public string Type { get; set; }
        public string[] DistributionPointGroupName { get; set; }
        public string[] DistributionPointName { get; set; }
        public CollectionTarget[] CollectionTargets { get; set; }
        public string Name { get; set; }
        public string AdminComments { get; set; }
        public string OptionalReference { get; set; }
        public string[] AdminCategories { get; set; }

        // We need a private variable for the public variable.
        private DateTime datePublished;
        public String DatePublished
        {
            get
            {
                return datePublished.ToString();
            }
            set
            {
                if (value == "{currentDate}")
                {
                    datePublished = DateTime.Now;
                }
            }
        }
        public bool AllowTSUsage { get; set; }
        public string LocalizedApplicationName { get; set; }
        public string[] UserCategories { get; set; }
        public Uri UserDocumentation { get; set; }
        public string UserDocumentationText { get; set; }
        public Uri PrivacyLink { get; set; }
        public string LocalizedDescription { get; set; }
        public string[] Keywords { get; set; }
        public bool FeaturedApp { get; set; }
        public Uri IconLocationFile { get; set; }
        public DeploymentType[] DeploymentTypes { get; set; }
    }
}
