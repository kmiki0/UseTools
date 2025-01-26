using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Windows.Input;
using JobManagementApp.Commands;
using JobManagementApp.Models;
using JobManagementApp.Services;

namespace JobManagementApp.ViewModels
{
    public class JobViewModel
    {
        public ObservableCollection<JobModel> Jobs { get; set; }
        public ICommand ExecuteJobCommand { get; }

        public JobViewModel()
        {
            Jobs = new ObservableCollection<JobModel>(JobService.LoadJobs());
            ExecuteJobCommand = new RelayCommand<JobModel>(ExecuteJob);
        }

        private void ExecuteJob(JobModel job)
        {
            if (job.ExecutionType == "コマンド")
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/C {job.Command}",
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                });
            }
            else if (job.ExecutionType == "DB更新")
            {
                JobService.ExecuteDatabaseJob(job.DbQuery);
            }
        }
    }
}
