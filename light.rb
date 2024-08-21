require 'nokogiri'
require 'fileutils'

HTMLBEG = <<~EOF
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>%s</title>
<style>
body {
  font-family: Copperplate;
  font-size: 1.2em;
  text-align: center; 
  color: #fff; 
  background-color: #343d46; 
}
.container {
  display: grid;
  grid-template-columns: repeat(auto-fit, 700px);
  justify-content: space-evenly;
  grid-gap: 20px;
}
.tag {
  justify-self: start;
  grid-column: 1 / -1;
  font-size: smaller;
  padding: 0 5px 0 5px;
  background-color: darkorange;
  border-radius: 10px;
}
video {
  border-radius: 10px;
}
</style>
</head>
<body class="container">
EOF

HTMLEND = <<~EOF
<script>
var list = document.querySelectorAll("video");
list.forEach(element => {
  element.volume = 0.1;
});
</script>
</body>
</html>
EOF

TAG = <<~EOF
<div class="tag">%s</div>
EOF

VIDEO = <<~EOF
<div>
  <div>%{desc}</div>
  <video width="700" height="394" controls>
    <source src="%{path}" type="video/mp4"/>
  </video>
</div>
EOF

def parse(src)
  File.open(src + 'config.xml', 'r') do |file|
    Nokogiri::XML(file).xpath('//item/@path|//item/@description')
  end.each_slice(2).map do |path, desc|
    desc = desc.to_s
    desc = desc.split('.').map { |token| token.strip }.join('. ')
    desc = desc.split(',').map { |token| token.strip }.join(', ')
    desc = desc.split('-').map { |token| token.strip }.join(': ')
    desc = desc.split('(').map { |token| token.strip }.join(' (')
    [path, desc]
  end
end

def cp(items, src, dst)
  return if Dir.exists? dst
  Dir.mkdir dst
  items.each do |path, _|
    FileUtils.cp src + path, dst
  end
end

def process(arg, file)
  src = '/Volumes/light/Content/moduls/z%02d/' % arg
  dst = 'm%02d/' % arg
  items = parse src
  cp items, src, dst
  file.write(
    TAG % dst.chomp('/'),
    items.map do |path, desc|
      VIDEO % { path: dst + path, desc: desc }
    end.join
  )
end

def run(*args)
  name = 'm%s.html' % args.map { |arg| '%02d' % arg }.join
  title = 'Module %s' % args.join(' ')
  File.open(name, 'w') do |file|
    file.write HTMLBEG % title
    args.each do |arg|
      process arg, file
    end
    file.write HTMLEND
  end
end

if __FILE__ == $0
  if ARGV.length < 1
    puts 'Too few arguments (a valid module number required)'
    exit
  end
  wd = File.basename __FILE__, '.rb'
  Dir.mkdir wd unless Dir.exists? wd
  Dir.chdir wd do 
    run *ARGV
  end
end

