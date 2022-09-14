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
  name = "EC2"
  type = "service check"
  message = "EC2 Down!"
  query = "\"datadog.agent.up\".over(\"*\").by(\"host\").last(2).count_by_status()"
}