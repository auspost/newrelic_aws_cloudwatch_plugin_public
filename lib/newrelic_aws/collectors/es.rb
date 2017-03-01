module NewRelicAWS
  module Collectors
    class ES < Base
      def elastic_search
        es = Aws::ElasticsearchService::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region,
        )
        es.list_domain_names.domain_names.map { |name| name.domain_name }
      end

      def metric_list
        [
          ["ClusterStatus.green", "Average", "Count"],
          ["Nodes", "Average", "Count"],
          ["CPUUtilization", "Average", "Percent"],
          ["FreeStorageSpace", "Average", "Megabytes"],
        ]
      end

      def collect
        data_points = []
        @agent_options = NewRelic::Plugin::Config.config.options
        aws = @agent_options["aws"]
        account_id = aws["account_id"].to_s
        elastic_search.each do |domain_name|
          metric_list.each do |(metric_name, statistic, unit)|
            data_point = get_data_point(
              :namespace     => "AWS/ES",
              :metric_name   => metric_name,
              :statistic     => statistic,
              :unit          => unit,
              :dimensions    => [
                  {
                    :name  => "DomainName",
                    :value => domain_name 
                  },
                  {
                    :name => "ClientId",
                    :value => account_id
                  }
                ]
            )
            NewRelic::PlatformLogger.debug("metric_name: #{metric_name}, statistic: #{statistic}, unit: #{unit}, response: #{data_point.inspect}")
            unless data_point.nil?
              data_points << data_point
            end
          end
        end
        data_points
      end
    end
  end
end
