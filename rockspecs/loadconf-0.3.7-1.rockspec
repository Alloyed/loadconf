package = "loadconf"
version = "0.3.7-1"
source = {
   url = "git://github.com/Alloyed/loadconf",
   tag = "v0.3.7",
}
description = {
   homepage = "https://github.com/Alloyed/loadconf",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.5"
}
build = {
   type = "builtin",
   modules = {
      loadconf = "loadconf.lua"
   }
}
