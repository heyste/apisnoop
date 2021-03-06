CREATE OR REPLACE VIEW "public"."stable_endpoint_stats" AS
  WITH stats as (
SELECT
  ec.bucket,
  ec.job,
  trim(trailing '-' from substring(bjs.job_version from 2 for 7)) as release, -- from v1.19.0-alphaxxx to 1.19.0
  ec.date,
  COUNT(1) as total_endpoints,
  COUNT(1) filter(WHERE tested is true) as test_hits,
  COUNT(1) filter(WHERE conf_tested is true) as conf_hits,
  ROUND(((count(*) filter(WHERE tested is true)) * 100 )::numeric / count(*), 2) as percent_tested,
  ROUND(((count(*) filter(WHERE conf_tested is true)) * 100 )::numeric / count(*), 2) as percent_conf_tested
  FROM endpoint_coverage ec
         JOIN bucket_job_swagger bjs on (bjs.bucket = ec.bucket AND bjs.job = ec.job)
    WHERE ec.level = 'stable'
 GROUP BY ec.date, ec.job, ec.bucket, bjs.job_version
  )
  SELECT
    *,
    test_hits - lag(test_hits) over (order by date) as test_hits_increase,
    conf_hits - lag(conf_hits) over (order by date) as conf_hits_increase,
    percent_tested - lag(percent_tested) over (order by date) as percent_tested_increase,
    percent_conf_tested - lag(percent_conf_tested) over (order by date) as percent_conf_tested_increase
    FROM
        stats
        ;
