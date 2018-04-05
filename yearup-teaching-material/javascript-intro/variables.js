/**
 * variables point to data. The data can be a primitive (integers, strings, etc),
 * an object or array, or a function. Basically, you can refer to anything with a variable.
 * Variables are declared using the reserved word var. 
 */

// This variable, x, holds the value 5
var x = 5;

// y holds the value x + 5, which refers to another variable 5
var y = x + 5;

// obj is an object with 2 properties
var obj = {
	key1: 'value1',
	key2: y
};

// arr is an array with 2 values
var arr = ['value1', 'value2'];

// helloWorld is a vairable that points to a function
var helloWorldVar = function() {
	alert('This is coming from helloWorldVar');
}