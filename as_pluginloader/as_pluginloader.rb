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
    @dir = @dir.tr("\\","/")
    
    
    # ============================
  
  
    def self.load_plugin_file
    # Loads single plugin from RB file
    
      # Pick an RB file
      if Sketchup.version.to_f < 7.0
        f = UI.openpanel "Select a SketchUp Ruby extension file (with RB extension) to load it"
      else
        f = UI.openpanel( "Select a SketchUp Ruby extension file (with RB extension) to load it", @dir, "*.rb" )
      end
  
      if f
        begin
        
          raise "Selected file is not an RB file." if File.extname(f) != ".rb"
          
          # Load this plugin
          d = File.dirname(f) 
          $:.push d
          load f
          # Set directory as last used and give feedback
          @dir = d
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          UI.messagebox "Successfully loaded Extension: \n\n#{f.upcase!}\n\nIt will remain available until you restart SketchUp."
          
        rescue => e
        
          UI.messagebox "Could not load extension: \n#{f.upcase!}\n\nError: #{e}"
          
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
          UI.messagebox "Select Folder with multiple SketchUp extensions (RB files) to load"
          d = UI.select_directory  # Title syntax not compatible with SU 8
        elsif v >= 7.0    
          UI.messagebox "Select any file in a folder with multiple SketchUp extensions - all will be loaded from that folder"
          f = UI.openpanel( "Select RB file", @dir, "*.rb" )
          d = File.dirname(f)    
        else       
          UI.messagebox "Select any file in a folder with multiple SketchUp extensions - all will be loaded from that folder"
          f = UI.openpanel "Select RB file"
          d = File.dirname(f)    
        end
        
        raise if d == nil
    
        # Get all of the RB files in the directory
        rbfiles = Array.new
        Dir.chdir(d)
        rbfiles = Dir.glob("*.rb")
     
        raise "No valid RB files in directory." if rbfiles.empty?
  
        # Modified require_all function - loads all plugins in folder
        # p rbfiles
        $:.push d
        rbfiles.each {|f| load f}
        # Set directory as last used and give feedback 
        @dir = d
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        UI.messagebox "Successfully loaded these extensions: \n\n#{rbfiles.join("\n").upcase!}\n\nThey will remain available until you restart SketchUp."
        
      rescue => e
      
        UI.messagebox "Did not load extensions.\n\nError: #{e}"  if !e.empty?
      
      end    
      
    end # load_plugin_folder
    
    
    # ============================  
    
    
    def self.load_plugin_zip
    # Installs a plugin permanently from a ZIP or RBZ file
    
      f = UI.openpanel "Select a plugin/extension installer file (with RBZ or ZIP extension)", @dir, "*.rbz;*.zip"
      
      if f
        begin
        
          raise "Selected file is not an RBZ or ZIP file." if !(File.extname(f).include? ".rbz" or File.extname(f).include? ".zip")
          
          # Install this plugin using SketchUp's built-in function
          Sketchup.install_from_archive(f)
          # Set directory as last used - no feedback here because this is done by installer
          @dir = File.dirname(f)
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          
        rescue => e
        
          UI.messagebox "Couldn't install this RBZ or ZIP extension: \n#{f.upcase!}\n\nError: #{e}"
          
        end
      end
      
    end # load_plugin_zip  
  
  
    # ============================
  
  
    def self.show_help
    # Show the website as an About dialog
    
      dlg = UI::WebDialog.new('Plugin/Extension Loader - Help', true,'AS_pluginloader_Help', 1100, 800, 150, 150, true)
      dlg.set_url('http://www.alexschreyer.net/projects/plugin-loader-for-sketchup')
      dlg.show
      
    end # show_help
    
    
    # ============================
    
    
    if !file_loaded?(__FILE__)
    
      # Get the SketchUp plugins menu
      as_rubymenu = UI.menu("Plugins").add_submenu("Plugin/Extension Loader")
    
      # Add menu items
      if as_rubymenu
      
        as_rubymenu.add_item("Load single plugin/extension (RB)") { AS_PluginLoader::load_plugin_file }
        as_rubymenu.add_item("Load all plugins/extensions from a folder (RB)") { AS_PluginLoader::load_plugin_folder }
    
        as_rubymenu.add_separator
        
        as_rubymenu.add_item("Install single plugin/extension (RBZ or ZIP)") { AS_PluginLoader::load_plugin_zip } if Sketchup.version_number >= 8000999
        as_rubymenu.add_item("Manage installed plugins/extensions") { UI.show_preferences "Extensions" }   
        as_rubymenu.add_item("Open SketchUp's Plugins folder") { UI.openURL("file:///#{Sketchup.find_support_file('Plugins')}") }
        as_rubymenu.add_item("Help") { AS_PluginLoader::show_help }
      
       end
      
      # Let Ruby know we have loaded this file
      file_loaded(__FILE__)
    
    end 
    

    # ============================
    
  
  end # module AS_PluginLoader
  
end # module AS_Extensions


# ============================
