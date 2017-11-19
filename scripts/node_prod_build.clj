(require 'cljs.build.api)

(cljs.build.api/build "src"
  {
  	:main 'server.core
  	:language-in :ecmascript5-strict
  	:optimizations :simple
   	:output-to "main.js"
   	:target :nodejs})

