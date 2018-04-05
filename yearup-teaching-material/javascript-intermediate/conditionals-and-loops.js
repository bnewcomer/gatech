/**
 * CONDITIONALS:
 * Conditional code is code that may or may not
 * be executed depending on runtime conditions
 * (which are evaluated when the program is running).
 * Conditional code is what gives code life and enables
 * interactivity.
 */

// create a variable
var x = 5;

console.log('x => ' + x);


console.log('-------------------------------------------------------');
/**
 * The if statement. If statements perform logical operations
 * and branch accordingly. If the expression in the if statement
 * evaluates to true then the code block immediately following the
 * statement is run. If the expression evaluates to false, then the
 * code block is skipped. If an else block is included, that code is
 * run.
 */

console.log('(x == 5) => ' + (x == 5));

if (x == 5) {
	console.log('x is equal to 5');
} else {
	console.log('x is not equal to 5');
}

console.log('-------------------------------------------------------');
/**
 * The while loop. The while loop is the simplest loop, 
 * which includes conditional code execution. A while loop will 
 * evaluate its logical expression and repeat the following code
 * block as long as the expression evaluates to true. When it
 * evaluates to false, control will leave the while loop.
 */

console.log('entering while loop');
while (x > 0) {
	
	console.log('x => ' + x + ', evaluating x > 0 => ' + (x > 0));
	
	x = x - 1;
}
console.log('while loop done');

console.log('x => ' + x + ', evaulating x > 0 => ' + (x > 0));

console.log('-------------------------------------------------------');
/**
 * The for loop. the for loop is really a dressed up while loop
 * that iterates for a certain number of types. To illistrate this
 * we will create two equivalent loops, one using while and one using for
 */

var i = 0;
while (i < 5) {
	console.log('this is the while loop, i => ' + i);
	i = i + 1;
}

for (var n = 0; n < 5; n++) {
	console.log('this is the for loop, n => ' + n);
}

console.log('-------------------------------------------------------');
/**
 * The for in loop. This is just a fancy loop that javascript has
 * created for developers' convenience. This loop iterates over an object
 * or array
 */

var arr = ['a', 'b', 'c', 'd', 'e'];

for (var i = 0; i < arr.length; i++) { 
	console.log('for loop: arr[' + i + '] => ' + arr[i]);
}

for (var n in arr) {
	console.log('for in loop: arr[' + n + '] => ' + arr[n]);
}












// Don't worry about code below this line ________________________________________


/**
 * logical operators:
 */
function goto(input) {
	switch (input) {
		case 'comparisons': 
			window.open('http://www.w3schools.com/js/js_comparisons.asp', '_blank');
			break;
		default:
			break;
	}
}