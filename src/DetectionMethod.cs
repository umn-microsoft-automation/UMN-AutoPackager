namespace UMNAutoPackager

{
    public class DetectionMethod : JsonBase
    {
        // Might need to make this a datatype
        public string Type { get; set; }
        public string KeyName { get; set; }
        public string FileName { get; set; }
        public string DirectoryName { get; set; }
        public string Path { get; set; }
        public bool? Is64Bit { get; set; }
        public bool? Existence { get; set; }
        // Might need to make this a datatype
        public string PropertyType { get; set; }
        public string ExpectedValue { get; set; }
        // Might need to make this a datatype
        public string ExpressionOperator { get; set; }
        public string Hive { get; set; }
        public bool? Value { get; set; }
        public string ValueName { get; set; }
        public string ProductCode { get; set; }
    }
}
