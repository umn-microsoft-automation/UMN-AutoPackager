namespace UMNAutoPackger
{
    public class DeploymentType
    {
        public string Name { get; set; }
        public string InstallerType { get; set; }
        public string AdminComments { get; set; }
        public string Language { get; set; }
        public bool CacheContent { get; set; }
        public bool BranchCache { get; set; }
        public bool ContentFallback { get; set; }
        // Might need to make this a datatype
        public string OnSlowNetwork { get; set; }
        public string InstallCMD { get; set; }
        public string UninstallCMD { get; set; }
        public bool RunAs32Bit { get; set; }
        // Might need to make this a datatype
        public string InstallBehavior { get; set; }
        public bool LogonRequired { get; set; }
        // Might need to make this a datatype
        public string UserInteraction { get; set; }
        public int EstimatedRuntime { get; set; }
        public int MaxRuntime { get; set; }
        // Might need to make this a datatype
        public string RebootBehavior { get; set; }
        public DetectionMethod[] DetectionMethods { get; set; }
    }
}
