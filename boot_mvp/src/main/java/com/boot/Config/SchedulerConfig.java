package com.boot.Config;


import org.springframework.batch.core.Job;
import org.springframework.batch.core.JobParameters;
import org.springframework.batch.core.JobParametersBuilder;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

@Configuration
@EnableScheduling
public class SchedulerConfig {

    private final JobLauncher jobLauncher;
    private final Job movieJob;

    @Autowired
    public SchedulerConfig(JobLauncher jobLauncher, Job movieJob) {
        this.jobLauncher = jobLauncher;
        this.movieJob = movieJob;
    }

    // 매일 09시 02분에 실행. mvp.movie-batch.cron=- 로 두면 실행하지 않음 (내장 DB 샘플 데이터를 유지할 때)
    @Scheduled(cron = "${mvp.movie-batch.cron:0 02 09 * * ?}")
    public void runMovieJob() {
        try {
            JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();
            jobLauncher.run(movieJob, jobParameters);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

