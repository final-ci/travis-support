require 'metriks'

module Travis
  module Metrics
    module Reporter
      class << self
        def librato(config = Travis.config)
          require 'metriks/librato_metrics_reporter'
          return unless config = config.librato
          puts 'Starting Librato Metriks reporter'
          source = config.librato_source
          source = "#{source}.#{ENV['DYNO']}" if ENV.key?('DYNO')
          on_error = proc {|ex| puts "librato error: #{ex.message} (#{ex.response.body})"}
          Metriks::LibratoMetricsReporter.new(config.email, config.token, source: source, on_error: on_error)
        end

        def graphite(config = Travis.config)
          require 'metriks/reporter/graphite'
          options = config.graphite || {}
          host, port = options.values_at(:host, :port)
          Metriks::Reporter::Graphite.new(host, port)
        end
      end
    end

    METRICS_VERSION = 'v1'

    class << self
      attr_reader :reporter

      def setup(adapter = nil, config = Travis.config)
        if adapter ||= config.metrics.try(:reporter)
          Travis.logger.info("Starting metriks reporter #{adapter}.")
          @reporter = Reporter.send(adapter, config)
        end

        if reporter
          reporter.start
        else
          Travis.logger.info('No metriks reporter configured.')
        end
      rescue Exception => e
        puts "Exception while starting metrics reporter:"
        puts e.message, e.backtrace
      end

      def started?
        !!reporter
      end

      def meter(event, options = {})
        return if !started? || options[:level] == :debug

        event = "#{METRICS_VERSION}.#{event}"
        started_at, finished_at = options[:started_at], options[:finished_at]

        if finished_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end
  end
end
