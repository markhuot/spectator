#!/usr/bin/env ruby

require 'rubygems'
require 'tilt'
require 'fssm'
require 'fileutils'

class Watcher
	def initialize(src, dest)
		@src = src
		@dest = dest
	end
	
	def sync(base, relative)
		path = File.split(relative)[0]
		path = path=='.' ? '' : path+'/'
		
		name = File.basename relative, '.*'
		
		in_file = "#{@src}/#{relative}"
		out_file = "#{@dest}/#{relative}"
		out_dir = File.dirname out_file
		
		if File.directory? in_file
			FileUtils.mkdir_p out_file if !File.directory? out_file
		
		
		elsif File.file? in_file
			FileUtils.mkdir_p out_dir if !File.directory? out_dir
			
			engine = Tilt[in_file]
			if not engine.nil? and template = engine.new(in_file)
				out_file = "#{@dest}/#{path}#{name}.html"
				file = File.open out_file, "wb"
				file.write template.render
				file.close
			else
				FileUtils.copy in_file, out_file
			end
		end
		
		puts ">>> #{in_file}"
		puts "    #{out_file}"
	end
	
	def delete(base, relative)
		path = File.split(relative)[0]
		name = File.basename relative, '.*'
		
		in_file = "#{@src}/#{relative}"
		out_file = "#{@dest}/#{relative}"
		out_dir = File.dirname out_file
		
		engine = Tilt[in_file]
		if not engine.nil?
			out_file = "#{@dest}/#{path}/#{name}.html"
		end
		
		FileUtils.rm_rf out_file if File.exists? out_file
		
		puts "--- #{out_file}"
	end
end

src = File.expand_path ARGV[0]
dest = File.expand_path ARGV[1]

watcher = Watcher.new src, dest

Dir["#{src}/**/*"].each do |file|
	relative = file.sub(/^#{src}\/?/, '')
	watcher.sync src, relative
end

FSSM.monitor(src, '**/*', :directories => true) do
	create do |base, relative, type|
		watcher.sync base, relative
	end
	update do |base, relative, type|
		watcher.sync base, relative
	end
	delete do |base, relative, type|
		watcher.delete base, relative
	end
end