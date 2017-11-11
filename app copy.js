//app.js

const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const AWS = require('aws-sdk');
const multer  = require('multer');
var jo = require('jpeg-autorotate');

const accessKeyId = "AKIAJYUDOK5G26RRCJJA";
const	secretAccessKey = "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";

const s3ToStudentCode = new AWS.S3({
	accessKeyId,
	secretAccessKey,
	region: "us-east-1"
});
const studentCodeBucket = "www.gegirlstech.com";

const app = express()
const port = process.env.PORT || 9000;

if (port === 9000) {
  app.use(cors()); //port 9000 meaning running locally not on AWS/Production.  
} else {
  app.use(cors({origin: "http://www.gegirlstech.com"}))   
}

app.use(bodyParser.json({limit: '10mb'}))
app.use(bodyParser.urlencoded({ extended: false, limit: '10mb' }));

app.post("/savecode", function(req, res) {
	console.log(req.body);
	const {pcNumber, code, month} = req.body;
  const key = `classes/${month}/studentCode/app${pcNumber}.js`;
	s3ToStudentCode.putObject(
		{
			Bucket: studentCodeBucket,
			Key: key,
			Body: code
		}, 
		function(err, data) {
	   	if (err) {
				console.log(err, err.stack); // an error occurred	  
				res.status(500).send({status:500, message: 'internal error', type:'internal'}); 	
	   	} else { 
	   		console.log(data); 
	   		res.status(200).send(Object.assign({status: 200}, data));}
		});
})

function putObject(Bucket, Key, Body, ContentType) {
  return new Promise((resolve, reject) => {
    s3ToStudentCode.putObject(
      { Bucket, Key, Body, ContentType, CacheControl: "no-cache" },
      function(err, data) {
        if (err) {
          reject(err); 
        } else { 
          resolve(data);
      }});
})}

const upload = multer()

app.post("/uploadPic", upload.single('file'), function(req, res) {
  console.log("got a POST at /uploadPic");

  const { month, pcNumber, filetype } = req.body;
  const key = `classes/${month}/studentPics/studentPic${pcNumber}`;
  const success = (data) => {
    res.status(200).send(Object.assign({status: 200}, data));
  }

  const handleError = (err) => {
    res.status(500).send({status:500, message: err, type:'internal'});
  }   
  console.log(req.body.data_uri)
  const originalBuffer = new Buffer(req.body.data_uri.replace(/^data:image\/\w+;base64,/, ""),'base64');
  console.log("putting picture here ", studentCodeBucket, " ", key);
  jo.rotate(originalBuffer, {}, function(error, buffer, orientation) {
    if (error) { //this is OK usually.  no re-orientation needed
      putObject(studentCodeBucket, key, originalBuffer, filetype)
      .then(success)
      .catch(handleError)      
    } else {
      putObject(studentCodeBucket, key, buffer, filetype)
      .then(success)
      .catch(handleError)
    }
  });
});


app.listen(port, function () {
  console.log('I am listening on port ' + port + "!")
})