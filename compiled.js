// Generated by Elfenben v1.0.14
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const AWS = require("aws-sdk");
const jo = require("jpeg-autorotate");
const multer = require("multer");
const AWSCredentials = require("./AWSCredentials");
const s3ToStudentCode = (function() {
    const accessKeyId = (AWSCredentials).accessKeyId,
        secretAccessKey = (AWSCredentials).secretAccessKey;
    return new AWS.S3({
			accessKeyId,
			secretAccessKey,
			region: "us-east-1"});
})();
const studentCodeBucket = "www.gegirlstech.com";
const app = express();
const port = (process.env.PORT || 9000);
((port === 9000) ?
    app.use(cors()) :
    app.use(cors({origin: "http://www.gegirlstech.com"})));
app.use(bodyParser.json({limit: '10mb'}));
app.use(bodyParser.urlencoded({ extended: false, limit: '10mb' }));
const saveCodeOptions = function(body) {
    return (function() {
        const pcNumber = (body).pcNumber,
            code = (body).code,
            month = (body).month,
            key = ["classes/",month,"/studentCode/app",pcNumber,".js"].join('');
        return {	Bucket: studentCodeBucket,
				Key: key,
				Body: code};
    })();
};
const promisifiedPutObject_ = function(options) {
    return new Promise(function(resolve,reject) {
        return s3ToStudentCode.putObject(options,function(err,data) {
            return (function() {
                console.log(err,data);
                return (err ?
                    reject(err) :
                    resolve(data));
            })();
        });
    });
};
const saveCodeHandler_ = function(body) {
    return promisifiedPutObject_(saveCodeOptions(body));
};
const createAppHandler = function(handlerFn) {
    return function(req,res) {
        return ((handlerFn((req).body)).then(function(data) {
            return (res.status(200)).send({status:200, data});
        })).catch(function(err) {
            return (res.status(500)).send({status: 500, message: err, type:'internal'});
        });
    };
};
const uploadpicOptions = function(body) {
    return (function() {
        const month = (body).month,
            pcNumber = (body).pcNumber,
            filetype = (body).filetype,
            regex = new RegExp("^data:image\\/\\w+;base64,"),
            Key = ["classes/",month,"/studentPics/studentPic",pcNumber].join(''),
            originalBuffer = new Buffer(body.data_uri.replace(regex,""),"base64");
        return { Bucket: studentCodeBucket, 
				Key,
				ContentType: filetype, 
				CacheControl: "no-cache",
				Body: originalBuffer};
    })();
};
const promisifiedJoRotate = function(fileBuffer,options) {
    return new Promise(function(resolve) {
        return jo.rotate(fileBuffer,{},function(error,buffer) {
            return (function() {
                const bufferToPut = (error ?
                    fileBuffer :
                    buffer);
                return resolve(bufferToPut);
            })();
        });
    });
};
const uploadpicHandler_ = function(body) {
    return (promisifiedJoRotate((uploadpicOptions(body)).Body,{})).then(function(bufferToPut) {
        return promisifiedPutObject_(Object.assign({},uploadpicOptions(body),{
            "Body": bufferToPut
        }));
    });
};
const main_ = function() {
    return (function() {
        app.post("/savecode",createAppHandler(saveCodeHandler_));
        app.post("/uploadpic",(multer()).single('file'),createAppHandler(uploadpicHandler_));
        return app.listen(port,function() {
            return console.log("I am listening on port ",port,"!");
        });
    })();
};
main_();
