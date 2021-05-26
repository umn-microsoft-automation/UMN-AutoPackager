using System;
using System.IO;
using System.Collections.Generic;
using System.Text.Json;
using System.Management.Automation;
using System.Text.Encodings.Web;

namespace UMNAutoPackager
{
    [Cmdlet(VerbsData.Update, "CurrentVersionJson")]
    [OutputType(typeof(bool))]
    public class UpdateCurrentVersionJson : PSCmdlet
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
        public string Version;

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            JsonSerializerOptions Options = new JsonSerializerOptions
            {
                AllowTrailingCommas = true,
                PropertyNameCaseInsensitive = true,
                IncludeFields = true,
                IgnoreNullValues = true
            };

            string PackageFile = File.ReadAllText(Path);
            //WriteVerbose(PackageFile);
            var PackageConfig = JsonSerializer.Deserialize<Dictionary<string, object>>(PackageFile);

            PackageConfig["currentVersion"] = Version;

            JsonSerializerOptions SerializeOptions = new JsonSerializerOptions
            {
                WriteIndented = true,
                IgnoreNullValues = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                IncludeFields = true,
                Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            };

            string OutputString = JsonSerializer.Serialize(PackageConfig, SerializeOptions);

            WriteVerbose(OutputString);

            File.WriteAllText(Path, OutputString);
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
