=begin

Copyright 2010-2013, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/plugin-loader-for-sketchup

Name :          PluginLoader

Version:        1.3

Date :          TBD

Description :   Adds a helper submenu to the plugin menu to offer these
                functions:
                - Load single plugin or load all plugins in a folder
                - Go to weblinks for plugin collections
                - Go to weblinks for Ruby resources
                
Usage :         The web links are self-explanatory. All will open in an
                external (system standard) browser. For the plugin loading
                functions it is important to note that plugin files have a RB
                extension.

History:        1.0 (3/9/2009):
                - first version
                1.1 (3/18/2009):
                - Added more plugin links and fixed some spelling
                - Added browser buttons and better explanation
                - Added help menu item and updated helpfile
                - Changed menu order a bit
                1.2 (11/3/2010):
                - Renamed some menu items
                - Added Google custom search
                - Added link to extension manager
                - Reformatted code and added module
                - Removed developer links (those are now in my Ruby Code Editor)
                - Changed layout of browser a bit
                - Fixed mac issues: dlg can't show modal, browser buttons dont work well
                1.3 (TBD):
                - Added RBZ loading option
                - Updates links
                - Default file location is now userprofile
                - Plugin remembers last folder
                - Fixed up some dialogs and added more feedback
                

TODO List:      - Dialog doesn't show up modal on mac.
                - Broser buttons don't work on mac.
                - Would be nice to open the plugin collections in a web dialog
                and then allow the user to download and install the plugin
                with one click. Later...
                - Folder selection is a bit workaroundish. A standard
                OS directory picker would be better.

=end


require 'sketchup.rb'

module AS_plugin_loader


  #============================


  HELPCONTENT =

"
Plugin Loader for SketchUp
v.1.2 (11/3/2010)
by Alexander Schreyer (www.alexschreyer.net)
------------------------------------------------

DESCRIPTION:

Adds a submenu to the plugin menu to offer these functions:
- Load single plugin or load all plugins in a folder
- Search online plugin collections and download plugins

WEBSITE:

http://www.alexschreyer.net/projects/plugin-loader-for-sketchup/

Subscribe to the comments on the above page so that you can be notified when a new version is available.

USE:

Loading plugins (single or multiple) -- Your plugin files (with RB extension) may be loaded from any location (hard disk, USB or network drive). If they are in the main SketchUp plugin folder, then you may be able to use this option to reload them (since they were already loaded when SketchUp started). For the second option, simply select any file within a folder and all contained plugins will be loaded.
Some (especially the more complex) plugins cannot be loaded using this method. In those cases, you'll have to install them into SketchUp's main plugins folder.

Finding plugins -- These links point to a variety of websites. After clicking a menu item, a web browser window opens within SketchUp. You can then browse to a plugin and download it. After closing the browser window, an option is presented to install the plugin right away. You can save these plugins anywhere. In a locked-down computer lab, it may be a good idea to save them to your USB memory stick.

INSTALLATION:

Download the ZIP file, unzip it and drop the contents into the SketchUp plugin directory (usually at C:\Program Files\Google\SketchUp 8\Plugins\ in Windows). Then re-start SketchUp and look for the new menu item in the Plugins menu.

Alternatively, you can save the plugin files anywhere (e.g. your USB memory stick - the H: drive in this example) and then load it into SketchUp (no restart required!) by opening the Ruby Console (Window > Ruby Console) and entering this (modify for your setup):

  load \"H:\\PluginLoader.rb\"

DISCLAIMER:

THIS SOFTWARE IS PROVIDED \"AS IS\" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

HISTORY:
                1.0 (3/9/2009) - first version
                1.1 (3/18/2009) - Changes:
                - Added more plugin links and fixed some spelling
                - Added browser buttons and better explanation
                - Added help menu item and updated helpfile
                - Changed menu order a bit
                1.2 (11/3/2010) - Changes:
                - Renamed some menu items
                - Added Google custom search
                - Added link to extension manager
                - Reformatted code and added module
                - Removed developer links (those are now in my Ruby Code Editor)
                - Changed layout of browser a bit
                - Fixed mac issues: dlg can't show modal, browser buttons dont work well

