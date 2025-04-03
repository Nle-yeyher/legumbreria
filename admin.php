<?php
session_start();
include("db.php");

// Verificar si el usuario es administrador
if (!isset($_SESSION['rol']) || $_SESSION['rol'] !== 'Administrador') {
    header("Location: login.php");
    exit();
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de Administrador</title>
    <link rel="stylesheet" href="admin.css">
</head>
<body>
    <div class="container">
        <h2>Panel de Administrador</h2>
        
        <!-- Mostrar Usuarios -->
        <h3>Usuarios Registrados</h3>
        <table border="1">
            <tr>
                <th>ID</th>
                <th>Usuario</th>
                <th>Rol</th>
                <th>Estado</th>
            </tr>
            <?php
            $result = $conn->query("SELECT id, usuario, rol, estado FROM usuarios");
            while ($row = $result->fetch_assoc()) {
                echo "<tr>
                        <td>{$row['id']}</td>
                        <td>{$row['usuario']}</td>
                        <td>{$row['rol']}</td>
                        <td>{$row['estado']}</td>
                    </tr>";
            }
            ?>
        </table>

        <!-- Mostrar Pedidos -->
        <h3>Pedidos Realizados</h3>
        <table border="1">
            <tr>
                <th>ID Pedido</th>
                <th>Usuario</th>
                <th>Estado</th>
                <th>Total</th>
                <th>Precio</th>
            </tr>
            <?php
  $result = $conn->query("SELECT carrito.id_carrito AS id_pedido, usuarios.usuario, productos.nombre AS producto, carrito.cantidad, (productos.precio * carrito.cantidad) AS total
  FROM carrito
  INNER JOIN usuarios ON carrito.id_usuario = usuarios.id
  INNER JOIN productos ON carrito.id_producto = productos.id_producto");

while ($row = $result->fetch_assoc()) {
echo "<tr>
<td>{$row['id_pedido']}</td>
<td>{$row['usuario']}</td>
<td>{$row['producto']}</td>
<td>{$row['cantidad']}</td>
<td>\${$row['total']}</td>
</tr>";
}

            ?>
        </table>

        <!-- Mostrar Stock -->
        <h3>Inventario</h3>
        <table border="1">
            <tr>
                <th>ID Producto</th>
                <th>Nombre</th>
                <th>Cantidad</th>
                <th>Precio</th>
            </tr>
            <?php
            $result = $conn->query("SELECT id_producto, nombre, cantidad, precio FROM productos");
            while ($row = $result->fetch_assoc()) {
                echo "<tr>
                        <td>{$row['id_producto']}</td>
                        <td>{$row['nombre']}</td>
                        <td>{$row['cantidad']}</td>
                        <td>\${$row['precio']}</td>
                    </tr>";
            }
            ?>
        </table>

        <a href="logout.php" class="link-button">Cerrar Sesión</a>
    </div>
</body>
</html>
