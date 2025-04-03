<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
session_start();
include 'db.php';

// Verificar si el usuario es administrador
if (!isset($_SESSION['usuario']) || $_SESSION['rol'] != 'Administrador') {
    die("Acceso denegado.");
}

// Si se envía un usuario para desbloquear
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $usuario = $_POST['usuario'];
    
    $sql = "UPDATE usuarios SET intentos_fallidos = 0, bloqueado = FALSE WHERE usuario = '$usuario'";
    
    if ($conn->query($sql) === TRUE) {
        echo "Usuario desbloqueado con éxito.";
    } else {
        echo "Error al desbloquear: " . $conn->error;
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Desbloquear Usuario</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h2>Desbloquear Usuario</h2>
        <form method="POST">
            <input type="text" name="usuario" placeholder="Usuario a desbloquear" required><br>
            <button type="submit">Desbloquear</button>
        </form>
    </div>
</body>
</html>