"


  # ============================
  
 
 
  # Get platform info
  @su_os = (Object::RUBY_PLATFORM =~ /mswin/i) ? 'windows' :
    ((Object::RUBY_PLATFORM =~ /darwin/i) ? 'mac' : 'other')
    
  # Get default directory as a start  
  @dir = (ENV['USERPROFILE'] != nil) ? ENV['USERPROFILE'] : 
    ((ENV['HOME'] != nil) ? ENV['HOME'] : File.dirname(__FILE__) )
  # Get working directory from last opened if it exists
  @last_dir = Sketchup.read_default "as_PluginLoader", "last_dir"
  @dir = @last_dir if @last_dir != nil
  # Do some spring cleaning
  @dir = @dir.split("/").join("\\") + "\\"
  if @su_os != 'windows'
    @dir = @dir.split("\\").join("/") + "/"
  end
  


  def self.load_plugin_file
  # Loads single plugin from RB file
  
    # UI.messagebox "Depending on a plugin's programmed dependecies, it may not be possible to load it using this tool.\nPlease make sure all required files are in the same directory."
    if Sketchup.version.to_f < 7.0
      filename = UI.openpanel "Select a SketchUp Ruby plugin file (with RB extension) to load it"
    else
      filename = UI.openpanel ( "Select a SketchUp Ruby plugin file (with RB extension) to load it", @dir, "*.rb" )
    end
    if filename
      begin
        # Load this plugin
        load filename
        # Set directory as last used and give feedback
        @dir = File.dirname(filename)
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir
        UI.messagebox "Successfully loaded RB plugin: \n#{filename}"
      rescue
        UI.messagebox "Could not load RB plugin: \n#{filename}"
      end
    end
    
  end # load_plugin_file



  def self.load_plugin_folder
  # Load all plugins from selected folder
  
    UI.messagebox "Select any file in the folder from where you would like to load all available RB plugins."
    if Sketchup.version.to_f < 7.0
      filename = UI.openpanel "Select any file - all plugins will be loaded from that folder"
    else
      filename = UI.openpanel ( "Select any file - all plugins will be loaded from that folder", @dir, "*.rb" )
    end
    if filename
      foldername = File.dirname(filename)
      begin
        # Modified require_all function - loads all plugins in folder
        rbfiles = Dir[File.join(foldername , "*.rb")]
        $:.push foldername
        rbfiles.each {|f| require f}
        # Set directory as last used and give feedback
        @dir = foldername
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir
        UI.messagebox "Successfully loaded all RB plugins from: \n#{foldername}"
      rescue
        UI.messagebox "Could not load all RB plugins from: \n#{foldername}"
      end
    end
    
  end # load_plugin_folder
  
  
  
  def self.load_plugin_zip
  # Installs a plugin permanently from a ZIP or RBZ file
  
    if Sketchup.version_number >= 8000999
      filename = UI.openpanel "Select a plugin/extension installer file (with RBZ or ZIP extension)", @dir, "*.rbz;*.zip"
      if filename
        begin
          # Install this plugin using SketchUp's built-in function
          Sketchup.install_from_archive(filename)
          # Set directory as last used - no feedback here because this is done by installer
          @dir = File.dirname(filename)
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir
        rescue
          UI.messagebox "Couldn't install this RBZ/ZIP plugin: \n#{filename}"
        end
      end
    else
      UI.messagebox "This tool can't install a plugin using your version of SketchUp. Please update to the latest version."
    end
    
  end # load_plugin_zip    



  def self.browse_webdlg(url)
  # Browse for plugins using webdialog
  
    dlg = UI::WebDialog.new("Download a SketchUp plugin...", true,
      "Plugin Browser", 960, 750, 150, 150, true);
    dlg_html = "<html><head></head><body style=\"margin:0;padding:0;font-family:Arial,sans-serif;font-size:9pt;color:#fff;background-color:#666;overflow:hidden;\"><div id=\"header\" style=\"height:10%;padding:10px;\">"
    if @su_os == 'windows'   # Only do this in Windows, javascript history doesn't work well on macs
      dlg_html += "<p style=\"width:20%;height:100%;float:left;\"><a href=\"javascript:history.back();\" style=\"color:#fff\">&laquo;BACK</a> | <a href=\"javascript:location.reload();\" style=\"color:#fff\">RELOAD</a> | <a href=\"javascript:history.forward()\" style=\"color:#fff\">NEXT&raquo;</a></p>"
    end
    dlg_html += "<p style=\"width:80%;float:right;text-align:left;\">Browse to a plugin and save it somewhere. If you want the plugin to automatically load with SketchUp, save it in this folder: <b>#{Sketchup.find_support_file("plugins")}</b>. Otherwise you'll have to load it manually.<br />Plugins have a RB file extension (Ruby script). Some may come in a ZIP archive that must be unzipped first. To install a plugin, get the RBZ or ZIP file and then use the installer menu item.</p></div><iframe style=\"clear:both;\" name=\"browser\" align=\"bottom\" id=\"browser\" src=\"#{url}\" width=\"100%\" height=\"90%\" scrolling=\"auto\" noresize=\"noresize\" frameborder=\"no\"></iframe></body></html>"
    dlg.set_html(dlg_html)
    dlg.navigation_buttons_enabled = false
    dlg.show_modal
    
    # Now ask if we should install/load the downloaded plugin
    if @su_os == 'windows'    # Only do this in Windows, Mac doesn't show dlg modal
      result = UI.messagebox "Do you want to load a plugin now?", MB_YESNO
      if (result == 6) # Clicked Yes
        load_plugin_file
      end
    end
    
  end # browse_webdlg
  
  

  def self.pluginloader_help
  # Show the About dialog and do an update check
  
    begin
      UI.messagebox HELPCONTENT, MB_MULTILINE, "Plugin Loader - About"
    rescue
      UI.messagebox "Couldn't display the About box.\nPlease go to my website for more information:\nhttp://www.alexschreyer.net/projects/plugin-loader-for-sketchup/"
    end
    
  end # pluginloader_help
  
  

