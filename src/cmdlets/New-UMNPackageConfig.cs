using System.Management.Automation;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsCommon.New, "UMNPackageConfig")]
    [OutputType(typeof(PackageConfig))]
    public class NewPackageDefinition : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0
        )]
        public string publisher;

        [Parameter(
            Mandatory = true,
            Position = 1
        )]
        public string productName;

        [Parameter(
            Mandatory = true,
            Position = 2
        )]
        public string description;
    }
}
