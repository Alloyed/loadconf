project="loadconf"
title="Loadconf"
description="A reference library for loading conf.lua files"
format="markdown"
file={"loadconf.lua"}
dir="doc"
sort_modules=true
use_markdown_titles=true
backtick_references=true

custom_see_handler("^love/([%w_#]+)$", function(page)
	return "love/"..page, "https://love2d.org/wiki/" .. page
end)
