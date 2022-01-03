using System;
using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace UMNAutoPackager
{
    public class DateTimeConverter : JsonConverter<DateTime>
    {
        public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            Debug.Assert(typeToConvert == typeof(DateTime));
            if (reader.GetString() == "{currentDate}")
            {
                return DateTime.Now;
            }
            else
            {
                return DateTime.Parse(reader.GetString());
            }
        }

        public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.ToUniversalTime().ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"));
        }
    }
}
