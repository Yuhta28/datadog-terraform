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
  name  = "EC2 host connectivity"
  type  = "service check"
  query = "\"datadog.agent.up\".over(\"*\").by(\"*\").last(1).pct_by_status()"
  #enable_logs_sample = true
  notify_no_data = true
  #notify_audit       = false
  priority     = 1
  include_tags = true
  timeout_h    = 0
  message      = <<EOF
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
  name              = "EC2 CPU monitor"
  type              = "query alert"
  query             = "avg(last_5m):avg:aws.ec2.cpuutilization{*} by {host} > 25"
  priority          = 1
  notify_no_data    = false
  renotify_interval = 0
  new_group_delay   = 60

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

# Create Dashboard ALB connection
resource "datadog_dashboard" "terraform-dashboard" {
  title       = "Datadog Dashboard made by Terraform"
  description = "Make By Terraform"
  layout_type = "ordered"
  reflow_type = "fixed"

  widget {
    timeseries_definition {
      legend_columns = ["avg", "max", "min", "sum", "value"]
      legend_layout  = "auto"
      show_legend    = "true"
      title_align    = "left"
      title_size     = 16
      request {
        display_type   = "line"
        on_right_yaxis = false
        formula {
          formula_expression = "query1"
        }
        query {
          metric_query {
            data_source = "metrics"
            name        = "query1"
            query       = "sum:aws.applicationelb.active_connection_count{*} by {hostname}.as_count()"
          }
        }
        style {
          line_type  = "solid"
          line_width = "normal"
          palette    = "dog_classic"
        }
      }
    }
    widget_layout {
      height = 2
      width  = 4
      x      = 0
      y      = 0
    }
  }
}

# Create SLO metric
resource "datadog_service_level_objective" "terraform-slo-metric" {
  name = "Sample Metric"
  type = "metric"
  query {
    numerator   = "sum:aws.applicationelb.httpcode_elb_4xx{host:staging-alb-680906109.ap-northeast-1.elb.amazonaws.com}"
    denominator = "sum:aws.applicationelb.httpcode_target_2xx{host:staging-alb-680906109.ap-northeast-1.elb.amazonaws.com}"
  }
  thresholds {
    timeframe       = "7d"
    target          = 99.9
    warning         = 99.99
    target_display  = "99.900"
    warning_display = "99.990"
  }
  thresholds {
    timeframe       = "30d"
    target          = 99.9
    warning         = 99.99
    target_display  = "99.900"
    warning_display = "99.990"
  }
}