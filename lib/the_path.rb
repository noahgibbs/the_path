require "the_path/version"

module ThePath
    class MailChimpImpl
        # This isn't necessarily all MailChimp fields. Just the ones the_path is willing to look at.
        LIST_FIELDS = [:id, :web_id, :name, :contact, :permission_reminder, :use_archive_bar, :campaign_defaults, :notify_on_subscribe, :notify_on_unsubscribe, :date_created, :list_rating, :email_type_option, :subscribe_url_short, :subscribe_url_long, :beamer_address, :visibility, :double_optin, :has_welcome, :marketing_permissions, :modules, :stats]

        def initialize(repo_path:)
            @dump_files = {}
            @repo_path = repo_path

            def_mc_dump_file("lists") do
                list_data = gibbon_client.lists.retrieve(params: { "count" => 50 })

                lists = list_data.body[:lists].map { |item| item.slice(*LIST_FIELDS) }
                lists
            end
        end

        # Create and return a Gibbon API client object
        def gibbon_client
            return @gibbon_client if @gibbon_client

            require "gibbon"

            unless ENV["MAILCHIMP_API_KEY"]
                raise "Please set a MailChimp API key in the environment variable MAILCHIMP_API_KEY!"
            end

            gibbon = Gibbon::Request.new(api_key: ENV["MAILCHIMP_API_KEY"])
            gibbon.symbolize_keys = true
            gibbon.debug = true
            @gibbon_client = gibbon
        end

        private

        # This low-level API creates a MailChimp JSON dump file if it doesn't exist or isn't fresh enough.
        # The API is ordinarily used by ThePath to ensure freshness of MailChimp data before doing things
        # that may depend on it.
        def def_mc_dump_file(filename, &block)
            @dump_files[filename] = block
        end

        public
        def dump_file_data(filename, freshness: 15 * 60)
            unless @dump_files[filename]
                raise "No such dumpfile name: #{filename.inspect}"
            end

            path = File.join(@repo_path, filename + ".json")
            if File.exist?(path) && (Time.now - File.mtime(path)) < freshness
                STDERR.puts "Data is already fresh!"
                return JSON.load File.read(path)
            end

            data = @dump_files[filename].call
            File.open(path, "w") { |f| f.puts JSON.pretty_generate data }
            data
        end
    end
end
