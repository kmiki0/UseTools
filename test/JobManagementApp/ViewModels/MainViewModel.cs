using System.Collections.ObjectModel;
using JobManagementApp.Models;

namespace JobManagementApp.ViewModels
{
    public class MainViewModel
    {
        public ObservableCollection<JobModel> Jobs { get; set; }

        public MainViewModel()
        {
            Jobs = new ObservableCollection<JobModel>
            {
                new JobModel { JobId = 1, ExecutionType = "コマンド", LogFilePath = "C:\\logs\\job1.log" },
                new JobModel { JobId = 2, ExecutionType = "DB更新", LogFilePath = "C:\\logs\\job2.log" }
            };
        }
    }
}
