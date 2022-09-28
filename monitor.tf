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
  query              = "\"datadog.agent.up\".over(\"*\").by(\"*\").last(1).pct_by_status()"
  #enable_logs_sample = true
  notify_no_data     = true
  #notify_audit       = false
  priority           = 1
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

resource "datadog_monitor" "CPU-monitor" {
  name  = "EC2 CPU monitor"
  type  = "query alert"
  query = "avg(last_5m):avg:aws.ec2.cpuutilization{*} by {host} > 25"
  priority = 1
  notify_no_data = false
  renotify_interval = 0
  new_group_delay = 60

  message = <<EOF
  {{#is_alert}}
  @slack-infratest  
  <!here> High CPU! The host is {{host}}.   
  If you are able to analyze and resolve, please chat for this alert message and then start to work on it.  
  {{/is_alert}}
  
  {{#is_recovery}}  
  @slack-infratest  
  resolved  
  {{/is_recovery}}
  EOF
}

resource "datadog_dashboard" "terraform-dashboard" {
  title = "Datadog Dashboard made by Terraform"
  description = "Make By Terraform"
  layout_type = "ordered"
}