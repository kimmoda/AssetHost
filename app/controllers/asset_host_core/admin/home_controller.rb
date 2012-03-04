module AssetHostCore
  class Admin::HomeController < AssetHostCore::ApplicationController  
    def index
    
    end

    #----------

    def chooser
      @assets = AssetHostCore::Asset.paginate(:per_page => 24, :page => 1, :order => "updated_at desc")
    
      render :layout => 'asset_host_core/minimal'
    end
  
    #----------

  end
end