using System.IO;
using System.Text.Json;
using System.Management.Automation;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsCommon.Set, "UMNPackageConfig")]
    [OutputType(typeof(FileInfo))]
    public class SetPackageDefinition : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public string Path;

        [Parameter(
            Mandatory = true,
            Position = 1,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public PackageConfig PackageDefinition;

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            JsonSerializerOptions Options = new JsonSerializerOptions
            {
                WriteIndented = true,
                IgnoreNullValues = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                IncludeFields = true
            };
            string JsonContent = JsonSerializer.Serialize<PackageConfig>(PackageDefinition, Options);
            File.WriteAllText(Path, JsonContent);
            FileInfo JsonFile = new FileInfo(Path);
            WriteVerbose(JsonContent);
            WriteObject(JsonFile);
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }

        protected override void StopProcessing()
        {
            base.StopProcessing();
        }
    }
}
