require "the_path/version"

require "fileutils"
require "yaml"

module ThePath
    class Config
        attr_reader :actions

        def initialize(&block)
            @actions = []
            self.instance_eval(&block)
        end

        def default_sender(text)
        end

        def action(pathfile_contents)
            @actions.push ::ThePath::Action.new(pathfile_contents)
        end
    end

    class MailChimpImpl
        # This isn't necessarily all MailChimp fields. Just the ones the_path is willing to look at.
        LIST_FIELDS = [:id, :web_id, :name, :contact, :permission_reminder, :use_archive_bar, :campaign_defaults, :notify_on_subscribe, :notify_on_unsubscribe, :date_created, :list_rating, :email_type_option, :subscribe_url_short, :subscribe_url_long, :beamer_address, :visibility, :double_optin, :has_welcome, :marketing_permissions, :modules, :stats]
        MEMBER_FIELDS = [:id, :email_address, :unique_email_id, :email_type, :status, :merge_fields, :interests, :stats, :ip_signup, :timestamp_signup, :ip_opt, :timestamp_opt, :member_rating, :last_changed, :language, :vip, :email_client, :location, :tags_count, :tags]
        CAMPAIGN_FIELDS = [:id, :web_id, :type, :create_time, :archive_url, :long_archive_url, :status, :emails_sent, :send_time, :content_type, :needs_block_refresh, :has_logo_merge_tag, :resendable, :recipients, :settings, :tracking, :report_summary, :delivery_status]
        OPEN_DETAILS_FIELDS = [:campaign_id, :list_id, :list_is_active, :email_id, :email_address, :vip, :opens_count, :opens]
        CLICK_DETAILS_FIELDS = [:id, :url, :total_clicks, :click_percentage, :unique_clicks, :unique_click_percentage, :last_click, :campaign_id]

        def initialize(repo_path:, freshness: 15 * 60)
            @freshness = freshness
            @cached_resources = {}
            @repo_path = repo_path

            @cached_resources["lists"] = proc do
                list_data = fully_load(proc { gibbon_client.lists }, :lists)

                lists = list_data.map { |item| item.slice(*LIST_FIELDS) }
                possibly_typos = LIST_FIELDS - lists[0].keys
                unless possibly_typos.empty?
                    STDERR.puts "May have a typo in field: #{possibly_typos.inspect} for lists"
                end

                lists.each do |list|
                    list_id = list[:id]
                    list_dir_path = File.join(@repo_path, "list_#{list_id}")
                    FileUtils.mkdir_p list_dir_path
                    @cached_resources["list_#{list_id}/members"] = proc do
                        members_data = fully_load(proc { gibbon_client.lists(list_id).members }, :members)
                        members_data = members_data.map { |item| item.slice(*MEMBER_FIELDS) }
                        possibly_typos = MEMBER_FIELDS - members_data[0].keys
                        unless possibly_typos.empty?
                            STDERR.puts "May have a typo in field: #{possibly_typos.inspect} for members"
                        end
                        members_data
                    end
                end

                lists
            end

            @cached_resources["campaigns"] = proc do
                campaign_data = fully_load(proc { gibbon_client.campaigns }, :campaigns)

                campaigns = campaign_data.map { |item| item.slice(*CAMPAIGN_FIELDS) }
                possibly_typos = CAMPAIGN_FIELDS - campaigns[0].keys
                unless possibly_typos.empty?
                    STDERR.puts "May have a typo in field: #{possibly_typos.inspect} for campaigns"
                end

                campaigns.each do |campaign|
                    campaign_id = campaign[:id]
                    campaign_dir_path = File.join(@repo_path, "campaign_#{campaign_id}")
                    FileUtils.mkdir_p campaign_dir_path
                    @cached_resources["campaign_#{campaign_id}/open_details"] = proc do
                        open_details_data = fully_load(proc { gibbon_client.reports(campaign_id).open_details }, :members)
                        open_details_data = open_details_data.map { |item| item.slice(*OPEN_DETAILS_FIELDS) }
                        if open_details_data.size > 0
                            possibly_typos = OPEN_DETAILS_FIELDS - open_details_data[0].keys
                            unless possibly_typos.empty?
                                STDERR.puts "May have a typo in field: #{possibly_typos.inspect} for members"
                            end
                        end
                        open_details_data
                    end

                    @cached_resources["campaign_#{campaign_id}/click_details"] = proc do
                        click_details_data = fully_load(proc { gibbon_client.reports(campaign_id).click_details }, :urls_clicked)
                        click_details_data = click_details_data.map { |item| item.slice(*CLICK_DETAILS_FIELDS) }
                        if click_details_data.size > 0
                            possibly_typos = CLICK_DETAILS_FIELDS - click_details_data[0].keys
                            unless possibly_typos.empty?
                                STDERR.puts "May have a typo in field: #{possibly_typos.inspect} for members"
                            end
                        end
                        click_details_data
                    end


                end

                campaigns
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
                cur_batch = nil
                attempts = 0
                until cur_batch
                    attempts += 1
                    begin
                        cur_batch = gibbon_request.call().retrieve(params: { "count": 50, "offset": offset.to_s })
                    rescue Gibbon::MailChimpError
                        raise "Couldn't load data (field #{data_field.inspect}) due to MailChimpError! #{$!.inspect}" if attempts > 5
                        STDERR.puts "Retrying after MailChimpError, attempt #{attempts.inspect}: #{$!.inspect}"
                    end
                end
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
        def known_resources(match: "")
            @cached_resources.keys.select { |key| key[match] }
        end

        # This is another bad idea for normal use - it fully loads every piece of
        # MailChimp data it can find, likely taking many HTTP requests to do so.
        # It will still use the cache files if freshness allows.
        def load_all_resources(freshness: @freshness, match: "")
            loaded_resources = []
            loop do
                known_resources = @cached_resources.keys
                new_resources = known_resources(match: match) - loaded_resources
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

    class Action
        def initialize(dot_path_contents)
            nothing,frontmatter,contents = dot_path_contents.split("---\n", 3)
            if nothing != ""
                raise "Error: Nothing should be before the front matter in a pathfile!"
            end

            @front_data = YAML.load(frontmatter)
            @contents = contents
        end
    end
end
