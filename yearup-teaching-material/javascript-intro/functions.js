/**
 * Functions are blocks of code that are referred to by a name so that they can
 * be reused. Functions can have input parameters and can return data.
 */

// This function, helloWorld, has no input parameters
// and calls another function (with an input param)
function helloWorld() {
	alert('Hello World!');
}

// alertWithParams takes in one parameter, param,
// which should be a string. The parameter is passed
// into another function.
function alertWithParam(param) {
	alert(param);
}

// callingCallbacks takes in one parameter, which
// must refer to a function. The input parameter
// is called immediately.
function callingCallbacks(callback) {
	callback();
}

// returningValues returns 5
function returningValues() {
	return 5;
}

// helloWorldRef is a variable that refers to a 
// function that is defined elsewhere
var helloWorldRef = helloWorld;

// objectWithFunctionRefs is an object with two properties,
// one of which refers to a function
var objectWithFunctionRefs = {
	ref1: helloWorld,
	ref2: 3
};

// window.onload is a global function that is defined by the
// javascript engine (which runs in the browser). We knwo this
// function is called when the window loads. If we want to interact
// with DOM elements, we can replace the window.onload function
// with our own so that we do not attempt to interact with the DOM
// until after the window has loaded.
// window.onload = function() {
// 	helloWorld();
//
// 	alertWithParam('Hey World!');
//
// 	callingCallbacks(helloWorld);
// }