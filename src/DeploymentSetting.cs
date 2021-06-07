namespace UMNAutoPackager
{
    public class DeploymentSetting : JsonBase
    {
        public bool AllowRepairApp { get; set; }
        public string DeployAction { get; set; }
        public string DeployPurpose { get; set; }
        public bool OverrideServiceWindow { get; set; }
        public bool PreDeploy { get; set; }
        public bool RebootOutsideServiceWindow { get; set; }
        public bool ReplaceToastNotificationWithDialog { get; set; }
        public bool SendWakeupPacket { get; set; }
        public string TimeBaseOn { get; set; }
        public string UserNotification { get; set; }
        public int AvailStart { get; set; }
        public int AvailHour { get; set; }
        public int AvailMinute { get; set; }
        public int DeadlineStart { get; set; }
        public int DeadlineHour { get; set; }
        public int DeadlineMinute { get; set; }
    }
}
