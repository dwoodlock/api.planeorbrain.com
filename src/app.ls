; clojurescript things.
(macro def (symbol value)
	(const ~symbol ~value))
(macro let (names vals rest...)
  ((function ~names ~rest...) ~@vals))
(macro or (rest...)
	(|| ~rest...))
(macro defn (symbol value value2)
	(const ~symbol (function(~value) ~value2)))
(macro fn (args body)
	(function ~args ~body))
(macro -> (rest...)
	(chain ~rest...))

; imports
(def express (require "express"))
(def bodyParser (require "body-parser"))
(def cors (require "cors"))
(def AWS (require "aws-sdk"))
(def jo (require "jpeg-autorotate"))
(def multer (require "multer"))

; constants needed for all methods.
(def s3ToStudentCode 
	(let 
		(accessKeyId secretAccessKey) 
		("AKIAJYUDOK5G26RRCJJA" "eXQ2hWLubY/p2wzkWEXpwf342Meoo5+tX8fefUHi")
		(new AWS.S3 {
			accessKeyId,
			secretAccessKey,
			region: "us-east-1"})))
(def studentCodeBucket "www.gegirlstech.com")

; getting the express app setup.
(def app (express))
(def port (or process.env.PORT 9000))
(if (= port 9000) 
	(app.use (cors))
	(app.use (cors {origin: "http://www.gegirlstech.com"})))
(app.use (bodyParser.json {limit: '10mb'}))
(app.use (bodyParser.urlencoded { extended: false, limit: '10mb' }))

;the handlers
;pure function to turn req.body into putObject options
(defn saveCodeOptions (body) 
	(let 
		(pcNumber code month) 
		((.pcNumber body) (.code body) (.month body))
		(let (key) ((str "classes/" month "/studentCode/app" pcNumber ".js"))
			{	Bucket: studentCodeBucket,
				Key: key,
				Body: code})))

(defn promisifiedPutObject_ (options)
	(new Promise (fn 
		(resolve reject)
		(s3ToStudentCode.putObject
			options
			(fn (err data)
				(do
					(console.log err data)
					(if err 
						(reject err)
						(resolve data))))))))

;takes a body
;return a promise fulfilled by an plain js object to send back to the client.
(defn saveCodeHandler_ (body) 
		(promisifiedPutObject_ (saveCodeOptions body)))

(defn createAppHandler (handlerFn)
	(fn (req res)
		(-> 
			(handlerFn (.body req))
			(.then (fn (data) (-> (res.status 200) (.send {status:200, data}))))
			(.catch (fn (err) (-> (res.status 500) (.send {status: 500, message: err, type:'internal'})))))))



;pure function to deterine uploadpic options
(defn uploadpicOptions (body)
	(let 
		(month pcNumber filetype regex)
		((.month body) (.pcNumber body) (.filetype body) (new RegExp "^data:image\\/\\w+;base64,"))
		(let 
			(Key originalBuffer) 
			((str "classes/" month "/studentPics/studentPic" pcNumber)
			 (new Buffer (body.data_uri.replace regex "") "base64"))
			{ Bucket: studentCodeBucket, 
				Key,
				ContentType: filetype, 
				CacheControl: "no-cache",
				Body: originalBuffer})))

; input fileBuffer to rotate, optionx
; output new fileBuffer delivered through a promise.
(defn promisifiedJoRotate (fileBuffer options)
	(new Promise (fn (resolve)
		(jo.rotate 
			fileBuffer
			{}
				(fn (error buffer)
					(let (bufferToPut) ((if error fileBuffer buffer))
						(resolve bufferToPut)))))))

;takes a body
;return a promise fulfilled by an plain js object to send back to the client.
(defn uploadpicHandler_ (body) 
	(new Promise (fn (resolve reject)
		(-> 
			(promisifiedJoRotate (.Body (uploadpicOptions body)) {})
			(.then (fn (bufferToPut)
				(-> 
					(promisifiedPutObject_ (Object.assign {} (uploadpicOptions body) {Body: bufferToPut}))
					(.then (fn (data) (resolve data)))
					(.catch (fn (err) (reject err))))))))))

(defn main_ () 
	(do 
		(app.post 
			"/savecode" 
			(createAppHandler saveCodeHandler_))
		(app.post
			"/uploadpic"
			(-> (multer) (.single 'file'))
			(createAppHandler uploadpicHandler_))
		(app.listen port (fn () (console.log "I am listening on port " port "!")))))

(main_)





