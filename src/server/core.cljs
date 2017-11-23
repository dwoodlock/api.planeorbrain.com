(ns server.core
  (:require 
  	[cljs.nodejs :as node]
  	[server.AWSCredentials]
  	))
(node/enable-util-print!)

; imports
(def express (node/require "express"))
(def bodyParser (node/require "body-parser"))
(def cors (node/require "cors"))
(def AWS (node/require "aws-sdk"))
(def jo (node/require "jpeg-autorotate"))
(def multer (node/require "multer"))

; constants needed for all methods.
(def s3ToStudentCode 
	(let 
		[
			AWSCredentials server.AWSCredentials/AWSCredentials
			accessKeyId (:accessKeyId AWSCredentials)
			secretAccessKey (:secretAccessKey AWSCredentials)]
		(AWS.S3. #js {
			:accessKeyId accessKeyId,
			:secretAccessKey secretAccessKey,
			:region "us-east-1"})))
(def studentCodeBucket "www.planeorbrain.com")

; getting the express app setup.
(def app (express))
(def port (or js/process.env.PORT 9000))
(if (= port 9000) 
	(.use  app (cors))
	(.use app (cors #js {:origin "http://www.planeorbrain.com"})))
(.use app (.json bodyParser #js {:limit "10mb"}))
(.use app (.urlencoded bodyParser #js {:extended false :limit "10mb" }))

;the handlers
;pure function to turn req.body into putObject options
(defn saveCodeOptions [body] 
	(let 
		[
			pcNumber (.-pcNumber body) 
			code (.-code body)
			month (.-month body) 
			key (str "classes/" month "/studentCode/app" pcNumber ".js")
		]
			#js {	:Bucket studentCodeBucket,
				:Key key,
				:Body code}))

(defn createAppHandler [handlerFn]
	(fn [req res]
		(-> 
			(handlerFn (.-body req))
			(.then (fn [data] (-> (.status res 200) (.send #js {:status 200 :data data}))))
			(.catch (fn [err] (-> (.status res 500) (.send #js {:status 500 :message err :type "internal"})))))))

(defn promisifiedPutObject! [options]
	(js/Promise. (fn [resolve reject]
		(.putObject s3ToStudentCode
			options
			(fn [err data]
				(do
					(.log js/console err data)
					(if err 
						(reject err)
						(resolve data))))))))

;input: a body
;returns: a promise fulfilled by an plain js object to send back to the client.
(defn saveCodeHandler! [body] 
		(promisifiedPutObject! (saveCodeOptions body)))

; input fileBuffer to rotate, optionx
; output new fileBuffer delivered through a promise.
(defn promisifiedJoRotate [fileBuffer options]
	(js/Promise. (fn [resolve]
		(jo.rotate 
			fileBuffer
			#js {}
				(fn [error buffer]
					(let [bufferToPut (if error fileBuffer buffer)]
						(resolve bufferToPut)))))))

;input body
;returns a map of options
(defn uploadpicOptions [body]
	(let 
		[	month (.-month body)
			pcNumber (.-pcNumber body)
			filetype (.-filetype body)
			regex (js/RegExp. "^data:image\\/\\w+;base64,")
			Key (str "classes/" month "/studentPics/studentPic" pcNumber)
			originalBuffer 			 (js/Buffer. (.replace (.-data_uri body) regex "") "base64")]
			{ :Bucket studentCodeBucket, 
				:Key Key,
				:ContentType filetype, 
				:CacheControl "no-cache",
				:Body originalBuffer}))

;takes a body
;return a promise fulfilled by an plain js object to send back to the client.
(defn uploadpicHandler! [body] 
	(-> 
		(promisifiedJoRotate (:Body (uploadpicOptions body)) #js {})
		(.then (fn [bufferToPut]
			(promisifiedPutObject! (clj->js (assoc (uploadpicOptions body) "Body" bufferToPut)))))))

(defn -main []
	(let [port (or process.env.PORT 9000)]
		(do 
			(.post app 
				"/savecode" 
				(createAppHandler saveCodeHandler!))
			(.post app
				"/uploadpic"
				(-> (multer) (.single "file"))
				(createAppHandler uploadpicHandler!))
			(.listen app port (fn [] (.log js/console "I am listening on port " port "!")))))) 

(set! *main-cli-fn* -main)
