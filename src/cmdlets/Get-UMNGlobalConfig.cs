using System.IO;
using System.Text.Json;
using System.Management.Automation;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsCommon.Get, "UMNGlobalConfig")]
    [OutputType(typeof(GlobalConfig))]
    public class GetUMNGlobalConfig : PSCmdlet
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
                    IncludeFields = true,
                    IgnoreNullValues = true
                };

                Options.Converters.Add(new DateTimeConverter());

                string GlobalConfigFile = File.ReadAllText(Path);
                WriteVerbose(GlobalConfigFile);
                GlobalConfig GlobalCfg = JsonSerializer.Deserialize<GlobalConfig>(GlobalConfigFile, Options);
                WriteObject(GlobalCfg);
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
