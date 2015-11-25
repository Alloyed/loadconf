package = "loadconf"
version = "scm-1"
source = {
   url = ""
}
description = {
   homepage = "",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      loadconf = "loadconf.lua"
   }
}
