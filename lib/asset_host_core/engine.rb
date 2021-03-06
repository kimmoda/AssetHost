require 'rails'
require 'rake' # I don't know why, please don't ask
require 'resque'
require 'elasticsearch/model'
require 'paperclip'

require 'coffee-rails'
require 'sass-rails'
require 'eco'
require 'bootstrap-sass'

require 'simple_form'
require 'kaminari'


module AssetHostCore
  class Engine < ::Rails::Engine
    @@mpath = nil
    @@redis_pubsub = nil

    isolate_namespace AssetHostCore

    # initialize our config hash
    config.assethost = ActiveSupport::OrderedOptions.new

    # -- post-initialization setup -- #

    config.after_initialize do
      # set our resque job's queue
      AssetHostCore::ResqueJob.instance_variable_set :@queue, AssetHostCore.config.resque_queue || "assethost"
    end

    initializer 'asset_host_core.register_processor' do
      Paperclip.configure do |c|
        # Since this isn't in the standard location that Paperclip
        # looks for it (lib/paperclip_processors), we should just
        # register is manually to be safe.
        c.register_processor :asset_thumbnail, Paperclip::AssetThumbnail
      end
    end

    # add resque's rake tasks
    rake_tasks do
      require "resque/tasks"
    end

    #----------

    def self.mounted_path
      if @@mpath
        return @@mpath.spec.to_s == '/' ? '' : @@mpath.spec.to_s
      end

      # -- find our path -- #

      route = Rails.application.routes.routes.detect do |route|
        route.app == self
      end

      if route
        @@mpath = route.path
      end

      return @@mpath.spec.to_s == '/' ? '' : @@mpath.spec.to_s
    end

    #----------

    def self.redis_pubsub
      if AssetHostCore.config.redis_pubsub
        if @@redis_pubsub
          return @@redis_pubsub
        end

        return @@redis_pubsub ||= Redis.new(AssetHostCore.config.redis_pubsub[:server])
      else
        return false
      end
    end

    #----------

    def self.redis_publish(data)
      if r = self.redis_pubsub
        return r.publish(AssetHostCore.config.redis_pubsub[:key]||"AssetHost",data.to_json)
      else
        return false
      end
    end
  end
end
