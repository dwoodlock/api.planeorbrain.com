# Plane or Brain backend APIs

This is the nodejs backend for the Plane or Brain game that I use to teach mobile app development to middle school aged kids.  This handles 2 POST transactions to file the student's code and upload their picture for the app.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.  You will need to change the AWS bits - credentials and bucket.  See deployment for notes on how to deploy the project on a live system.

### Prerequisites

nodejs
java (v8+)
rlwrap (if you use the repl)  


### Installing

For development, clone the repository and then

```
npm install 
npm run dev
```

After code changes, you will need to control-c and run again.  

To start up a repl

```
npm run repl
(in-ns 'server.core)
(load-file "src/server/core.cljs")
```

To build a production version ready for AWS let's say:

```
npm run build
```


The backend accepts two post transactions.  I haven't posted the front-end code yet so hard to test by yourself.

## Deployment

For AWS, assuming you have done a production build, just upload main.js (once built) and package.json.  There is an npm start
script that AWS will find and use to start it up.

## Built With

* ClojureScript

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


