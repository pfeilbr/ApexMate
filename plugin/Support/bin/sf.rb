#!/usr/bin/env ruby

require 'ostruct'
require 'erb'
require 'cgi'

BUNDLE_SUPPORT = ENV['TM_BUNDLE_SUPPORT']
SUPPORT_PATH = ENV['TM_SUPPORT_PATH']
TM_FILEPATH = ENV['TM_FILEPATH']
TM_SELECTED_TEXT = ENV['TM_SELECTED_TEXT']
BASENAME = File.basename(TM_FILEPATH)
APEX_LOADER_PATH="#{BUNDLE_SUPPORT}/bin/apexLoader.app/Contents/MacOS/apexLoader"

COMMAND = ARGV[0]

HTML_TEMPLATE = <<-EOF
<!DOCTYPE html>

<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title><%= o.title %></title>
	<link rel="stylesheet" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.0/themes/ui-lightness/jquery-ui.css" type="text/css" media="screen" title="no title" charset="utf-8">
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript" charset="utf-8"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.0/jquery-ui.min.js" type="text/javascript" charset="utf-8"></script>
	<script type="text/javascript" charset="utf-8">
	jQuery(function($) {
		
	});	
	</script>
	<style type="text/css" media="screen">
	body {
	  background-color:#eee;
	}
	
	.list div:nth-child(odd){
	  background-color:#eee;
	}

	.list div:nth-child(even){
	  background-color:#B3D4FF;
	}	
	</style>
	
</head>
	<body>
	  <div id='header'>
	    <h1><%= o.title %></h1>
	  </div>
		<div id='content'>
		  <%= o.content %>
		</div>
	</body>
</html>
EOF

def hash2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hash2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hash2ostruct(i) }
  else
    object
  end
end

def html_list arr
  list_elements = arr.map {|e| "<div>#{CGI::escapeHTML(e)}</div>" }.join("\n")
  "<div class='list'>#{list_elements}</div>"
end

def html_output options
  o = hash2ostruct(options)
  erb = ERB.new( HTML_TEMPLATE, nil, "-" )
  erb.result( binding )
end

def login
  cmd = "\"#{APEX_LOADER_PATH}\" setCredentials"
  output = `#{cmd}`
  html_output :title => COMMAND, :content => output
end

def compileClass
  cmd = "\"#{APEX_LOADER_PATH}\" package \"#{TM_FILEPATH}\""
  output = `#{cmd}`
  html_output :title => COMMAND, :content => output
end

def compileTrigger
  cmd = "\"#{APEX_LOADER_PATH}\" trigger \"#{TM_FILEPATH}\""
  output = `#{cmd}`
  html_output :title => COMMAND, :content => output
end

def deployApexPage
  cmd = "\"#{APEX_LOADER_PATH}\" apexpage \"#{TM_FILEPATH}\""
  output = `#{cmd}`
  html_output :title => COMMAND, :content => output
  page_name = File.basename(BASENAME, '.page')
  %x{open "https://na7.salesforce.com/apex/#{page_name}"}
end

def runTests
  cmd = "\"#{APEX_LOADER_PATH}\" runTests \"#{TM_FILEPATH}\""
  output = `#{cmd}`
  html_output :title => COMMAND, :content => output
end


def executeAnonymous
  cmd = "\"#{APEX_LOADER_PATH}\" execAnon \"#{TM_FILEPATH}\""
  output = `#{cmd}`
  lines = output.split("\n")
  debug_lines = lines.select{|l| l =~ /USER_DEBUG/}
  debug_lines = debug_lines.map{ |l| l.split("|DEBUG|")[1] }
  
  output = if debug_lines.length == 0
    output
  else
    html_list debug_lines
  end
  
  html_output :title => COMMAND, :content => output
end

puts send(COMMAND.to_sym)
