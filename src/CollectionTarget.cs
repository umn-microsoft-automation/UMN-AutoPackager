namespace UMNAutoPackager
{
    public class CollectionTarget : JsonBase
    {
        public string Type { get; set; }
        public string Name { get; set; }
        public string LimitingCollectionName { get; set; }
        public string RefreshType { get; set; }
        public string RecurInterval { get; set; }
        public int RecurCount { get; set; }
        public int Month { get; set; }
        public int Day { get; set; }
        public int Year { get; set; }
        public int Hour { get; set; }
        public int Minute { get; set; }
        public DeploymentSetting DeploymentSettings { get; set; }
    }
}
