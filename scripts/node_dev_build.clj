(require 'cljs.build.api)

(cljs.build.api/build "src"
  {
  	:main 'server.core
  	:optimizations :none
   	:output-to "main.js"
   	:target :nodejs})

