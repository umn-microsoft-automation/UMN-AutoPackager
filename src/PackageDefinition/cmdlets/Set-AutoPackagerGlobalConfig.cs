using System.IO;
using System.Text.Json;
using System.Management.Automation;

namespace UMNAutoPackger
{
    [Cmdlet(VerbsCommon.Set, "AutoPackagerGlobalConfig")]
    [OutputType(typeof(FileInfo))]
    public class SetAutoPackagerGlobalConfig : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public string filePath;

        [Parameter(
            Mandatory = true,
            Position = 1,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public AutoPackagerConfiguration packagerConfiguration;

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
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
            string JsonContent = JsonSerializer.Serialize<AutoPackagerConfiguration>(packagerConfiguration, Options);
            File.WriteAllText(filePath, JsonContent);
            FileInfo JsonFile = new FileInfo(filePath);
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
