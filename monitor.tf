# monitor.tf
resource "datadog_monitor" "process_alert_example" {
  name    = "Process Alert Monitor"
  type    = "process alert"
  message = "Multiple Java processes running on example-tag"
  query   = "processes('java').over('example-tag').rollup('count').last('10m') > 1"
  monitor_thresholds {
    critical          = 1.0
    critical_recovery = 0.0
  }

  notify_no_data    = false
  renotify_interval = 60
}

resource "datadog_monitor" "ec2-check" {
  name               = "EC2 host connectivity"
  type               = "service check"
  query              = "\"datadog.agent.up\".over(\"*\").by(\"*\").last(2).count_by_status()"
  #enable_logs_sample = true
  notify_no_data     = true
  #notify_audit       = false
  priority           = 1
  #no_data_timeframe  = 2
  #renotify_interval  = 10
  include_tags       = true
  timeout_h          = 0
  message            = <<EOF
{{#is_alert}}
@slack-infratest  
<!here>There is an anomaly in EC2 host connectivity. The host is {{host}}.   
If you are able to analyze and resolve, please chat for this alert message and then start to work on it.  
{{/is_alert}}

{{#is_recovery}}
@slack-infratest  
The alert about EC2 host connectivity was resolved!!  
{{/is_recovery}}
EOF
}