<?php
$servername = "localhost";
$username = "root"; // Si usas XAMPP, el usuario por defecto es 'root'
$password_db = ""; // Deja vacío si no has puesto contraseña a MySQL
$dbname = "legumbreria"; // Nombre de tu base de datos

// Conexión a la base de datos
$conn = new mysqli($servername, $username, $password_db, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}
?>
