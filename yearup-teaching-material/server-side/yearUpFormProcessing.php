<?php

$link = mysqli_connect("localhost", "yearup", "yearup", "yearup");
	
$first_name = $_GET['first_name'];
$last_name = $_GET['last_name'];
$age = $_GET['age'];

echo "Connection successful </br>";

/* Select queries return a resultset */
if (isset($_GET['insert'])) {
	echo "creating person...</br>";
	
	$query = "INSERT INTO roll (first_name, last_name, age) "
		. "VALUES ('{$first_name}', '{$last_name}', {$age});";
} else if (isset($_GET['delete'])) {
	echo "deleting person...</br>";
	
	$query = "DELETE FROM roll "
		. "WHERE first_name = '{$first_name}';";
}

if (mysqli_query($link, $query)) {
	echo "query successful </br>";
} else {
	echo "query unsuccessful </br>";
}
?>

<a href="yearUp.php">Go Back</a>