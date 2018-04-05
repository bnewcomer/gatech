<?php

if (isset($_GET['sql'])) {
	$sql = $_GET['sql'];

// create mysqli connection with info
// host: localhost
// user: yearup
// passwd: yearup
// db: yearup
$mysqli = new mysqli('localhost', 'yearup', 'yearup', 'yearup');

// run query
$result = $mysqli->query($sql);

// place result in an array
$parsedResult = array();
foreach ($result as $row)
	$parsedResult[] = $result->fetch_assoc();

// display roll as json
header('Content-Type: application/json');
echo json_encode($parsedResult);

} else {
?>

<form action="index.php" method="GET">
	<textarea name="sql" placeholder="sql"></textarea>
	<button type="submit">run</button>
</form>

<style>
form
{
	width:500px;
	margin:0 auto;
}
textarea
{
	display:block;
	margin:10px;
	width:100%;
	min-height:100px;
}
</style>

<?php } ?>