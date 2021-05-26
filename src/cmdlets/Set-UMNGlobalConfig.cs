using System.IO;
using System.Text.Json;
using System.Text.Encodings.Web;
using System.Management.Automation;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsCommon.Set, "UMNGlobalConfig")]
    [OutputType(typeof(FileInfo))]
    public class SetUMNGlobalConfig : PSCmdlet
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
        public GlobalConfig GlobalConfig;

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
                IncludeFields = true,
                Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            };

            string JsonContent = JsonSerializer.Serialize<GlobalConfig>(GlobalConfig, Options);
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
