using System.Data.SQLite;
using JobManagementApp.Models;

namespace JobManagementApp.Services
{
    public static class JobService
    {
        private const string ConnectionString = "Data Source=Data/jobs.db;Version=3;";

        public static List<JobModel> LoadJobs()
        {
            var jobs = new List<JobModel>();
            using (var conn = new SQLiteConnection(ConnectionString))
            {
                conn.Open();
                var cmd = new SQLiteCommand("SELECT * FROM Jobs", conn);
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        jobs.Add(new JobModel
                        {
                            JobId = reader.GetInt32(0),
                            ExecutionType = reader.GetString(1),
                            LogFilePath = reader.GetString(2),
                            Command = reader.IsDBNull(3) ? "" : reader.GetString(3),
                            DbQuery = reader.IsDBNull(4) ? "" : reader.GetString(4)
                        });
                    }
                }
            }
            return jobs;
        }

        public static void ExecuteDatabaseJob(string query)
        {
            using (var conn = new SQLiteConnection(ConnectionString))
            {
                conn.Open();
                var cmd = new SQLiteCommand(query, conn);
                cmd.ExecuteNonQuery();
            }
        }
    }
}
