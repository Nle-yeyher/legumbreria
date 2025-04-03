<?php
session_start();
if (!isset($_SESSION['usuario']) || $_SESSION['rol'] !== "Vendedor") {
    echo "Acceso denegado.";
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="style.css">
    <title>Área Vendedor</title>
</head>
<body>
    <h2>Bienvenido, <?= $_SESSION['usuario']; ?> (Vendedor)</h2>
    <a href="logout.php">Cerrar sesión</a>
</body>
</html>
