using System.IO;
using System.Text.Json;
using System.Management.Automation;

namespace UMNAutoPackger
{
    [Cmdlet(VerbsCommon.Get, "AutoPackagerGlobalConfig")]
    [OutputType(typeof(AutoPackagerConfiguration))]
    public class GetAutoPackagerGlobalConfig : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public string filePath;

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
                    PropertyNameCaseInsensitive = true
                };

                string ConfigurationFile = File.ReadAllText(filePath);
                WriteVerbose(ConfigurationFile);
                AutoPackagerConfiguration PackagerConfiguration = JsonSerializer.Deserialize<AutoPackagerConfiguration>(ConfigurationFile);
                WriteObject(PackagerConfiguration);
            }
            catch (JsonException ex)
            {
                ErrorRecord ER = new ErrorRecord(ex, "JsonError", ErrorCategory.NotSpecified, filePath);
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
