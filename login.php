<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
session_start();
include 'db.php';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $usuario = $_POST['usuario'];
    $clave = $_POST['clave'];

    // Verificar si el usuario existe
    $sql = "SELECT * FROM usuarios WHERE usuario = '$usuario'";
    $result = $conn->query($sql);

    if ($result->num_rows == 1) {
        $row = $result->fetch_assoc();

        // Verificar si el usuario está bloqueado
        if ($row['bloqueado']) {
            echo "Este usuario está bloqueado. Contacta al administrador.";
        } else {
            // Verificar la contraseña
            if (password_verify($clave, $row['clave'])) {
                $_SESSION['usuario'] = $usuario;
                $_SESSION['rol'] = $row['rol'];
                $_SESSION['id_usuario'] = $row['id'];

                // Reiniciar los intentos fallidos al iniciar sesión correctamente
                $conn->query("UPDATE usuarios SET intentos_fallidos = 0 WHERE usuario = '$usuario'");

                // Redirigir según el rol
                if ($row['rol'] == "Cliente") {
                    header("Location: cliente.php");
                } elseif ($row['rol'] == "Vendedor") {
                    header("Location: vendedor.php");
                } elseif ($row['rol'] == "Administrador") {
                    header("Location: admin.php");
                }
                elseif ($row['rol'] == "Proveedor") {
                    header("Location: proveedor.php");
                }
                exit;
            } else {
                // Incrementar intentos fallidos
                $intentos = $row['intentos_fallidos'] + 1;
                $conn->query("UPDATE usuarios SET intentos_fallidos = $intentos WHERE usuario = '$usuario'");

                // Bloquear si supera los 4 intentos
                if ($intentos >= 4) {
                    $conn->query("UPDATE usuarios SET bloqueado = TRUE WHERE usuario = '$usuario'");
                    echo "Cuenta bloqueada por demasiados intentos fallidos.";
                } else {
                    echo "Contraseña incorrecta. Intentos: $intentos / 4";
                }
            }
        }
    } else {
        echo "Usuario no encontrado.";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="style.css">
    <title>Iniciar Sesión</title>
</head>
<body>
<div class="container">
    <h2>Iniciar Sesión</h2>
    <form method="POST">
        <input type="text" name="usuario" placeholder="Usuario" required>
        <input type="password" name="clave" placeholder="Contraseña" required>
        <button type="submit">Ingresar</button>
    </form>
    <a href="register.php" class="link-button">Registrarme</a>
</div>


</body>
</html>
