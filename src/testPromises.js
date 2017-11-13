//testPromises.js

function main() {
	outerPromise()
	.then((data) => console.log("promise got resolved to ", data))
}

//input: none
//output: String delivered through a Promise.
function innerPromise() {
	return new Promise((resolve) => {
		setTimeout(() => {
			resolve("innerPromise resolution value")
		}, 2000)
	})
}

function outerPromise() {
	return new Promise((resolve) => {
		return innerPromise()
	})
}



main()