using System;

namespace UMNAutoPackger
{
    public class DeploymentSetting
    {
        public bool AllowRepairApp { get; set; }
        public string DeployAction { get; set; }
        public string DeployPurpose { get; set; }
        public bool OverrideServiceWindow { get; set; }
        public bool PreDeploy { get; set; }
        public bool RebootOutsideServiceWindow { get; set; }
        public bool ReplaceToastNotificationWithDialog { get; set; }
        public bool SendWakeupPacket { get; set; }
        public string TimeBasedOn { get; set; }
        public string UserNotification { get; set; }
        public int AvailStart { get; set; }
        public int AvailHour { get; set; }
        public int AvailMinute { get; set; }
    }
}