end # module



# ====================================================



if !file_loaded?(__FILE__)

  # Get the SketchUp plugins menu
  plugins_menu = UI.menu("Plugins")
  as_rubymenu = plugins_menu.add_submenu("Plugin Loader")

  # Add menu items
  if as_rubymenu
  
    as_rubymenu.add_item("Load single plugin (RB)") { AS_plugin_loader::load_plugin_file }
    as_rubymenu.add_item("Load all plugins from a folder") { AS_plugin_loader::load_plugin_folder }
    as_rubymenu.add_item("Install single plugin (RBZ or ZIP)") { AS_plugin_loader::load_plugin_zip }
    as_rubymenu.add_item("Manage installed plugins") { UI.show_preferences "Extensions" }
    
    as_rubymenu.add_separator
  
    as_rubymenu.add_item("Plugin Search (Google Custom Search)") {
      AS_plugin_loader::browse_webdlg("http://www.google.com/cse?cx=004295665205910887318:3ovib9jeubq&ie=UTF-8&q=") }
    as_rubymenu.add_item("Trimble - SketchUp Plugins Index") {
      AS_plugin_loader::browse_webdlg("http://www.sketchup.com/download/plugins.html") }
    as_rubymenu.add_item("Trimble - SketchUp Ruby Scripts Index") {
      AS_plugin_loader::browse_webdlg("http://www.sketchup.com/download/rubyscripts.html") }
    as_rubymenu.add_item("SketchUp Plugin Index") {
      AS_plugin_loader::browse_webdlg("http://sketchupplugins.com/") }
    as_rubymenu.add_item("SketchUcation - Plugins Index") {
      AS_plugin_loader::browse_webdlg("http://sketchucation.com/forums/viewtopic.php?f=323&t=28782") }
    as_rubymenu.add_item("SCF - Visual Plugin Index") {
      AS_plugin_loader::browse_webdlg("http://sketchucation.com/forums/viewtopic.php?f=323&t=16909") }
    as_rubymenu.add_item("Ruby Library Depot") {
      AS_plugin_loader::browse_webdlg("http://rhin.crai.archi.fr/rld/") }
      
    as_rubymenu.add_separator

    as_rubymenu.add_item("About") { AS_plugin_loader::pluginloader_help }
  
   end
  
  # Let Ruby know we have loaded this file
  file_loaded(__FILE__)

end # if
