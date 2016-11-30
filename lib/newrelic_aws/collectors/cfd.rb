module NewRelicAWS
  module Collectors
    class CFD < Base
      def cloudfront_distributions
        cfd = Aws::CloudFront::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region,
        )
        cfd.list_distributions.distribution_list.items.map { |name| name.id }
      end

      def metric_list
        [
          ["Requests", "Sum", "Count"],
          ["BytesDownloaded", "Sum", "Bytes", 0],
          ["BytesUploaded", "Sum", "Bytes", 0],
          ["TotalErrorRate", "Average", "Percent", 0],
          ["4xxErrorRate", "Average", "Percent", 0],
          ["5xxErrorRate", "Average", "Percent", 0]
        ]
      end

      def collect
        data_points = []
        cloudfront_distributions.each do | distribution_id |
          metric_list.each do |(metric_name, statistic, unit, default_value)|
            data_point = get_data_point(
              :namespace     => "AWS/CloudFront",
              :metric_name   => metric_name,
              :statistic     => statistic,
              :unit          => unit,
              :default_value => default_value,
              :dimensions    => [
                {
                  :name  => "DistributionId",
                  :value => distribution_id
                },
                {
                  :name  => "Region",
                  :value => "Global"
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
