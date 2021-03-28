SELECT employee_id,
       session_id,
       min(logged_at) AS start_time,
       max(logged_at) AS end_time
FROM
  ( SELECT *,
           sum(session_new) OVER (PARTITION BY employee_id
                                  ORDER BY logged_at ASC) AS session_id
   FROM
     ( SELECT employee_id,
              logged_at,
              prev_log_time,
              CASE
                  WHEN diff_prev/60 > 5 THEN 1
                  ELSE 0
              END AS session_new
      FROM
        (SELECT *,
                EXTRACT(EPOCH
                        FROM (logged_at - prev_log_time)) AS diff_prev
         FROM
           ( SELECT employee_id,
                    log_minute AS logged_At,
                    lag(log_minute) OVER (PARTITION BY employee_id
                                          ORDER BY log_minute ASC) AS prev_log_time
            FROM
              ( SELECT employee_id,
                       date_trunc('min', logged_at::TIMESTAMP) AS log_minute
               FROM app_analytics
               WHERE logged_at >= date_Trunc('month', now() - interval '12 months')
               GROUP BY 1,
                        2 ) b ) a ) a ) b) c
GROUP BY 1,
         2;
