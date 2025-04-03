<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
session_start();
include 'db.php';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $usuario = $_POST['usuario'];
    $clave = $_POST['clave'];
    $rol = $_POST['rol'];

    // Verificar si el usuario ya existe
    $sql = "SELECT * FROM usuarios WHERE usuario = '$usuario'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        echo "Error: Este usuario ya existe.";
    } else {
        // Cifrar la contraseña antes de guardarla
        $clave_cifrada = password_hash($clave, PASSWORD_BCRYPT);

        // Insertar usuario en la base de datos
        $sql = "INSERT INTO usuarios (usuario, clave, rol) VALUES ('$usuario', '$clave_cifrada', '$rol')";
        
        if ($conn->query($sql) === TRUE) {
            echo "Registro exitoso. <a href='login.php'>Iniciar sesión</a>";
        } else {
            echo "Error al registrar: " . $conn->error;
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Registro</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="container">
    <h2>Registro</h2>
    <form method="POST">
        <input type="text" name="usuario" placeholder="Usuario" required>
        <input type="password" name="clave" placeholder="Contraseña" required>
        <select name="rol">
            <option value="Cliente">Cliente</option>
            <option value="Vendedor">Vendedor</option>
            <option value="Administrador">Administrador</option>
            <option value="Proveedor">Proveedor</option>
        </select>
        <button type="submit">Registrarse</button>
    </form>
    <a href="login.php" class="link-button">Ya tengo una cuenta</a>
</div>

</body>
</html>
