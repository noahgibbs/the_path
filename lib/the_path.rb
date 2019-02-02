require "the_path/version"

require "fileutils"

module ThePath
    class MailChimpImpl
        # This isn't necessarily all MailChimp fields. Just the ones the_path is willing to look at.
        LIST_FIELDS = [:id, :web_id, :name, :contact, :permission_reminder, :use_archive_bar, :campaign_defaults, :notify_on_subscribe, :notify_on_unsubscribe, :date_created, :list_rating, :email_type_option, :subscribe_url_short, :subscribe_url_long, :beamer_address, :visibility, :double_optin, :has_welcome, :marketing_permissions, :modules, :stats]
        MEMBER_FIELDS = [:id, :email_address, :unique_email_id, :email_type, :status, :merge_fields, :interests, :stats, :ip_signup, :timestamp_signup, :ip_opt, :timestamp_opt, :member_rating, :last_changed, :language, :vip, :email_client, :location, :tags_count, :tags]

        def initialize(repo_path:, freshness: 15 * 60)
            @freshness = freshness
            @cached_resources = {}
            @repo_path = repo_path

            @cached_resources["lists"] = proc do
                list_data = fully_load(proc { gibbon_client.lists }, :lists)

                lists = list_data.map { |item| item.slice(*LIST_FIELDS) }

                lists.each do |list|
                    list_id = list[:id]
                    list_dir_path = File.join(@repo_path, "list_#{list_id}")
                    FileUtils.mkdir_p list_dir_path
                    @cached_resources["list_#{list_id}/members"] = proc do
                        members_data = fully_load(proc { gibbon_client.lists(list_id).members }, :members)
                        members_data.map { |item| item.slice(*MEMBER_FIELDS) }
                        #members_data
                    end
                end

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
            #gibbon.debug = true
            @gibbon_client = gibbon
        end

        # This grabs *all* of a given resource in batches, then returns it.
        # There are many reasons this can be a bad idea, which is why MailChimp
        # doesn't just let you do it trivially.
        #
        # In this case, this is a code smell and should be replaced by a
        # batch-load process which messes with only one chunk at a time.
        # Later, when the complexity is warranted, that will happen.
        def fully_load(gibbon_request, data_field)
            offset = 0
            data = []
            # There are several clever ways to use cur_batch.body[:total_items] here. Instead, we just keep
            # querying until we get less than the batch size and call it a day.
            loop do
                cur_batch = gibbon_request.call().retrieve(params: { "count": 50, "offset": offset.to_s })
                STDERR.puts "Concatenating current batch, existing size: #{data.size}, total size: #{cur_batch.body[:total_items].inspect}, data field: #{data_field.inspect}, new obj type: #{cur_batch.body[data_field].class}"
                if cur_batch.body[data_field] == nil
                    STDERR.puts "Error in return value:"
                    STDERR.puts cur_batch.body.inspect
                end
                data.concat cur_batch.body[data_field]
                if cur_batch.body[data_field].size < 50
                    # That was the last batch
                    return data
                end
                offset += 50
            end
        end

        # Return a list of all currently-known resource names.
        # Note that loading a resource can make other resources knowable,
        # which is a serious flaw in the current system.
        def known_resources
            @cached_resources.keys
        end

        # This is another bad idea for normal use - it fully loads every piece of
        # MailChimp data it can find, likely taking many HTTP requests to do so.
        # It will still use the cache files if freshness allows.
        def load_all_resources(freshness: @freshness)
            loaded_resources = []
            loop do
                known_resources = @cached_resources.keys
                new_resources = known_resources - loaded_resources
                return if new_resources.empty?
                new_resources.each do |new_resource|
                    STDERR.puts "Loading new resource: #{new_resource.inspect}"
                    # Load this resource, writing a cache file and possibly adding new knowable resources
                    cached_resource_get(new_resource, freshness: freshness)
                end
                loaded_resources += new_resources
            end
        end

        # Eventually this must be replaced. Right now it's not clear how resources get declared in a
        # refreshable way. If freshness is set to nil, files will automatically be considered stale.
        def cached_resource_get(resource_name, freshness: @freshness)
            path = File.join(@repo_path, resource_name + ".json")

            unless @cached_resources[resource_name]
                raise "No known resource named: #{resource_name.inspect}"
            end

            if freshness && File.exist?(path) && (Time.now - File.mtime(path)) < freshness
                STDERR.puts "Data is already fresh: #{resource_name.inspect} / Allowed: #{freshness.inspect} / Current: #{Time.now - File.mtime(path)}"
                return JSON.load File.read(path)
            end

            data = @cached_resources[resource_name].call
            STDERR.puts "Writing to file: #{path.inspect}"
            File.open(path, "w") { |f| f.puts JSON.pretty_generate data }
            data
        end
    end
end
