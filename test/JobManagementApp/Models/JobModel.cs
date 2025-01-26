namespace JobManagementApp.Models
{
    public class JobModel
    {
        public int JobId { get; set; }
        public string ExecutionType { get; set; }
        public string LogFilePath { get; set; }
        public string Command { get; set; }
        public string DbQuery { get; set; }
    }
}
