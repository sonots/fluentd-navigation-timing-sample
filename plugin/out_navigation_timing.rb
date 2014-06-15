module Fluent; end

class Fluent::NavigationTimingOutput < Fluent::Output
  Fluent::Plugin.register_output('navigation_timing', self)

  config_param :tag, :string, :default => nil

  # To support log_level option implemented by Fluentd v0.10.43
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  def configure(conf)
    super
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      new_record = {}
      new_record['redirect'] = record['redirectEnd'].to_i - record['redirectStart'].to_i
      new_record['appCache'] = record['domainLookupStart'].to_i - record['fetchStart'].to_i
      new_record['dns']      = record['domainLookupEnd'].to_i - record['domainLookupStart'].to_i
      new_record['tcp']      = record['connectionEnd'].to_i - record['connectionStart'].to_i
      new_record['request']  = record['responseStart'].to_i - record['requestStart'].to_i
      new_record['response'] = record['responseEnd'].to_i - record['responseStart'].to_i
      new_record['dom']      = record['domComplete'].to_i - record['domLoading'].to_i
      new_record['onLoad']   = record['loadEventEnd'].to_i - record['loadEventStart'].to_i
      log.info "out_navigation_timing: #{new_record}"
      Fluent::Engine.emit(@tag, time, new_record)
    end

    chain.next
  rescue => e
    log.warn e.message
    log.warn e.backtrace.join(', ')
  end
end
