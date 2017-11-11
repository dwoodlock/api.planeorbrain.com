; clojurescript things.
(macro def (symbol value)
	(var ~symbol ~value))
(macro let (names vals rest...)
  ((function ~names ~rest...) ~@vals))
(macro or (rest...)
	(|| ~rest...))
(macro defn (symbol value value2)
	(var ~symbol (function(~value) ~value2)))
(macro fn (args body)
	(function ~args ~body))

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

(defn createPutObjectCallback (res)
	(fn (err data)
		(do 
			(console.log err data)
			(if err 
				(-> (res.status 500) (.send {status: 500, message: err, type:'internal'}))
				(-> (res.status 200) (.send {status:200, data}))))))

(app.post 
	"/savecode" 
	(fn 
		(req res) 
		(let 
			(options callback) 
			((saveCodeOptions (.body req)) (createPutObjectCallback res)) 
			(do 
				(console.log (.body req))
				(s3ToStudentCode.putObject 
					options
					callback)))))

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

(app.post
	"/uploadpic"
	(-> (multer) (.single 'file'))
	(fn 
		(req res) 
		(do 
			(console.log "got a post at /uploadpic")
			(let (options) ((uploadpicOptions (.body req)))
				(jo.rotate 
					(.Body options)
					{}
					(fn 
						(error buffer orientation)
						(let (bufferToPut) ((if error (.Body options) buffer))
							(let (updatedOptions) (Object.assign {} options {Body: bufferToPut})
								(s3ToStudentCode.putObject 
									options 
									(createPutObjectCallback res))))))))))

(app.listen port (fn () (console.log "I am listening on port " port "!")))

