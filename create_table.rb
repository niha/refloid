require 'rubygems'
require 'open-uri'
require 'rexml/document'
require 'htree'
require 'pstore'

CLASS_REFERENCE_URL = 'http://developer.android.com/reference/classes.html'
CLASS_XPATH = "//td[@class='jd-linkcol']"

page = open(CLASS_REFERENCE_URL){|f| f.read }
doc = HTree.parse(page).to_rexml
tds = REXML::XPath.match(doc, CLASS_XPATH)
# class = [name, href, apilevel]
classes = tds.map do |td|
# ActivityUnitTestCase<T extends Activity> みたいな一つの td が複数の a を持つ場合もあるので
# td でひいて最初の a だけを加える
  a = td.elements.first
  tr = td.parent
  name = a.text
  href = a.attributes['href'].sub(/^\/reference/, '')
  # R.styleable だけ apilevel が設定されていないけど無視
  apilevel = (tr.attributes['class'].split - %w(alt-color api)).first.sub(/^apilevel-/, '').to_i
  [name, href, apilevel]
end

# Annotation とか名前被ってるのがあるので、そういうのは href から適当に名前空間で補完して区別
# /hoge/huga/hige/Name.html とかから hoge.huga.hige.Name を作る
names = classes.map &:first
classes.map! do |name, href, apilevel|
  if names.count(name) > 1
    name = (href.split('/')[1..-2] + [name]).join('.')
  end
  [name, href, apilevel]
end

# hoge.huga.ClassName みたいなのを ClassName と hoge.huga.ClassName に分けて
# Hash<class_name, Array<[name, href, apilevel]>> を作る
table = Hash.new
classes.each do |name, href, apilevel|
  class_name = name.split('.').last
  table[class_name] = [] if !table.has_key?(class_name)
  table[class_name] << [name, href, apilevel]
end

table.each do |class_name, candidates|
  table[class_name] = candidates.sort
end

db = PStore.new('table.db')
db.transaction{ db[:table] = table }

