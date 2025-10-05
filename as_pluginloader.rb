=begin

Copyright 2009-2025, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED 'AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR ANY COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY ARISING FROM, OUT OF OR IN CONNECTION WITH THIS SOFTWARE OR THE USE OR OTHER DEALINGS IN THIS SOFTWARE.

WHERE APPLICABLE, THIRD-PARTY MATERIALS AND THIRD-PARTY PLATFORMS ARE PROVIDED 'AS IS' AND THE USER OF THIS SOFTWARE ASSUMES ALL RISK AND LIABILITY REGARDING ANY USE OF (OR RESULTS OBTAINED THROUGH) THIRD-PARTY MATERIALS OR THIRD-PARTY PLATFORMS.

License:        GPL (https://www.gnu.org/licenses/gpl-3.0.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/plugin-loader-for-sketchup

Name :          Ruby / Extension Loader

Version:        1.9

Date :          5/6/2020

Description :   Adds a menu item to the Plugins/Extensions menu, which helps with on-demand 
                loading of SketchUp extensions from any location.
                - Load single RB extension (on-demand)
                - Load all RB extensions from a folder (on-demand)
                - Install extension from RBZ or ZIP file
                - Store additional load location

Usage :         Place Ruby / extension and support files into a convenient location
                (e.g. a folder on a USB drive). Make sure correct extension folder structure is kept.
                Then load extensions using this tool from the lcation on-demand. After restarting
                SketchUp, your extension will be unloaded again, keeping SketchUp slim.

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
                1.3 (5/15/2013):
                - Added RBZ installing option
                - Updated archive links
                - Default file location is now userprofile
                - Plugin remembers last folder
                - Fixed up some dialogs and added more feedback
                - Now reports error if problem occurs
                - New folder structure
                - Fixed multiple loader code
                1.4 (5/16/2013):
                - Removed browser feature to comply with Trimble rules
                1.5 (2/17/2014):
                - Fixed saving of file paths to registry
                - Code cleanup
                1.6 (2/11/2015):
                - Cleaned up code
                - Added SU 15's dialog selector
                - Renamed plugin to extension where applicable
                1.7 (2/22/2015):
                - Added plugins directory menu item
                - Code cleanup
                - SketchUp 8 syntax error fix
                1.8 (9/10/2019):
                - Drop pre-SU8 support
                - Code cleanup
                - Minor bugfixes
                - Open dialog file selector update
                - Updated help website location and dialog
                - Drop word "plugin" in favor of "extension"
                - Show Extension Manager instead of preferences
                - Offer to store additional loading directory (e.g. on USB drive)
                1.9 (5/6/2020)
                - Minor code cleanup edits
                - Dialog fix for SU 2020 (GC issue)
                1.9.1 (TBD)
                - Minor code fixes
                

TODO List:

=end


# ========================


require 'sketchup'
require 'extensions'


# ========================


module AS_Extensions

  module AS_PluginLoader
  
    @extversion           = "1.9"
    @exttitle             = "Ruby / Extension Loader"
    @extname              = "as_pluginloader"
    
    @extdir = File.dirname(__FILE__)
    @extdir.force_encoding('UTF-8') if @extdir.respond_to?(:force_encoding)
    
    loader = File.join( @extdir , @extname , "as_pluginloader.rb" )
   
    extension             = SketchupExtension.new( @exttitle , loader )
    extension.copyright   = "Copyright 2009-#{Time.now.year} Alexander C. Schreyer"
    extension.creator     = "Alexander C. Schreyer, www.alexschreyer.net"
    extension.version     = @extversion
    extension.description = "Adds a menu item to the Plugins/Extensions menu, which helps with on-demand loading of SketchUp extensions from any location."
    
    Sketchup.register_extension( extension , true )
         
  end  # module AS_PluginLoader
  
end  # module AS_Extensions


# ========================
