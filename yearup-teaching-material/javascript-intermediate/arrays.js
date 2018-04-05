/**
 * ARRAYS (AND OBJECTS):
 * 
 * Arrays are data structures that hold data values
 * that are indexed sequentially, starting from 0
 * 
 * Objects are data structures that hold data values 
 * that are indexed by names (name-value pairs)
 */

var array = ['apple', 'banana', 'kiwi', 'orange', 'grape', 'strawberry'];

var object = {
	firstFruit: 	'Apple',
	secondFruit: 	'Banana',
	thirdFruit: 	'Kiwi',
	fourthFruit: 	'Orange',
	fifthFruit: 	'Grape', 
	sixthFruit: 	'Strawberry'
};

console.log(array);
console.log(object);


console.log('-------------------------------------------------------');
/**
 * we can access individual elements of arrays using an index.
 * we access object elements using names
 */

console.log('array[0] => ' + array[0]);
console.log('object.firstFruit => ' + object.firstFruit);


console.log('-------------------------------------------------------');
/**
 * we can use arrays in loops
 */

for (var index in array) {
	console.log('array[' + index + '] => ' + array[index]);
}

for (var pname in object) {
	console.log('object[' + pname + '] => ' + object[pname]);
}