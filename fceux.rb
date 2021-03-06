class Fceux < Formula
  desc "The all in one NES/Famicom Emulator"
  homepage "http://fceux.com"
  url "https://downloads.sourceforge.net/project/fceultra/Source%20Code/2.2.2%20src/fceux-2.2.2.src.tar.gz"
  sha256 "804d11bdb4a195f3a580ce5d2d01be877582763378637e16186a22459f5fe5e1"
  revision 3

  bottle do
    cellar :any
    sha256 "56512e7e3f4f874b330928f5a0ba9e30e71c9779772f342df348712e821cf583" => :el_capitan
    sha256 "a4d73c5f9ea1e74c74a3c4d25d3b2ee50f2724e1484a164cbf68636b740bb2cc" => :yosemite
    sha256 "d0bc3e23c70b73ee69ef17e5ceff417fa2d712998630711a66fd95e8df6e15ae" => :mavericks
  end

  deprecated_option "no-gtk" => "without-gtk+3"

  depends_on "pkg-config" => :build
  depends_on "scons" => :build
  depends_on "sdl"
  depends_on "gtk+3" => :recommended
  depends_on "lua51"

  # Make scons honor PKG_CONFIG_PATH and PKG_CONFIG_LIBDIR
  # Reported upstream: https://sourceforge.net/p/fceultra/bugs/625
  # Additional patches added to remove all traces of X11 and to enable a build against gtk+3.
  # Filed as bug https://sourceforge.net/p/fceultra/bugs/703/
  patch :DATA

  def install
    args = []
    args << "GTK=0"
    args << ((build.with? "gtk+3") ? "GTK3=1" : "GTK3=0")
    scons *args
    bin.install "src/fceux"
  end

  test do
    system "fceux", "-h"
  end
end

__END__
diff --git a/SConstruct b/SConstruct
index 4d5b446..36be2c4 100644
--- a/SConstruct
+++ b/SConstruct
@@ -62,6 +62,10 @@ if os.environ.has_key('CPPFLAGS'):
   env.Append(CPPFLAGS = os.environ['CPPFLAGS'].split())
 if os.environ.has_key('LDFLAGS'):
   env.Append(LINKFLAGS = os.environ['LDFLAGS'].split())
+if os.environ.has_key('PKG_CONFIG_PATH'):
+  env['ENV']['PKG_CONFIG_PATH'] = os.environ['PKG_CONFIG_PATH']
+if os.environ.has_key('PKG_CONFIG_LIBDIR'):
+  env['ENV']['PKG_CONFIG_LIBDIR'] = os.environ['PKG_CONFIG_LIBDIR']

 print "platform: ", env['PLATFORM']

@@ -112,16 +116,12 @@ else:
       Exit(1)
     # Add compiler and linker flags from pkg-config
     config_string = 'pkg-config --cflags --libs gtk+-2.0'
-    if env['PLATFORM'] == 'darwin':
-      config_string = 'PKG_CONFIG_PATH=/opt/X11/lib/pkgconfig/ ' + config_string
     env.ParseConfig(config_string)
     env.Append(CPPDEFINES=["_GTK2"])
     env.Append(CCFLAGS = ["-D_GTK"])
   if env['GTK3']:
     # Add compiler and linker flags from pkg-config
     config_string = 'pkg-config --cflags --libs gtk+-3.0'
-    if env['PLATFORM'] == 'darwin':
-      config_string = 'PKG_CONFIG_PATH=/opt/X11/lib/pkgconfig/ ' + config_string
     env.ParseConfig(config_string)
     env.Append(CPPDEFINES=["_GTK3"])
     env.Append(CCFLAGS = ["-D_GTK"])
diff --git a/SConstruct b/SConstruct
index dc6698e..a23350a 100644
--- a/SConstruct
+++ b/SConstruct
@@ -140,11 +140,11 @@ else:
     lua_available = False
     if conf.CheckLib('lua5.1'):
       env.Append(LINKFLAGS = ["-ldl", "-llua5.1"])
-      env.Append(CCFLAGS = ["-I/usr/include/lua5.1"])
+      env.Append(CCFLAGS = ["-I/usr/local/include/lua5.1"])
       lua_available = True
     elif conf.CheckLib('lua'):
       env.Append(LINKFLAGS = ["-ldl", "-llua"])
-      env.Append(CCFLAGS = ["-I/usr/include/lua"])
+      env.Append(CCFLAGS = ["-I/usr/local/include/lua"])
       lua_available = True
     if lua_available == False:
       print 'Could not find liblua, exiting!'
diff --git a/src/drivers/sdl/SConscript b/src/drivers/sdl/SConscript
index 7a53b07..6a9cbeb 100644
--- a/src/drivers/sdl/SConscript
+++ b/src/drivers/sdl/SConscript
@@ -1,12 +1,3 @@
-# Fix compliation error about 'XKeysymToString' by linking X11 explicitly
-# Thanks Antonio Ospite!
-Import('env')
-config_string = 'pkg-config --cflags --libs x11'
-if env['PLATFORM'] == 'darwin':
-  config_string = 'PKG_CONFIG_PATH=/opt/X11/lib/pkgconfig/ ' + config_string
-env.ParseConfig(config_string)
-Export('env')
-
 source_list = Split(
     """
     input.cpp
diff --git a/src/drivers/sdl/gui.cpp b/src/drivers/sdl/gui.cpp
index 98d4471..5599b35 100644
--- a/src/drivers/sdl/gui.cpp
+++ b/src/drivers/sdl/gui.cpp
@@ -20,7 +20,6 @@

 #include <gtk/gtk.h>
 #include <gdk/gdkkeysyms.h>
-#include <gdk/gdkx.h>

 #ifdef _GTK3
 #include <gdk/gdkkeysyms-compat.h>
@@ -1158,7 +1157,7 @@ void openSoundConfig()
										NULL);
	gtk_window_set_icon_name(GTK_WINDOW(win), "audio-x-generic");
	main_hbox = gtk_hbox_new(FALSE, 15);
-	vbox = gtk_vbox_new(False, 5);
+	vbox = gtk_vbox_new(FALSE, 5);

	// sound enable check
	soundChk = gtk_check_button_new_with_label("Enable sound");
diff --git a/src/drivers/sdl/sdl-video.cpp b/src/drivers/sdl/sdl-video.cpp
index 88aacd3..ed9ef3e 100644
--- a/src/drivers/sdl/sdl-video.cpp
+++ b/src/drivers/sdl/sdl-video.cpp
@@ -42,7 +42,6 @@

 #ifdef _GTK
 #include "gui.h"
-#include <gdk/gdkx.h>
 #endif

 #include <cstdio>
