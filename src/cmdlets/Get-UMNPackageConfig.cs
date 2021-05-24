using System.IO;
using System.Text.Json;
using System.Management.Automation;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsCommon.Get, "UMNPackageConfig")]
    [OutputType(typeof(PackageConfig))]
    public class GetPackageDefinition : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public string Path;

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            try
            {
                JsonSerializerOptions Options = new JsonSerializerOptions
                {
                    AllowTrailingCommas = true,
                    PropertyNameCaseInsensitive = true,
                    IncludeFields = true
                };

                Options.Converters.Add(new DateTimeConverter());

                string PackageFile = File.ReadAllText(Path);
                WriteVerbose(PackageFile);
                PackageConfig PackageDef = JsonSerializer.Deserialize<PackageConfig>(PackageFile, Options);
                WriteObject(PackageDef);
            }
            catch (JsonException ex)
            {
                ErrorRecord ER = new ErrorRecord(ex, "JsonError", ErrorCategory.NotSpecified, Path);
                WriteError(ER);
            }
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
