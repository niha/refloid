require 'pstore'
exit if ARGV.empty?
class_name, current_apilevel = ARGV
current_apilevel ||= 8 # Android 2.2
current_apilevel = current_apilevel.to_i
table = PStore.new("#{ENV['HOME']}/.vim/plugin/table.db").transaction{|db| db[:table] }
candidates = table[class_name] || table.select{|k,v| k.start_with?(class_name) }.inject([]){|l, r| l + r[1] }
exit if candidates.size > 9
puts candidates.select{|name, href, apilevel| apilevel <= current_apilevel }.map{|name, href, _| "#{name} #{href}" }

