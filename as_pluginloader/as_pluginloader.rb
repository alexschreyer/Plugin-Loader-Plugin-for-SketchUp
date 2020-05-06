# ============================
# Main file for Plugin Loader
# ============================


require 'sketchup'


# ============================


module AS_Extensions

  module AS_PluginLoader
  
  
    # ============================
    
    
    # Get default user directory as a start  
    @dir = (ENV['USERPROFILE'] != nil) ? ENV['USERPROFILE'] : 
           ((ENV['HOME'] != nil) ? ENV['HOME'] : File.dirname(__FILE__) )
    # Get working directory from last opened if it exists
    @last_dir = Sketchup.read_default "as_PluginLoader", "last_dir"
    @dir = @last_dir if @last_dir != nil
    # Do some spring cleaning on the path
    @dir = File.expand_path( @dir )

    # Load extensions at startup from saved added path
    @added_path = Sketchup.read_default 'as_PluginLoader', 'added_path', ''
    if @added_path != ""
      loc = File.expand_path( @added_path )
      require_all( loc )
    end
    
    # ============================
  
  
    def self.load_plugin_file
    # Loads single plugin from RB file
    
      # Pick an RB file      
      f = UI.openpanel( "Select the main (top level) Ruby / Extension file to load it", @dir, "Ruby Files|*.rb|All Files|*.*||" )
  
      if f
      
        begin
        
          raise "Selected file is not a Ruby file." if File.extname(f) != ".rb"
          
          # Load this plugin
          d = File.dirname( f )
          d = File.expand_path( d )
          $: << d unless $:.include? d
          load f
          
          # Set directory as last used and give feedback
          @dir = d
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          UI.messagebox "Successfully loaded Ruby file / extension at: \n\n#{f}\n\nIf this is an extension, then it will remain available until you exit SketchUp."
          
        rescue => e
        
          UI.messagebox "Could not load Ruby file / extension at: \n#{f}\n\nError: #{e}"
          
        end
        
      end
      
    end # load_plugin_file
    
    
    # ============================
  
  
    def self.load_plugin_folder
    # Load all plugins from selected folder
    
      begin
      
        # Get directory of RB files. Can't use directory selection if less than 15
        v = Sketchup.version.to_f
        if v >= 15.0
          d = UI.select_directory(
            title: "Select folder containing the main Ruby files / extensions (RB files) to load",
            directory: @dir
          )
        else   
          UI.messagebox( "Select any file in a folder containing the main Ruby files / extensions (RB files) - everything will be loaded from that folder" )
          f = UI.openpanel( "Select any file", @dir, "*.rb" )
          d = File.dirname( f )    
        end
        
        raise if d == nil
        
        d = File.expand_path( d )
        Dir.chdir( d )  
        $: << d unless $:.include? d    
    
        # Get all of the RB files in the directory
        rbfiles = Array.new
        rbfiles = Dir.glob("*.rb")
        raise "No valid RB files in directory." if rbfiles.empty?
  
        # Modified require_all function - loads all files in folder
        rbfiles.each {|f| load f}
        
        # Set directory as last used and give feedback 
        @dir = d
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        UI.messagebox "Successfully loaded Ruby files / extensions: \n\n#{rbfiles.join("\n")}\n\nFrom: #{@dir.to_s}\n\nIf these are extensions, then they will remain available until you exit SketchUp."
        
      rescue => e
      
        UI.messagebox "Did not load files / extensions.\n\nError: #{e}" if !e.to_s.empty?
      
      end    
      
    end # load_plugin_folder
    
    
    # ============================  
    
    
    def self.load_plugin_zip
    # Installs a plugin permanently from a ZIP or RBZ file
    
      f = UI.openpanel("Select an extension installer file (with RBZ or ZIP extension)", @dir, "RBZ Files|*.rbz|ZIP Files|*.zip|All Files|*.*||")
      
      if f
      
        begin
        
          raise "Selected file is not an RBZ or ZIP file." if !(File.extname(f).include? ".rbz" or File.extname(f).include? ".zip")
          
          # Install this plugin using SketchUp's built-in function
          res = Sketchup.install_from_archive( f )
          UI.messagebox "Successfully installed extension from: \n\n#{f}\n\nThis extension will remain available until you uninstall it from the Extension Manager dialog." if res 
          
          # Set directory as last used - no feedback here because this is done by installer
          d = File.dirname( f )
          @dir = File.expand_path( d )
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          
        rescue => e
        
          UI.messagebox "Couldn't install this RBZ or ZIP extension: \n#{f}\n\nError: #{e}"
          
        end
        
      end
      
    end # load_plugin_zip  
    
    
    # ============================
  
  
    def self.add_path
    # Offer to add an additional load path to the SketchUp startup
    
      @added_path = Sketchup.read_default 'as_PluginLoader', 'added_path', ''
      
      msg = "In addition to loading from SketchUp's regular Plugins/Extensions directory, "
      if @added_path != ""
        msg += "all extensions contained in the following directory are also currently being loaded automatically at startup:\n\n#{@added_path}\n\nDo you want to change this?"
      else
        msg += "no extensions are currently being loaded from an additional location.\n\nDo you want to specify a new, separate startup loading directory?"
      end
      res = UI.messagebox msg, MB_YESNO
      
      if res == IDYES
      
        d = UI.select_directory( title: "Select additional directory containing Extensions to be loaded at startup" )
        
        if d != nil
          @added_path = File.expand_path( d )
          UI.messagebox "The following additional directory path has now been stored:\n\n#{@added_path}\n\nExtensions contained within it will be loaded automatically each time you start SketchUp."
        else
          res = UI.messagebox "Do you want to clear this currently stored directory:\n\n#{@added_path}\n\nDoing so will only load regularly installed SketchUp extensions at the next startup.", MB_YESNO
          @added_path = "" if res == IDYES
        end
        
      end
      
      Sketchup.write_default 'as_PluginLoader', 'added_path', @added_path
    
    end # add_path 
  
  
    # ============================
  
  
    def self.show_url( title , url )
    # Show website either as a WebDialog or HtmlDialog
    
      if Sketchup.version.to_f < 17 then   # Use old dialog
        @dlg = UI::WebDialog.new( title , true ,
          title.gsub(/\s+/, "_") , 1000 , 600 , 100 , 100 , true);
        @dlg.navigation_buttons_enabled = false
        @dlg.set_url( url )
        @dlg.show      
      else   #Use new dialog
        @dlg = UI::HtmlDialog.new( { :dialog_title => title, :width => 1000, :height => 600,
          :style => UI::HtmlDialog::STYLE_DIALOG, :preferences_key => title.gsub(/\s+/, "_") } )
        @dlg.set_url( url )
        @dlg.show
        @dlg.center
      end  
    
    end  

    def self.show_help
    # Show the website as an About dialog
    
      show_url( "#{@exttitle} - Help" , 'https://alexschreyer.net/projects/plugin-loader-for-sketchup/' )

    end # show_help
    
    
    # ============================
    
    
    if !file_loaded?(__FILE__)
    
      # Get the SketchUp plugins menu
      as_rubymenu = UI.menu("Plugins").add_submenu("Ruby / Extension Loader")
    
      # Add menu items
      if as_rubymenu
      
        as_rubymenu.add_item("Load single Ruby file / extension (RB)") { AS_PluginLoader::load_plugin_file }
        as_rubymenu.add_item("Load all Ruby files / extensions from a directory (RB)") { AS_PluginLoader::load_plugin_folder }
        as_rubymenu.add_item("Set/Edit additional load path for extensions") { AS_PluginLoader::add_path }        
    
        as_rubymenu.add_separator
        
        as_rubymenu.add_item("Install single extension (RBZ or ZIP)") { AS_PluginLoader::load_plugin_zip } if Sketchup.version_number >= 8000999
        as_rubymenu.add_item("Manage installed extensions") { UI.show_extension_manager } if UI.respond_to?('show_extension_manager')
        as_rubymenu.add_item("Open SketchUp's Plugins/Extensions directory") { UI.openURL("file:///#{Sketchup.find_support_file('Plugins')}") }
        
        as_rubymenu.add_separator
        
        as_rubymenu.add_item("Help") { AS_PluginLoader::show_help }
      
       end
      
      # Let Ruby know we have loaded this file
      file_loaded(__FILE__)
    
    end 
    

    # ============================
    
  
  end # module AS_PluginLoader
  
end # module AS_Extensions


# ============================
