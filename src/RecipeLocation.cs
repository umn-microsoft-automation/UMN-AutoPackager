using System;

namespace UMNAutoPackager
{
    public class RecipeLocation : JsonBase
    {
        public string LocationType { get; set; }
        public Uri LocationUri { get; set; }
    }
}
