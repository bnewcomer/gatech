<?php
// create the link to the MySQL database
$link = mysqli_connect("localhost", "yearup", "yearup", "yearup");
?>

<?php

// check that connection was successful
if (mysqli_connect_errno()) {
    
	echo "Connection failed: " . mysqli_connect_error() . "\n";
	die();

} else {
	
	echo "Connection successful </br>";
	
	/* Select queries return a resultset */
	$sql = "SELECT * FROM roll;";

	if ($result = $link->query($sql)) {
    
		echo "query successful </br>";
   
		$resultArray = array();
		while ($row = $result->fetch_assoc()) {
			$resultArray[] = $row;
		}
   
	} else {
		echo "query unsuccessful";
	}
}
?>

<html>

	<head>
		<title>Year Up PHP</title>
	</head>
	
	<body>
		<div id="resultArrayDiv">
		<pre>
			<?php var_dump($resultArray); ?>
		</pre>
		</div>
		<hr>
		<form id="name_form" action="yearUpFormProcessing.php" method="get">
			Submit your info! </br></br>
			First Name:	<input type="text" name="first_name"></input> </br></br>
			Last Name: 	<input type="text" name="last_name"></input> </br></br>
			Age: 		<input type="number" name="age"></input> </br></br>
						<input type="submit" name="insert" value="Submit"/> </br></br>
						<input type="submit" name="delete" value="Delete"/>
		</form>
	</body>
	
</html>